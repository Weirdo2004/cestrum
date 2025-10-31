// <-- ADD THIS IMPORT
import 'package:ces/interactive_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // <-- ADD THIS IMPORT
import 'signup_data.dart';
import 'step1_details.dart';
import 'step2_profile.dart';
import 'step3_photo.dart';
import 'step4_terms.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final PageController _pageController = PageController();
  final SignUpData _signUpData = SignUpData();
  int _currentPage = 0;
  final int _totalPages = 4;
  bool _isLoading = false;
  String _loadingMessage = 'Creating your account...'; // For loading text

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  // --- UPDATED SIGNUP LOGIC (WITH PHOTO UPLOAD) ---
  Future<void> _onSignUp() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Creating your account...';
    });

    try {
      // 1. Create user in Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _signUpData.email.trim(),
        password: _signUpData.password.trim(),
      );

      User? user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed.');
      }

      // 2. Handle Photo Upload (if one was picked in Step 3)
      String? photoURL; // Start with null
      if (_signUpData.photoFile != null) {
        setState(() {
          _loadingMessage = 'Uploading photo...'; // Update loading text
        });

        // Create storage reference
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pics')
            .child('${user.uid}.jpg');

        // Upload the file
        final uploadTask = await storageRef.putFile(_signUpData.photoFile!);

        // Get the download URL
        photoURL = await uploadTask.ref.getDownloadURL();
      }

      // 3. Save user data to Cloud Firestore
      setState(() {
        _loadingMessage = 'Finishing setup...';
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': _signUpData.email,
        'name': _signUpData.name,
        'nickname': _signUpData.nickname,
        'age': _signUpData.age,
        'gender': _signUpData.gender,
        'showAge': _signUpData.showAge,
        'purpose': _signUpData.purpose.toList(),
        'photoURL':
            photoURL, // Use the photoURL variable (will be null if no photo)
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Navigate to home screen
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
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
    final double progress = (_currentPage + 1) / _totalPages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
      backgroundColor: Color(0xFF2C6485),
      body: Stack(
        children: [
          InteractiveGridBackground(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Step1Details(data: _signUpData, onNext: _nextPage),
                Step2Profile(
                    data: _signUpData,
                    onNext: _nextPage,
                    onBack: _previousPage),
                Step3Photo(
                    data: _signUpData,
                    onNext: _nextPage,
                    onBack: _previousPage),
                Step4Terms(
                    data: _signUpData,
                    onSignUp: _onSignUp,
                    onBack: _previousPage),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      _loadingMessage, // Use the dynamic loading message
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
