import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_ui/scripts/populate_users_and_chats.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter/foundation.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _bulkEmailsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _bulkEmailsController.dispose();
    super.dispose();
  }

  Future<void> _addSingleUser() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showMessage('Please enter an email address', isError: true);
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please enter a password', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Store current user
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Create new user account
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user to Firestore
      final displayName = name.isEmpty ? email.split('@').first : name;
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': displayName,
        'email': email,
        'nickname': '',
        'bio': '',
        'createdAt': FieldValue.serverTimestamp(),
        'online': false,
      });

      // Sign back in as the original user
      if (currentUser != null) {
        // Note: This signs out the new user and you need to sign back in
        await FirebaseAuth.instance.signOut();
        _showMessage('User created: $email\nYou\'ll need to sign back in as yourself.', isError: false);
      }

      _emailController.clear();
      _nameController.clear();
      _passwordController.clear();
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Failed to create user';
      if (e.code == 'email-already-in-use') {
        errorMsg = 'Email already exists';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Invalid email format';
      } else if (e.code == 'weak-password') {
        errorMsg = 'Password should be at least 6 characters';
      }
      _showMessage(errorMsg, isError: true);
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addBulkUsers() async {
    final emailsText = _bulkEmailsController.text.trim();
    if (emailsText.isEmpty) {
      _showMessage('Please enter at least one email', isError: true);
      return;
    }

    final emails = emailsText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.contains('@'))
        .toList();

    if (emails.isEmpty) {
      _showMessage('No valid emails found', isError: true);
      return;
    }

    const defaultPassword = 'password123'; // Default password for bulk creation

    setState(() => _isLoading = true);

    try {
      final results = <String>[];
      
      for (final email in emails) {
        try {
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: defaultPassword,
          );

          final displayName = email.split('@').first;
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'name': displayName,
            'email': email,
            'nickname': '',
            'bio': '',
            'createdAt': FieldValue.serverTimestamp(),
            'online': false,
          });

          results.add('✓ $email');
          
          // Sign out after each creation
          await FirebaseAuth.instance.signOut();
        } catch (e) {
          results.add('✗ $email: ${e.toString().substring(0, 50)}');
        }
      }

      _showBulkResultsDialog(results, defaultPassword);
      _bulkEmailsController.clear();
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _populateClassmates() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Classmates & Chats'),
        content: const Text(
          'This will add 11 users and generate 55 one-on-one conversations (every person talks to every other person).\n\n'
          'Friend groups get casual chats, others get formal classmate chats.\n\n'
          'Default password: password123\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF57C00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        // On web, use ChatService to generate conversations for current user
        debugPrint('🌐 Web platform detected - using ChatService to generate conversations');
        await ChatService().ensureAllConversations();
        _showMessage('✅ Successfully generated conversations for your account!', isError: false);
      } else {
        // On native, use PopulateUsersAndChats which adds test users
        await PopulateUsersAndChats.run();
        _showMessage('✅ Successfully added 11 classmates and generated 55 conversations!', isError: false);
      }
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showBulkResultsDialog(List<String> results, String defaultPassword) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk User Creation Results'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Default password: $defaultPassword\n', 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              const Text('Results:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...results.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(r, style: const TextStyle(fontSize: 12)),
              )),
              const SizedBox(height: 16),
              const Text('⚠️ You\'ll need to sign back in as yourself.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loginAsUser(String email) async {
    // Show password input dialog
    final passwordController = TextEditingController(text: 'password123');
    
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login as User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Login as: $email'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                hintText: 'Default: password123',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            const Text(
              '⚠️ This will log you out of your current account.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF57C00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );

    if (shouldLogin != true) {
      passwordController.dispose();
      return;
    }

    final password = passwordController.text.trim();
    passwordController.dispose();

    if (password.isEmpty) {
      _showMessage('Please enter a password', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sign out current user
      await FirebaseAuth.instance.signOut();
      
      // Sign in as the selected user
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      
      // Navigate back to home screen
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      _showMessage('Logged in as $email', isError: false);
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Failed to login';
      if (e.code == 'user-not-found') {
        errorMsg = 'User not found';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Wrong password';
      } else if (e.code == 'invalid-credential') {
        errorMsg = 'Invalid credentials. Try "password123" or the password you set.';
      }
      _showMessage(errorMsg, isError: true);
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _quickLoginButton(String email, String name) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : () => _loginAsUser(email),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: const Icon(Icons.person, size: 16),
      label: Text(name, style: const TextStyle(fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFFF57C00),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warning Card
                  Card(
                    color: Colors.orange.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚠️ Important Note',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Creating users will log you out. You\'ll need to sign back in with your own account after adding users.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Login Section (Admin)
                  Card(
                    elevation: 3,
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.admin_panel_settings, color: Colors.blue, size: 26),
                              SizedBox(width: 8),
                              Text(
                                'Quick Login (Admin)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Switch to a test account quickly:',
                            style: TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _quickLoginButton('james.berto@example.com', 'James'),
                              _quickLoginButton('franz.smith@example.com', 'Franz'),
                              _quickLoginButton('jerome.brown@example.com', 'Jerome'),
                              _quickLoginButton('christian.ace@example.com', 'Christian'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Default password: password123',
                            style: TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Generate Classmates Section
                  Card(
                    elevation: 4,
                    color: const Color(0xFFFFF3E0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Color(0xFFF57C00), size: 28),
                              SizedBox(width: 8),
                              Text(
                                'Quick Setup',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF57C00),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Add 11 classmates with one-on-one conversations between everyone:',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Christian, James, Franz, Jerome\n'
                            '• Michael, Jian, Paolo, Enrico\n'
                            '• Nicole, Allyxis, Trisha\n\n'
                            '55 total conversations (every pair)',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _populateClassmates,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF57C00),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.group_add, size: 24),
                            label: const Text(
                              'Generate Classmates & Chats',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(thickness: 2),
                  const SizedBox(height: 24),

                  // Single User Section
                  const Text(
                    'Add Single User',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addSingleUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF57C00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Create User', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 32),
                  const Divider(thickness: 2),
                  const SizedBox(height: 32),

                  // Bulk User Section
                  const Text(
                    'Add Multiple Users (Bulk)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter one email per line. Default password "password123" will be used.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bulkEmailsController,
                    decoration: const InputDecoration(
                      labelText: 'Email Addresses (one per line)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _addBulkUsers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.group_add),
                    label: const Text('Create All Users', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 24),

                  // View Current Users Section
                  const Divider(thickness: 2),
                  const SizedBox(height: 24),
                  const Text(
                    'Current Users in Database',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final users = snapshot.data!.docs;
                      if (users.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No users found in database'),
                          ),
                        );
                      }

                      return Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: users.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final user = users[index].data() as Map<String, dynamic>;
                            final name = user['name'] ?? 'Unknown';
                            final email = user['email'] ?? 'No email';
                            final online = user['online'] ?? false;
                            final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
                            final isCurrentUser = email == currentUserEmail;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: online ? Colors.green : Colors.grey,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(name)),
                                  if (isCurrentUser)
                                    const Chip(
                                      label: Text('You', style: TextStyle(fontSize: 10)),
                                      backgroundColor: Color(0xFFFFF3E0),
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
                              ),
                              subtitle: Text(email),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (online)
                                    const Icon(Icons.circle, color: Colors.green, size: 12),
                                  if (!isCurrentUser) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.login, color: Color(0xFFF57C00)),
                                      tooltip: 'Login as this user',
                                      onPressed: () => _loginAsUser(email),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
