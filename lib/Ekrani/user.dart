import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _slika;
  String _statusPoruka = "Spremno za prijavu";
  String _koordinate = "";
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _prijaviProblem() async {
    // Validacija
    if (_titleController.text.isEmpty) {
      _showSnackBar("Molim te unesi naslov problema", isError: true);
      return;
    }

    if (_slika == null) {
      _showSnackBar("Molim te fotografiraj problem", isError: true);
      return;
    }

    setState(() {
      _statusPoruka = "Dobijam lokaciju...";
      _isSubmitting = true;
    });
    
    try {
      //Provera da li je GPS upaljen
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _statusPoruka = "Molim te uključi GPS!");
        return;
      }

      //Dozvole
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _statusPoruka = "Dozvola za lokaciju odbijena");
          return;
        }
      }

      //Dobijanje lokacije
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _statusPoruka = "Učitavam sliku na server...";
        _koordinate = "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
      });

      String? uploadedUrl = await uploadToCloudinary(_slika!);

      if (uploadedUrl != null) {
        String adresa = await adresaIzKoordinata(position.latitude, position.longitude);
        
        setState(() {
          _statusPoruka = "Analiziram sliku...";
        });

        // Analiza slike
        String? analiza = await _geminiService.analizirajSliku(_slika!);
        
        if (analiza != null) {
          // Sačuva problem u Firestore
          try {
            await FirebaseFirestore.instance.collection('problems').add({
              'userId': FirebaseAuth.instance.currentUser?.uid,
              'title': _titleController.text,
              'description': _descriptionController.text,
              'analysis': analiza,
              'location': adresa,
              'coordinates': _koordinate,
              'imageUrl': uploadedUrl,
              'status': 'pending',
              'timestamp': DateTime.now(),
            });

            if (mounted) {
              setState(() {
                _statusPoruka = "Problem je uspešno prijavljen!";
                _isSubmitting = false;
              });

              _showSnackBar("Problem prijavljen! Hvala na prijavi.", isError: false);

              // Očisti forme
              _titleController.clear();
              _descriptionController.clear();
              _slika = null;
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _statusPoruka = "Greška pri čuvanju: $e";
                _isSubmitting = false;
              });
            }
            print('Greška pri čuvanju problema: $e');
          }
        } else {
          if (mounted) {
            setState(() {
              _statusPoruka = "Slika nije prepoznata kao komunalni problem.";
              _isSubmitting = false;
            });
            _showSnackBar("Slika nije prepoznata kao komunalni problem", isError: true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusPoruka = "Greška: $e";
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _fotografirajProblem() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 30,
      );

      if (image != null) {
        setState(() {
          _slika = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar("Greška pri fotografisanju: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prijavi Problem"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: _buildSidebar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prijavi Problem',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fotografiraj i prijavi komunalni problem sa detaljima',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Naslov
                  Text(
                    'Naslov problema',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Npr. Oštećena šina, Bujica vode...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Opis
                  Text(
                    'Opis problema (opciono)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Dodaj detaljniji opis problema...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Slika
                  Text(
                    'Fotografija problema',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.green[300]!,
                        width: 2,
                      ),
                    ),
                    child: _slika == null
                        ? InkWell(
                            onTap: _fotografirajProblem,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 60,
                                  color: Colors.green[600],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Dodaj fotografiju',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.file(
                                  _slika!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: FloatingActionButton.small(
                                  backgroundColor: Colors.red[600],
                                  onPressed: () {
                                    setState(() => _slika = null);
                                  },
                                  child: const Icon(Icons.close),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Status poruka
                  if (_statusPoruka.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[300]!),
                      ),
                      child: Text(
                        _statusPoruka,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Dugme za slanje
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _prijaviProblem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        disabledBackgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isSubmitting ? 'Slanje...' : 'Pošalji Prijavu',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green[700],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Korisnik',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? 'email@example.com',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: Colors.green[700]),
            title: const Text('Početna'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.list_alt, color: Colors.blue[600]),
            title: const Text('Vidi Probleme'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[600]),
            title: const Text('Odjavi Se'),
            onTap: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthPage()),
                    (route) => false,
                  );
                }
              } catch (e) {
                _showSnackBar('Greška pri logoutu: $e', isError: true);
              }
            },
          ),
        ],
      ),
    );
  }
}