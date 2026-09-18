import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../services/database_helper.dart';

import 'action_selection_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final bool returnBarcodeOnly;
  const BarcodeScannerScreen({super.key, this.returnBarcodeOnly = false});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController? _cameraController;
  bool _isProcessing = false;
  bool _cameraAvailable = true;
  bool _flashOn = false;
  final _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() {
    try {
      _cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    } catch (e) {
      setState(() => _cameraAvailable = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(String barcode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    _cameraController?.stop();

    // If caller just wants the barcode string back (e.g. add product screen)
    if (widget.returnBarcodeOnly) {
      if (mounted) Navigator.pop(context, barcode);
      return;
    }

    final product = await DatabaseHelper.instance.getProductByBarcode(barcode);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ActionSelectionScreen(
            barcode: barcode,
            product: product,
          ),
        ),
      );
    }
  }

  void _showManualEntryDialog() {
    final language = context.read<AppLanguage>();
    _manualController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          language.manualBarcodeEntry,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: TextField(
          controller: _manualController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: language.enterBarcode,
            prefixIcon: const Icon(Icons.qr_code, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(language.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final barcode = _manualController.text.trim();
              if (barcode.isNotEmpty) {
                Navigator.pop(ctx);
                _onBarcodeDetected(barcode);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(language.searchAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguage>();
    return Scaffold(
      body: Stack(
        children: [
          // Camera or placeholder background
          if (_cameraAvailable && _cameraController != null)
            Positioned.fill(
              child: MobileScanner(
                controller: _cameraController!,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                    _onBarcodeDetected(barcodes.first.rawValue!);
                  }
                },
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.navyDark.withValues(alpha: 0.8),
                      AppColors.navyDeep.withValues(alpha: 0.9),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off_outlined, size: 64, color: Colors.white.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(
                        language.cameraUnavailable,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.surface,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.navyDark),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        language.scanBarcodeTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Viewfinder overlay
          Center(
            child: SizedBox(
              width: 280,
              height: 180,
              child: Stack(
                children: [
                  // Instruction label
                  Positioned(
                    top: -48,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          language.alignBarcode,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Corner borders
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                  // Scanning line
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildControlButton(
                        icon: _flashOn ? Icons.flashlight_on : Icons.flashlight_off,
                        label: language.torchOn,
                        onTap: () {
                          if (_cameraController != null) {
                            _cameraController!.toggleTorch();
                            setState(() => _flashOn = !_flashOn);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildControlButton(
                        icon: Icons.keyboard_alt_outlined,
                        label: language.manualEntry,
                        onTap: _showManualEntryDialog,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    final isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft ? const Radius.circular(16) : Radius.zero,
            topRight: alignment == Alignment.topRight ? const Radius.circular(16) : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft ? const Radius.circular(16) : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight ? const Radius.circular(16) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 15,
            ),
          ],
        ),
      ),
    );
  }
}

