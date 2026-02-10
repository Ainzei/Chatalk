import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/utils/image_loader.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final ChatService _chatService = ChatService();
  AppUser? _currentUser;
  bool _isDarkMode = false;
  bool _isActiveStatus = false;
  static const String _sandovalEmail = 'sandovalchristianace3206@gmail.com';
  static const String _sandovalPfpPath =
      'facebook-AceSandoval3206-2026-02-03-alN4NiXy/your_facebook_activity/messages/inbox/jeromefranzandjames_33543101728622614/photos/1585610535908571.jpg';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = _chatService.currentUserId;
    final user = await _chatService.fetchUser(uid);
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _currentUser == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              children: [
                const SizedBox(height: 20),
                // Profile Picture Section - LARGER
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 90, // LARGER - was 60
                        backgroundImage: _currentUser!.email == _sandovalEmail
                            ? getImageProvider(_sandovalPfpPath)
                            : _currentUser!.photoUrl.isNotEmpty
                                ? NetworkImage(_currentUser!.photoUrl)
                                : null,
                        backgroundColor: const Color(0xFFFFE0B2),
                        child: (_currentUser!.email == _sandovalEmail ||
                                _currentUser!.photoUrl.isNotEmpty)
                            ? null
                            : Text(
                                _currentUser!.name.isNotEmpty
                                    ? _currentUser!.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[800],
                            border: Border.all(
                              color: Colors.black,
                              width: 3,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Camera feature coming soon'),
                                  backgroundColor: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name
                Center(
                  child: Text(
                    _currentUser?.name ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                
                // Username/Handle
                Center(
                  child: Text(
                    '@${_currentUser?.nickname ?? _currentUser?.name.split(' ').first ?? 'user'}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Settings Section 1
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        icon: Icons.circle,
                        title: 'Active status',
                        trailing: Text(
                          _isActiveStatus ? 'On' : 'Off',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          setState(() {
                            _isActiveStatus = !_isActiveStatus;
                          });
                        },
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      _buildSettingTile(
                        icon: Icons.dark_mode,
                        title: 'Dark mode',
                        trailing: Text(
                          _isDarkMode ? 'On' : 'Off',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          setState(() {
                            _isDarkMode = !_isDarkMode;
                          });
                        },
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      _buildSettingTile(
                        icon: Icons.accessibility,
                        title: 'Accessibility',
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      _buildSettingTile(
                        icon: Icons.privacy_tip,
                        title: 'Privacy & safety',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Settings Section 2
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildSettingTile(
                    icon: Icons.family_restroom,
                    title: 'Family Center',
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 16),

                // Settings Section 3
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        icon: Icons.person,
                        title: 'Avatar',
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      _buildSettingTile(
                        icon: Icons.alternate_email,
                        title: 'Username',
                        trailing: Text(
                          '@${_currentUser?.nickname ?? _currentUser?.name.split(' ').first ?? 'user'}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      _buildSettingTile(
                        icon: Icons.notifications,
                        title: 'Notifications & sounds',
                        trailing: const Text(
                          'On',
                          style: TextStyle(color: Colors.grey),
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing,
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
