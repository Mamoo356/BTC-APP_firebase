import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for data
import 'package:firebase_auth/firebase_auth.dart';
import 'author_management.dart'; // Import หน้าจัดการหนังสือ
import 'coin_management_screen.dart'; // Import หน้าจัดการเหรียญ
import 'author_profile.dart'; // Import หน้าดูโปรไฟล์

class AuthorHomeScreen extends StatefulWidget {
  const AuthorHomeScreen({super.key});

  @override
  _AuthorHomeScreenState createState() => _AuthorHomeScreenState();
}

class _AuthorHomeScreenState extends State<AuthorHomeScreen> {
  final _auth = FirebaseAuth.instance;
  User? currentUser;
  int publishedBooks = 0;
  int totalOrders = 0;
  int coinsEarned = 0;
  int _selectedIndex = 0; // สำหรับการเลือกหน้าใน BottomNavigationBar

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _loadAuthorData();
    }
  }

 Future<void> _loadAuthorData() async {
  try {
    // โหลดข้อมูลหนังสือและยอดขายจาก Firestore
    DocumentReference userDocRef = FirebaseFirestore.instance
        .collection('authors')
        .doc(currentUser!.uid);

    var userDoc = await userDocRef.get();

    if (userDoc.exists) {
      // พิมพ์ข้อมูลที่ดึงมาเพื่อตรวจสอบ
      print('User Document Data: ${userDoc.data()}');
      print('Document Type: ${userDoc.data().runtimeType}');

      var data = userDoc.data();
      
      // ตรวจสอบข้อมูลว่ามีชนิดเป็น List หรือไม่
      if (data is List) {
        print('Error: Data is a List, expected a Map');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Data format is incorrect (List found, expected Map)')),
        );
        return; // ออกจากฟังก์ชันถ้าข้อมูลเป็น List
      }

      // ถ้ามีเอกสารผู้ใช้ ให้ดึงข้อมูลฟิลด์ต่างๆ ถ้าไม่มีให้กำหนดเป็นค่าเริ่มต้น 0
      setState(() {
        publishedBooks = userDoc.get('publishedBooks') ?? 0;
        totalOrders = userDoc.get('totalOrders') ?? 0;
        coinsEarned = userDoc.get('coinsEarned') ?? 0;
      });
    } else {
      // ถ้าเอกสารยังไม่มีอยู่ใน Firestore สร้างเอกสารใหม่พร้อมฟิลด์เริ่มต้น
      await userDocRef.set({
        'publishedBooks': 0,
        'totalOrders': 0,
        'coinsEarned': 0,
      });
      setState(() {
        publishedBooks = 0;
        totalOrders = 0;
        coinsEarned = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data created with default values.')),
      );
    }
  } catch (e) {
    // จัดการข้อผิดพลาด
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading user data: ${e.toString()}')),
    );
  }
}


  // เปลี่ยนหน้าตามที่เลือกจาก BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // หน้า Home ไม่ต้องทำอะไร
        break;
      case 1:
        // ไปยัง Book Management
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BookManagementScreen()),
        );
        break;
      case 2:
        // ไปยัง Author Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthorProfilePage()), // เปลี่ยนเป็นหน้าดูโปรไฟล์
        );
        break;
      case 3:
        // ไปยัง Coin Management
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CoinManagementScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Author Home', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown[800],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // สรุปผลงาน
              _buildSummarySection(),
              const SizedBox(height: 20),

              // การแจ้งเตือน
              _buildNotificationSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Book Management',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle), // เปลี่ยนไอคอนเป็นโปรไฟล์
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Coin Management',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown[800], // สีไอคอนเมื่อเลือกแล้ว
        unselectedItemColor: Colors.brown[300], // สีไอคอนเมื่อยังไม่ถูกเลือก
        onTap: _onItemTapped, // เรียกฟังก์ชันเปลี่ยนหน้า
      ),
    );
  }

  // สรุปผลงาน
  Widget _buildSummarySection() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(10),
      color: Colors.brown[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown[900]),
            ),
            const SizedBox(height: 10),
            _buildSummaryItem('Published Books', publishedBooks.toString()),
            _buildSummaryItem('Total Orders', totalOrders.toString()),
            _buildSummaryItem('Coins Earned', coinsEarned.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: Colors.brown[700])),
          Text(value, style: TextStyle(fontSize: 16, color: Colors.brown[900], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // การแจ้งเตือน
  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown[900]),
        ),
        const SizedBox(height: 10),
        StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('authorId', isEqualTo: currentUser!.uid)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            var notifications = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var notification = notifications[index];
                return ListTile(
                  title: Text(notification['title']),
                  subtitle: Text(notification['message']),
                  leading: Icon(Icons.notifications, color: Colors.brown[700]),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
