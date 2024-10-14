import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/sign_in_screen.dart';
import 'screens/reader_home.dart'; // Reader Home Screen
import 'screens/ManageCoins.dart'; // Coin Management Screen
import 'screens/reader_profile.dart'; // Reader Profile Screen
import 'screens/reader_library.dart'; // My Library Screen
import 'screens/author_home.dart'; // Author Home Screen
import 'screens/author_management.dart'; // Author Management Screen
import 'screens/author_profile.dart'; // Author Profile Screen
import 'screens/coin_management_screen.dart'; // Coin Management Screen
import 'screens/sign_up_screen.dart'; // Sign Up Screen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCAqLMCXSvzx3hfd0S_jNWybKU-RNpJ6tc",
        appId: '1:1015500684608:android:589b1f21312ff3fca60ea5',
        messagingSenderId: '1015500684608',
        projectId: 'fir-book-308ab',
        databaseURL: "https://fir-book-308ab-default-rtdb.asia-southeast1.firebasedatabase.app",
        storageBucket: 'fir-book-308ab.appspot.com',
      ),
    );
  }
  
  runApp(const MyApp()); // เรียกใช้ MyApp
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book App',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      initialRoute: '/',  // กำหนดเส้นทางเริ่มต้น
      routes: {
        '/': (context) => SignInScreen(),  // หน้า SignIn
        '/signin': (context) => SignInScreen(),  // หน้า SignIn
        '/signUp': (context) => const SignUpScreen(), // หน้า SignUp
        '/readerHome': (context) => const ReaderHomeScreen(),  // หน้า Reader Home
        '/authorHome': (context) => const AuthorHomeScreen(),  // หน้า Author Home
        '/authorManagement': (context) => const BookManagementScreen(), // หน้า Author Management
        '/authorProfile': (context) => const AuthorProfilePage(),  // หน้า Author Profile
        '/coinManagement': (context) => const CoinManagementScreen(),  // หน้า Coin Management
        '/manageCoins': (context) => const CoinManagement(),  // หน้า Manage Coins
        '/profile': (context) => const ProfileScreen(),  // หน้า Reader Profile
        '/library': (context) => const MyLibraryScreen(),  // หน้า My Library
      },
    );
  }
}
