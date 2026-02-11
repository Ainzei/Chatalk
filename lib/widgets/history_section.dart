import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/models/chat_preview.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';

class HistorySection extends StatelessWidget {
  const HistorySection({Key? key}) : super(key: key);

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  String _formatTime(BuildContext context, DateTime? time) {
    if (time == null) return '';
    return TimeOfDay.fromDateTime(time).format(context);
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return StreamBuilder<List<ChatPreview>>(
      stream: chatService.chatPreviewsStream(),
      builder: (context, snapshot) {
        final chats = snapshot.data ?? const [];
        final recent = chats.take(6).toList();

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'History',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _HistoryCard(
                  title: 'Messages',
                  icon: Icons.chat_bubble_outline,
                  child: recent.isEmpty
                      ? const _EmptyHistory(message: 'No recent messages')
                      : _HistoryList(
                          items: recent,
                          itemBuilder: (context, chat) => _HistoryChatTile(
                            chat: chat,
                            chatService: chatService,
                            initialBuilder: _initial,
                            timeBuilder: _formatTime,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                _HistoryCard(
                  title: 'Media',
                  icon: Icons.photo_library_outlined,
                  child: recent.isEmpty
                      ? const _EmptyHistory(message: 'No recent media')
                      : _HistoryList(
                          items: recent,
                          itemBuilder: (context, chat) => _HistoryGenericTile(
                            chat: chat,
                            chatService: chatService,
                            titleBuilder: (user) => 'Media shared with ${user.name}',
                            subtitleBuilder: (user) => 'Photos and videos',
                            leadingIcon: Icons.image_outlined,
                            initialBuilder: _initial,
                            timeBuilder: _formatTime,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                _HistoryCard(
                  title: 'Files',
                  icon: Icons.insert_drive_file_outlined,
                  child: recent.isEmpty
                      ? const _EmptyHistory(message: 'No recent files')
                      : _HistoryList(
                          items: recent,
                          itemBuilder: (context, chat) => _HistoryGenericTile(
                            chat: chat,
                            chatService: chatService,
                            titleBuilder: (user) => 'Files shared with ${user.name}',
                            subtitleBuilder: (user) => 'Documents and attachments',
                            leadingIcon: Icons.attach_file,
                            initialBuilder: _initial,
                            timeBuilder: _formatTime,
                          ),
                        ),
                ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFF57C00)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.items,
    required this.itemBuilder,
  });

  final List<ChatPreview> items;
  final Widget Function(BuildContext, ChatPreview) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => itemBuilder(context, items[index]),
    );
  }
}

class _HistoryChatTile extends StatelessWidget {
  const _HistoryChatTile({
    required this.chat,
    required this.chatService,
    required this.initialBuilder,
    required this.timeBuilder,
  });

  final ChatPreview chat;
  final ChatService chatService;
  final String Function(String) initialBuilder;
  final String Function(BuildContext, DateTime?) timeBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: chatService.fetchUser(chat.otherUserId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const SizedBox.shrink();
        }
        final imageProvider = ProfilePhotoHelper.getProfileImage(user.id, userName: user.name, photoUrl: user.photoUrl);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFFFE0B2),
            backgroundImage: imageProvider,
            child: !ProfilePhotoHelper.hasProfilePhoto(
              user.id,
              userName: user.name,
              photoUrl: user.photoUrl,
            )
                ? Text(
                    initialBuilder(user.name),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Text(
            user.name,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            chat.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          trailing: Text(
            timeBuilder(context, chat.lastMessageAt),
            style: const TextStyle(color: Colors.black45, fontSize: 11),
          ),
        );
      },
    );
  }
}

class _HistoryGenericTile extends StatelessWidget {
  const _HistoryGenericTile({
    required this.chat,
    required this.chatService,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.leadingIcon,
    required this.initialBuilder,
    required this.timeBuilder,
  });

  final ChatPreview chat;
  final ChatService chatService;
  final String Function(AppUser) titleBuilder;
  final String Function(AppUser) subtitleBuilder;
  final IconData leadingIcon;
  final String Function(String) initialBuilder;
  final String Function(BuildContext, DateTime?) timeBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: chatService.fetchUser(chat.otherUserId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const SizedBox.shrink();
        }
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFFFE0B2),
            child: Icon(leadingIcon, color: const Color(0xFFF57C00), size: 18),
          ),
          title: Text(
            titleBuilder(user),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          subtitle: Text(
            subtitleBuilder(user),
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          trailing: Text(
            timeBuilder(context, chat.lastMessageAt),
            style: const TextStyle(color: Colors.black45, fontSize: 11),
          ),
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        message,
        style: const TextStyle(color: Colors.black45, fontSize: 12),
      ),
    );
  }
}
