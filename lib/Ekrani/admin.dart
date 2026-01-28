import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final List<Map<String, String>> reports = [
    {'id': '1', 'user': 'John Doe', 'title': 'Bug Report', 'date': '2024-01-15', 'description': 'App crashes on login screen'},
    {'id': '2', 'user': 'Jane Smith', 'title': 'Feature Request', 'date': '2024-01-14', 'description': 'Add dark mode support'},
    {'id': '3', 'user': 'Mike Johnson', 'title': 'Performance Issue', 'date': '2024-01-13', 'description': 'Slow loading on home page'},
    {'id': '4', 'user': 'Sarah Williams', 'title': 'UI Bug', 'date': '2024-01-12', 'description': 'Button alignment issues'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Reports'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return GestureDetector(
            onTap: () {
              _showReportDetail(context, report);
            },
            child: Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(report['title']!),
                subtitle: Text('${report['user']!} - ${report['date']!}'),
                trailing: const Icon(Icons.arrow_forward),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showReportDetail(BuildContext context, Map<String, String> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report['title']!),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('User: ${report['user']!}'),
              const SizedBox(height: 8),
              Text('Date: ${report['date']!}'),
              const SizedBox(height: 8),
              Text('Description: ${report['description']!}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}