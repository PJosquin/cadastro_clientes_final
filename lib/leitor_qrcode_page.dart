import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class LeitorQrCodePage extends StatefulWidget {
  const LeitorQrCodePage({Key? key}) : super(key: key);

  @override
  State<LeitorQrCodePage> createState() => _LeitorQrCodePageState();
}

class _LeitorQrCodePageState extends State<LeitorQrCodePage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? qrCodeLido;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler QR Code da Nota Fiscal'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: (qrCodeLido != null)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'QR Code detectado:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            qrCodeLido!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.blueAccent),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context, qrCodeLido);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Usar este QR Code'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                            ),
                          ),
                        ],
                      )
                    : const Text('Aponte a câmera para o QR Code da nota fiscal'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (qrCodeLido == null && scanData.code != null) {
        setState(() {
          qrCodeLido = scanData.code;
        });
        controller.stopCamera(); // pausa a câmera após ler o QR
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
