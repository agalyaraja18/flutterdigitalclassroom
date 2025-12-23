import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/pdf_analyzer_provider.dart';
import '../../models/chat_message.dart';

class PdfAnalyzerScreen extends StatefulWidget {
  const PdfAnalyzerScreen({super.key});

  @override
  State<PdfAnalyzerScreen> createState() => _PdfAnalyzerScreenState();
}

class _PdfAnalyzerScreenState extends State<PdfAnalyzerScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PdfAnalyzerProvider>(context, listen: false).addWelcomeMessage();
    });
  }

  Future<void> _pickAndAnalyzePdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true, // This ensures bytes are available
      );

      if (result != null && result.files.first.bytes != null) {
        final fileName = result.files.first.name;
        final bytes = result.files.first.bytes!;
        
        // Show title input dialog
        final title = await _showTitleDialog(fileName);
        if (title == null || title.isEmpty) return;
        
        final provider = Provider.of<PdfAnalyzerProvider>(context, listen: false);
        final (success, error) = await provider.uploadPdfFromBytes(
          title: title,
          fileName: fileName,
          bytes: bytes,
        );
        
        if (!success && mounted) {
          _showSnackBar(error ?? 'Failed to upload PDF');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error selecting PDF: ${e.toString()}');
      }
    }
  }

  Future<String?> _showTitleDialog(String fileName) async {
    final controller = TextEditingController(text: fileName.replaceAll('.pdf', ''));
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.description, color: AppConstants.primaryColor),
            SizedBox(width: 8),
            Text('PDF Title'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter a title for your PDF document:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Enter PDF title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    _queryController.clear();
    
    final provider = Provider.of<PdfAnalyzerProvider>(context, listen: false);
    final (success, error) = await provider.queryPdf(query);
    
    if (!success && mounted) {
      _showSnackBar(error ?? 'Failed to send query');
    }
  }

  // Future<void> _getSummary() async {
  //   final provider = Provider.of<PdfAnalyzerProvider>(context, listen: false);
  //   final (success, error) = await provider.getSummary();
  //   
  //   if (!success && mounted) {
  //     _showSnackBar(error ?? 'Failed to get summary');
  //   }
  // }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear the conversation and reset the PDF analyzer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<PdfAnalyzerProvider>(context, listen: false).clearSession();
              Provider.of<PdfAnalyzerProvider>(context, listen: false).addWelcomeMessage();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PDF Analyzer', style: TextStyle(fontSize: 18)),
            Consumer<PdfAnalyzerProvider>(
              builder: (context, provider, child) {
                if (provider.currentPdfTitle != null) {
                  return Text(
                    provider.currentPdfTitle!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Consumer<PdfAnalyzerProvider>(
            builder: (context, provider, child) {
              if (provider.hasActiveSession) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // IconButton(
                    //   icon: const Icon(Icons.summarize),
                    //   onPressed: _getSummary,
                    //   tooltip: 'Get Summary',
                    // ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _clearChat,
                      tooltip: 'Clear Chat',
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _pickAndAnalyzePdf,
            tooltip: 'Upload PDF',
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<PdfAnalyzerProvider>(
          builder: (context, provider, child) {
            // Ensure we scroll to bottom after a new message arrives
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (provider.messages.isNotEmpty) {
                _scrollToBottom();
              }
            });

            return Column(
            children: [
              // Status banner
              if (provider.isUploading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Uploading and analyzing PDF...'),
                    ],
                  ),
                ),

              // Error banner
              if (provider.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.red.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          Provider.of<PdfAnalyzerProvider>(context, listen: false).clearError();
                        },
                      ),
                    ],
                  ),
                ),

              // Chat messages
              // Show recent uploads panel if documents exist
              if (provider.documents.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.grey.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recent uploads', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 84,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.documents.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final doc = provider.documents[idx];
                            final status = doc.conversionStatus ?? 'pending';
                            return GestureDetector(
                              onTap: () async {
                                // If a session exists, select this document as active
                                if (doc.sessionId != null && doc.sessionId!.isNotEmpty) {
                                  provider.selectDocument(doc);
                                  _showSnackBar('Selected: ${doc.title}');
                                } else {
                                  // otherwise, show a tooltip/snackbar
                                  _showSnackBar('Document is being processed (status: $status).');
                                }
                              },
                              child: Container(
                                width: 220,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Uploaded by ${doc.uploadedByUsername}', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                                        const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Debug panel removed for production UI

              Expanded(
                child: provider.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(provider.messages[index]);
                        },
                      ),
              ),

              // Suggestion chips
              if (provider.hasActiveSession && provider.messages.length < 5)
                _buildSuggestionChips(),

              // Input field
              _buildInputField(provider),
            ],
          );
        },
      ),
    ),
  );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description,
                size: 64,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AI PDF Analyzer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a PDF to start analyzing with AI',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickAndAnalyzePdf,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppConstants.primaryColor
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: !message.isUser ? const Radius.circular(4) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser)
              const Row(
                children: [
                  Icon(
                    Icons.smart_toy,
                    size: 16,
                    color: AppConstants.primaryColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            if (!message.isUser) const SizedBox(height: 8),
            Text(
              message.content,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      'Summarize this document',
      'What are the key points?',
      'Explain the main topic',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((suggestion) {
          return ActionChip(
            label: Text(suggestion),
            onPressed: () {
              _queryController.text = suggestion;
              _sendQuery();
            },
            backgroundColor: Colors.grey[100],
            labelStyle: const TextStyle(fontSize: 13),
          );
        }).toList(),
      ),
    );
  }

  

  Widget _buildInputField(PdfAnalyzerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: provider.hasActiveSession 
                    ? 'Ask anything about the PDF...' 
                    : 'Upload a PDF to start',
                enabled: provider.hasActiveSession && !provider.isLoading,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppConstants.primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendQuery(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: (provider.hasActiveSession && !provider.isLoading) ? _sendQuery : null,
            icon: provider.isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: (provider.hasActiveSession && !provider.isLoading)
                  ? AppConstants.primaryColor 
                  : Colors.grey[300],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
