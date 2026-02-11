import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/models/chat_preview.dart';
import 'package:flutter_chat_ui/screens/chat_screen.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';

class MessageRequestsSection extends StatelessWidget {
  const MessageRequestsSection({Key? key}) : super(key: key);

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return StreamBuilder<List<ChatPreview>>(
      stream: chatService.messageRequestsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? const [];
        if (requests.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No message requests',
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
          );
        }

        return FutureBuilder<Map<String, AppUser>>(
          future: chatService.fetchUsers(
            requests.map((r) => r.otherUserId).toList(),
          ),
          builder: (context, usersSnapshot) {
            if (!usersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = usersSnapshot.data ?? {};
            final validRequests = requests
                .where((request) => users.containsKey(request.otherUserId))
                .toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: validRequests.length,
              itemBuilder: (context, index) {
                final request = validRequests[index];
                final user = users[request.otherUserId]!;
                final imageProvider = ProfilePhotoHelper.getProfileImage(
                  user.id,
                  userName: user.name,
                  photoUrl: user.photoUrl,
                );

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: imageProvider,
                    child: !ProfilePhotoHelper.hasProfilePhoto(
                      user.id,
                      userName: user.name,
                      photoUrl: user.photoUrl,
                    )
                        ? Text(_initial(user.name))
                        : null,
                  ),
                  title: Text(user.name),
                  subtitle: Text(
                    request.lastMessage.isNotEmpty
                        ? request.lastMessage
                        : 'Message request',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => chatService.acceptFriendRequest(user.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => chatService.declineFriendRequest(user.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(user: user),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                );
              },
            );
          },
        );
      },
    );
  }
}
