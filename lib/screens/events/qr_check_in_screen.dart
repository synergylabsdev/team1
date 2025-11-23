import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/qr_check_in_service.dart';
import '../../utils/app_theme.dart';

class QRCheckInScreen extends StatefulWidget {
  const QRCheckInScreen({super.key});

  @override
  State<QRCheckInScreen> createState() => _QRCheckInScreenState();
}

class _QRCheckInScreenState extends State<QRCheckInScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _fallbackCodeController = TextEditingController();
  bool _isProcessing = false;
  bool _showScanner = true;

  @override
  void dispose() {
    _scannerController.dispose();
    _fallbackCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String? code) async {
    if (code == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _showScanner = false;
    });

    try {
      final response = await QRCheckInService.processQRCode(code);
      
      setState(() {
        _isProcessing = false;
      });

      if (response.isSuccess) {
        _scannerController.stop();
        _showSuccessDialog(response.points ?? 50);
      } else {
        _showErrorDialog(response.message ?? 'Unknown error');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  Future<void> _handleManualCheckIn() async {
    final code = _fallbackCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a fallback code'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await QRCheckInService.checkInWithFallbackCode(code);
      
      setState(() {
        _isProcessing = false;
      });

      if (response.isSuccess) {
        _showSuccessDialog(response.points ?? 50);
        _fallbackCodeController.clear();
      } else {
        _showErrorDialog(response.message ?? 'Unknown error');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  void _showSuccessDialog(int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 32),
            const SizedBox(width: 8),
            const Text('Check-In Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You have successfully checked in!',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Card(
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Points Awarded',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$points',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close check-in screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorColor, size: 32),
            const SizedBox(width: 8),
            const Text('Check-In Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showScanner = true;
                _isProcessing = false;
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In'),
        actions: [
          IconButton(
            icon: Icon(_showScanner ? Icons.keyboard : Icons.qr_code_scanner),
            onPressed: () {
              setState(() {
                _showScanner = !_showScanner;
              });
            },
            tooltip: _showScanner ? 'Manual Entry' : 'Scan QR Code',
          ),
          if (_showScanner)
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () => _scannerController.toggleTorch(),
            ),
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing check-in...'),
                ],
              ),
            )
          : _showScanner
              ? _buildScannerView()
              : _buildManualEntryView(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        // Camera view
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null && !_isProcessing) {
                _handleQRCode(barcode.rawValue);
                break;
              }
            }
          },
        ),

        // Overlay with scanning area
        Container(
          decoration: ShapeDecoration(
            shape: QrScannerOverlayShape(
              borderColor: AppTheme.primaryColor,
              borderRadius: 16,
              borderLength: 30,
              borderWidth: 4,
              cutOutSize: 250,
            ),
          ),
        ),

        // Instructions
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Point your camera at the event QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'The QR code should be displayed at the event venue',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualEntryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.keyboard,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Manual Check-In',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the fallback code provided at the event',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _fallbackCodeController,
            decoration: const InputDecoration(
              labelText: 'Fallback Code',
              hintText: 'Enter the event code (e.g., ABCD1234)',
              prefixIcon: Icon(Icons.qr_code),
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _handleManualCheckIn(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isProcessing ? null : _handleManualCheckIn,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text(
              'Check In',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// Reuse the overlay shape from qr_scanner_screen.dart
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final _cutOutSize = cutOutSize < width || cutOutSize < height
        ? (width < height ? width : height) - 40
        : cutOutSize;

    final _cutOutLeft = (width - _cutOutSize) / 2;
    final _cutOutTop = (height - _cutOutSize) / 2;
    final _cutOutRight = _cutOutLeft + _cutOutSize;
    final _cutOutBottom = _cutOutTop + _cutOutSize;

    // Draw overlay
    final overlayPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            _cutOutLeft,
            _cutOutTop,
            _cutOutRight,
            _cutOutBottom,
          ),
          Radius.circular(borderRadius),
        ),
      );

    canvas.drawPath(overlayPath, Paint()..color = overlayColor);

    // Draw border
    final borderPath = Path()
      ..moveTo(_cutOutLeft + borderRadius, _cutOutTop)
      ..lineTo(_cutOutLeft + _cutOutSize - borderRadius, _cutOutTop)
      ..quadraticBezierTo(
        _cutOutLeft + _cutOutSize,
        _cutOutTop,
        _cutOutLeft + _cutOutSize,
        _cutOutTop + borderRadius,
      )
      ..lineTo(_cutOutLeft + _cutOutSize, _cutOutTop + _cutOutSize - borderRadius)
      ..quadraticBezierTo(
        _cutOutLeft + _cutOutSize,
        _cutOutTop + _cutOutSize,
        _cutOutLeft + _cutOutSize - borderRadius,
        _cutOutTop + _cutOutSize,
      )
      ..lineTo(_cutOutLeft + borderRadius, _cutOutTop + _cutOutSize)
      ..quadraticBezierTo(
        _cutOutLeft,
        _cutOutTop + _cutOutSize,
        _cutOutLeft,
        _cutOutTop + _cutOutSize - borderRadius,
      )
      ..lineTo(_cutOutLeft, _cutOutTop + borderRadius)
      ..quadraticBezierTo(
        _cutOutLeft,
        _cutOutTop,
        _cutOutLeft + borderRadius,
        _cutOutTop,
      );

    canvas.drawPath(
      borderPath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    // Draw corners
    final cornerLength = borderLength;
    final cornerWidth = borderWidth;

    // Top-left corner
    canvas.drawLine(
      Offset(_cutOutLeft, _cutOutTop + cornerLength),
      Offset(_cutOutLeft, _cutOutTop),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(_cutOutLeft, _cutOutTop),
      Offset(_cutOutLeft + cornerLength, _cutOutTop),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cornerWidth,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(_cutOutRight - cornerLength, _cutOutTop),
      Offset(_cutOutRight, _cutOutTop),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(_cutOutRight, _cutOutTop),
      Offset(_cutOutRight, _cutOutTop + cornerLength),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cornerWidth,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(_cutOutRight, _cutOutBottom - cornerLength),
      Offset(_cutOutRight, _cutOutBottom),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(_cutOutRight, _cutOutBottom),
      Offset(_cutOutRight - cornerLength, _cutOutBottom),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cornerWidth,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(_cutOutLeft + cornerLength, _cutOutBottom),
      Offset(_cutOutLeft, _cutOutBottom),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(_cutOutLeft, _cutOutBottom),
      Offset(_cutOutLeft, _cutOutBottom - cornerLength),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cornerWidth,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}

