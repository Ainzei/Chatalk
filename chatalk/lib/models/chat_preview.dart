import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPreview {
  final String chatId;
  final String otherUserId;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderId;
  final bool isLastMessageRead;
  final bool isMessageRequest;
  final String requestTo;
  final bool isArchived;

  const ChatPreview({
    required this.chatId,
    required this.otherUserId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderId,
    this.isLastMessageRead = false,
    this.isMessageRequest = false,
    this.requestTo = '',
    this.isArchived = false,
  });

  factory ChatPreview.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String currentUserId,
  ) {
    final data = doc.data() ?? {};
    final participants = List<String>.from(data['participants'] ?? const []);
    final otherUserId =
        participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    final Timestamp? ts = data['lastMessageAt'] as Timestamp?;
    
    // Check if last message was read by current user
    final readBy = List<String>.from(data['readBy'] ?? const []);
    final isLastMessageRead = readBy.contains(currentUserId);
    
    return ChatPreview(
      chatId: doc.id,
      otherUserId: otherUserId,
      lastMessage: (data['lastMessage'] ?? '').toString(),
      lastMessageAt: ts?.toDate(),
      lastSenderId: (data['lastSenderId'] ?? '').toString(),
      isLastMessageRead: isLastMessageRead,
      isMessageRequest: (data['isMessageRequest'] ?? false) == true,
      requestTo: (data['requestTo'] ?? '').toString(),
      isArchived: (data['isArchived'] ?? false) == true,
    );
  }
}
