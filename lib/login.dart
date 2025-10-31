import 'package:ces/interactive_widget.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // If form is not valid, do nothing
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
      // If login is successful, the StreamBuilder in main.dart
      // will automatically navigate to the HomeScreen.
      // Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      _showErrorSnackBar(message);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C6485),
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/signup'),
            child: const Text('Sign Up'),
          )
        ],
      ),
      body: InteractiveGridBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Student Email',
                        prefixIcon: const Icon(Icons.email_rounded),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    // Show loading indicator or button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : FuturisticRippleButton(
                            onPressed: _login,
                            isElevated: true,
                            child: const Text('Login'),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
