import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/screens/user_profile_screen.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';

class FriendRequestsSection extends StatelessWidget {
  const FriendRequestsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return StreamBuilder(
      stream: chatService.currentUserDocStream(),
      builder: (context, currentUserSnapshot) {
        final currentUserData = currentUserSnapshot.data?.data();
        final requestIds =
            List<String>.from(currentUserData?['friendRequests'] ?? const []);

        return StreamBuilder<List<AppUser>>(
          stream: chatService.usersStream(),
          builder: (context, usersSnapshot) {
            final users = usersSnapshot.data ?? const [];
            final requests =
                users.where((u) => requestIds.contains(u.id)).toList();

            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (requests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No friend requests',
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Friend Requests (${requests.length})',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (requests.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final user = requests[index];
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
                                ? Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                  )
                                : null,
                          ),
                          title: Text(user.name),
                          subtitle: Text(
                            user.nickname ?? 'Tap to view profile',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                tooltip: 'Accept',
                                onPressed: () =>
                                    chatService.acceptFriendRequest(user.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                tooltip: 'Decline',
                                onPressed: () =>
                                    chatService.declineFriendRequest(user.id),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfileScreen(user: user),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
