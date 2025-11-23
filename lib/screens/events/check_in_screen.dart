import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/event_model.dart';
import '../../services/check_in_service.dart';
import '../../utils/app_theme.dart';
import 'qr_scanner_screen.dart';

class CheckInScreen extends StatefulWidget {
  final EventModel event;
  final VoidCallback? onCheckInComplete;

  const CheckInScreen({
    super.key,
    required this.event,
    this.onCheckInComplete,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _isCheckingIn = false;
  bool _checkInComplete = false;
  int _pointsEarned = 0;

  Future<void> _performCheckIn() async {
    setState(() {
      _isCheckingIn = true;
    });

    try {
      final checkIn = await CheckInService.checkIn(
        eventId: widget.event.id,
        barcodeUsed: widget.event.fallbackCode,
        pointsEarned: 10, // Default points
      );

      setState(() {
        _isCheckingIn = false;
        _checkInComplete = true;
        _pointsEarned = checkIn?.pointsEarned ?? 10;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in successful! You earned $_pointsEarned points!'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      widget.onCheckInComplete?.call();
    } catch (e) {
      setState(() {
        _isCheckingIn = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_checkInComplete) ...[
              // Event Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        widget.event.storeName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.event.location,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Barcode/QR Code Display
              if (widget.event.qrCodeUrl != null)
                Image.network(
                  widget.event.qrCodeUrl!,
                  height: 200,
                  width: 200,
                )
              else if (widget.event.fallbackCode != null)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: widget.event.fallbackCode!,
                        version: QrVersions.auto,
                        size: 200,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Check-In Code',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.event.fallbackCode!,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Instructions
              Card(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Option 1: Show this code to event staff\nOption 2: Scan the event QR code',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Scan QR Code Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isCheckingIn
                      ? null
                      : () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QRScannerScreen(),
                            ),
                          );

                          if (result == true) {
                            // Check-in was successful via QR scan
                            setState(() {
                              _checkInComplete = true;
                              _pointsEarned = 10;
                            });
                            widget.onCheckInComplete?.call();
                          }
                        },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Event QR Code'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Manual Check-In Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCheckingIn ? null : _performCheckIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.successColor,
                  ),
                  child: _isCheckingIn
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Confirm Check-In (Manual)',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ] else ...[
              // Success State
              Icon(
                Icons.check_circle,
                size: 80,
                color: AppTheme.successColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Check-In Complete!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'You earned',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_pointsEarned Points',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

