import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});
  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Problem> problems = [];
  
  // Podrazumevana lokacija (Beograd)
  static const LatLng _initialPosition = LatLng(44.8176, 20.4762);

  @override
  void initState() {
    super.initState();
    _loadProblemsFromFirestore();
  }

  Future<void> _loadProblemsFromFirestore() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('problems').get();
      
      List<Problem> loadedProblems = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        double? latitude;
        double? longitude;
        
        // Pokušaj prvo sa Map strukturom
        if (data['coordinates'] is Map<String, dynamic>) {
          final coords = data['coordinates'] as Map<String, dynamic>;
          latitude = (coords['latitude'] as num?)?.toDouble();
          longitude = (coords['longitude'] as num?)?.toDouble();
        }
        // Ako je String, parsuj iz stringa "Lat: X, Long: Y"
        else if (data['coordinates'] is String) {
          final coordString = data['coordinates'] as String;
          try {
            final parts = coordString.split(', ');
            if (parts.length == 2) {
              final latStr = parts[0].replaceAll('Lat: ', '').trim();
              final lngStr = parts[1].replaceAll('Long: ', '').trim();
              latitude = double.tryParse(latStr);
              longitude = double.tryParse(lngStr);
            }
          } catch (e) {
            print('Greška pri parsiranju koordinata iz stringa: $e');
          }
        }
        
        if (latitude != null && longitude != null) {
          loadedProblems.add(
            Problem(
              id: doc.id,
              title: data['title'] ?? 'Problem',
              description: data['description'] ?? 'Bez opisa',
              location: data['location'] ?? 'Nepoznato',
              analysis: data['analysis'] ?? '',
              status: data['status'] ?? 'Nepoznato',
              latitude: latitude,
              longitude: longitude,
              imageUrl: data['imageUrl'],
            ),
          );
        }
      }
      
      setState(() {
        problems = loadedProblems;
      });
    } catch (e) {
      print('Greška pri učitavanju problema: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri učitavanju mape: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'aktivni':
        return Colors.red;
      case 'rešeni':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  void _showProblemDetails(Problem problem) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        problem.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(problem.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        problem.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  problem.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text(
                  'Lokacija: ${problem.location}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                if (problem.imageUrl != null && problem.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      problem.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                ],
                if (problem.analysis.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'AI Analiza:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    problem.analysis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa lokacije'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: problems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nema prijavljenih problema',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : FlutterMap(
              options: MapOptions(
                initialCenter: _initialPosition,
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_aplikacija',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: problems
                      .map(
                        (problem) => Marker(
                          point: LatLng(problem.latitude, problem.longitude),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showProblemDetails(problem),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getStatusColor(problem.status),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }
}

class Problem {
  final String id;
  final String title;
  final String description;
  final String location;
  final String analysis;
  final String status;
  final double latitude;
  final double longitude;
  final String? imageUrl;

  Problem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.analysis,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
  });
}