import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';

class PDFViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const PDFViewerScreen({
    Key? key,
    required this.fileUrl,
    required this.fileName,
  }) : super(key: key);

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _downloadAndSaveFile();
  }

  Future<void> _downloadAndSaveFile() async {
    try {
      final response = await http.get(Uri.parse(widget.fileUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${widget.fileName}');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      } else {
        throw Exception(
          'Échec du téléchargement du PDF: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      setState(() {
        error = 'Échec du chargement du PDF: $e';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up temporary file
    if (localPath != null) {
      File(localPath!).delete().catchError((e) {
        print('Error deleting temp file: $e');
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fileName)),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text(error!))
              : localPath != null
              ? PDFView(
                filePath: localPath!,
                onError: (error) {
                  print('PDFView error: $error');
                  setState(() {
                    error = 'Échec du rendu du PDF: $error';
                  });
                },
              )
              : Center(child: Text('Échec du chargement du PDF')),
    );
  }
}
