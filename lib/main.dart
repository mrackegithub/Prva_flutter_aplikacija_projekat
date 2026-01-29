import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Ekrani/login.dart';
import 'Ekrani/welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prijavi Problem',
      theme: ThemeData(
        primarySwatch: Colors.green,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: const Color.fromARGB(255, 8, 187, 47),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Ovo automatski proverava da li je korisnik ulogovan
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);
  
  // Pomoćna funkcija za učitavanje role-a korisnika
  Future<String> _getUserRole(String uid) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        String role = doc.data()!['role'] as String;
        print("Uloga korisnika: $role");
        return role;
      }
      return "user";
    } catch (e) {
      print("Greška pri učitavanju role-a: $e");
      return "user";
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Ako se još učitava
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Ako je korisnik ulogovan
        if (snapshot.hasData) {
          User user = snapshot.data!;
          String uid = user.uid;
          
          if (user.emailVerified) {
            // Koristi FutureBuilder da čeka role
            return FutureBuilder<String>(
              future: _getUserRole(uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (roleSnapshot.hasData) {
                  String role = roleSnapshot.data!;
                  
                  if (role == "admin") {
                    print("Admin ulogovan");
                    return const WelcomeScreen();
                  } else {
                    print("Korisnik ulogovan");
                    return const WelcomeScreen();
                  }
                }
                
                return const WelcomeScreen();
              },
            );
          }
        }
        
        return const AuthPage();
      },
    );
  }
}