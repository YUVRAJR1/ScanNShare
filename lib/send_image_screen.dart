import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class SendImageScreen extends StatefulWidget {
  const SendImageScreen({super.key});

  @override
  State<SendImageScreen> createState() => _SendImageScreenState();
}

class _SendImageScreenState extends State<SendImageScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  List<String> allQrChunks = [];
  int currentChunkIndex = 0;
  bool showAuthorizationToggle = false;
  bool onlyAuthorizedUser = false;
  String receiverUsername = '';

  Timer? slideshowTimer;
  bool isSlideshowRunning = false;
  bool hasStartedSlideshow = false;

  late AnimationController _playController;

  @override
  void initState() {
    super.initState();
    _playController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  Future<void> pickAndGenerateQRCode() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    Uint8List imageBytes = await pickedFile.readAsBytes();
    int chunkSize = 1500;

    final bool isTextHeavy = await imageHasOver300Letters(imageBytes);
    Uint8List compressedBytes = await compressImageSmart(
      imageBytes,
      isTextDominant: isTextHeavy,
      maxChunks: 50,
      chunkSize: chunkSize,
    );

    final base64Image = base64Encode(compressedBytes);
    final now = DateTime.now();
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final imageChunks = _splitBase64(base64Image, chunkSize);
    final totalParts = imageChunks.length;

    List<String> qrChunks = [];
    final String fileType = isTextHeavy ? 'png' : 'jpg';

    for (int i = 0; i < totalParts; i++) {
      final payload = {
        'receiver': onlyAuthorizedUser ? receiverUsername.trim() : null,
        'timestamp': formattedTime,
        'partIndex': i,
        'totalParts': totalParts,
        'imageChunk': imageChunks[i],
        'fileType': fileType,
      };
      qrChunks.add(jsonEncode(payload));
    }

    setState(() {
      allQrChunks = qrChunks;
      currentChunkIndex = 0;
      showAuthorizationToggle = false;
      isSlideshowRunning = false;
      hasStartedSlideshow = false;
    });

    slideshowTimer?.cancel();
  }

  Future<bool> imageHasOver300Letters(Uint8List imageBytes) async {
    final textRecognizer = TextRecognizer();
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_image.png');
    await tempFile.writeAsBytes(imageBytes);
    final inputImage = InputImage.fromFile(tempFile);
    final RecognizedText result = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return result.text.replaceAll(RegExp(r'[^A-Za-z]'), '').length > 300;
  }

  Future<Uint8List> compressImageSmart(Uint8List imageBytes, {required bool isTextDominant, required int maxChunks, required int chunkSize}) async {
    final img.Image? original = img.decodeImage(imageBytes);
    if (original == null) return imageBytes;

    int resizeWidth = original.width > 600 ? 400 : original.width;
    int resizeHeight = (original.height * (resizeWidth / original.width)).round();

    Uint8List compressed;
    int estimatedChunks = 999;

    if (isTextDominant) {
      final resized = img.copyResize(original, width: resizeWidth, height: resizeHeight);
      compressed = Uint8List.fromList(img.encodePng(resized));
    } else {
      int quality = 50;
      while (true) {
        final resized = img.copyResize(original, width: resizeWidth, height: resizeHeight);
        compressed = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
        final base64Length = base64Encode(compressed).length;
        estimatedChunks = (base64Length / chunkSize).ceil();

        if (estimatedChunks <= maxChunks || (resizeWidth <= 200 && quality <= 50)) break;
        if (resizeWidth > 200) {
          resizeWidth = (resizeWidth * 0.9).toInt();
          resizeHeight = (resizeHeight * 0.9).toInt();
        } else if (quality > 50) {
          quality -= 5;
        } else {
          break;
        }
      }
    }

    return compressed;
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
      _playController.forward();
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
          _playController.reverse();
        });
      }
    });
  }

  void stopSlideshow() {
    slideshowTimer?.cancel();
    setState(() {
      isSlideshowRunning = false;
      _playController.reverse();
    });
  }

  @override
  void dispose() {
    slideshowTimer?.cancel();
    _playController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQr = allQrChunks.isNotEmpty ? allQrChunks[currentChunkIndex] : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Send Image via QR', style: TextStyle(color: Colors.black87)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      body: SafeArea(
        child: Container(
          color: const Color(0xFFF4F4F4),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (currentQr != null)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                              if (currentChunkIndex > 0)
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                                  iconSize: 28,
                                  onPressed: () => setState(() => currentChunkIndex--),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                '${currentChunkIndex + 1} / ${allQrChunks.length}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              const SizedBox(width: 8),
                              if (currentChunkIndex < allQrChunks.length - 1)
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.black),
                                  iconSize: 28,
                                  onPressed: () => setState(() => currentChunkIndex++),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('No QR generated', style: TextStyle(color: Colors.black45)),
                    ),
                  ),
                const SizedBox(height: 24),
                if (allQrChunks.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          IconButton(
                            icon: AnimatedIcon(
                              icon: AnimatedIcons.play_pause,
                              progress: _playController,
                              color: Colors.black,
                            ),
                            iconSize: 36,
                            onPressed: () {
                              isSlideshowRunning ? stopSlideshow() : startSlideshow();
                            },
                          ),
                          const Text('Start Slideshow', style: TextStyle(color: Colors.black)),
                        ],
                      ),
                      const SizedBox(width: 24),
                      if (hasStartedSlideshow)
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restart_alt, color: Colors.black),
                              iconSize: 36,
                              onPressed: () {
                                stopSlideshow();
                                setState(() => currentChunkIndex = 0);
                                startSlideshow();
                              },
                            ),
                            const Text('From Beginning', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                    ],
                  ),
                const SizedBox(height: 24),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Receiver Email (optional)',
                    labelStyle: const TextStyle(color: Colors.black),
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    floatingLabelStyle: const TextStyle(color: Colors.black),
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
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: pickAndGenerateQRCode,
                  icon: const Icon(Icons.image, color: Colors.white),
                  label: const Text('Pick Image & Generate QR', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
