import 'package:application_login/homepage.dart';
import 'package:application_login/login.dart';
import 'package:application_login/signup.dart';
import 'package:application_login/theme_controller.dart';
import 'package:application_login/transition_screen.dart'; // <-- ✅ Make sure this is imported
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();
  Get.put(ThemeController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();

    return Obx(
          () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Image Transfer App',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,

        // ✅ Start with Splash Transition Screen
        home: TransitionScreen(
          nextScreen: FirebaseAuth.instance.currentUser != null
              ? const Homepage()
              : const Login(),
        ),

        // ✅ Optional named routes if needed elsewhere
        getPages: [
          GetPage(name: '/login', page: () => const Login()),
          GetPage(name: '/signup', page: () => const Signup()),
          GetPage(name: '/home', page: () => const Homepage()),
        ],
      ),
    );
  }
}
