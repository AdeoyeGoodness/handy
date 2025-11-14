class MessageThreadModel {
  MessageThreadModel({
    required this.id,
    required this.initiatorId,
    required this.receiverId,
    this.bookingId,
    this.lastMessageAt,
  });

  final int id;
  final int initiatorId;
  final int receiverId;
  final int? bookingId;
  final DateTime? lastMessageAt;

  factory MessageThreadModel.fromJson(Map<String, dynamic> json) {
    return MessageThreadModel(
      id: json['id'] as int,
      initiatorId: json['initiator_id'] as int,
      receiverId: json['receiver_id'] as int,
      bookingId: json['booking_id'] as int?,
      lastMessageAt:
          json['last_message_at'] != null ? DateTime.parse(json['last_message_at'] as String) : null,
    );
  }
}

class MessageModel {
  MessageModel({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.messageType,
    this.readAt,
  });

  final int id;
  final int threadId;
  final int senderId;
  final String content;
  final DateTime sentAt;
  final String? messageType;
  final DateTime? readAt;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      threadId: json['thread_id'] as int,
      senderId: json['sender_id'] as int,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
      messageType: json['message_type'] as String?,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
    );
  }
}

