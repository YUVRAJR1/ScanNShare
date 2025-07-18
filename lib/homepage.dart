import 'package:application_login/login.dart';
import 'package:application_login/send_image_screen.dart';
import 'package:application_login/send_document_screen.dart';
import 'package:application_login/send_pdf_screen.dart';
import 'package:application_login/send_ppt_screen.dart';
import 'package:application_login/receive_image_screen.dart';
import 'package:application_login/profile_screen.dart';
import 'package:application_login/SettingsScreen.dart';
import 'package:application_login/premium_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

// ... [imports remain unchanged]

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(const Login());
  }

  List<Widget> get _pages => [
    const HomeTab(),
    const PremiumScreen(),
    const ReceiveImageScreen(),
    const SettingsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          backgroundColor: const Color(0xFFFAFBFC),
          elevation: 0,
          centerTitle: true,
          title: Transform.scale(
            scale: 4.95,
            child: SizedBox(
              height: 60,
              child: Lottie.asset(
                'assets/Animation_15.json',
                repeat: true,
                reverse: false,
                animate: true,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 16, // 🔼 Bigger font
        unselectedFontSize: 12, // 🔽 Smaller font
        selectedIconTheme: const IconThemeData(size: 30), // 🔼 Bigger icon
        unselectedIconTheme: const IconThemeData(size: 24),
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.workspace_premium),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amberAccent.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            label: 'Premium',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PageController _pageController = PageController(viewportFraction: 0.75);
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiles = [
      {
        'title': 'Send Image',
        'color': const Color.fromRGBO(245, 245, 245, 0.15),
        'icon': SizedBox(
          width: 250,
          height: 250,
          child: Lottie.asset('assets/Animation_12.json', fit: BoxFit.contain),
        ),
        'onTap': () => Get.to(() => const SendImageScreen()),
      },
      {
        'title': 'Send Document',
        'color': const Color(0xFFFFB74D),
        'icon': SizedBox(
          width: 250,
          height: 250,
          child: Lottie.asset('assets/Animation_14.json', fit: BoxFit.contain),
        ),
        'onTap': () => Get.to(() => const SendDocumentScreen()),
      },
      {
        'title': 'Send PDF',
        'color': Colors.green,
        'icon': SizedBox(
          width: 180,
          height: 180,
          child: Lottie.asset('assets/Animation_13.json', fit: BoxFit.contain),
        ),
        'onTap': () => Get.to(() => const SendPdfScreen()),
      },
      {
        'title': 'Send PPT',
        'color': Colors.purple,
        'icon': SizedBox(
          width: 250,
          height: 240,
          child: Lottie.asset('assets/Animation_11.json', fit: BoxFit.contain),
        ),
        'onTap': () => Get.to(() => const SendPptScreen()),
      },
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
              constraints: const BoxConstraints(minHeight: 160),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft, // ⬆️ Moves text up
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'WELCOME!',
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'Snap it !',
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Padding(
                            padding: const EdgeInsets.only(left: 20), // 👈 Tune value as needed
                            child: Text(
                              'Send it !',
                              style: GoogleFonts.montserrat(
                                textStyle: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-24, -11),
                    child: Transform.scale(
                      scale: 2.5,
                      child: SizedBox(
                        width: 80,
                        height: 90,
                        child: Lottie.asset('assets/hi.json', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: tiles.length,
                itemBuilder: (context, index) {
                  final scale = 1.0 - (_currentPage - index).abs() * 0.1;
                  final rotateY = (_currentPage - index) * 0.3;

                  return Transform(
                    transform: Matrix4.identity()
                      ..scale(scale)
                      ..rotateY(rotateY),
                    alignment: Alignment.center,
                    child: _buildSendTile(
                      title: tiles[index]['title'] as String,
                      icon: tiles[index]['icon'] as Widget,
                      color: tiles[index]['color'] as Color,
                      onTap: tiles[index]['onTap'] as VoidCallback,
                      isLottie: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendTile({
    required String title,
    required Widget icon,
    required Color color,
    required VoidCallback onTap,
    required bool isLottie,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: icon,
            ),
            const SizedBox(height: 0),
            Transform.translate(
              offset: (title == 'Send Document' || title == 'Send Image' || title == 'Send PPT')
                  ? const Offset(0, -50)
                  : Offset.zero,
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 25,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
