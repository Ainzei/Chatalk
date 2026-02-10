import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/screens/chat_screen_new.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';

class UserProfileScreen extends StatelessWidget {
  final AppUser user;

  const UserProfileScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageProvider = ProfilePhotoHelper.getProfileImage(
      user.id,
      userName: user.name,
      photoUrl: user.photoUrl,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          user.name,
          style: const TextStyle(
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Profile Picture Section
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: imageProvider,
                  backgroundColor: const Color(0xFFFFE0B2),
                  child: !ProfilePhotoHelper.hasLocalPhoto(
                    user.id,
                    userName: user.name,
                  )
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 30),

              // User Info Section
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
                      'Profile Information',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Name', user.name),
                    const SizedBox(height: 12),
                    if (user.nickname != null && user.nickname!.isNotEmpty)
                      _buildInfoRow('Nickname', user.nickname!),
                    if (user.nickname != null && user.nickname!.isNotEmpty)
                      const SizedBox(height: 12),
                    if (user.email.isNotEmpty)
                      _buildInfoRow('Email', user.email),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Message Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(user: user),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Send Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
