import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'author_home.dart';  // หน้าหลักนักเขียน
import 'reader_home.dart';  // หน้าหลักนักอ่าน

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? userRole; // To store selected user role
  final DatabaseReference _database = FirebaseDatabase.instance.ref(); // Reference to Realtime Database

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png', // โลโก้
              height: 100,
            ),
            const SizedBox(height: 20),
            Text(
              'Create New Account',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown[800]),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black), // เปลี่ยนสีขอบเป็นสีดำ
                ),
                fillColor: Colors.brown[100],
                filled: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black), // เปลี่ยนสีขอบเป็นสีดำ
                ),
                fillColor: Colors.brown[100],
                filled: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black), // เปลี่ยนสีขอบเป็นสีดำ
                ),
                fillColor: Colors.brown[100],
                filled: true,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Role',
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black), // เปลี่ยนสีขอบเป็นสีดำ
                ),
                fillColor: Colors.brown[100],
                filled: true,
              ),
              value: userRole,  // แก้ไขเพื่อให้รองรับค่า null
              items: const [
                DropdownMenuItem(value: 'writer', child: Text('Writer')),
                DropdownMenuItem(value: 'reader', child: Text('Reader')),
              ],
              onChanged: (value) {
                setState(() {
                  userRole = value;
                });
              },
              validator: (value) => value == null ? 'Please select a role' : null,  // ตรวจสอบการเลือก Role
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                  return;
                }
                if (userRole == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a role')));
                  return;
                }
                try {
                  UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: emailController.text,
                    password: passwordController.text,
                  );

                  DatabaseReference userRef = _database.child('users/${userCredential.user?.uid}');
                  await userRef.set({
                    'name': nameController.text,
                    'email': emailController.text,
                    'role': userRole,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Registered Successfully')));

                  if (userRole == 'writer') {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthorHomeScreen()));
                  } else if (userRole == 'reader') {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReaderHomeScreen()));
                  }

                } on FirebaseAuthException catch (e) {
                  if (e.code == 'email-already-in-use') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The email address is already in use.')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.brown, // เปลี่ยนสีตัวอักษรในปุ่มเป็นสีขาว
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
