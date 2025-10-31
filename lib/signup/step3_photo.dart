import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'signup_data.dart'; // Your data model

class Step3Photo extends StatefulWidget {
  final SignUpData data;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step3Photo({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<Step3Photo> createState() => _Step3PhotoState();
}

class _Step3PhotoState extends State<Step3Photo> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load the image if we already have one (e.g., user went back and forth)
    if (widget.data.photoFile != null) {
      _imageFile = widget.data.photoFile;
    }
  }

  // Show a dialog to choose camera or gallery
  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take photo from Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Pick an image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          // --- THIS IS THE KEY ---
          // Save the file to the shared data model
          widget.data.photoFile = _imageFile;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          Text(
            'Add a Profile Photo',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'This helps people recognize you.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // The CircleAvatar for picking and displaying the photo
          Center(
            child: GestureDetector(
              onTap: _showImageSourceDialog, // Show choice dialog
              child: CircleAvatar(
                radius: 100,
                backgroundColor: const Color.fromARGB(255, 102, 132, 134),
                backgroundImage:
                    _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null
                    ? Icon(
                        Icons.add_a_photo_outlined,
                        size: 60,
                        color: theme.primaryColor.withOpacity(0.7),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // "Continue" button
          ElevatedButton(
            onPressed: widget.onNext, // Just go to the next page
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child:
                Text(_imageFile == null ? 'Continue' : 'Continue with Photo'),
          ),
          const SizedBox(height: 20),

          // Back Button
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_ios_rounded),
                iconSize: 24,
                color: theme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
