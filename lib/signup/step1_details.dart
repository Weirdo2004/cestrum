import 'package:flutter/material.dart';
import 'signup_data.dart';

class Step1Details extends StatefulWidget {
  final SignUpData data;
  final VoidCallback onNext;

  const Step1Details({super.key, required this.data, required this.onNext});

  @override
  State<Step1Details> createState() => _Step1DetailsState();
}

class _Step1DetailsState extends State<Step1Details> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndNext() {
    // Validate the form
    if (_formKey.currentState?.validate() ?? false) {
      // No need to call save() as onChanged already updated the data object
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldFill = Theme.of(context).colorScheme.surface.withOpacity(0.04);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );
    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(
          color: const Color.fromARGB(255, 237, 236, 241), width: 1.0),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(35.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              'Welcome! Tell us about you.',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 246, 247, 248),
              ),
            ),
            const SizedBox(height: 90),
            TextFormField(
              initialValue: widget.data.email,
              decoration: InputDecoration(
                labelText: 'Student Email',
                enabledBorder: enabledBorder,
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: fieldFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: fieldBorder,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => widget.data.email = value,
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),
            TextFormField(
              initialValue: widget.data.name,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.person_outline),
                enabledBorder: enabledBorder,
                filled: true,
                fillColor: fieldFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: fieldBorder,
              ),
              keyboardType: TextInputType.name,
              onChanged: (value) => widget.data.name = value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),
            TextFormField(
              initialValue: widget.data.nickname,
              decoration: InputDecoration(
                labelText: 'Nickname',
                enabledBorder: enabledBorder,
                prefixIcon: Icon(Icons.star_border_outlined),
                filled: true,
                fillColor: fieldFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: fieldBorder,
              ),
              keyboardType: TextInputType.text,
              onChanged: (value) => widget.data.nickname = value,
              // Nickname can be optional, so no validator
            ),
            const SizedBox(height: 25),
            TextFormField(
              initialValue: widget.data.age.toString(),
              decoration: InputDecoration(
                labelText: 'Age',
                enabledBorder: enabledBorder,
                prefixIcon: Icon(Icons.cake_outlined),
                filled: true,
                fillColor: fieldFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: fieldBorder,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => widget.data.age = int.tryParse(value) ?? 18,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your age';
                }
                if (int.tryParse(value) == null || int.parse(value) < 18) {
                  return 'You must be 18 or older';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),
            // --- NEW PASSWORD FIELDS ---
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                enabledBorder: enabledBorder,
                filled: true,
                fillColor: fieldFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: fieldBorder,
              ),
              obscureText: true,
              onChanged: (value) => widget.data.password = value,
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                enabledBorder: enabledBorder,
                filled: true,
                fillColor: fieldFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: fieldBorder,
              ),
              obscureText: true,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            // --- END NEW FIELDS ---
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton.filled(
                onPressed: _validateAndNext, // <-- MODIFIED
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                iconSize: 24,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
