import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/check_in_service.dart';
import '../../services/event_service.dart';
import '../../utils/app_theme.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String? code) async {
    if (code == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Parse the QR code - it should contain event ID or check-in code
      // Format could be: "EVENT:{eventId}" or just the eventId or a check-in code
      String? eventId;
      
      if (code.startsWith('EVENT:')) {
        eventId = code.substring(6);
      } else if (code.startsWith('CHECKIN:')) {
        // If it's a check-in code, we need to find the event
        final event = await EventService.findEventByCheckInCode(code.substring(8));
        eventId = event?.id;
      } else {
        // Try to use the code directly as event ID
        // First verify it's a valid event
        final event = await EventService.getEventById(code);
        if (event != null) {
          eventId = code;
        } else {
          // Try to find event by fallback code
          final eventByCode = await EventService.findEventByCheckInCode(code);
          eventId = eventByCode?.id;
        }
      }

      if (eventId == null) {
        throw Exception('Invalid QR code. Could not find event.');
      }

      // Check in the user
      final checkIn = await CheckInService.checkIn(
        eventId: eventId,
        barcodeUsed: code,
        pointsEarned: 10,
      );

      if (mounted) {
        _controller.stop();
        
        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Check-in successful! You earned ${checkIn?.pointsEarned ?? 10} points!',
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, true); // Return true to indicate successful check-in
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );

        // Resume scanning after error
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  _handleQRCode(barcode.rawValue);
                  break; // Process only the first barcode
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isProcessing) ...[
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Processing check-in...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Point your camera at the event QR code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The QR code should be displayed at the event venue',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom overlay shape for QR scanner
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

