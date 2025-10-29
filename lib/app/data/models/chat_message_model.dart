class ChatMessage {
  final int? id;
  final String message;
  final bool isUser;
  final DateTime createdAt;

  ChatMessage({
    this.id,
    required this.message,
    required this.isUser,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'isUser': isUser ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> m) {
    return ChatMessage(
      id: m['id'] as int?,
      message: m['message'] as String,
      isUser: (m['isUser'] as int) == 1,
      createdAt: DateTime.parse(m['createdAt'] as String),
    );
  }
}
