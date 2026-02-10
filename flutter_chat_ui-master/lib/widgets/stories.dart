import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/screens/chat_screen.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';

class Stories extends StatefulWidget {
  const Stories({Key? key}) : super(key: key);

  @override
  State<Stories> createState() => _StoriesState();
}

class _StoriesState extends State<Stories> {
  final ChatService _chatService = ChatService();

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  String _displayName(String name) {
    final trimmed = name.trim();
    if (trimmed.contains('@')) {
      return trimmed.split('@').first;
    }
    return trimmed;
  }

  ImageProvider? _avatarProvider(
    String userId,
    String userName, {
    String photoUrl = '',
  }) {
    if (userId.isEmpty) return null;
    return ProfilePhotoHelper.getProfileImage(
      userId,
      userName: userName,
      photoUrl: photoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Material(
        color: Colors.white,
        elevation: 6.0,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: StreamBuilder(
            stream: _chatService.currentUserDocStream(),
            builder: (context, currentUserSnapshot) {
              final data = currentUserSnapshot.data?.data();
              final stories = List<String>.from(data?['stories'] ?? const []);
              final currentUserName = (data?['name'] ?? 'Your').toString();

              return StreamBuilder<AppUser?>(
                stream: _chatService.currentUserDocStream().asyncMap(
                  (snapshot) async {
                    final currentUserId = _chatService.currentUserId;
                    if (currentUserId.isEmpty) return null;
                    return await _chatService.fetchUser(currentUserId);
                  },
                ),
                builder: (context, currentUserAsync) {
                  final currentUser = currentUserAsync.data;

                  return StreamBuilder<List<AppUser>>(
                    stream: _chatService.usersStream(),
                    builder: (context, usersSnapshot) {
                      final users = usersSnapshot.data ?? const [];
                      final currentUserId = _chatService.currentUserId;
                      final filtered = users
                          .where((u) => u.id != currentUserId)
                          .where((u) => stories.contains(u.id))
                          .toList();

                      return Column(
                        children: <Widget>[
                          SizedBox(
                            height: 110.0, // LARGER - was 86.0
                            child: ListView.builder(
                              padding: const EdgeInsets.only(left: 8.0),
                              scrollDirection: Axis.horizontal,
                              itemCount: 1 + filtered.length, // +1 for "Your Story"
                              itemBuilder: (BuildContext context, int index) {
                                // First item is "Your Story"
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: <Widget>[
                                        Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                  width: 2.5,
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                radius: 30.0, // LARGER - was 22.0
                                                backgroundImage: currentUser != null
                                                    ? _avatarProvider(
                                                        currentUser.id,
                                                        currentUser.name,
                                                        photoUrl: currentUser.photoUrl,
                                                      )
                                                    : null,
                                                child: currentUser == null ||
                                                        !ProfilePhotoHelper.hasLocalPhoto(
                                                          currentUser.id,
                                                          userName: currentUser.name,
                                                        )
                                                    ? Text(
                                                        _initial(currentUserName),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.blue,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4.0),
                                        const Text(
                                          'Your Story',
                                          style: TextStyle(
                                            color: Colors.blueGrey,
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                // Other stories
                                final AppUser friend = filtered[index - 1];
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        user: friend,
                                      ),
                                    ),
                                  ),
                                  onLongPress: () async {
                                    await _chatService.toggleStory(friend.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${friend.name} removed from stories'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: <Widget>[
                                        Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [Colors.purple, Colors.orange, Colors.pink],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(2.5),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            child: CircleAvatar(
                                              radius: 28.0, // LARGER - was 20.0
                                              backgroundImage: _avatarProvider(
                                                friend.id,
                                                friend.name,
                                                photoUrl: friend.photoUrl,
                                              ),
                                              child: !ProfilePhotoHelper.hasLocalPhoto(
                                                friend.id,
                                                userName: friend.name,
                                              )
                                                  ? Text(
                                                      _initial(_displayName(friend.name)),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4.0),
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            _displayName(friend.name),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.blueGrey,
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
