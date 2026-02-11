import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/models/chat_preview.dart';
import 'package:flutter_chat_ui/screens/chat_screen.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';

class ArchiveSection extends StatelessWidget {
  const ArchiveSection({Key? key}) : super(key: key);

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return StreamBuilder<List<ChatPreview>>(
      stream: chatService.archivedChatsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final archivedChats = snapshot.data ?? const [];
        if (archivedChats.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No archived chats',
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
          );
        }

        return FutureBuilder<Map<String, AppUser>>(
          future: chatService.fetchUsers(
            archivedChats.map((r) => r.otherUserId).toList(),
          ),
          builder: (context, usersSnapshot) {
            if (!usersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = usersSnapshot.data ?? {};
            final validChats = archivedChats
                .where((chat) => users.containsKey(chat.otherUserId))
                .toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: validChats.length,
              itemBuilder: (context, index) {
                final chat = validChats[index];
                final user = users[chat.otherUserId]!;
                final imageProvider = ProfilePhotoHelper.getProfileImage(
                  user.id,
                  userName: user.name,
                  photoUrl: user.photoUrl,
                );

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: imageProvider,
                    child: !ProfilePhotoHelper.hasLocalPhoto(
                      user.id,
                      userName: user.name,
                    )
                        ? Text(_initial(user.name))
                        : null,
                  ),
                  title: Text(user.name),
                  subtitle: Text(
                    chat.lastMessage.isNotEmpty
                        ? chat.lastMessage
                        : 'No messages',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.unarchive, color: Colors.blue),
                    tooltip: 'Unarchive',
                    onPressed: () => chatService.unarchiveChat(chat.chatId),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(user: user),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
