import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/screens/chat_screen.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';
import 'package:flutter_chat_ui/models/chat_preview.dart';
import 'package:flutter_chat_ui/models/app_user.dart';

class RecentChats extends StatefulWidget {
  const RecentChats({Key? key}) : super(key: key);

  @override
  State<RecentChats> createState() => _RecentChatsState();
}

class _RecentChatsState extends State<RecentChats> {
  final ChatService _chatService = ChatService();

  @override
  void dispose() {
    // Don't dispose ChatService as it's a singleton
    super.dispose();
  }

  void _showChatActions(BuildContext context, AppUser user, ChatService chatService, bool hasStory, String chatId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Mute'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Muted')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(context);
                chatService.archiveChat(chatId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat archived')),
                );
              },
            ),
            ListTile(
              leading: Icon(
                hasStory ? Icons.remove_circle : Icons.add_circle,
                color: Colors.orange,
              ),
              title: Text(hasStory ? 'Remove Story' : 'Add to Stories'),
              onTap: () async {
                Navigator.pop(context);
                await chatService.toggleStory(user.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        hasStory
                            ? '${user.name} removed from stories'
                            : '${user.name} added to stories',
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Blocked')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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
    return StreamBuilder(
      stream: _chatService.currentUserDocStream(),
      builder: (context, currentUserSnapshot) {
        final currentUserData = currentUserSnapshot.data?.data();
        final stories = List<String>.from(currentUserData?['stories'] ?? []);

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
            child: StreamBuilder<List<ChatPreview>>(
              stream: _chatService.chatPreviewsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chats = snapshot.data!;
                if (chats.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                    ),
                  );
                }

                // Batch fetch all users at once
                return FutureBuilder<Map<String, AppUser>>(
                  future: _chatService.fetchUsers(
                    chats.map((c) => c.otherUserId).toList(),
                  ),
                  builder: (context, usersSnapshot) {
                    if (!usersSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = usersSnapshot.data!;
                    final currentUserId = _chatService.currentUserId;
                    
                    // Filter out chats where user doesn't exist, archived chats, and chats where we sent the last message
                    final validChats = chats.where((c) => 
                      users.containsKey(c.otherUserId) && 
                      !c.isArchived &&
                      c.lastSenderId != currentUserId  // Only show chats where the other person sent the last message
                    ).toList();
                    
                    if (validChats.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No new messages',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        ),
                      );
                    }
                    
                    // Create list of chats with their data
                    final List<dynamic> chatItems = [];
                    
                    // Add individual chats with their data
                    for (var chat in validChats) {
                      chatItems.add({
                        'data': chat,
                        'user': users[chat.otherUserId]!,
                        'timestamp': chat.lastMessageAt ?? DateTime(2000),
                        'hasStory': stories.contains(chat.otherUserId),
                      });
                    }
                    
                    // Sort by timestamp (most recent first), then stories
                    chatItems.sort((a, b) {
                      // Story users always first
                      final aHasStory = a['hasStory'] == true;
                      final bHasStory = b['hasStory'] == true;
                      if (aHasStory && !bHasStory) return -1;
                      if (!aHasStory && bHasStory) return 1;
                      
                      // Then by timestamp
                      final aTime = a['timestamp'] as DateTime;
                      final bTime = b['timestamp'] as DateTime;
                      return bTime.compareTo(aTime); // Most recent first
                    });

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: chatItems.length,
                      itemBuilder: (context, index) {
                        final item = chatItems[index];
                        final chat = item['data'] as ChatPreview;
                        final user = item['user'] as AppUser;
                        final hasStory = item['hasStory'] as bool;
                        return _buildChatItem(context, chat, user, hasStory);
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatItem(BuildContext context, ChatPreview chat, AppUser user, bool hasStory) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(user: user),
        ),
      ),
      onLongPress: () => _showChatActions(context, user, _chatService, hasStory, chat.chatId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: <Widget>[
            _buildUserAvatar(user, hasStory),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    chat.lastMessage,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),
            _buildChatStatus(context, chat, hasStory),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(AppUser user, bool hasStory) {
    return Stack(
      children: [
        Container(
          decoration: hasStory ? const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.orange, Colors.pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ) : null,
          padding: hasStory ? const EdgeInsets.all(2.5) : null,
          child: CircleAvatar(
            radius: hasStory ? 27.5 : 30.0,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: hasStory ? 25.0 : 28.0,
              backgroundImage: ProfilePhotoHelper.getProfileImage(
                user.id,
                userName: user.name,
                photoUrl: user.photoUrl,
              ),
              backgroundColor: Colors.grey[300],
              child: !ProfilePhotoHelper.hasProfilePhoto(
                user.id,
                userName: user.name,
                photoUrl: user.photoUrl,
              )
                  ? Text(
                      _initial(user.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatStatus(BuildContext context, ChatPreview chat, bool hasStory) {
    return SizedBox(
      width: 50.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            _formatTime(context, chat.lastMessageAt),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6.0),
          if (chat.lastSenderId != _chatService.currentUserId)
            Container(
              width: 10.0,
              height: 10.0,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            )
          else if (chat.isLastMessageRead)
            const Icon(Icons.done_all, color: Colors.blue, size: 14.0)
          else
            const Icon(Icons.done, color: Colors.grey, size: 14.0),
        ],
      ),
    );
  }
}
