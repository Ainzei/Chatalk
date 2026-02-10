import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/agora_token_service.dart';
import '../services/chat_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String userName;
  final String? callId; // For tracking the call
  final int? localUid; // Local Agora UID
  final bool isAudioOnly; // Audio-only call

  const VideoCallScreen({
    Key? key,
    required this.channelName,
    required this.userName,
    this.callId,
    this.localUid,
    this.isAudioOnly = false,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isMuted = false;
  bool _isCameraOff = false;
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    initAgora();
  }

  Future<void> initAgora() async {
    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Create Agora engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: '29bf12aed25044f99a211542314d7798',
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUserJoined = true;
          });
          debugPrint('Agora: local joined uid=${connection.localUid}');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
          debugPrint('Agora: remote joined uid=$remoteUid');
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
          });
          debugPrint('Agora: remote offline uid=$remoteUid reason=$reason');
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('Agora error: $err $msg');
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    if (!widget.isAudioOnly) {
      await _engine.enableVideo();
    }
    await _engine.enableAudio();
    await _engine.setEnableSpeakerphone(true);
    await _engine.startPreview();

    final localUid = widget.localUid ?? 1;

    // Generate token and join channel
    final token = AgoraTokenService.generateToken(
      channelName: widget.channelName,
      uid: localUid,
    );
    
    // Video call: Channel=${widget.channelName}, Token generated, UID=$localUid

    await _engine.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: localUid,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
    // End the call in Firestore
    if (widget.callId != null) {
      await _chatService.endCall(widget.callId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen) - only for video calls
          if (!widget.isAudioOnly)
            Center(
              child: _remoteVideo(),
            )
          else
            // Audio call - show user avatar
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey[600],
                    child: Text(
                      widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Voice call in progress...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          // Local video (small preview) - only for video calls
          if (!widget.isAudioOnly)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.only(top: 50, right: 20),
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _localUserJoined
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine,
                            canvas: VideoCanvas(uid: widget.localUid ?? 1),
                          ),
                        )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
              ),
            ),
          ),
          // Top bar
          Positioned(
            top: 40,
            left: 20,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Bottom controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 40),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  FloatingActionButton(
                    backgroundColor: _isMuted ? Colors.red : Colors.white24,
                    onPressed: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                      _engine.muteLocalAudioStream(_isMuted);
                    },
                    child: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                  // End call button
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                  // Camera toggle button - only for video calls
                  if (!widget.isAudioOnly)
                    FloatingActionButton(
                      backgroundColor:
                          _isCameraOff ? Colors.red : Colors.white24,
                      onPressed: () {
                        setState(() {
                          _isCameraOff = !_isCameraOff;
                        });
                        _engine.muteLocalVideoStream(_isCameraOff);
                      },
                      child: Icon(
                        _isCameraOff ? Icons.videocam_off : Icons.videocam,
                        color: Colors.white,
                      ),
                    ),
                  // Switch camera button - only for video calls
                  if (!widget.isAudioOnly)
                    FloatingActionButton(
                      backgroundColor: Colors.white24,
                      onPressed: () => _engine.switchCamera(),
                      child: const Icon(Icons.flip_camera_android,
                          color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return const Center(
        child: Text(
          'Waiting for other user to join...',
          style: TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}

