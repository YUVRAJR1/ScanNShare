import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 1),
          const Center(
            child: Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                fontSize: 26, // ⬅️ Adjustable height
                color: Colors.black,
                letterSpacing: 1.2,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          _buildSectionTitle('Help & About'),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black12),
            ),
            elevation: 3,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined, color: Colors.black),
                  title: const Text('User Guide', style: TextStyle(color: Colors.black)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                  onTap: () => Get.to(() => const UserGuidePage()),
                ),
                const Divider(height: 1, color: Colors.black12),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.black),
                  title: const Text('About Scan N Share', style: TextStyle(color: Colors.black)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                  onTap: () => Get.to(() => const AboutAppPage()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// User Guide Page
// =========================
class UserGuidePage extends StatelessWidget {
  const UserGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('User Guide', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              'Welcome to Scan N Share!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 20),
            Text(
              'Scan N Share helps you securely and efficiently share images and files across devices using QR codes. Follow the steps below to get started:',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 20),
            Text(
              'Getting Started:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 10),
            Text(
              '1. Send File:\n• Go to the Home screen and tap “Send Image”, “Send PDF”, or the appropriate option.\n• Pick a file from your device.\n• The app will generate a QR code. You can share it via slideshow or manually.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 16),
            Text(
              '2. Receive File:\n• Go to “Receive Image”.\n• Scan the QR codes live using your camera or from your gallery.\n• Once all parts are scanned, your file will be reconstructed and ready for download.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 16),
            Text(
              '3. Settings:\n• Access the settings screen to view app info or the user guide.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 20),
            Text(
              'Tips for Best Performance:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 10),
            Text(
              '• Ensure good lighting conditions while scanning QR codes.\n• Use a steady hand or tripod for scanning via camera.\n• When sending large files, ensure no frame is skipped during QR slideshow.\n• Always allow storage permissions when prompted.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
// =========================
// About App Page
// =========================
class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('About Scan N Share', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              'About Scan N Share',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 20),
            Text(
              'Scan N Share is a lightweight and secure application that enables you to send and receive files using QR codes — without needing internet or Bluetooth.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 20),
            Text(
              'Core Features:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 10),
            Text('• Send and receive images, PDFs, and documents instantly using QR codes.',
                style: TextStyle(fontSize: 16, color: Colors.black87)),
            Text('• Live QR camera scanning or scan from gallery.', style: TextStyle(fontSize: 16, color: Colors.black87)),
            Text('• Offline functionality — no internet required.', style: TextStyle(fontSize: 16, color: Colors.black87)),
            Text('• Clean UI with black & white theme for distraction-free experience.',
                style: TextStyle(fontSize: 16, color: Colors.black87)),
            SizedBox(height: 20),
            Text(
              'Why Use Scan N Share?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 10),
            Text(
              'Whether you want to share a file during a class, at a seminar, or between devices without internet — Scan N Share makes it fast, safe, and intuitive.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 20),
            Text(
              'Developer Info:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 10),
            Text('Developed by: Scan N Share', style: TextStyle(fontSize: 16, color: Colors.black87)),
            Text('Version: 1.0.0', style: TextStyle(fontSize: 16, color: Colors.black87)),
            Text('For support or suggestions, please contact us via the app or website.',
                style: TextStyle(fontSize: 16, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
