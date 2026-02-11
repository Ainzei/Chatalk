import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../screens/call_screen.dart';
import '../models/app_user.dart';

class IncomingCallListener extends StatefulWidget {
  final Widget child;

  const IncomingCallListener({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    _listenForCalls();
  }

  void _listenForCalls() {
    _chatService.listenForIncomingCalls().listen((callDoc) async {
      if (callDoc == null) return;

      final callData = callDoc.data() as Map<String, dynamic>;
      final callerId = callData['callerId'] as String;
      final isVideo = callData['isVideo'] as bool;
      final callId = callData['callId'] as String;
      final channelName = (callData['channelName'] ?? '') as String;
      final localUid = _chatService.uidForUser(_chatService.currentUserId);

      // Get the caller's info
      final callerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(callerId)
          .get();

      if (!mounted) return;

      if (callerDoc.exists) {
        final callerData = callerDoc.data() ?? {};
        final caller = AppUser.fromMap(callerData, callerId);

        // Show incoming call screen
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CallScreen(
              user: caller,
              isVideo: isVideo,
              callId: callId,
              channelName: channelName.isEmpty ? null : channelName,
              localUid: localUid,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
