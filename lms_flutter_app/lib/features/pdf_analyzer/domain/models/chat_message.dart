class ChatMessage {
  final int id;
  final String messageType;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.messageType,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
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

    final messageType = (json['message_type'] ?? json['messageType'] ?? 'ai').toString();
    final content = (json['content'] ?? '').toString();

    DateTime ts = DateTime.now();
    try {
      final raw = json['timestamp'] ?? json['created_at'] ?? json['time'];
      if (raw is String) {
        ts = DateTime.tryParse(raw) ?? DateTime.now();
      } else if (raw is int) {
        ts = DateTime.fromMillisecondsSinceEpoch(raw);
      }
    } catch (_) {
      ts = DateTime.now();
    }

    return ChatMessage(
      id: idVal,
      messageType: messageType,
      content: content,
      timestamp: ts,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'message_type': messageType,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() => 'ChatMessage{id: $id, type: $messageType}';
}
