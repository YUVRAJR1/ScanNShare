import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String upiId = "ryuvraj2106@okaxis";
  final String upiName = "ScanNShare";

  String selectedPlan = '3'; // default selected plan
  String amount = "597"; // ₹199 * 3

  Map<String, Map<String, dynamic>> plans = {
    '12': {'unit': 'months', 'price': '₹149/mo', 'amount': 1788, 'save': 'SAVE 50%'},
    '3': {'unit': 'months', 'price': '₹199/mo', 'amount': 597, 'save': 'SAVE 33%'},
    '1': {'unit': 'month', 'price': '₹299/mo', 'amount': 299},
  };

  Future<void> _launchUPIPayment() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final Uri uri = Uri.parse(
      'upi://pay?'
          'pa=${Uri.encodeComponent(upiId)}'
          '&pn=${Uri.encodeComponent(upiName)}'
          '&tn=${Uri.encodeComponent("ScanNShare Premium")}'
          '&am=${Uri.encodeComponent(amount)}'
          '&cu=${Uri.encodeComponent("INR")}',
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // No transaction dialog here anymore
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Could not launch any UPI app.")),
      );
    }
  }

  void _selectPlan(String durationKey) {
    setState(() {
      selectedPlan = durationKey;
      amount = plans[durationKey]!['amount'].toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFEFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Lottie.asset(
                    'assets/premium_animation.json',
                    height: 200,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unlimited PDF, PPT Access and so more!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: plans.entries.map((entry) {
                      final duration = entry.key;
                      final plan = entry.value;
                      return GestureDetector(
                        onTap: () => _selectPlan(duration),
                        child: _buildPlanBox(
                          duration,
                          plan['unit'],
                          plan['price'],
                          highlight: selectedPlan == duration,
                          save: plan['save'],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _launchUPIPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      "Get ${plans[selectedPlan]!['unit']} / ₹$amount",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "When will I be billed?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Your UPI Account will be charged upon confirmation of your purchase.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Does My subscription Auto Renew?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Yes. You can disable this at any time with just one tap in the app store.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanBox(String duration, String unit, String price,
      {bool highlight = false, String? save}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: highlight ? Colors.orange.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? Colors.orange : Colors.grey.shade300,
          width: highlight ? 2 : 1,
        ),
      ),
      width: 100,
      child: Column(
        children: [
          if (save != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: highlight ? Colors.orange : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                save,
                style: TextStyle(
                  fontSize: 10,
                  color: highlight ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(height: 18), // placeholder

          Text(
            duration,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.orange : Colors.black,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 14,
              color: highlight ? Colors.orange : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
