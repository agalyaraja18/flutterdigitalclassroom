class PdfDocument {
  final int id;
  final String title;
  final String pdfFile;
  final String? audioFile;
  final String uploadedBy;
  final String conversionStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  PdfDocument({
    required this.id,
    required this.title,
    required this.pdfFile,
    this.audioFile,
    required this.uploadedBy,
    required this.conversionStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => conversionStatus == 'pending';
  bool get isProcessing => conversionStatus == 'processing';
  bool get isCompleted => conversionStatus == 'completed';
  bool get isFailed => conversionStatus == 'failed';

  String get statusDisplayText {
    switch (conversionStatus) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Converting...';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return 'Unknown';
    }
  }

  factory PdfDocument.fromJson(Map<String, dynamic> json) {
    return PdfDocument(
      id: json['id'] as int,
      title: json['title'] as String,
      pdfFile: json['pdf_file'] as String,
      audioFile: json['audio_file'] as String?,
      uploadedBy: json['uploaded_by'] as String,
      conversionStatus: json['conversion_status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'pdf_file': pdfFile,
      'audio_file': audioFile,
      'uploaded_by': uploadedBy,
      'conversion_status': conversionStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PdfDocument copyWith({
    int? id,
    String? title,
    String? pdfFile,
    String? audioFile,
    String? uploadedBy,
    String? conversionStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PdfDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      pdfFile: pdfFile ?? this.pdfFile,
      audioFile: audioFile ?? this.audioFile,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      conversionStatus: conversionStatus ?? this.conversionStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PdfDocument{id: $id, title: $title, status: $conversionStatus}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfDocument &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}