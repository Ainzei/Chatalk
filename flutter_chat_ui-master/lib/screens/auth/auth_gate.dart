import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/screens/auth/sign_in.dart';
import 'package:flutter_chat_ui/screens/home_screen.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/widgets/incoming_call_listener.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _error;

  Future<void> _ensureProfile() async {
    try {
      await ChatService().ensureUserProfile();
    } catch (e) {
      debugPrint('Warning: Could not create user profile: $e');
      // Don't fail on profile creation errors
    }
  }

  Future<void> _handleAuthError(String? message) async {
    if (message != null && (message.contains('invalid') ||
        message.contains('expired') ||
        message.contains('malformed'))) {
      // Sign out and ask user to log in again
      await FirebaseAuth.instance.signOut();
      setState(() {
        _error = 'Session expired. Please sign in again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          _handleAuthError(snapshot.error.toString());
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Authentication Error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      setState(() => _error = null);
                    },
                    child: const Text('Sign Out & Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return SignInScreen(initialError: _error);
        }

        return FutureBuilder<void>(
          future: _ensureProfile(),
          builder: (context, ensureSnapshot) {
            if (ensureSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (ensureSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Error Loading Profile'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const IncomingCallListener(
              child: HomeScreen(),
            );
          },
        );
      },
    );
  }
}
