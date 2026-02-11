import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/screens/call_screen.dart';
import 'package:flutter_chat_ui/screens/user_profile_screen.dart';
import 'package:flutter_chat_ui/screens/video_player_screen.dart';
import 'package:flutter_chat_ui/widgets/audio_message_bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatScreen extends StatefulWidget {
  final AppUser user;

  const ChatScreen({Key? key, required this.user}) : super(key: key);

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final ScrollController _scrollController = ScrollController();
  bool _isRecording = false;
  String? _currentUserName;
  String? _currentUserPhotoUrl;
  static const int _messagesLimit = 50;
  
  // Advanced messaging features
  Map<String, dynamic>? _replyToMessage;
  String? _replyToMessageId;
  bool _isOtherUserTyping = false;
  String? _editingMessageId;
  String? _editingText;

  @override
  void initState() {
    super.initState();
    // Mark the last message as read when chat is opened
    _chatService.markLastMessageAsRead(widget.user.id);
    _loadCurrentUserName();
    _listenToTypingStatus();
    
    // Set typing indicator on text change
    _controller.addListener(() {
      if (_controller.text.isNotEmpty) {
        _chatService.setTyping(widget.user.id, true);
      } else {
        _chatService.setTyping(widget.user.id, false);
      }
    });
  }

  void _listenToTypingStatus() {
    _chatService.typingStatusStream(widget.user.id).listen((isTyping) {
      if (mounted) {
        setState(() {
          _isOtherUserTyping = isTyping;
        });
      }
    });
  }

  @override
  void dispose() {
    _chatService.setTyping(widget.user.id, false);
    _controller.dispose();
    _recorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserName() async {
    final me = await _chatService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _currentUserName = me?.name;
      _currentUserPhotoUrl = me?.photoUrl;
    });
  }

  Future<bool> _ensurePermissions(List<Permission> permissions) async {
    final statuses = await permissions.request();
    return statuses.values.any((status) => status.isGranted);
  }

  void _showPermissionDenied(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label permission denied')),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  ImageProvider? _avatarProvider(String photoUrl) {
    if (photoUrl.isEmpty) return null;
    return NetworkImage(photoUrl);
  }

  Widget _buildMessage(String text, String time, bool isMe, {String? senderName}) {
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
      bubble: bubble,
    );
  }

  Widget _buildMessageRow({
    required bool isMe,
    required Widget bubble,
    String? senderName,
  }) {
    final displayName = (senderName != null && senderName.isNotEmpty)
        ? senderName
        : (isMe ? _currentUserName ?? 'You' : widget.user.name);
    final avatarUrl = isMe ? (_currentUserPhotoUrl ?? '') : widget.user.photoUrl;

    final avatar = GestureDetector(
      onTap: () {
        if (!isMe) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(user: widget.user),
            ),
          );
        }
      },
      child: CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFFFFE0B2),
        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
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

  String _formatHeaderDate(DateTime date) {
    final months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    // Handle editing
    if (_editingMessageId != null) {
      await _chatService.editMessage(widget.user.id, _editingMessageId!, text);
      setState(() {
        _editingMessageId = null;
        _editingText = null;
      });
      _controller.clear();
      return;
    }
    
    // Send with reply if applicable
    if (_replyToMessageId != null) {
      await _chatService.sendMessageWithReply(
        widget.user.id,
        text,
        senderName: _currentUserName,
        replyToMessageId: _replyToMessageId,
        replyToData: _replyToMessage,
      );
      setState(() {
        _replyToMessage = null;
        _replyToMessageId = null;
      });
    } else {
      await _chatService.sendMessage(
        widget.user.id,
        text,
        senderName: _currentUserName,
      );
    }
    _controller.clear();
  }

  void _showMessageActions(String messageId, Map<String, dynamic> messageData, bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_reaction, color: Colors.orange),
              title: const Text('React'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(messageId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.blue),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyToMessageId = messageId;
                  _replyToMessage = messageData;
                });
              },
            ),
            if (isMe && messageData['type'] == 'text')
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.green),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editingMessageId = messageId;
                    _editingText = messageData['text'] ?? '';
                    _controller.text = _editingText!;
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.forward, color: Colors.indigo),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                _showForwardDialog(messageData);
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin, color: Colors.purple),
              title: const Text('Pin'),
              onTap: () async {
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                await _chatService.pinMessage(widget.user.id, messageId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message pinned')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: isMe ? Colors.red : Colors.grey),
              title: Text(isMe ? 'Delete for everyone' : 'Delete for me'),
              onTap: () async {
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                await _chatService.deleteMessage(
                  widget.user.id,
                  messageId,
                  forEveryone: isMe,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message deleted')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(String messageId) {
    final reactions = ['❤️', '😂', '😮', '😢', '🙏', '👍', '🔥', '🎉'];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          children: reactions.map((emoji) {
            return GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await _chatService.addReaction(widget.user.id, messageId, emoji);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showForwardDialog(Map<String, dynamic> messageData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forward message'),
        content: const Text('Forward to which contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact picker coming soon')),
              );
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  void _setReplyTo(String messageId, Map<String, dynamic> messageData) {
    setState(() {
      _replyToMessageId = messageId;
      _replyToMessage = messageData;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToMessageId = null;
      _replyToMessage = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
      _editingText = null;
      _controller.clear();
    });
  }

  Future<void> _sendImage() async {
    try {
      final granted = await _ensurePermissions([
        Permission.photos,
        Permission.storage,
      ]);
      if (!granted) {
        _showPermissionDenied('Photos');
        return;
      }
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading image...')),
      );
      
      final file = File(image.path);
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await _chatService.uploadFile(
        file: file,
        folder: 'chat_images',
        fileName: fileName,
      );
      if (url == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
        return;
      }
      if (!mounted) return;
      
      await _chatService.sendMediaMessage(
        otherUserId: widget.user.id,
        type: 'image',
        mediaUrl: url,
        fileName: fileName,
        senderName: _currentUserName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image sent')),
        );
      }
    } catch (e) {
      debugPrint('Error sending image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _sendVideo() async {
    final granted = await _ensurePermissions([
      Permission.videos,
      Permission.storage,
    ]);
    if (!granted) {
      _showPermissionDenied('Videos');
      return;
    }
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    final file = File(video.path);
    final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final url = await _chatService.uploadFile(
      file: file,
      folder: 'chat_videos',
      fileName: fileName,
    );
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload video')),
        );
      }
      return;
    }
    await _chatService.sendMediaMessage(
      otherUserId: widget.user.id,
      type: 'video',
      mediaUrl: url,
      fileName: fileName,
      senderName: _currentUserName,
    );
  }

  Future<void> _sendFile() async {
    try {
      final granted = await _ensurePermissions([
        Permission.storage,
      ]);
      if (!granted) {
        _showPermissionDenied('Storage');
        return;
      }
      final result = await FilePicker.platform.pickFiles(withData: false);
      if (result == null || result.files.isEmpty) return;
      if (!mounted) return;
      
      final picked = result.files.first;
      if (picked.path == null) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploading ${picked.name}...')),
      );
      
      final file = File(picked.path!);
      final fileName = picked.name;
      final url = await _chatService.uploadFile(
        file: file,
        folder: 'chat_files',
        fileName: fileName,
      );
      if (url == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload file')),
          );
        }
        return;
      }
      if (!mounted) return;
      
      await _chatService.sendMediaMessage(
        otherUserId: widget.user.id,
        type: 'file',
        mediaUrl: url,
        fileName: fileName,
        fileSize: picked.size,
        senderName: _currentUserName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${picked.name} sent')),
        );
      }
    } catch (e) {
      debugPrint('Error sending file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _sendProfilePhoto() async {
    final me = await _chatService.getCurrentUser();
    if (me == null || me.photoUrl.isEmpty) return;
    await _chatService.sendMediaMessage(
      otherUserId: widget.user.id,
      type: 'profile',
      mediaUrl: me.photoUrl,
      fileName: 'profile.jpg',
      senderName: _currentUserName,
    );
  }

  Future<void> _toggleRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path == null) return;
      final file = File(path);
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final url = await _chatService.uploadFile(
        file: file,
        folder: 'chat_audio',
        fileName: fileName,
      );
      if (url == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload voice message')),
          );
        }
        return;
      }
      await _chatService.sendMediaMessage(
        otherUserId: widget.user.id,
        type: 'audio',
        mediaUrl: url,
        fileName: fileName,
        senderName: _currentUserName,
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
    setState(() => _isRecording = true);
  }

  void _showAttachments() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFFF57C00)),
                title: const Text('Send image'),
                onTap: () {
                  Navigator.pop(context);
                  _sendImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFFF57C00)),
                title: const Text('Send video'),
                onTap: () {
                  Navigator.pop(context);
                  _sendVideo();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Color(0xFFF57C00)),
                title: const Text('Send file'),
                onTap: () {
                  Navigator.pop(context);
                  _sendFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_circle, color: Color(0xFFF57C00)),
                title: const Text('Send profile picture'),
                onTap: () {
                  Navigator.pop(context);
                  _sendProfilePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _wrapBubble({
    required Widget child,
    required bool isMe,
    String? senderName,
  }) {
    return _buildMessageRow(
      isMe: isMe,
      senderName: senderName,
      bubble: child,
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> data, String time, bool isMe, String messageId) {
    final type = (data['type'] ?? 'text').toString();
    final text = (data['text'] ?? '').toString();
    final mediaUrl = (data['mediaUrl'] ?? '').toString();
    final fileName = (data['fileName'] ?? '').toString();
    final fileSize = data['fileSize'] as int?;
    final durationMs = data['durationMs'] as int?;
    final senderName = (data['senderName'] ?? '').toString();
    final reactions = (data['reactions'] as Map<String, dynamic>?) ?? {};
    final isEdited = data['isEdited'] == true;
    final replyTo = data['replyTo'] as Map<String, dynamic>?;
    final isForwarded = data['isForwarded'] == true;

    Widget messageWidget;
    switch (type) {
      case 'image':
      case 'profile':
        messageWidget = _wrapBubble(
          isMe: isMe,
          senderName: senderName,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: mediaUrl,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 220,
                height: 220,
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 220,
                height: 220,
                color: Colors.grey[300],
                child: const Icon(Icons.error, color: Colors.red),
              ),
              memCacheWidth: 440,
              memCacheHeight: 440,
            ),
          ),
        );
        break;
      case 'video':
        messageWidget = _wrapBubble(
          isMe: isMe,
          senderName: senderName,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(url: mediaUrl),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFF57C00) : const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_fill,
                      color: isMe ? Colors.white : Colors.black87),
                  const SizedBox(width: 8),
                  Text(
                    fileName.isEmpty ? 'Video' : fileName,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;
      case 'audio':
        messageWidget = _wrapBubble(
          isMe: isMe,
          senderName: senderName,
          child: AudioMessageBubble(
            url: mediaUrl,
            isMe: isMe,
            durationMs: durationMs,
          ),
        );
        break;
      case 'file':
        messageWidget = _wrapBubble(
          isMe: isMe,
          senderName: senderName,
          child: InkWell(
            onTap: () async {
              final uri = Uri.parse(mediaUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFF57C00) : const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_drive_file,
                      color: isMe ? Colors.white : Colors.black87),
                  const SizedBox(width: 8),
                  Text(
                    fileName.isEmpty ? 'File' : fileName,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  if (fileSize != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${(fileSize / 1024).ceil()} KB',
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
        break;
      default:
        messageWidget = _buildMessage(text, time, isMe, senderName: senderName);
    }

    // Wrap with advanced features
    return GestureDetector(
      // Long press to show message actions
      onLongPress: () => _showMessageActions(messageId, data, isMe),
      // Double tap to quick react with heart
      onDoubleTap: () => _chatService.addReaction(widget.user.id, messageId, '❤️'),
      child: Dismissible(
        key: Key(messageId),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          // Swipe to reply
          _setReplyTo(messageId, data);
          return false; // Don't actually dismiss
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.reply, color: Colors.blue),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Forwarded indicator
            if (isForwarded)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 50,
                  right: isMe ? 50 : 0,
                  bottom: 4,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.forward, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('Forwarded', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            // Reply-to preview
            if (replyTo != null)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 50 : 50,
                  right: isMe ? 50 : 50,
                  bottom: 4,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                      left: BorderSide(
                        color: Color(0xFFF57C00),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        replyTo['senderName'] ?? 'Someone',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFFF57C00),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        replyTo['text'] ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            // Actual message
            messageWidget,
            // Edited indicator
            if (isEdited)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 50,
                  right: isMe ? 50 : 0,
                  top: 2,
                ),
                child: const Text(
                  'edited',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            // Reactions
            if (reactions.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 50,
                  right: isMe ? 50 : 0,
                  top: 4,
                ),
                child: Wrap(
                  spacing: 4,
                  children: reactions.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Typing indicator
          if (_isOtherUserTyping)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  SizedBox(width: 10),
                  Icon(Icons.more_horiz, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'typing...',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          // Edit preview
          if (_editingMessageId != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF57C00)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16, color: Color(0xFFF57C00)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit message',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF57C00),
                          ),
                        ),
                        Text(
                          _editingText ?? '',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _cancelEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // Reply preview
          if (_replyToMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: Color(0xFFF57C00), width: 3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: Color(0xFFF57C00)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to ${_replyToMessage!['senderName'] ?? 'Someone'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF57C00),
                          ),
                        ),
                        Text(
                          _replyToMessage!['text'] ?? '',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // Message input row
          Row(
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showAttachments,
              borderRadius: BorderRadius.circular(20.0),
              child: Container(
                width: 36.0,
                height: 36.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12),
                ),
                child: const Icon(Icons.add, size: 18.0, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Message',
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleRecording,
                      borderRadius: BorderRadius.circular(16.0),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 18.0,
                        color: _isRecording ? Colors.red : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10.0),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(20.0),
              child: Container(
                width: 36.0,
                height: 36.0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF57C00),
                ),
                child: const Icon(Icons.send, size: 18.0, color: Colors.white),
              ),
            ),
          ),
        ],
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24.0),
          ),
        ),
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
              if (!mounted) return;
              // Initiate call and create call document in Firestore
              final call = await _chatService.initiateCall(
                recipientId: widget.user.id,
                isVideo: true,
              );
              if (!mounted) return;
              final localUid = _chatService.uidForUser(_chatService.currentUserId);
              if (!mounted) return;
              if (mounted) {
                Navigator.push(
                  context,
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
              }
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
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
                      child: CircleAvatar(
                        radius: 22.0,
                        backgroundImage: _avatarProvider(widget.user.photoUrl),
                        backgroundColor: Colors.grey[300],
                        child: widget.user.photoUrl.isEmpty
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
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _chatService.messagesStream(widget.user.id, limit: _messagesLimit),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet\nSay hi! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    reverse: true,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final messageId = doc.id;
                      final senderId = (data['senderId'] ?? '').toString();
                      final Timestamp? ts = data['createdAt'] as Timestamp?;
                      final date = ts?.toDate();
                      final time = date == null
                          ? ''
                          : TimeOfDay.fromDateTime(date).format(context);
                      final bool isMe = senderId == _chatService.currentUserId;

                      final DateTime? nextDate = index < docs.length - 1
                          ? (docs[index + 1].data()['createdAt'] as Timestamp?)
                              ?.toDate()
                          : null;
                      final bool showDateHeader = nextDate == null ||
                          date == null ||
                          nextDate.year != date.year ||
                          nextDate.month != date.month ||
                          nextDate.day != date.day;

                      return Column(
                        children: [
                          RepaintBoundary(
                            child: _buildMessageContent(data, time, isMe, messageId),
                          ),
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
