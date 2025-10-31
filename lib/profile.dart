import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user is logged in.");
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!docSnapshot.exists) {
        throw Exception("User data not found in Firestore.");
      }

      if (mounted) {
        setState(() {
          _userData = docSnapshot.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Error: $_errorMessage',
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_userData == null) {
      return const Center(
          child: Text('An unknown error occurred.',
              style: TextStyle(color: Colors.red, fontSize: 16)));
    }

    // Extract data
    final String name = _userData!['name'] ?? 'No Name';
    final String email = _userData!['email'] ?? 'No Email';
    final String? photoURL = _userData!['photoURL'];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade300,
            // Use NetworkImage if photoURL exists, otherwise show placeholder
            backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
            child: photoURL == null
                ? const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
