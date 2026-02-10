import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/screens/chat_screen.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _imageFile;
  String? _imageUrl;
  bool _loading = false;
  bool _showAllUsers = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      return await ChatService().uploadFile(
        file: _imageFile!,
        folder: 'profile_images',
        fileName: fileName,
      );
    } catch (e) {
      _showError('Failed to upload image: $e');
      return null;
    }
  }

  Future<void> _addFriend(String userId) async {
    setState(() => _loading = true);

    try {
      await ChatService().addFriend(userId);
      
      // Fetch the user's details to navigate to chat
      final addedUser = await ChatService().fetchUser(userId);
      
      if (mounted && addedUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend added!')),
        );
        
        // Navigate to the chat screen with the added user
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(user: addedUser),
          ),
        );
      } else if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to add friend: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _showAllUsers ? _buildUsersList() : _buildCreateProfile(),
      floatingActionButton: _showAllUsers
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _showAllUsers = false;
                });
              },
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.person_add),
              label: const Text('Create New Profile'),
            )
          : null,
    );
  }

  Widget _buildUsersList() {
    final chatService = ChatService();
    
    return StreamBuilder(
      stream: chatService.currentUserDocStream(),
      builder: (context, currentUserSnapshot) {
        final currentUserData = currentUserSnapshot.data?.data();
        final friends = List<String>.from(currentUserData?['friends'] ?? const []);

        return StreamBuilder(
          stream: chatService.usersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No users found'),
              );
            }

            final users = snapshot.data!;
            final currentUserId = chatService.currentUserId;
            final availableUsers = users
                .where((u) => u.id != currentUserId && !friends.contains(u.id))
                .toList();

            if (availableUsers.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No new users to add.\nCreate a new profile below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: availableUsers.length,
              itemBuilder: (context, index) {
                final user = availableUsers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: user.photoUrl.isNotEmpty
                          ? NetworkImage(user.photoUrl)
                          : null,
                      child: user.photoUrl.isEmpty
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(user.email.isNotEmpty ? user.email : '@${user.name.toLowerCase().replaceAll(' ', '_')}'),
                    trailing: ElevatedButton.icon(
                      onPressed: _loading ? null : () => _addFriend(user.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add'),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCreateProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create New User Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Profile Picture
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : null,
                  child: _imageFile == null
                      ? const Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: Colors.grey,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap to select profile picture',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name required' : null,
            ),
            const SizedBox(height: 16),

            // Email Field (Optional)
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 30),

            // Create Button
            ElevatedButton(
              onPressed: _loading ? null : _createProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create Profile',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
            const SizedBox(height: 16),

            // Back Button
            TextButton(
              onPressed: () {
                setState(() {
                  _showAllUsers = true;
                });
              },
              child: const Text('Back to Users List'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // Upload image if selected
      if (_imageFile != null) {
        _imageUrl = await _uploadImage();
      }

      // Create user profile
      await ChatService().createUserProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        photoUrl: _imageUrl ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile created successfully!')),
        );
        setState(() {
          _showAllUsers = true;
          _nameController.clear();
          _emailController.clear();
          _imageFile = null;
          _imageUrl = null;
        });
      }
    } catch (e) {
      _showError('Failed to create profile: $e');
    } finally {
      setState(() => _loading = false);
    }
  }
}
