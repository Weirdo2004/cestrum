import 'package:flutter/material.dart';
import 'signup_data.dart';

class Step2Profile extends StatefulWidget {
  final SignUpData data;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step2Profile({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<Step2Profile> createState() => _Step2ProfileState();
}

class _Step2ProfileState extends State<Step2Profile> {
  late bool _showAge;
  late Set<String> _purpose;

  @override
  void initState() {
    super.initState();
    _showAge = widget.data.showAge;
    _purpose = widget.data.purpose;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Profile',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),

          Text('Your Gender', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: widget.data.gender.isEmpty ? null : widget.data.gender,
            decoration: InputDecoration(
              labelText: 'Select Gender',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                    color: const Color.fromARGB(255, 237, 236, 241),
                    width: 1.0),
              ),
              prefixIcon: Icon(Icons.wc_outlined),
            ),
            items:
                ['Male', 'Female', 'Non-Binary', 'Other', 'Prefer not to say']
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
            onChanged: (value) {
              setState(() {
                widget.data.gender = value ?? '';
              });
            },
          ),
          const SizedBox(height: 32),

          Text('Looking for...', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'friends',
                label: Text('Friends'),
                icon: Icon(Icons.people_outline),
              ),
              ButtonSegment(
                value: 'date',
                label: Text('Date'),
                icon: Icon(Icons.favorite_border),
              ),
            ],
            selected: _purpose,
            onSelectionChanged: (newSelection) {
              setState(() {
                // Allow both, one, or none (though we default to friends)
                _purpose = newSelection;
                widget.data.purpose = newSelection;
              });
            },
            multiSelectionEnabled: true,
          ),
          const SizedBox(height: 32),

          SwitchListTile(
            title:
                Text('Show age on profile', style: theme.textTheme.titleMedium),
            value: _showAge,
            onChanged: (value) {
              setState(() {
                _showAge = value;
                widget.data.showAge = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 40),
          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_ios_rounded),
                iconSize: 24,
                color: theme.primaryColor,
              ),
              IconButton.filled(
                onPressed: widget.onNext,
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                iconSize: 24,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
