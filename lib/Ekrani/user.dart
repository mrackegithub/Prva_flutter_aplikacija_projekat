import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mapa.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import '../services/cloudinary.dart';
import '../services/gemini.dart';


Future<String> adresaIzKoordinata(double lat, double lng) async {
  try {
    // 1. Dobij listu mogućih lokacija za te koordinate
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

    // 2. Uzmi prvu (najprecizniju) lokaciju
    Placemark place = placemarks[0];

    String address =
        "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
    
    return address;
  } catch (e) {
    return "Fejlovalo je: $e";
  }
  
}




class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GeminiService _geminiService = GeminiService();

  File? _slika;
  String _statusPoruka = "Spremno za prijavu";
  String _koordinate = "";
  String _lokacija = "";
  String _analiza = "";
  Future<void> _prijaviProblem() async {
    setState(() {
      _statusPoruka = "Dobijam lokaciju...";
      _koordinate = "";
    });
    
    try {
      // 1. Provera da li je GPS upaljen
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _statusPoruka = "Molim te uključi GPS!");
        return;
      }

      // 2. Dozvole
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _statusPoruka = "Dozvola za lokaciju odbijena");
          return;
        }
      }

      // 3. Dobijanje lokacije (Najsigurniji način)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        
      );

      // 4. Kamera
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 30,
      );

      if (image != null) {
        File slikaFajl = File(image.path);
        setState(() {
           _slika = slikaFajl;
           _statusPoruka = "Šaljem sliku na server..."; // Obaveštavamo korisnika
        });
        String? uploadedUrl = await uploadToCloudinary(slikaFajl);

        if (uploadedUrl != null) {
          String adresa = await adresaIzKoordinata(position.latitude, position.longitude);
          setState(() {
          _slika = File(image.path);
          _koordinate = "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
          _lokacija = adresa;
          _geminiService.analizirajSliku(slikaFajl).then((analiza) {//valjda radi
            if (analiza != null) {
              setState(() {
                _analiza = analiza;
                _statusPoruka = "Problem prijavljen: $_analiza\nNa lokaciji:\n$_lokacija";
              });
            } else {
              setState(() {
                _statusPoruka = "Slika nije prepoznata kao komunalni problem.";
              });
            }
          });
          _statusPoruka = " Problem prijavljen na lokaciji:\n$_lokacija";
        }); 
        }

        
      } else {
        setState(() => _statusPoruka = "Slikanje otkazano.");
      }
    } catch (e) {
      setState(() => _statusPoruka = "Greška: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eko Redar - Prijavi Problem"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.amber),
              child: Text("meni", style: TextStyle(color: Colors.white,fontSize: 25)),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Mapa"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                );
              },

            ),
          ],
              ),
          
        ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Prikaz slike
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: _slika == null
                    ? const Icon(Icons.add_a_photo, size: 80, color: Colors.green)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_slika!, fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(height: 20),
              
              Text(_statusPoruka, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_koordinate.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_koordinate, style: const TextStyle(color: Colors.blueGrey, fontSize: 16)),
                ),
              
              const SizedBox(height: 30),

              // Dugme
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _prijaviProblem,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text("USLIKAJ I LOCIRAJ", style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}