import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';

class SendPptScreen extends StatefulWidget {
  const SendPptScreen({Key? key}) : super(key: key);

  @override
  State<SendPptScreen> createState() => _SendPptScreenState();
}

class _SendPptScreenState extends State<SendPptScreen> with TickerProviderStateMixin {
  List<String> allQrChunks = [];
  int currentChunkIndex = 0;
  bool onlyAuthorizedUser = false;
  String receiverUsername = '';
  Timer? slideshowTimer;
  bool isSlideshowRunning = false;
  bool _hasStartedSlideshow = false;
  bool _showStartFromBeginning = false;

  late AnimationController _playController;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _qrIndexController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _playController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    slideshowTimer?.cancel();
    _playController.dispose();
    _focusNode.dispose();
    _qrIndexController.dispose();
    _scrollController.dispose();
    super.dispose();
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
              _showCountdownDialog();
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showCountdownDialog() {
    int count = 3;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: StatefulBuilder(
          builder: (context, setState) {
            Future.delayed(const Duration(seconds: 1), () {
              if (count > 1) {
                setState(() => count--);
              } else {
                Navigator.pop(context);
                startSlideshow();
              }
            });
            return Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Text(
                  '$count',
                  key: ValueKey(count),
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void startSlideshow() {
    if (allQrChunks.isEmpty || isSlideshowRunning) return;
    setState(() {
      isSlideshowRunning = true;
      _hasStartedSlideshow = true;
    });
    _playController.forward();
    slideshowTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (currentChunkIndex < allQrChunks.length - 1) {
        setState(() => currentChunkIndex++);
      } else {
        stopSlideshow();
      }
    });
  }

  void stopSlideshow() {
    slideshowTimer?.cancel();
    setState(() => isSlideshowRunning = false);
    _playController.reverse();
  }

  Future<void> pickAndGenerateQRCode() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ppt', 'pptx'],
        withData: true,
      );
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No PPT selected')));
        return;
      }

      final file = result.files.single;
      final ext = file.extension?.toLowerCase();
      if (ext != 'ppt' && ext != 'pptx') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only PPT/PPTX allowed')));
        return;
      }

      final fileBytes = file.bytes!;
      final compressed = Uint8List.fromList(ZLibEncoder().encode(fileBytes)!);
      final base64Str = base64Encode(compressed);
      const int chunkSize = 1500;
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final chunks = _splitBase64(base64Str, chunkSize);

      final qrList = List.generate(chunks.length, (i) {
        return jsonEncode({
          'receiver': onlyAuthorizedUser ? receiverUsername.trim() : null,
          'timestamp': timestamp,
          'partIndex': i,
          'totalParts': chunks.length,
          'imageChunk': chunks[i],
          'fileType': ext,
        });
      });

      setState(() {
        allQrChunks = qrList;
        currentChunkIndex = 0;
        isSlideshowRunning = false;
        _hasStartedSlideshow = false;
        _showStartFromBeginning = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  List<String> _splitBase64(String s, int size) {
    final out = <String>[];
    for (var i = 0; i < s.length; i += size) {
      out.add(s.substring(i, i + size > s.length ? s.length : i + size));
    }
    return out;
  }

  Widget _buildNavigationControls() {
    double arrowSize = 28; // 🔧 You can adjust this to any size you prefer

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (currentChunkIndex > 0)
          IconButton(
            icon: Icon(Icons.arrow_back,
                color: Colors.black, // ✅ Black color
                size: arrowSize),
            onPressed: () {
              _focusNode.unfocus();
              setState(() => currentChunkIndex--);
            },
          ),
        const SizedBox(width: 8),
        Text(
          '${currentChunkIndex + 1} / ${allQrChunks.length}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold, // ✅ Bold font
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        if (currentChunkIndex < allQrChunks.length - 1)
          IconButton(
            icon: Icon(Icons.arrow_forward,
                color: Colors.black, // ✅ Black color
                size: arrowSize),
            onPressed: () {
              _focusNode.unfocus();
              setState(() => currentChunkIndex++);
            },
          ),
      ],
    );
  }

  Widget _buildSlideshowControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            IconButton(
              iconSize: 36,
              icon: AnimatedIcon(
                icon: AnimatedIcons.play_pause,
                progress: _playController,
                color: Colors.black, // ✅ Black color
              ),
              onPressed: () {
                if (isSlideshowRunning) {
                  stopSlideshow();
                } else if (!_hasStartedSlideshow) {
                  _showStartDialog();
                } else {
                  startSlideshow();
                }
              },
            ),
            const SizedBox(height: 4),
            const Text(
              'Start Slideshow',
              style: TextStyle(color: Colors.black), // ✅ Black text
            ),
          ],
        ),
        const SizedBox(width: 24),
        if (_showStartFromBeginning)
          Column(
            children: [
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.restart_alt, color: Colors.black), // ✅ Black icon
                onPressed: () {
                  _focusNode.unfocus();
                  stopSlideshow();
                  setState(() => currentChunkIndex = 0);
                  startSlideshow();
                },
              ),
              const SizedBox(height: 4),
              const Text(
                'From Beginning',
                style: TextStyle(color: Colors.black), // ✅ Black text
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = (allQrChunks.isNotEmpty && currentChunkIndex < allQrChunks.length)
        ? allQrChunks[currentChunkIndex]
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Send PPT via QR',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      body: SafeArea(
        child: Container(
          color: const Color(0xFFF4F4F4), // Light background to match image
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (current != null)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          QrImageView(
                            data: current,
                            version: QrVersions.auto,
                            size: 300,
                          ),
                          const SizedBox(height: 12),
                          _buildNavigationControls(),
                        ],
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No QR generated',
                        style: TextStyle(color: Colors.black45),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                if (allQrChunks.isNotEmpty) _buildSlideshowControls(),
                const SizedBox(height: 30),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined),
                    labelText: 'Receiver Email (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black, width: 2), // ✅ Black when focused
                    ),
                    floatingLabelStyle: const TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) => receiverUsername = v,
                ),

                const SizedBox(height: 14),
                SwitchListTile(
                  title: const Text(
                    'Restrict to receiver only',
                    style: TextStyle(color: Colors.black), // ✅ Black text label
                  ),
                  value: onlyAuthorizedUser,
                  activeColor: Colors.white,         // ✅ Thumb color when ON
                  activeTrackColor: Colors.black,    // ✅ Track (background) when ON
                  inactiveThumbColor: Colors.black,  // ✅ Thumb when OFF
                  inactiveTrackColor: Colors.black12, // Optional dimmed black track
                  onChanged: (v) => setState(() => onlyAuthorizedUser = v),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: pickAndGenerateQRCode,
                  child: const Text(
                    'Pick PPT & Generate QR',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
