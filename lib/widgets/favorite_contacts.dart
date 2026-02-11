import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/screens/chat_screen.dart';
import 'package:flutter_chat_ui/screens/add_friend_screen.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';

class FavoriteContacts extends StatefulWidget {
  const FavoriteContacts({Key? key}) : super(key: key);

  @override
  State<FavoriteContacts> createState() => _FavoriteContactsState();
}

class _FavoriteContactsState extends State<FavoriteContacts> {
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
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              final favorites = List<String>.from(data?['favorites'] ?? const []);

              return StreamBuilder<List<AppUser>>(
                stream: _chatService.usersStream(),
                builder: (context, usersSnapshot) {
                  final users = usersSnapshot.data ?? const [];
                  final currentUserId = _chatService.currentUserId;
                  final filtered = users
                      .where((u) => u.id != currentUserId)
                      .where((u) => favorites.contains(u.id))
                      .toList();

                  return Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text(
                              'Favorite Contacts',
                              style: TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.person_add,
                              ),
                              iconSize: 26.0,
                              color: Colors.orange,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddFriendScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 96.0,
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No favorites yet\nLong press a contact to add',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.blueGrey),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(left: 8.0),
                                scrollDirection: Axis.horizontal,
                                itemCount: filtered.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final AppUser friend = filtered[index];
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
                                      await _chatService.toggleFavorite(friend.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${friend.name} removed from favorites'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: <Widget>[
                                          Stack(
                                            children: [
                                              CircleAvatar(
                                                radius: 22.0,
                                                backgroundImage:
                                                    _avatarProvider(
                                                      friend.id,
                                                      friend.name,
                                                      photoUrl: friend.photoUrl,
                                                    ),
                                                child: !ProfilePhotoHelper.hasProfilePhoto(
                                                  friend.id,
                                                  userName: friend.name,
                                                  photoUrl: friend.photoUrl,
                                                )
                                                  ? Text(
                                                    _initial(_displayName(friend.name)),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                        FontWeight.bold),
                                                    )
                                                    : null,
                                              ),
                                              const Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Icon(
                                                  Icons.star,
                                                  color: Colors.orange,
                                                  size: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            _displayName(friend.name),
                                            style: const TextStyle(
                                              color: Colors.blueGrey,
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w600,
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
          ),
        ),
      ),
    );
  }
}
