// ignore_for_file: unnecessary_null_comparison

import 'package:firebase_book/screens/reader_library.dart';
import 'package:flutter/material.dart';
import 'package:firebase_book/screens/ManageCoins.dart'; // Import หน้าจัดการเหรียญ
import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับดึงข้อมูลจาก Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_book/screens/reader_profile.dart'; // Import หน้าจอโปรไฟล์นักอ่าน
// ignore: duplicate_import
import 'reader_library.dart'; // Import หน้าจอ My Library

class ReaderHomeScreen extends StatefulWidget {
  const ReaderHomeScreen({super.key});

  @override
  _ReaderHomeScreenState createState() => _ReaderHomeScreenState();
}

class _ReaderHomeScreenState extends State<ReaderHomeScreen> {
  final _auth = FirebaseAuth.instance;
  User? currentUser;
  String? profileImageUrl;
  String? displayName;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    setState(() {
      displayName =
          userDoc.data()!.containsKey('name') ? userDoc['name'] : 'User';
      profileImageUrl = userDoc.data()!.containsKey('profileImageUrl')
          ? userDoc['profileImageUrl']
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : const AssetImage('assets/default_profile.png') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Text(displayName ?? 'User', style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.brown[800], // เปลี่ยนสีของ AppBar เป็นสีน้ำตาล
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ประกาศหรือโปรโมชั่น
            _buildAnnouncementSection(),

            // หนังสือแนะนำ
            _buildSectionTitle('Recommended Books'),
            _buildBookList('recommended_books'), // แสดงหนังสือแนะนำ

            // หนังสือใหม่
            _buildSectionTitle('New Books'),
            _buildBookList('new_books'), // แสดงหนังสือใหม่

            // หมวดหมู่หนังสือต่างๆ
            _buildSectionTitle('Categories'),
            _buildCategoryShortcut(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Coins', // ย้ายไอคอนเหรียญลงมาที่ nav bar
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books), // ไอคอนไปยัง My Library
            label: 'Library',
          ),
        ],
        currentIndex: 0, // หน้าปัจจุบันคือ Home
        selectedItemColor: Colors.brown[800], // สีไอคอนเมื่อเลือกแล้ว
        unselectedItemColor: Colors.brown[300], // สีไอคอนเมื่อยังไม่ถูกเลือก
        onTap: (index) {
          switch (index) {
            case 0:
              // หน้าปัจจุบันคือ Home ไม่ต้องทำอะไร
              break;
            case 1:
              // ไปยังหน้าโปรไฟล์นักอ่าน
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
            case 2:
              // ไปยังหน้า Coin Management
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CoinManagement()),
              );
              break;
            case 3:
              // ไปยังหน้า My Library
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyLibraryScreen()),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildAnnouncementSection() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(10),
      color: Colors.brown[100],
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promotion & Announcements',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[900]),
            ),
            const SizedBox(height: 5),
            Text('50% off on selected books! Free books for members.',
                style: TextStyle(color: Colors.brown[800])),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown[700]),
      ),
    );
  }

  Widget _buildBookList(String collectionName) {
    return SizedBox(
      height: 180,
      child: StreamBuilder(
        stream:
            FirebaseFirestore.instance.collection(collectionName).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var books = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (context, index) {
              var book = books[index];
              return _buildBookCard(book['title'], book['imageUrl']);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookCard(String title, String imageUrl) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: Colors.brown[100],
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            imageUrl != null
                ? Image.network(imageUrl, height: 80, fit: BoxFit.cover)
                : Icon(Icons.book, size: 50, color: Colors.brown[600]),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[900])),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryShortcut() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Wrap(
        spacing: 10,
        children: [
          _buildCategoryButton('Novel'),
          _buildCategoryButton('Comic'),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(category: category),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.brown[800], // สีปุ่มให้ตรงกับธีม
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      ),
      child: Text(category),
    );
  }
  
  CategoryScreen({required String category}) {}
}
