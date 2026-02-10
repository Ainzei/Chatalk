import 'package:flutter_chat_ui/models/message_model.dart';
import 'package:flutter_chat_ui/models/user_model.dart';

class Group {
  final String id; // Unique identifier for the group
  String name;
  List<User> members;
  List<Message> messages;
  String? profilePicturePath; // Optional group-specific profile picture
  DateTime lastMessageAt; // Track last message time for sorting

  Group({
    String? id,
    required this.name, 
    required this.members, 
    List<Message>? messages,
    this.profilePicturePath,
    DateTime? lastMessageAt,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       messages = messages ?? [],
       lastMessageAt = lastMessageAt ?? DateTime.now();
  
  // Update last message time when a message is added
  void addMessage(Message message) {
    messages.add(message);
    lastMessageAt = DateTime.now();
  }
}
