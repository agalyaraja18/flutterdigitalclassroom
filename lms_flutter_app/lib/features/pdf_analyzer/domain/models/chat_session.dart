import 'chat_message.dart';

class ChatSession {
  final int id;
  final String sessionId;
  final int pdfDocument;
  final String pdfTitle;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.sessionId,
    required this.pdfDocument,
    required this.pdfTitle,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.messages,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    // defensive parsing to tolerate slight schema differences
  final msgs = (json['messages'] as List<dynamic>?) ?? [];

    int idVal = 0;
    try {
      if (json['id'] is int) {
        idVal = json['id'] as int;
      } else if (json['id'] != null) {
        idVal = int.tryParse(json['id'].toString()) ?? 0;
      }
    } catch (_) {
      idVal = 0;
    }

    final sessionId = (json['session_id'] ?? json['sessionId'] ?? '').toString();

    int pdfDocId = 0;
    try {
      if (json['pdf_document'] is int) {
        pdfDocId = json['pdf_document'] as int;
      } else if (json['pdf_document'] is Map<String, dynamic>) {
        pdfDocId = (json['pdf_document']['id'] is int) ? json['pdf_document']['id'] as int : int.tryParse(json['pdf_document']['id']?.toString() ?? '') ?? 0;
      } else if (json['pdf_document'] != null) {
        pdfDocId = int.tryParse(json['pdf_document'].toString()) ?? 0;
      }
    } catch (_) {
      pdfDocId = 0;
    }

    final pdfTitle = (json['pdf_title'] ?? json['pdfTitle'] ?? json['pdf_document_title'] ?? '').toString();

    DateTime created = DateTime.now();
    DateTime updated = DateTime.now();
    try {
      final c = json['created_at'] ?? json['createdAt'] ?? json['created_at_iso'];
      if (c is String) created = DateTime.tryParse(c) ?? DateTime.now();
    } catch (_) {}
    try {
      final u = json['updated_at'] ?? json['updatedAt'] ?? json['updated_at_iso'];
      if (u is String) updated = DateTime.tryParse(u) ?? DateTime.now();
    } catch (_) {}

    final isActive = (json['is_active'] is bool) ? json['is_active'] as bool : (json['isActive'] is bool ? json['isActive'] as bool : true);

    final parsedMessages = msgs.map((m) {
      try {
        return ChatMessage.fromJson(m as Map<String, dynamic>);
      } catch (_) {
        return ChatMessage(id: 0, messageType: 'ai', content: m.toString(), timestamp: DateTime.now());
      }
    }).toList();

    return ChatSession(
      id: idVal,
      sessionId: sessionId,
      pdfDocument: pdfDocId,
      pdfTitle: pdfTitle,
      createdAt: created,
      updatedAt: updated,
      isActive: isActive,
      messages: parsedMessages,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'pdf_document': pdfDocument,
        'pdf_title': pdfTitle,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_active': isActive,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  @override
  String toString() => 'ChatSession{sessionId: $sessionId, pdf: $pdfTitle}';
}
