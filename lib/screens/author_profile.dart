import 'package:flutter/material.dart';

void main() {
  runApp(const AuthorProfilePage());
}

class AuthorProfilePage extends StatelessWidget {
  const AuthorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.brown,
        hintColor: Colors.orange,
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Author Profile'),
          backgroundColor: Colors.brown,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // รูปโปรไฟล์
              const CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(
                    'https://via.placeholder.com/150'), // รูป placeholder สามารถเปลี่ยนเป็น URL ของจริง
              ),
              const SizedBox(height: 20),
              // ชื่อนักเขียน
              Text(
                'Author Name',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              // Bio
              Text(
                'This is a short bio about the author. It gives a brief introduction or description.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
              // ปุ่มแก้ไขโปรไฟล์
              ElevatedButton.icon(
                onPressed: () {
                  // เพิ่มฟังก์ชันการแก้ไขโปรไฟล์
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              // ปุ่มออกจากระบบ
              ElevatedButton.icon(
                onPressed: () {
                  // เพิ่มฟังก์ชันการออกจากระบบ
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
