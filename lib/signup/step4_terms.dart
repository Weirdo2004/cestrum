import 'package:flutter/material.dart';
import 'signup_data.dart';

class Step4Terms extends StatefulWidget {
  final SignUpData data;
  final VoidCallback onSignUp;
  final VoidCallback onBack;

  const Step4Terms({
    super.key,
    required this.data,
    required this.onSignUp,
    required this.onBack,
  });

  @override
  State<Step4Terms> createState() => _Step4TermsState();
}

class _Step4TermsState extends State<Step4Terms> {
  late bool _agreedToTerms;

  @override
  void initState() {
    super.initState();
    _agreedToTerms = widget.data.agreedToTerms;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'One last step...',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),

          Container(
            height: 200, // Placeholder for terms text
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 102, 132, 134),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SingleChildScrollView(
              child: Text('Please read and agree to our Terms & Conditions.\n\n'
                  '1. You must be a student.\n'
                  '2. You must be respectful to all users.\n'
                  '3. Do not share personal information you are not comfortable with.\n'
                  '4. ...\n'
                  // Add more terms text here
                  ),
            ),
          ),
          const SizedBox(height: 20),

          CheckboxListTile(
            title: Text(
              'I agree to the Terms & Conditions',
              style: theme.textTheme.titleMedium,
            ),
            value: _agreedToTerms,
            onChanged: (value) {
              setState(() {
                _agreedToTerms = value ?? false;
                widget.data.agreedToTerms = _agreedToTerms;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 40),

          // Sign Up Button
          ElevatedButton(
            // Disable button if terms are not agreed to
            onPressed: _agreedToTerms ? widget.onSignUp : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              // Show a disabled state
              backgroundColor: _agreedToTerms
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surface,
              foregroundColor:
                  _agreedToTerms ? Colors.white : Colors.white.withOpacity(0.5),
            ),
            child: const Text('Sign Up & Start'),
          ),

          const SizedBox(height: 20),

          // Navigation Button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_ios_rounded),
              iconSize: 24,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
