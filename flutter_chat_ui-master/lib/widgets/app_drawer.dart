import 'package:flutter/material.dart';

class AppDrawer extends StatefulWidget {
  final String userName;
  final String userUsername;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onMessageRequestsTap;
  final VoidCallback? onArchiveTap;
  final VoidCallback? onFriendRequestsTap;

  const AppDrawer({
    Key? key,
    required this.userName,
    required this.userUsername,
    this.onProfileTap,
    this.onSettingsTap,
    this.onMessageRequestsTap,
    this.onArchiveTap,
    this.onFriendRequestsTap,
  }) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Profile Header
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${widget.userUsername}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Profile
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              widget.onProfileTap?.call();
              Navigator.pop(context);
            },
          ),
          // Switch Profile
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Switch Profile'),
            onTap: () {
              Navigator.pop(context);
              // Add switch profile logic here
            },
          ),
          const Divider(),
          // Message Requests
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('Message Requests'),
            onTap: () {
              widget.onMessageRequestsTap?.call();
              Navigator.pop(context);
            },
          ),
          // Friend Requests
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Friend Requests'),
            onTap: () {
              widget.onFriendRequestsTap?.call();
              Navigator.pop(context);
            },
          ),
          // Archive
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('Archive'),
            onTap: () {
              widget.onArchiveTap?.call();
              Navigator.pop(context);
            },
          ),
          const Divider(),
          // Settings
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              widget.onSettingsTap?.call();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
