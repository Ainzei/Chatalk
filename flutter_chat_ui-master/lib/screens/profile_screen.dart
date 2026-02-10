import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/utils/image_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final ChatService _chatService = ChatService();
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  AppUser? _currentUser;
  static const String _sandovalEmail = 'sandovalchristianace3206@gmail.com';
  static const String _sandovalPfpPath =
      'facebook-AceSandoval3206-2026-02-03-alN4NiXy/your_facebook_activity/messages/inbox/jeromefranzandjames_33543101728622614/photos/1585610535908571.jpg';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nicknameController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final uid = _chatService.currentUserId;
    final user = await _chatService.fetchUser(uid);
    if (user != null) {
      setState(() {
        _currentUser = user;
        _nameController.text = user.name;
        _nicknameController.text = user.nickname ?? '';
      });
    }
  }

  Future<void> _updateProfile() async {
    await _chatService.updateProfile(
      name: _nameController.text,
      nickname: _nicknameController.text,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _currentUser == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Profile Picture Section
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
                                      fontSize: 48, // Larger text too
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
                                color: Colors.orange,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 20),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Camera feature coming soon'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Names Section
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Names',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Full Name',
                              hintStyle:
                                  TextStyle(color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nicknames Section
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nicknames',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add a nickname for how you want to be called',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nicknameController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Your Nickname',
                              hintStyle:
                                  TextStyle(color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const SizedBox(height: 10),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Account Info
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Email',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _currentUser?.email ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

}
