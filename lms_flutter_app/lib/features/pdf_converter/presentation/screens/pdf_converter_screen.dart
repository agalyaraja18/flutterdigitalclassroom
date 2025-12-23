import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/pdf_provider.dart';
import '../../domain/models/pdf_document_model.dart';

class PdfConverterScreen extends StatefulWidget {
  const PdfConverterScreen({super.key});

  @override
  State<PdfConverterScreen> createState() => _PdfConverterScreenState();
}

class _PdfConverterScreenState extends State<PdfConverterScreen> {
  final PdfProvider _pdfProvider = PdfProvider();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlayingUrl;
  bool _isPlaying = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _pdfProvider.startPollingForUpdates();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pdfProvider.dispose();
    super.dispose();
  }

  Future<void> _uploadPdf() async {
    // Pick PDF file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: true, // Important for web compatibility
    );

    if (result == null || result.files.isEmpty) return;

    final platformFile = result.files.single;
    final fileName = platformFile.name;

    // Validate file size (max 50MB)
    if (platformFile.size > 50 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File size too large. Maximum size is 50MB.'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
      return;
    }

    // Show title input dialog
    final title = await _showTitleInputDialog(fileName);
    if (title == null || title.trim().isEmpty) return;

    // Upload PDF using the web-compatible method
    final success = await _pdfProvider.uploadPdfFromPlatformFile(platformFile, title.trim());

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF uploaded successfully! Conversion will start shortly.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_pdfProvider.errorMessage ?? 'Upload failed'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<String?> _showTitleInputDialog(String fileName) async {
    final controller = TextEditingController(
      text: fileName.replaceAll('.pdf', '').replaceAll('_', ' '),
    );

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a title for your PDF document:'),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Title',
              controller: controller,
              hint: 'Enter document title',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                Navigator.of(context).pop(title);
              }
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _pdfProvider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PDF to Audio'),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _pdfProvider.loadDocuments(refresh: true),
            ),
          ],
        ),
        body: Consumer<PdfProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.documents.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Column(
              children: [
                // Upload Section
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Convert PDF to Audio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload your PDF document and we\'ll convert it to an audio file for you',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: 'Upload PDF',
                        onPressed: provider.isUploading ? null : _uploadPdf,
                        isLoading: provider.isUploading,
                        backgroundColor: Colors.white,
                        textColor: Colors.red.shade600,
                        icon: const Icon(Icons.upload_file, color: Colors.red),
                      ),
                    ],
                  ),
                ),

                // Documents List
                Expanded(
                  child: provider.documents.isEmpty
                      ? _buildEmptyState()
                      : _buildDocumentsList(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No PDF documents yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first PDF to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(PdfProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadDocuments(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.documents.length + (provider.hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.documents.length) {
            // Load more indicator
            provider.loadMoreDocuments();
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final document = provider.documents[index];
          return _buildDocumentCard(document, provider);
        },
      ),
    );
  }

  Widget _buildDocumentCard(PdfDocument document, PdfProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // PDF Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Document Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.onSurfaceColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uploaded by ${document.uploadedBy}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(document.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(document.conversionStatus).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    document.statusDisplayText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(document.conversionStatus),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          if (document.isCompleted || document.isFailed)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                    if (document.isCompleted && document.audioFile != null) ...[
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_isPlaying) {
                                _pauseAudio();
                              } else if (_isPaused) {
                                _resumeAudio();
                              } else {
                                _playAudio(document.audioFile!);
                              }
                            },
                            icon: Icon(_isPlaying ? Icons.pause : (_isPaused ? Icons.play_arrow : Icons.play_arrow)),
                            color: AppConstants.primaryColor,
                          ),
                          IconButton(
                            onPressed: () => _stopAudio(),
                            icon: const Icon(Icons.stop),
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomButton(
                              text: 'Download',
                              onPressed: () => _downloadAudio(document.audioFile!),
                              height: 40,
                              icon: const Icon(Icons.download, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (document.isFailed) ...[
                    Expanded(
                      child: CustomButton(
                        text: 'Retry',
                        onPressed: () => provider.retryConversion(document.id),
                        type: ButtonType.outline,
                        height: 40,
                        icon: const Icon(Icons.refresh, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Delete button
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _deleteDocument(document, provider),
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),

          // Progress Indicator for Processing
          if (document.isProcessing || document.isPending)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(document.conversionStatus),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    document.isPending
                        ? 'Waiting to be processed...'
                        : 'Converting PDF to audio...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      final src = _absoluteAudioUrl(audioUrl);

      // If already playing a different URL, stop it first
      if (_currentPlayingUrl != null && _currentPlayingUrl != src) {
        await _audioPlayer.stop();
      }

      _currentPlayingUrl = src;
      await _audioPlayer.play(UrlSource(src));
      _isPlaying = true;
      _isPaused = false;
      if (mounted) setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playing audio...'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to play audio'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
      _isPaused = true;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pause audio'), backgroundColor: AppConstants.errorColor),
        );
      }
    }
  }

  Future<void> _resumeAudio() async {
    try {
      if (_currentPlayingUrl != null) {
        await _audioPlayer.resume();
        _isPlaying = true;
        _isPaused = false;
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resume audio'), backgroundColor: AppConstants.errorColor),
        );
      }
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _isPaused = false;
      _currentPlayingUrl = null;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to stop audio'), backgroundColor: AppConstants.errorColor),
        );
      }
    }
  }

  String _absoluteAudioUrl(String audioUrl) {
    String src = audioUrl;
    if (!src.startsWith('http')) {
      final base = Uri.parse(AppConstants.baseUrl);
      final origin = '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
      src = origin + (audioUrl.startsWith('/') ? audioUrl : '/$audioUrl');
    }
    return src;
  }

  Future<void> _downloadAudio(String audioUrl) async {
    try {
      String src = audioUrl;
      if (!src.startsWith('http')) {
        final base = Uri.parse(AppConstants.baseUrl);
        final origin = '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
        src = origin + (audioUrl.startsWith('/') ? audioUrl : '/$audioUrl');
      }
      final uri = Uri.parse(src);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $audioUrl';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download audio'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteDocument(PdfDocument document, PdfProvider provider) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final success = await provider.deleteDocument(document.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to delete document'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    }
  }
}