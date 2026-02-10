import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum AuthMode { options, login, signup }

class SignInScreen extends StatefulWidget {
  final String? initialError;

  const SignInScreen({super.key, this.initialError});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  AuthMode mode = AuthMode.options;

  double panelHeight = 260;
  final double minHeight = 260;
  late double maxHeight;

  bool loading = false;
  bool showPassword = false;

  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    maxHeight = MediaQuery.of(context).size.height * 0.7;
    
    // Show initial error if provided
    if (widget.initialError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showError(widget.initialError!);
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ================= BACKGROUND =================
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color.fromARGB(255, 255, 153, 0),
                  Color.fromARGB(255, 253, 51, 0),
                ],
              ),
            ),
          ),

          // ================= LOGO + TITLE =================
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Text(
                        'chatalk',
                        style: TextStyle(
                          fontFamily: 'YesevaOne',
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: -33,
                        top: -4,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 35,
                          height: 35,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'welcome world',
                    style: TextStyle(
                      fontFamily: 'YesevaOne',
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(2, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ================= DRAGGABLE PANEL =================
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  panelHeight -= details.delta.dy;
                  panelHeight = panelHeight.clamp(minHeight, maxHeight);
                });
              },
              onVerticalDragEnd: (_) {
                if (panelHeight < maxHeight * 0.6) {
                  setState(() {
                    panelHeight = minHeight;
                    mode = AuthMode.options;
                  });
                } else {
                  setState(() {
                    panelHeight = maxHeight;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOut,
                height: panelHeight,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(45)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 25),

                      if (mode == AuthMode.options) ...[
                        authButton("Login", () {
                          setState(() {
                            mode = AuthMode.login;
                            panelHeight = maxHeight;
                          });
                        }),
                        const SizedBox(height: 20),
                        authButton("Sign Up", () {
                          setState(() {
                            mode = AuthMode.signup;
                            panelHeight = maxHeight;
                          });
                        }),
                      ],

                      if (mode == AuthMode.login) loginForm(),
                      if (mode == AuthMode.signup) signupForm(),

                      if (loading)
                        const Padding(
                          padding: EdgeInsets.all(25),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget authButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Colors.orange, width: 2),
        ),
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure && !showPassword,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  Widget loginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          field(emailController, "Email"),
          const SizedBox(height: 20),
          field(passwordController, "Password", obscure: true),
          const SizedBox(height: 30),
          submitButton("Login", login),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                sendPasswordReset(email);
              } else {
                showError('Enter your email first.');
              }
            },
            child: const Text('Forgot password?'),
          ),
        ],
      ),
    );
  }

  Widget signupForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          field(emailController, "Email"),
          const SizedBox(height: 20),
          field(passwordController, "Password", obscure: true),
          const SizedBox(height: 20),
          field(confirmController, "Confirm Password", obscure: true),
          const SizedBox(height: 30),
          submitButton("Create Account", signup),
        ],
      ),
    );
  }

  Widget submitButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // ================= FIREBASE =================

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Login failed.';
      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'Account not found. Please sign up first.';
          break;
        case 'wrong-password':
          errorMsg = 'Incorrect password. Try again.';
          break;
        case 'invalid-email':
          errorMsg = 'Invalid email format.';
          break;
        case 'user-disabled':
          errorMsg = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMsg = 'Too many login attempts. Try again later.';
          break;
        case 'invalid-credential':
          errorMsg = 'Invalid credentials. Please check your email and password.';
          break;
        default:
          errorMsg = e.message ?? 'Login failed. ${e.code}';
      }
      showError(errorMsg);
    } catch (e) {
      showError('Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmController.text) {
      showError("Passwords do not match");
      return;
    }

    setState(() => loading = true);

    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          showEmailExistsDialog(emailController.text.trim());
          break;
        case 'invalid-email':
          showError('Please enter a valid email address.');
          break;
        case 'weak-password':
          showError('Password is too weak. Use at least 6 characters.');
          break;
        default:
          showError(e.message ?? e.toString());
      }
    } catch (e) {
      showError(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      showError('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      showError(e.message ?? 'Could not send password reset email.');
    } catch (e) {
      showError(e.toString());
    }
  }

  void showEmailExistsDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email already in use'),
        content: Text(
          'The email $email is already registered. Would you like to sign in or reset the password?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                mode = AuthMode.login;
                emailController.text = email;
                panelHeight = maxHeight;
              });
            },
            child: const Text('Sign in'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              sendPasswordReset(email);
            },
            child: const Text('Reset password'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
