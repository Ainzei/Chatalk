import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';

class OnlineUsers extends StatefulWidget {
  const OnlineUsers({Key? key}) : super(key: key);

  @override
  State<OnlineUsers> createState() => _OnlineUsersState();
}

class _OnlineUsersState extends State<OnlineUsers> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUserId;

    return StreamBuilder<List<AppUser>>(
      stream: _chatService.usersStream(),
      builder: (context, snapshot) {
        final users = snapshot.data ?? const [];
        final onlineUsers = users
            .where((user) => user.id != currentUserId && user.isOnline)
            .toList();

        if (onlineUsers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No one is online right now',
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: onlineUsers.length,
          itemBuilder: (context, index) {
            final user = onlineUsers[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: ProfilePhotoHelper.getProfileImage(
                  user.id,
                  userName: user.name,
                  photoUrl: user.photoUrl,
                ),
                child: !ProfilePhotoHelper.hasProfilePhoto(
                  user.id,
                  userName: user.name,
                  photoUrl: user.photoUrl,
                )
                    ? Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : '?',
                      )
                    : null,
              ),
              title: Text(user.name),
              subtitle:
                  Text(user.nickname != null ? user.nickname! : 'Online'),
              trailing: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
