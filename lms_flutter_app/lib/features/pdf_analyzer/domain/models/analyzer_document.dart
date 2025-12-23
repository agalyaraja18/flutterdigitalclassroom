class AnalyzerDocument {
  final int id;
  final String title;
  final String pdfFile;
  final DateTime uploadDate;
  final DateTime? lastQueried;
  final String uploadedByUsername;
  final bool isActive;
  final String? conversionStatus; // e.g. 'pending', 'processing', 'done'
  final String? sessionId; // optional session id created after conversion

  AnalyzerDocument({
    required this.id,
    required this.title,
    required this.pdfFile,
    required this.uploadDate,
    this.lastQueried,
    required this.uploadedByUsername,
    required this.isActive,
    this.conversionStatus,
    this.sessionId,
  });

  factory AnalyzerDocument.fromJson(Map<String, dynamic> json) {
    return AnalyzerDocument(
      id: json['id'] as int,
      title: json['title'] as String,
      pdfFile: json['pdf_file'] as String,
      uploadDate: DateTime.tryParse((json['upload_date'] ?? json['created_at'])?.toString() ?? '') ?? DateTime.now(),
      lastQueried: json['last_queried'] != null ? DateTime.tryParse(json['last_queried'] as String) : null,
      uploadedByUsername: (json['uploaded_by_username'] ?? json['uploaded_by'] ?? '').toString(),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      conversionStatus: json['conversion_status']?.toString(),
      sessionId: json['session_id']?.toString() ?? json['chat_session_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'pdf_file': pdfFile,
        'upload_date': uploadDate.toIso8601String(),
  'last_queried': lastQueried?.toIso8601String(),
  'conversion_status': conversionStatus,
  'session_id': sessionId,
        'uploaded_by_username': uploadedByUsername,
        'is_active': isActive,
      };

  @override
  String toString() => 'AnalyzerDocument{id: $id, title: $title}';
}
