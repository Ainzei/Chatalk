import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/screens/video_call_screen.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';

class CallScreen extends StatefulWidget {
  final AppUser user;
  final bool isVideo;
  final String? callId; // For incoming calls
  final String? channelName; // For call channel
  final int? localUid; // Local Agora UID

  const CallScreen({
    Key? key,
    required this.user,
    required this.isVideo,
    this.callId,
    this.channelName,
    this.localUid,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late ChatService chatService;

  @override
  void initState() {
    super.initState();
    chatService = ChatService();
  }

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  ImageProvider? _avatarProvider(String photoUrl) {
    if (photoUrl.isEmpty) return null;
    return NetworkImage(photoUrl);
  }

  @override
  Widget build(BuildContext context) {
    final channelName = widget.channelName ??
        chatService.chatIdFor(
          chatService.currentUserId,
          widget.user.id,
        );
    final localUid = widget.localUid ??
        chatService.uidForUser(chatService.currentUserId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: _avatarProvider(widget.user.photoUrl),
              backgroundColor: Colors.grey[300],
              child: widget.user.photoUrl.isEmpty
                  ? Text(
                      _initial(widget.user.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.user.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isVideo ? 'Video calling…' : 'Audio calling…',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'decline',
                  backgroundColor: Colors.red,
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    if (!mounted) return;
                    if (widget.callId != null) {
                      await chatService.declineCall(widget.callId!);
                    }
                    if (!mounted) return;
                    nav.pop();
                  },
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
                const SizedBox(width: 30),
                FloatingActionButton(
                  heroTag: 'accept',
                  backgroundColor: Colors.green,
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    if (!mounted) return;
                    if (widget.callId != null) {
                      await chatService.acceptCall(widget.callId!);
                    }
                    if (!mounted) return;
                    nav.pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => VideoCallScreen(
                          channelName: channelName,
                          userName: widget.user.name,
                          callId: widget.callId,
                          localUid: localUid,
                          isAudioOnly: !widget.isVideo,
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.call, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
