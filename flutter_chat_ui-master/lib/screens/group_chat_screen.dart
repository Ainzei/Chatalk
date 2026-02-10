import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_chat_ui/models/message_model.dart';
import 'package:flutter_chat_ui/models/user_model.dart';
import 'package:flutter_chat_ui/utils/image_loader.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/widgets/groups.dart';

class GroupChatScreen extends StatefulWidget {
  final dynamic group; // keep flexible

  const GroupChatScreen({Key? key, required this.group}) : super(key: key);

  @override
  GroupChatScreenState createState() => GroupChatScreenState();
}

class GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _controller = TextEditingController();

  void _leaveGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave ${widget.group.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove from globalGroups
              globalGroups.removeWhere((g) => g.name == widget.group.name);
              
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Left ${widget.group.name}')),
              );
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  String _getGcId(String name) {
    // Match the ID generation from import_gc_photos.py
    String slugify(String s) {
      s = s.toLowerCase();
      s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      s = s.replaceAll(RegExp(r'_+'), '_');
      s = s.replaceAll(RegExp(r'^_|_$'), '');
      return s.isEmpty ? 'group' : s;
    }

    int stableHash(String text) {
      int h = 5381;
      for (int i = 0; i < text.length; i++) {
        h = ((h << 5) + h) + text.codeUnitAt(i);
        h = h & 0x7fffffff;
      }
      return h;
    }

    return "gc_${slugify(name)}_${stableHash(name)}";
  }

  Widget _buildMessage(String text, String time, bool isMe,
      {String? senderName, String? senderImageUrl}) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFF57C00) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            time,
            style: TextStyle(
              color: isMe ? Colors.white70 : Colors.black54,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return _buildMessageRow(
      isMe: isMe,
      senderName: senderName,
      senderImageUrl: senderImageUrl,
      bubble: bubble,
    );
  }

  Widget _buildMessageRow({
    required bool isMe,
    required Widget bubble,
    String? senderName,
    String? senderImageUrl,
  }) {
    final displayName = (senderName ?? '').isNotEmpty
        ? senderName!
        : isMe
            ? 'You'
            : 'Member';
    final avatarUrl = isMe ? (senderImageUrl ?? '') : '';

    final avatar = GestureDetector(
      onTap: () {
        // Note: Group chat users are mock data with integer IDs, not Firebase users
        // So we don't navigate to profile for them
        if (!isMe && senderName != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$senderName is a demo group chat user'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFFFFE0B2),
        backgroundImage: avatarUrl.isNotEmpty ? getImageProvider(avatarUrl) : null,
        child: avatarUrl.isEmpty
            ? Text(
                _initial(displayName),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );

    final content = Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (displayName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, left: 2.0, right: 2.0),
            child: Text(
              displayName,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          child: bubble,
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(
        top: 6.0,
        bottom: 6.0,
        left: isMe ? 48.0 : 16.0,
        right: isMe ? 16.0 : 48.0,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isMe
            ? [
                Flexible(child: content),
                const SizedBox(width: 8.0),
                avatar,
              ]
            : [
                avatar,
                const SizedBox(width: 8.0),
                Flexible(child: content),
              ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    final fbUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;
    
    final senderName = fbUser.displayName ?? fbUser.email ?? 'Anonymous';
    
    // Add message locally for immediate UI update (use currentUser constant from Message model)
    final m = Message(
        sender: const User(
          id: 0,
          name: 'Me',
          imageUrl: 'assets/images/profile.jpg',
        ),
        time: 'Now',
        text: text,
        isLiked: false,
        unread: false);
    setState(() {
      widget.group.addMessage(m); // Use addMessage to update lastMessageAt
      _controller.clear();
    });
    
    // Save to database with proper timestamp
    try {
      await ChatService().sendGroupMessage(
        groupId: widget.group.id,
        senderId: fbUser.uid,
        senderName: senderName,
        text: text,
        type: 'text',
      );
    } catch (e) {
      debugPrint('Error saving group message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.name),
            Text('${group.members.length} members',
                style: const TextStyle(fontSize: 12.0)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'leave') {
                _leaveGroup(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Leave Group', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF57C00),
                        width: 2.0,
                      ),
                    ),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('group_chats')
                          .doc(_getGcId(widget.group.name))
                          .snapshots(),
                      builder: (context, snapshot) {
                        ImageProvider? backgroundImage;
                        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                          try {
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            final photoUrl = data?['photoUrl'] as String?;
                            if (photoUrl != null && photoUrl.isNotEmpty) {
                              if (photoUrl.startsWith('/') || photoUrl.contains(':')) {
                                try {
                                  backgroundImage = FileImage(File(photoUrl));
                                } catch (e) {
                                  backgroundImage = null;
                                }
                              } else {
                                backgroundImage = NetworkImage(photoUrl);
                              }
                            }
                          } catch (e) {
                            // Field doesn't exist, ignore
                            backgroundImage = null;
                          }
                        }
                        return CircleAvatar(
                          radius: 22.0,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: backgroundImage,
                          child: backgroundImage == null
                              ? Text(
                                  _initial(widget.group.name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    '${group.members.length} members',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: group.messages.length,
              itemBuilder: (context, index) {
                final Message message = group.messages[index];
                final bool isMe = message.sender.id == currentUser.id;
                return _buildMessage(
                  message.text,
                  message.time,
                  isMe,
                  senderName: message.sender.name,
                  senderImageUrl: message.sender.imageUrl,
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            color: Colors.white,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration.collapsed(
                        hintText: 'Send a message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
