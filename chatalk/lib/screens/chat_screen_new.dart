import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/screens/call_screen.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';
import 'package:flutter_chat_ui/screens/user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final AppUser user;

  const ChatScreen({Key? key, required this.user}) : super(key: key);

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _chatService.markLastMessageAsRead(widget.user.id);
    _loadCurrentUserName();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserName() async {
    final me = await _chatService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _currentUserName = me?.name;
    });
  }

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  ImageProvider? _avatarProvider(String userId, String userName) {
    if (userId.isEmpty) return null;
    return ProfilePhotoHelper.getProfileImage(
      userId,
      userName: userName,
    );
  }

  Widget _buildMessage(String text, String time, bool isMe, {String? senderName}) {
    final bubble = Container(
      margin: EdgeInsets.only(
        top: 6.0,
        bottom: 6.0,
        left: isMe ? 70.0 : 16.0,
        right: isMe ? 16.0 : 70.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFF57C00) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (senderName != null && !isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                senderName,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }

  String _formatHeaderDate(DateTime date) {
    final months = <String>[
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _chatService.sendMessage(
      widget.user.id,
      text,
      senderName: _currentUserName,
    );
    _controller.clear();
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 16.0),
      color: Colors.white,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: Colors.black12),
              ),
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Message',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10.0),
          Container(
            width: 36.0,
            height: 36.0,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF57C00),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, size: 18.0),
              color: Colors.white,
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF57C00),
        elevation: 0.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.call),
            iconSize: 22.0,
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    user: widget.user,
                    isVideo: false,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            iconSize: 24.0,
            color: Colors.white,
            onPressed: () async {
              final nav = Navigator.of(context);
              if (!mounted) return;
              final call = await _chatService.initiateCall(
                recipientId: widget.user.id,
                isVideo: true,
              );
              if (!mounted) return;
              final localUid = _chatService.uidForUser(_chatService.currentUserId);
              if (!mounted) return;
              nav.push(
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    user: widget.user,
                    isVideo: true,
                    callId: call?['callId'],
                    channelName: call?['channelName'],
                    localUid: localUid,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8.0),
            Column(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(user: widget.user),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF57C00), width: 2.0),
                    ),
                    child: CircleAvatar(
                      radius: 22.0,
                      backgroundImage: _avatarProvider(widget.user.id, widget.user.name),
                      backgroundColor: Colors.grey[300],
                      child: !ProfilePhotoHelper.hasLocalPhoto(
                        widget.user.id,
                        userName: widget.user.name,
                      )
                          ? Text(
                              _initial(widget.user.name),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _chatService.messagesStream(widget.user.id),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? const [];
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    itemCount: docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      final data = docs[index].data();
                      final senderId = (data['senderId'] ?? '').toString();
                      final Timestamp? ts = data['createdAt'] as Timestamp?;
                      final date = ts?.toDate();
                      final time = date == null
                          ? ''
                          : TimeOfDay.fromDateTime(date).format(context);
                      final bool isMe = senderId == _chatService.currentUserId;
                      final text = (data['text'] ?? '').toString();
                      final senderName = (data['senderName'] ?? '').toString();

                      final DateTime? prevDate = index > 0
                          ? (docs[index - 1].data()['createdAt'] as Timestamp?)
                              ?.toDate()
                          : null;
                      final bool showDateHeader = prevDate == null ||
                          date == null ||
                          prevDate.year != date.year ||
                          prevDate.month != date.month ||
                          prevDate.day != date.day;

                      return Column(
                        children: [
                          if (showDateHeader && date != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Text(
                                  _formatHeaderDate(date),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          _buildMessage(text, time, isMe, senderName: senderName),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }
}
