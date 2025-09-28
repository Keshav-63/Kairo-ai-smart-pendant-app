import 'package:flutter/material.dart';
import 'package:smart_pendant_app/services/drive_api_service.dart';

class DriveFilesScreen extends StatefulWidget {
  const DriveFilesScreen({super.key});

  @override
  State<DriveFilesScreen> createState() => _DriveFilesScreenState();
}

class _DriveFilesScreenState extends State<DriveFilesScreen> {
  late Future<List<dynamic>> _files;

  @override
  void initState() {
    super.initState();
    _files = DriveApiService().listFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Drive Files'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _files,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(snapshot.data![index]['name']),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text("${snapshot.error}"),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}