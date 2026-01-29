import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var acs = ActionCodeSettings(
    // URL na koji će korisnik biti poslat na webu (mora biti dodat u Firebase konzolu)
    url: 'https://mtsprojekat-flutter.firebaseapp.com/', 
    handleCodeInApp: true,
    androidPackageName: 'com.example.flutter_aplikacija', // tvoj namespace iz build.gradle
    androidInstallApp: true,
    androidMinimumVersion: '12',
);
  // Trenutni korisnik
  User? get currentUser => _auth.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;
  AuthService() {
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();
      _isGoogleSignInInitialized = true;
    } catch (e) {
      print('Failed to initialize Google Sign-In: $e');
    }
  }
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await _initializeGoogleSignIn();
    }
  }
  Future<GoogleSignInAccount> signInWithGoogle() async {
  await _ensureGoogleSignInInitialized();

  try {
    // authenticate() throws exceptions instead of returning null
    final GoogleSignInAccount account = await _googleSignIn.authenticate(
      scopeHint: ['email'],  // Specify required scopes
    );
    return account;
  } on GoogleSignInException catch (e) {
    print('Google Sign-In error: $e');
    rethrow;
  } catch (error) {
    print('Unexpected Google Sign-In error: $error');
    rethrow;
  }
}
Future<GoogleSignInAccount?> attemptSilentSignIn() async {
  await _ensureGoogleSignInInitialized();

  try {
    // attemptLightweightAuthentication can return Future or immediate result
    final result = _googleSignIn.attemptLightweightAuthentication();

    // Handle both sync and async returns
    if (result is Future<GoogleSignInAccount?>) {
      return await result;
    } else {
      return result as GoogleSignInAccount?;
    }
  } catch (error) {
    print('Silent sign-in failed: $error');
    return null;
  }
}
GoogleSignInAuthentication getAuthTokens(GoogleSignInAccount account) {
  // authentication is now synchronous
  return account.authentication;
}
GoogleSignInAccount? _currentGoogleUser;

bool get isSignedIn => _currentGoogleUser != null;

Future<void> signIn() async {
  try {
    _currentGoogleUser = await signInWithGoogle();
  } catch (error) {
    _currentGoogleUser = null;
    rethrow;
  }
}
Future<Map<String, dynamic>> signInWithGoogleFirebase() async {
  await _ensureGoogleSignInInitialized();

  try {
    // Authenticate with Google
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
      scopeHint: ['email'],
    );

    // Get authorization tokens
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create Firebase credential - idToken je dovoljan za Google OAuth
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase
    final UserCredential userCredential = await _auth.signInWithCredential(credential);

    // Update local state
    _currentGoogleUser = googleUser;

    // Check if new user
    bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

    return {
      'userCredential': userCredential,
      'isNewUser': isNewUser,
      'displayName': googleUser.displayName,
      'email': googleUser.email,
      'photoUrl': googleUser.photoUrl,
    };
  } catch (e) {
    print('Google Firebase Sign-In error: $e');
    rethrow;
  }
}
  
  // Sačuvaj Google korisnika u Firestore
  Future<void> saveGoogleUser(String uid, String email, String name, String surname) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'surname': surname,
        'email': email,
        'role': 'user',
        'registry_date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving Google user: $e');
      rethrow;
    }
  }

  // Stream auth promena
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // EMAIL/PASSWORD REGISTRACIJA
  Future<void> registerWithEmail(String email, String password, String name, String surname) async {
    try {
      // 1. Kreiraj korisnika u Firebase-u
      UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
      );
      String role = "user";
      User? user = result.user;
      String uid = result.user!.uid;
      if(name=="admin"){
        role="admin";
      }
      await _firestore.collection('users').doc(uid).set({
      'name': name,
      'surname': surname,
      'email': email,
      'role': role,
      'registry_date': FieldValue.serverTimestamp(),
    });

      if (user != null) {
        // Pošalji verifikacioni mejl
        await user.sendEmailVerification(acs);
        await _auth.signOut();
        
        
      }
      
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    }
  }

  // EMAIL/PASSWORD LOGIN
  Future<void> signInWithEmail(String email, String password) async {
    try {
      // Pokušaj logovanja
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        
        await user.reload();
        
        
        User? refreshedUser = _auth.currentUser;

        // 3. Ako NIJE potvrdio, izbaci ga i javi grešku
        if (refreshedUser != null && !refreshedUser.emailVerified) {
          await _auth.signOut();
          throw 'Vaš email nije verifikovan. Proverite inbox pre prijave.';
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (e) {
      rethrow;
    }
  }

 

  // PASSWORD RESET
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentGoogleUser = null;
    await _auth.signOut();
  }

  // ERROR HANDLING
  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Lozinka je previše slaba';
      case 'email-already-in-use':
        return 'Email već postoji';
      case 'user-not-found':
        return 'Korisnik ne postoji';
      case 'wrong-password':
        return 'Pogrešna lozinka';
      case 'invalid-email':
        return 'Nevažeći email';
      default:
        return e.message ?? 'Greška';
    }
  }
}