import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_chat_ui/widgets/stories.dart';
import 'package:flutter_chat_ui/widgets/recent_chats.dart';
import 'package:flutter_chat_ui/widgets/history_section.dart';
import 'package:flutter_chat_ui/widgets/online_users.dart';
import 'package:flutter_chat_ui/widgets/friends_section.dart';
import 'package:flutter_chat_ui/widgets/groups_section.dart';
import 'package:flutter_chat_ui/widgets/drawer_search_slivers.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/screens/profile_screen.dart';
import 'package:flutter_chat_ui/screens/settings_screen.dart';
import 'package:flutter_chat_ui/screens/user_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0; // 0=Messages,1=Online,2=Groups,3=Friends,4=History
  double _panelHeight = _panelMaxHeight;
  static const double _panelMinHeight = 0.0;
  static const double _panelMaxHeight = 80.0;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    // Repair any chats missing lastMessageAt timestamp
    _chatService.repairChatsTimestamps();
  }

  void _handlePanelDragUpdate(DragUpdateDetails details) {
    setState(() {
      _panelHeight = (_panelHeight + details.delta.dy)
          .clamp(_panelMinHeight, _panelMaxHeight);
    });
  }

  void _handlePanelDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    const midPoint = (_panelMinHeight + _panelMaxHeight) / 2;
    final shouldOpen = velocity > 0 || _panelHeight > midPoint;

    setState(() {
      _panelHeight = shouldOpen ? _panelMaxHeight : _panelMinHeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Drawer(
          elevation: 16.0,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20.0),
              bottomRight: Radius.circular(20.0),
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                const Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _DrawerCard(
                  children: [
                    StreamBuilder(
                      stream: _chatService.currentUserDocStream(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data();
                        final name = (data?['name'] ?? 'Your Profile').toString();
                        final nickname = (data?['nickname'] ?? '').toString().trim();
                        final email = (data?['email'] ?? '').toString().trim();
                        final handle = nickname.isNotEmpty
                            ? '@$nickname'
                            : email.isNotEmpty
                                ? '@${email.split('@').first}'
                                : '@user';
                        // Use local profile photos from folder
                        final imageProvider = ProfilePhotoHelper.getProfileImage(
                          FirebaseAuth.instance.currentUser?.uid ?? '',
                          userName: name,
                        );

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFFE0B2),
                            backgroundImage: imageProvider,
                            onBackgroundImageError: (exception, stackTrace) {
                              // If image fails to load, show initials
                            },
                            child: imageProvider is NetworkImage
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(name),
                          subtitle: Text('Switch profile · $handle'),
                          trailing: null,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.black),
                      title: const Text('Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DrawerCard(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.chat_bubble_outline, color: Colors.black),
                      title: const Text('Message requests'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedCategory = 3);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.archive_outlined, color: Colors.black),
                      title: const Text('Archive'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedCategory = 5);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DrawerCard(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.people, color: Colors.black),
                      title: const Text('Friend requests'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedCategory = 4);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DrawerCard(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings, color: Color(0xFFF57C00)),
                      title: const Text('User Management'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserManagementScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Communities',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _DrawerCard(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add, color: Colors.black),
                      title: const Text('Create community'),
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Colors.white,
            toolbarHeight: 80.0,
            collapsedHeight: 80.0,
            pinned: true,
            elevation: 0.0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: 'Menu',
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Transform.translate(
                    offset: const Offset(0, 12),
                    child: Text(
                      'chatalk',
                      style: GoogleFonts.yesevaOne(
                        fontSize: 32.0,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30,
                    top: 4,
                    child: Image.asset(
                      'assets/badge/logo.png',
                      width: 25,
                      height: 25,
                    ),
                  ),
                ],
              ),
            ),
            centerTitle: true,
            actions: const [],
          ),
          ...buildDrawerSearchSlivers(
            panelHeight: _panelHeight,
            onPanelDragUpdate: _handlePanelDragUpdate,
            onPanelDragEnd: _handlePanelDragEnd,
            selectedIndex: _selectedCategory,
            onSelectTab: (index) => setState(() => _selectedCategory = index),
          ),
          if (_selectedCategory == 0 || _selectedCategory == 1)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StoriesHeaderDelegate(),
            ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                ),
              ),
              child: _buildCategoryContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case 1:
        return const OnlineUsers();
      case 2:
        return const GroupsSection();
      case 3:
        return const FriendsSection();
      case 4:
        return const HistorySection();
      default:
        return const RecentChats();
    }
  }
}

class _StoriesHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const double _height = 110.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).colorScheme.secondary,
      child: const Stories(),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _DrawerCard extends StatelessWidget {
  const _DrawerCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: children
            .map(
              (child) => Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.black12,
                  listTileTheme: const ListTileThemeData(
                    iconColor: Colors.black87,
                    textColor: Colors.black87,
                    subtitleTextStyle: TextStyle(color: Colors.black54),
                  ),
                ),
                child: child,
              ),
            )
            .toList(),
      ),
    );
  }
}
