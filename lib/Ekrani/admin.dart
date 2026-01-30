import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'mapa.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedStatus = 'Svi';
  String _sortBy = 'datum_silazno'; // datum_silazno, datum_uzlazno, status

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Odjavi se',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF4CAF50),
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    'Admin Meni',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upravljanje problemima',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildSidebarItem(
                    icon: Icons.dashboard,
                    label: 'Sve probleme',
                    onTap: () {
                      setState(() => _selectedStatus = 'Svi');
                      Navigator.pop(context);
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.pending_actions,
                    label: 'Aktivni problemi',
                    onTap: () {
                      setState(() => _selectedStatus = 'Aktivni');
                      Navigator.pop(context);
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.check_circle,
                    label: 'Rešeni problemi',
                    onTap: () {
                      setState(() => _selectedStatus = 'Rešeni');
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(height: 24),
                  _buildSidebarItem(
                    icon: Icons.map,
                    label: 'Mapa',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapaScreen()),
                      );
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.analytics,
                    label: 'Statistika',
                    onTap: () {
                      Navigator.pop(context);
                      _showStatistike();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Sortiranje i filtriranje
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton('Svi'),
                        const SizedBox(width: 8),
                        _buildFilterButton('Aktivni'),
                        const SizedBox(width: 8),
                        _buildFilterButton('Rešeni'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _sortBy,
                  onChanged: (value) => setState(() => _sortBy = value!),
                  items: const [
                    DropdownMenuItem(
                      value: 'datum_silazno',
                      child: Text('Najnoviji prvi'),
                    ),
                    DropdownMenuItem(
                      value: 'datum_uzlazno',
                      child: Text('Najstariji prvi'),
                    ),
                    DropdownMenuItem(
                      value: 'status',
                      child: Text('Po statusu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista problema
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('problems')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_turned_in,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nema prijavljenih problema',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var problems = snapshot.data!.docs;

                // Filtriraj po statusu
                if (_selectedStatus != 'Svi') {
                  problems = problems
                      .where((doc) =>
                          (doc.data() as Map<String, dynamic>)['status']
                              .toLowerCase() ==
                          _selectedStatus.toLowerCase())
                      .toList();
                }

                // Sortiranje
                if (_sortBy == 'datum_uzlazno') {
                  problems.sort((a, b) {
                    final aTime =
                        (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                    final bTime =
                        (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                    return (aTime?.compareTo(bTime ?? Timestamp.now()) ?? 0);
                  });
                } else if (_sortBy == 'status') {
                  problems.sort((a, b) {
                    final aStatus =
                        ((a.data() as Map<String, dynamic>)['status'] as String?)
                                ?.toLowerCase() ??
                            '';
                    final bStatus =
                        ((b.data() as Map<String, dynamic>)['status'] as String?)
                                ?.toLowerCase() ??
                            '';
                    return aStatus.compareTo(bStatus);
                  });
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: problems.length,
                  itemBuilder: (context, index) {
                    final data = problems[index].data() as Map<String, dynamic>;
                    return _buildProblemCard(
                      problems[index].id,
                      data,
                      context,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4CAF50)),
      title: Text(label),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: Colors.grey[200],
    );
  }

  Widget _buildFilterButton(String label) {
    final isSelected = _selectedStatus == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildProblemCard(
    String docId,
    Map<String, dynamic> data,
    BuildContext context,
  ) {
    final status = (data['status'] as String?)?.toLowerCase() ?? 'aktivni';
    final timestamp = data['timestamp'] as Timestamp?;
    final date = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(
                timestamp.millisecondsSinceEpoch)
            .toLocal()
            .toString()
            .split('.')[0]
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Bez naslova',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (status != 'rešeni')
                    ElevatedButton.icon(
                      onPressed: () => _markAsResolved(docId),
                      icon: const Icon(Icons.check),
                      label: const Text('Reši'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(docId, data['title'] ?? 'Problem'),
                    icon: const Icon(Icons.delete),
                    label: const Text('Obriši'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showProblemDetails(context, docId, data),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Detalji',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProblemDetails(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data['title'] ?? 'Bez naslova',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              _detailRow('Opis:', data['description'] ?? 'N/A'),
              const SizedBox(height: 12),
              _detailRow('Korisnik:', data['userId'] ?? 'N/A'),
              const SizedBox(height: 12),
              _detailRow(
                'Status:',
                (data['status'] as String?)?.toUpperCase() ?? 'N/A',
              ),
              const SizedBox(height: 12),
              _detailRow(
                'Lokacija:',
                data['location'] ?? data['adresa'] ?? 'N/A',
              ),
              const SizedBox(height: 12),
              _detailRow(
                'Trebam pomoć:',
                (data['needsHelp'] as bool?) ?? false ? 'DA' : 'NE',
              ),
              if (data['imageUrl'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    data['imageUrl'],
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Zatvori'),
                  ),
                  const SizedBox(width: 12),
                  if ((data['status'] as String?)?.toLowerCase() != 'rešeni')
                    ElevatedButton.icon(
                      onPressed: () {
                        _markAsResolved(docId);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Označi kao rešeno'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(String docId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje problema'),
        content: Text('Da li si siguran da želiš da obrišeš problem "$title"?\n\nOva akcija se ne može poništiti.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteProblem(docId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Obriši', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _markAsResolved(String docId) {
    _firestore.collection('problems').doc(docId).update({
      'status': 'rešeni',
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Problem označen kao rešen'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: $e'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _deleteProblem(String docId) {
    _firestore.collection('problems').doc(docId).delete().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Problem obrisan'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška pri brisanju: $e'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _showStatistike() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Statistika problema',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('problems').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  int ukupno = docs.length;
                  int aktivni = docs
                      .where((d) =>
                          ((d.data() as Map)['status'] as String?)
                              ?.toLowerCase() ==
                          'aktivni')
                      .length;
                  int reseni = docs
                      .where((d) =>
                          ((d.data() as Map)['status'] as String?)
                              ?.toLowerCase() ==
                          'rešeni')
                      .length;
                  int trebaJuPomoc = docs
                      .where((d) =>
                          ((d.data() as Map)['needsHelp'] as bool?) ?? false)
                      .length;

                  return Column(
                    children: [
                      _statCard('Ukupno problema', ukupno.toString(), Colors.blue),
                      const SizedBox(height: 12),
                      _statCard('Aktivnih', aktivni.toString(), Colors.orange),
                      const SizedBox(height: 12),
                      _statCard('Rešenih', reseni.toString(), Colors.green),
                      const SizedBox(height: 12),
                      _statCard('Trebaju pomoć', trebaJuPomoc.toString(), Colors.purple),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktivni':
        return Colors.red;
      case 'rešeni':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odjava'),
        content: const Text('Да ли si siguran da želiš da se odjaviš?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Odjavi se', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}