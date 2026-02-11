import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<String> memberIds;

  const GroupChatScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.memberIds,
  }) : super(key: key);

  @override
  GroupChatScreenState createState() => GroupChatScreenState();
}

class GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  Map<String, String> _userNameCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserNames();
  }

  Future<void> _loadUserNames() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final cache = <String, String>{};

      for (final userId in widget.memberIds) {
        try {
          final doc = await firestore.collection('users').doc(userId).get();
          if (doc.exists) {
            final data = doc.data() ?? {};
            cache[userId] = (data['name'] ?? 'Unknown').toString();
          }
        } catch (e) {
          debugPrint('Error loading user name for $userId: $e');
          cache[userId] = 'Unknown';
        }
      }

      if (mounted) {
        setState(() {
          _userNameCache = cache;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error in _loadUserNames: $e');
      // Set loading to false anyway so screen shows
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _leaveGroup() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave ${widget.groupName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _chatService.removeGroupMember(
                  widget.groupId,
                  _chatService.currentUserId,
                );
                if (mounted) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Left ${widget.groupName}')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error leaving group: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getInitial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final senderName =
        _userNameCache[currentUser.uid] ?? currentUser.displayName ?? 'Anonymous';

    _controller.clear();

    try {
      await _chatService.sendGroupMessage(
        groupId: widget.groupId,
        senderId: currentUser.uid,
        senderName: senderName,
        text: text,
        type: 'text',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          debugPrint('User navigated back from loading screen');
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Loading...'),
            automaticallyImplyLeading: true,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        debugPrint('Leaving group chat: ${widget.groupId}');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.groupName),
              Text(
                '${widget.memberIds.length} members',
                style: const TextStyle(fontSize: 12.0),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'leave') {
                  _leaveGroup();
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
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.groupMessagesStream(widget.groupId),
              builder: (context, snapshot) {
                // Handle errors
                if (snapshot.hasError) {
                  debugPrint('Error loading messages: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        const Text('Error loading messages'),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start chatting!'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msgDoc = messages[index];
                    final msgData = msgDoc.data();
                    final senderId = msgData['senderId'] ?? '';
                    final senderName = msgData['senderName'] ?? 'Unknown';
                    final text = msgData['text'] ?? '';
                    final timestamp = msgData['createdAt'] as Timestamp?;
                    final isMe = senderId == FirebaseAuth.instance.currentUser?.uid;

                    final timeString = timestamp != null
                        ? _formatTime(timestamp.toDate())
                        : 'Now';

                    return _buildMessageTile(
                      text: text,
                      senderName: senderName,
                      time: timeString,
                      isMe: isMe,
                      senderId: senderId,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: const Color(0xFFF57C00),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMessageTile({
    required String text,
    required String senderName,
    required String time,
    required bool isMe,
    required String senderId,
  }) {
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
                Flexible(child: bubble),
                const SizedBox(width: 8.0),
              ]
            : [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFFFE0B2),
                  child: Text(
                    _getInitial(senderName),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      bubble,
                    ],
                  ),
                ),
              ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (msgDate == today) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (msgDate == yesterday) {
      return 'Yesterday ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
