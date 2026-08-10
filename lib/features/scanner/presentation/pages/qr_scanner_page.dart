import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanning = true;
  String? barcodeValue;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR / Barcode Scanner'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: isScanning
                ? MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && isScanning) {
                        setState(() {
                          isScanning = false;
                          barcodeValue = barcodes.first.rawValue;
                        });
                        controller.stop();
                      }
                    },
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(Icons.qr_code_scanner, color: Colors.white54, size: 100),
                    ),
                  ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (barcodeValue != null) ...[
                    const Text('Scanned Result:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    SelectableText(
                      barcodeValue!,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              isScanning = true;
                              barcodeValue = null;
                            });
                            controller.start();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Scan Again'),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.check),
                          label: const Text('Done'),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Icon(Icons.qr_code, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Point your camera at a QR code or barcode'),
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
