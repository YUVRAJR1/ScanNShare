import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:archive/archive.dart';

class ReceiveImageScreen extends StatefulWidget {
  const ReceiveImageScreen({super.key});

  @override
  State<ReceiveImageScreen> createState() => _ReceiveImageScreenState();
}

class _ReceiveImageScreenState extends State<ReceiveImageScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? scannedImageBytes;
  bool showImage = false;
  String fileType = 'unknown';

  Map<int, String> scannedParts = {};
  int? expectedTotalParts;
  String? currentImageTimestamp;

  CameraController? _cameraController;
  bool isDetecting = false;
  late final BarcodeScanner barcodeScanner;
  bool isCameraActive = false;

  @override
  void initState() {
    super.initState();
    barcodeScanner = BarcodeScanner();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    barcodeScanner.close();
    super.dispose();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.back);

    _cameraController = CameraController(camera, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();
    _cameraController!.startImageStream((CameraImage image) async {
      if (isDetecting) return;
      isDetecting = true;

      try {
        final imageFile = await convertYUV420toImageFile(image);
        final inputImage = InputImage.fromFilePath(imageFile.path);
        final barcodes = await barcodeScanner.processImage(inputImage);

        for (final barcode in barcodes) {
          final scannedData = barcode.rawValue ?? '';
          if (scannedData.isNotEmpty) {
            await processScannedData(scannedData);
            break;
          }
        }
      } catch (e) {
        debugPrint('QR scan error: $e');
      } finally {
        isDetecting = false;
      }
    });

    setState(() {});
  }

  Future<File> convertYUV420toImageFile(CameraImage image) async {
    final int width = image.width;
    final int height = image.height;
    final img.Image imgData = img.Image(width: width, height: height);

    final Plane plane = image.planes[0];
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int index = y * plane.bytesPerRow + x;
        final int pixel = plane.bytes[index];
        imgData.setPixelRgba(x, y, pixel, pixel, pixel, 255);
      }
    }

    final jpg = img.encodeJpg(imgData);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/frame_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(jpg);
    return file;
  }

  Future<void> scanQRFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final barcodes = await barcodeScanner.processImage(inputImage);
      for (final barcode in barcodes) {
        final scannedData = barcode.rawValue ?? '';
        if (scannedData.isNotEmpty) {
          await processScannedData(scannedData);
        }
      }
    }
  }

  Future<void> processScannedData(String scannedData) async {
    try {
      final data = jsonDecode(scannedData);
      final partIndex = data['partIndex'];
      final totalParts = data['totalParts'];
      final chunk = data['imageChunk'];
      final timestamp = data['timestamp'];
      final receiverInQR = data['receiver'];
      final fileTypeFromQR = data['fileType'];

      if (partIndex == null || totalParts == null || chunk == null || timestamp == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incomplete QR data')),
        );
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (receiverInQR != null && currentUser?.email != receiverInQR) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized user')),
        );
        return;
      }

      fileType = (fileTypeFromQR ?? 'unknown').toLowerCase();

      if (currentImageTimestamp != timestamp) {
        scannedParts.clear();
        currentImageTimestamp = timestamp;
        expectedTotalParts = totalParts;
      }

      if (!scannedParts.containsKey(partIndex)) {
        scannedParts[partIndex] = chunk;
        setState(() {});
      }

      if (scannedParts.length == totalParts) {
        final sortedChunks = List.generate(totalParts, (i) => scannedParts[i]!);
        final fullBase64 = sortedChunks.join();
        final compressedBytes = base64Decode(fullBase64);
        Uint8List rawBytes;

        if (fileType == 'png' || fileType == 'jpg' || fileType == 'jpeg') {
          rawBytes = compressedBytes;
        } else {
          rawBytes = Uint8List.fromList(ZLibDecoder().decodeBytes(compressedBytes));
        }

        if (fileType == 'png' || fileType == 'jpg' || fileType == 'jpeg') {
          final img.Image? image = img.decodeImage(rawBytes);
          if (image == null) throw Exception('Failed to decode image');
          final sharpened = img.convolution(image, filter: [
            0, -1, 0,
            -1, 5, -1,
            0, -1, 0
          ]);
          scannedImageBytes = Uint8List.fromList(img.encodePng(sharpened));
        } else {
          scannedImageBytes = rawBytes;
        }

        showImage = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileType file successfully reconstructed!')),
        );

        await _cameraController?.stopImageStream();
        setState(() {
          isCameraActive = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error decoding QR: $e')),
      );
    }
  }

  Future<void> saveToDownloads(Uint8List bytes) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission not granted')),
      );
      return;
    }

    final directory = Directory('/storage/emulated/0/Download');
    final filePath = '${directory.path}/scanned_file_${DateTime.now().millisecondsSinceEpoch}.$fileType';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${fileType.toUpperCase()} saved to Downloads')),
    );
  }

  List<int> getMissingParts() {
    if (expectedTotalParts == null) return [];
    return List.generate(expectedTotalParts!, (index) => index + 1)
        .where((i) => !scannedParts.containsKey(i - 1))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scannedCount = scannedParts.length;
    final totalCount = expectedTotalParts ?? 0;
    final missingParts = getMissingParts();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Receive File via QR',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  color: Colors.black,
                  letterSpacing: 1.2,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () async {
                      if (!isCameraActive) {
                        await initializeCamera();
                        setState(() {
                          isCameraActive = true;
                        });
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: const Text('Scan QR', style: TextStyle(color: Colors.white)),
                  ),
                  if (isCameraActive &&
                      _cameraController != null &&
                      _cameraController!.value.isInitialized)
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          height: 250,
                          width: 260,
                          decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                          child: CameraPreview(_cameraController!),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: scanQRFromGallery,
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: const Text('Scan QR from Gallery', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (expectedTotalParts != null && scannedCount < totalCount)
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 80,
                        width: 80,
                        child: CircularProgressIndicator(
                          value: scannedCount / totalCount,
                          strokeWidth: 6,
                          backgroundColor: Colors.black12,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      ),
                      Text('$scannedCount / $totalCount', style: const TextStyle(color: Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (missingParts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Missing QR codes: ${missingParts.join(', ')}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 20),
            if (showImage && scannedImageBytes != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    (fileType == 'png' || fileType == 'jpg' || fileType == 'jpeg')
                        ? Image.memory(scannedImageBytes!, height: 300)
                        : Text('$fileType file reconstructed. Click below to save.',
                        style: const TextStyle(color: Colors.black)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      onPressed: () async {
                        await saveToDownloads(scannedImageBytes!);
                      },
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: const Text('Download File', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
