import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:html' as html;

class SimpleTestScreen extends StatefulWidget {
  const SimpleTestScreen({super.key});

  @override
  State<SimpleTestScreen> createState() => _SimpleTestScreenState();
}

class _SimpleTestScreenState extends State<SimpleTestScreen> {
  String _status = 'Ready to test';
  List<dynamic> _documents = [];
  bool _loading = false;
  bool _uploading = false;
  String? _token;
  PlatformFile? _selectedFile;

  Future<void> _testLogin() async {
    setState(() {
      _loading = true;
      _status = 'Testing login...';
    });

    try {
      final requestBody = jsonEncode({'username': 'admin', 'password': 'admin123'});
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/auth/login/'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        setState(() {
          _status = 'Login successful! Token: ${data['token'].substring(0, 10)}...';
        });

        // Now test PDF documents
        await _testPdfDocuments(_token!);
      } else {
        String serverMessage = '${response.statusCode} - ${response.body}';
        try {
          final decoded = jsonDecode(response.body);
          serverMessage = decoded.toString();
        } catch (_) {}

        // ignore: avoid_print
        print('Test login failed (${response.statusCode}): ${response.body}');

        setState(() {
          _status = 'Login failed: $serverMessage';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Test login error: $e');
      setState(() {
        _status = 'Login error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _testPdfDocuments(String token) async {
    setState(() {
      _status = 'Testing PDF documents API...';
    });

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/pdf/documents/?page=1'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _documents = data['results'] ?? [];
          _status = 'PDF API successful! Found ${_documents.length} documents';
        });
      } else {
        setState(() {
          _status = 'PDF API failed: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'PDF API error: $e';
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _status = 'Selected file: ${_selectedFile!.name}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error picking file: $e';
      });
    }
  }

  Future<void> _uploadPdf() async {
    if (_selectedFile == null) {
      setState(() {
        _status = 'Please select a PDF file first';
      });
      return;
    }

    if (_token == null) {
      setState(() {
        _status = 'Please login first';
      });
      return;
    }

    setState(() {
      _uploading = true;
      _status = 'Uploading PDF...';
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/api/pdf/upload/'),
      );

      request.headers['Authorization'] = 'Token $_token';
      request.fields['title'] = _selectedFile!.name.replaceAll('.pdf', '');

      if (_selectedFile!.bytes != null) {
        // For web, use bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'pdf_file',
            _selectedFile!.bytes!,
            filename: _selectedFile!.name,
          ),
        );
      } else {
        setState(() {
          _status = 'Error: Could not read file data';
          _uploading = false;
        });
        return;
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        setState(() {
          _status = 'PDF uploaded successfully! Processing...';
          _selectedFile = null;
        });

        // Refresh the documents list
        await _testPdfDocuments(_token!);
      } else {
        setState(() {
          _status = 'Upload failed: ${response.statusCode} - $responseBody';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Upload error: $e';
      });
    }

    setState(() {
      _uploading = false;
    });
  }

  void _downloadAudio(String audioUrl, String title) {
    try {
      // Create and click anchor directly without storing unused local variable
      html.AnchorElement(href: audioUrl)
        ..target = '_blank'
        ..download = '${title.replaceAll(' ', '_')}.wav'
        ..click();

      setState(() {
        _status = 'Downloading audio: $title';
      });
    } catch (e) {
      setState(() {
        _status = 'Error downloading audio: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF to Audio Converter'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                'Status: $_status',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),

            // Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _testLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login & Load Documents', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),

            // PDF Upload Section
            if (_token != null) ...[
              const Divider(),
              const Text(
                'PDF Upload & Conversion',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // File Selection
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFile != null
                          ? 'Selected: ${_selectedFile!.name}'
                          : 'No file selected',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Size: ${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // File picker and upload buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _uploading ? null : _pickFile,
                      icon: const Icon(Icons.file_present),
                      label: const Text('Select PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_uploading || _selectedFile == null) ? null : _uploadPdf,
                      icon: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload),
                      label: Text(_uploading ? 'Uploading...' : 'Upload & Convert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Documents List
            if (_documents.isNotEmpty) ...[
              const Text(
                'PDF Documents:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(doc['title'] ?? 'No title'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${doc['conversion_status'] ?? 'Unknown'}'),
                            Text('Uploaded by: ${doc['uploaded_by'] ?? 'Unknown'}'),
                            if (doc['audio_file'] != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.volume_up, size: 16, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        // Download audio file
                                        final audioUrl = 'http://127.0.0.1:8000${doc['audio_file']}';
                                        _downloadAudio(audioUrl, doc['title']);
                                      },
                                      child: const Text(
                                        'Audio Available (Click to download)',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        leading: Icon(
                          doc['conversion_status'] == 'completed'
                              ? Icons.check_circle
                              : doc['conversion_status'] == 'failed'
                                  ? Icons.error
                                  : Icons.hourglass_empty,
                          color: doc['conversion_status'] == 'completed'
                              ? Colors.green
                              : doc['conversion_status'] == 'failed'
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}