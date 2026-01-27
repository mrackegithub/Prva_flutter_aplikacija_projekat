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
      
      User? user = result.user;
      String uid = result.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': name,
      'surname': surname,
      'email': email,
      'registry_date': FieldValue.serverTimestamp(),
    });

      if (user != null) {
        // 2. Pošalji verifikacioni mejl
        await user.sendEmailVerification(acs);
        await _auth.signOut();
        // 3. OBAVEZNO: Odmah ga izloguj
        // Firebase ga po defaultu uloguje pri registraciji, mi to prekidamo
        
      }
      
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    }
  }

  // EMAIL/PASSWORD LOGIN
  Future<void> signInWithEmail(String email, String password) async {
    try {
      // 1. Pokušaj logovanja
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // 2. Osvježi podatke (da vidimo da li je u međuvremenu kliknuo link)
        await user.reload();
        
        // Moramo ponovo dohvatiti usera nakon reloada
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

  // GOOGLE SIGN-IN - ZA VERZIJU 7.2.0
  Future<UserCredential?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;
      
      // Proveri da li platforma podržava authenticate()
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        // Koristi novi API (v7.x)
        googleUser = await GoogleSignIn.instance.authenticate();
      
      
      
      

      // Uzmi auth detalje
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Dobij tokene preko authorizationClient (novi način u v7.x)
      final authClient = GoogleSignIn.instance.authorizationClient;
      final authorization = await authClient.authorizationForScopes(['email']);

      // Kreiraj Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken ,
        idToken: googleAuth.idToken,
      );

      // Uloguj se u Firebase
      return await _auth.signInWithCredential(credential);
      
    }} catch (e) {
      throw 'Google Sign-In greška: $e';
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
    await GoogleSignIn.instance.signOut();
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