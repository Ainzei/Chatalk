import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/screens/chat_screen.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';

List<Widget> buildDrawerSearchSlivers({
  required double panelHeight,
  required ValueChanged<DragUpdateDetails> onPanelDragUpdate,
  required ValueChanged<DragEndDetails> onPanelDragEnd,
  required int selectedIndex,
  required ValueChanged<int> onSelectTab,
}) {
  return <Widget>[
    SliverToBoxAdapter(
      child: Column(
        children: <Widget>[
          GestureDetector(
            onVerticalDragUpdate: onPanelDragUpdate,
            onVerticalDragEnd: onPanelDragEnd,
            child: Container(
              width: double.infinity,
              height: 30.0,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 60.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: panelHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
            ),
            child: panelHeight <= 4.0
                ? const SizedBox.shrink()
                : Center(
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: double.infinity,
                        viewportFraction: 0.3,
                        enableInfiniteScroll: true,
                        scrollPhysics: const BouncingScrollPhysics(),
                        padEnds: false,
                      ),
                      items: const [
                        'Messages',
                        'Online',
                        'Groups',
                        'Friends',
                        'History',
                      ].asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Builder(
                          builder: (context) {
                            final isSelected = index == selectedIndex;
                            return Center(
                              child: GestureDetector(
                                onTap: () => onSelectTab(index),
                                child: Text(
                                  item,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Aileron',
                                    color: isSelected
                                        ? Colors.white
                                      : Colors.white.withValues(alpha: 0.75),
                                    fontWeight:
                                        isSelected ? FontWeight.w700 : FontWeight.w400,
                                    fontSize: 24.0,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    ),
    SliverPersistentHeader(
      pinned: true,
      delegate: _SearchBarHeaderDelegate(),
    ),
  ];
}

class _SearchBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 64.0;

  @override
  double get maxExtent => 64.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
      alignment: Alignment.center,
      child: SearchAnchor(
        builder: (BuildContext context, SearchController controller) {
          return SearchBar(
            controller: controller,
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 16.0),
            ),
            hintText: 'Search users...',
            onTap: controller.openView,
            onChanged: (_) => controller.openView(),
            leading: const Icon(Icons.search),
          );
        },
        suggestionsBuilder:
            (BuildContext context, SearchController controller) async {
          final chatService = ChatService();
          final query = controller.text.toLowerCase().trim();

          if (query.isEmpty) {
            return [
              const ListTile(
                leading: Icon(Icons.search, color: Colors.grey),
                title: Text(
                  'Search for users by name or email',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ];
          }

          // Get current user's friends to filter
          final currentUserDoc = await chatService
              .currentUserDocStream()
              .first
              .timeout(const Duration(seconds: 3));
          final currentUserData = currentUserDoc.data();
          final friends = List<String>.from(currentUserData?['friends'] ?? const []);
          final currentUserId = chatService.currentUserId;

          // Get all users
          final users = await chatService
              .usersStream()
              .first
              .timeout(const Duration(seconds: 3));

          // Filter by search query and exclude current user
          final results = users.where((user) {
            if (user.id == currentUserId) return false;
            final nameMatch = user.name.toLowerCase().contains(query);
            final emailMatch = (user as dynamic).email?.toString().toLowerCase().contains(query) ?? false;
            return nameMatch || emailMatch;
          }).toList();

          if (results.isEmpty) {
            return [
              const ListTile(
                leading: Icon(Icons.person_off, color: Colors.grey),
                title: Text(
                  'No users found',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ];
          }

          return results.map((user) {
            final isFriend = friends.contains(user.id);
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
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(user.name),
              subtitle: Text(user.id),
              trailing: isFriend
                  ? IconButton(
                      icon: const Icon(Icons.chat, color: Colors.orange),
                      onPressed: () {
                        controller.closeView(null);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(user: user),
                          ),
                        );
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.blue),
                      onPressed: () async {
                        try {
                          await chatService.sendFriendRequest(user.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Friend request sent to ${user.name}'),
                              ),
                            );
                            controller.closeView(null);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to send request: $e')),
                            );
                          }
                        }
                      },
                    ),
              onTap: isFriend
                  ? () {
                      controller.closeView(null);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(user: user),
                        ),
                      );
                    }
                  : null,
            );
          }).toList();
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
