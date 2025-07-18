import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransitionScreen extends StatefulWidget {
  final Widget nextScreen;

  const TransitionScreen({super.key, required this.nextScreen});

  @override
  State<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends State<TransitionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // ⬇️ Use Get.off instead of Navigator
    Timer(const Duration(seconds: 1), () {
      Get.off(() => widget.nextScreen);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D3C60),
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Image.asset(
            'assets/my_logo.png',
            width: 120,
            height: 120,
          ),
        ),
      ),
    );
  }
}
