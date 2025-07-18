import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:archive/archive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:application_login/premium_screen.dart'; // Update path if needed

class SendPdfScreen extends StatefulWidget {
  const SendPdfScreen({super.key});

  @override
  State<SendPdfScreen> createState() => _SendPdfScreenState();
}

class _SendPdfScreenState extends State<SendPdfScreen> {
  List<String> allQrChunks = [];
  int currentChunkIndex = 0;
  bool onlyAuthorizedUser = false;
  String receiverUsername = '';
  Timer? slideshowTimer;
  bool isSlideshowRunning = false;
  bool hasStartedSlideshow = false;
  bool showStartFromBeginning = false;

  static const int maxFreeUses = 2;

  Future<void> pickAndGenerateQRCode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('loggedInEmail');

    if (email == null) {
      _showAlert('Login Required', 'Please login to use this feature.');
      return;
    }

    final String usageKey = 'pdfUsage_$email';
    int usageCount = prefs.getInt(usageKey) ?? 0;

    if (usageCount >= maxFreeUses) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      return; // 🔐 Prevents further code execution
    }


    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) {
      _showAlert('Error', 'No file selected.');
      return;
    }

    Uint8List? originalBytes = result.files.single.bytes;

    if (originalBytes == null) {
      final path = result.files.single.path;
      if (path == null) {
        _showAlert('Error', 'File path is null. Cannot read file.');
        return;
      }
      final file = File(path);
      originalBytes = await file.readAsBytes();
    }

    Uint8List compressedBytes = _compressPdf(originalBytes);
    if (compressedBytes.isEmpty) {
      _showAlert('Error', 'Compression failed or resulted in empty data.');
      return;
    }

    String base64Compressed = base64Encode(compressedBytes);
    if (base64Compressed.isEmpty) {
      _showAlert('Error', 'Base64 string is empty.');
      return;
    }

    int chunkSize = 1500;
    final imageChunks = _splitBase64(base64Compressed, chunkSize);
    final totalParts = imageChunks.length;
    final now = DateTime.now();
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    List<String> qrChunks = [];
    for (int i = 0; i < totalParts; i++) {
      final payload = {
        'receiver': onlyAuthorizedUser ? receiverUsername.trim() : null,
        'timestamp': formattedTime,
        'partIndex': i,
        'totalParts': totalParts,
        'imageChunk': imageChunks[i],
        'fileType': 'pdf',
      };

      try {
        final encoded = jsonEncode(payload);
        qrChunks.add(encoded);
      } catch (e) {
        _showAlert('Error', 'Failed to encode QR payload.');
        return;
      }
    }

    // Update usage count
    await prefs.setInt(usageKey, usageCount + 1);

    setState(() {
      allQrChunks = qrChunks;
      currentChunkIndex = 0;
      isSlideshowRunning = false;
      hasStartedSlideshow = false;
      showStartFromBeginning = true;
    });
  }

  Uint8List _compressPdf(Uint8List pdfBytes) {
    final encoder = ZLibEncoder();
    final compressed = encoder.encode(pdfBytes);
    return Uint8List.fromList(compressed);
  }

  List<String> _splitBase64(String base64Str, int chunkSize) {
    List<String> chunks = [];
    for (int i = 0; i < base64Str.length; i += chunkSize) {
      chunks.add(base64Str.substring(i, i + chunkSize > base64Str.length ? base64Str.length : i + chunkSize));
    }
    return chunks;
  }

  void startSlideshow() {
    if (allQrChunks.isEmpty || isSlideshowRunning) return;

    setState(() {
      isSlideshowRunning = true;
      hasStartedSlideshow = true;
    });

    slideshowTimer?.cancel();
    slideshowTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (currentChunkIndex < allQrChunks.length - 1) {
        setState(() {
          currentChunkIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          isSlideshowRunning = false;
        });
      }
    });
  }

  void stopSlideshow() {
    slideshowTimer?.cancel();
    setState(() => isSlideshowRunning = false);
  }

  void _showStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Ready to Start Slideshow?'),
        content: const Text('Each QR code will be shown for 2 seconds.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              startSlideshow();
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    slideshowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQr = allQrChunks.isNotEmpty ? allQrChunks[currentChunkIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send PDF via QR'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: const Color(0xFFF4F4F4),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (currentQr != null)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        QrImageView(
                          data: currentQr,
                          version: QrVersions.auto,
                          size: 300,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                              onPressed: !isSlideshowRunning && currentChunkIndex > 0
                                  ? () => setState(() => currentChunkIndex--)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'QR ${currentChunkIndex + 1} of ${allQrChunks.length}',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward, color: Colors.black, size: 28),
                              onPressed: !isSlideshowRunning && currentChunkIndex < allQrChunks.length - 1
                                  ? () => setState(() => currentChunkIndex++)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('No QR generated', style: TextStyle(color: Colors.black45)),
                ),
              const SizedBox(height: 30),
              if (allQrChunks.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        IconButton(
                          iconSize: 36,
                          icon: Icon(
                            isSlideshowRunning ? Icons.stop : Icons.play_arrow,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            if (isSlideshowRunning) {
                              stopSlideshow();
                            } else if (!hasStartedSlideshow) {
                              _showStartDialog();
                            } else {
                              startSlideshow();
                            }
                          },
                        ),
                        const SizedBox(height: 4),
                        const Text('Start Slideshow', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    if (showStartFromBeginning)
                      Column(
                        children: [
                          IconButton(
                            iconSize: 36,
                            icon: const Icon(Icons.restart_alt, color: Colors.black),
                            onPressed: () {
                              stopSlideshow();
                              setState(() => currentChunkIndex = 0);
                              startSlideshow();
                            },
                          ),
                          const SizedBox(height: 4),
                          const Text('From Beginning', style: TextStyle(color: Colors.black)),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: 30),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  labelText: 'Receiver Email (optional)',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                  floatingLabelStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (val) => receiverUsername = val,
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                title: const Text('Restrict to receiver only', style: TextStyle(color: Colors.black)),
                value: onlyAuthorizedUser,
                activeColor: Colors.white,
                activeTrackColor: Colors.black,
                inactiveThumbColor: Colors.black,
                inactiveTrackColor: Colors.black12,
                onChanged: (val) => setState(() => onlyAuthorizedUser = val),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: pickAndGenerateQRCode,
                child: const Text('Pick PDF & Generate QR', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
