import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AgeVerificationDialog extends StatelessWidget {
  final int requiredAge;
  final VoidCallback onVerified;
  final VoidCallback? onDeclined;

  const AgeVerificationDialog({
    super.key,
    this.requiredAge = 21,
    required this.onVerified,
    this.onDeclined,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Age Verification Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user,
            size: 64,
            color: AppTheme.warningColor,
          ),
          const SizedBox(height: 16),
          Text(
            'You must be $requiredAge years or older to access age-restricted categories.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          const Text(
            'By proceeding, you confirm that you are of legal age.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        if (onDeclined != null)
          TextButton(
            onPressed: onDeclined,
            child: const Text('Cancel'),
          ),
        ElevatedButton(
          onPressed: onVerified,
          child: Text('I Confirm I Am $requiredAge+'),
        ),
      ],
    );
  }
}

