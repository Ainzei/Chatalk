import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/screens/chat_screen.dart';
import 'package:flutter_chat_ui/screens/user_profile_screen.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';

class FriendsSection extends StatelessWidget {
  const FriendsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return StreamBuilder(
      stream: chatService.currentUserDocStream(),
      builder: (context, currentUserSnapshot) {
        final currentUserData = currentUserSnapshot.data?.data();
        final friendsIds =
            List<String>.from(currentUserData?['friends'] ?? const []);
        final requestIds =
            List<String>.from(currentUserData?['friendRequests'] ?? const []);
        final currentUserId = chatService.currentUserId;

        return StreamBuilder<List<AppUser>>(
          stream: chatService.usersStream(),
          builder: (context, usersSnapshot) {
            final users = usersSnapshot.data ?? const [];
            final friends =
                users.where((u) => friendsIds.contains(u.id)).toList();
            final requests =
                users.where((u) => requestIds.contains(u.id)).toList();
            final suggested = users
                .where((u) =>
                    u.id != currentUserId &&
                    !friendsIds.contains(u.id) &&
                    !requestIds.contains(u.id))
                .toList();

            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _buildSectionHeader('Friends'),
                if (friends.isEmpty)
                  _buildEmptyState('No friends yet')
                else
                  _buildUserList(
                    friends,
                    context: context,
                    trailingBuilder: (_) => const Icon(Icons.check, color: Colors.green),
                    onTap: (user) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(user: user),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
                _buildSectionHeader('Friend Requests'),
                if (requests.isEmpty)
                  _buildEmptyState('No friend requests')
                else
                  _buildUserList(
                    requests,
                    context: context,
                    trailingBuilder: (user) => Row(
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
                  ),
                const SizedBox(height: 16),
                _buildSectionHeader('Suggested Friends'),
                if (suggested.isEmpty)
                  _buildEmptyState('No suggestions right now')
                else
                  _buildUserList(
                    suggested,
                    context: context,
                    trailingBuilder: (user) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.mail_outline, color: Colors.blue),
                          tooltip: 'Message',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(user: user),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_add, color: Colors.orange),
                          tooltip: 'Send Friend Request',
                          onPressed: () => chatService.sendFriendRequest(user.id),
                        ),
                      ],
                    ),
                    onTap: (user) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(user: user),
                        ),
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

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.blueGrey),
      ),
    );
  }

  Widget _buildUserList(
    List<AppUser> users, {
    required Widget Function(AppUser user) trailingBuilder,
    void Function(AppUser user)? onTap,
    BuildContext? context,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final imageProvider = ProfilePhotoHelper.getProfileImage(user.id, userName: user.name, photoUrl: user.photoUrl);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: imageProvider,
            child: !ProfilePhotoHelper.hasLocalPhoto(
              user.id,
              userName: user.name,
            )
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  )
                : null,
          ),
          title: Text(user.name),
          subtitle: Text(user.nickname ?? 'Tap to view profile'),
          trailing: trailingBuilder(user),
          onTap: onTap == null ? null : () => onTap(user),
        );
      },
    );
  }
}
