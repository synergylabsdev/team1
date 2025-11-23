import 'package:flutter/material.dart';

class TermsAndConditionsDialog extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback? onDecline;

  const TermsAndConditionsDialog({
    super.key,
    required this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Terms & Conditions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please read and accept our Terms & Conditions to continue.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'By using SampleFinder, you agree to:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('• Use the app responsibly and legally'),
            const Text('• Provide accurate information'),
            const Text('• Respect age restrictions for events'),
            const Text('• Follow all applicable laws and regulations'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Open full terms in browser or new screen
                // For now, just show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Full terms available at support page'),
                  ),
                );
              },
              child: const Text('View Full Terms & Conditions'),
            ),
          ],
        ),
      ),
      actions: [
        if (onDecline != null)
          TextButton(
            onPressed: onDecline,
            child: const Text('Decline'),
          ),
        ElevatedButton(
          onPressed: onAccept,
          child: const Text('Accept'),
        ),
      ],
    );
  }
}

