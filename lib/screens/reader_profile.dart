import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? currentUser;
  String? name;
  String? email;
  int coinBalance = 0;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? profileImageUrl;
  String? oldPassword;
  String? newPassword;
  String? confirmPassword;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      name = currentUser!.displayName;
      email = currentUser!.email;
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser!.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

        if (userData != null) {
          setState(() {
            profileImageUrl = userData['profileImageUrl'];
            coinBalance = userData['coinBalance'] ?? 0;
          });
        }
      } else {
        setState(() {
          profileImageUrl = null;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  Future<void> _updateProfile(String newName, String newEmail) async {
    await currentUser!.updateDisplayName(newName);
    await currentUser!.updateEmail(newEmail);
    await _firestore.collection('users').doc(currentUser!.uid).update({
      'name': newName,
      'email': newEmail,
    });
    setState(() {
      name = newName;
      email = newEmail;
    });
  }

  Future<void> _changePassword() async {
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }
    try {
      // Check if old password is correct
      AuthCredential credential = EmailAuthProvider.credential(
        email: email!,
        password: oldPassword!,
      );
      await currentUser!.reauthenticateWithCredential(credential);

      // Update password
      await currentUser!.updatePassword(newPassword!);
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'password': newPassword,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadProfileImage();
    }
  }

 Future<void> _uploadProfileImage() async {
  if (_imageFile == null) return;

  try {
    String fileName = 'profile_images/${currentUser!.uid}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(_imageFile!);

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    await _firestore.collection('users').doc(currentUser!.uid).update({
      'profileImageUrl': downloadUrl,
    });

    setState(() {
      profileImageUrl = downloadUrl;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile picture updated successfully!')),
    );
  } catch (e) {
    // แสดงข้อผิดพลาดใน SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error uploading image: $e')),
    );
    print('Error: $e');  // เพื่อให้เห็นรายละเอียดของข้อผิดพลาดใน console
  }
}


  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacementNamed('/signin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : const AssetImage('assets/default_profile.png') as ImageProvider,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name ?? 'No Name',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[900],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      email ?? 'No Email',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.brown[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                       ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo, color: Colors.white), // เปลี่ยนสีไอคอนเป็นสีขาว
                          label: const Text(
                            'Choose from Gallery',
                            style: TextStyle(color: Colors.white), // กำหนดสีตัวอักษรในปุ่มเป็นสีขาว
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown[400], // สีพื้นหลังปุ่ม
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20), // ปุ่มมีขอบโค้งมน
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, color: Colors.white), // เปลี่ยนสีไอคอนเป็นสีขาว
                          label: const Text(
                            'Take a Photo',
                            style: TextStyle(color: Colors.white), // กำหนดสีตัวอักษรในปุ่มเป็นสีขาว
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown[400], // สีพื้นหลังปุ่ม
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20), // ปุ่มมีขอบโค้งมน
                            ),
                          ),
                        ),


                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) => email = value,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _updateProfile(name!, email!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[600],
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Update Information', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                obscureText: true,
                onChanged: (value) => oldPassword = value,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                obscureText: true,
                onChanged: (value) => newPassword = value,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                obscureText: true,
                onChanged: (value) => confirmPassword = value,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[600],
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Change Password', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              Text(
                'Coin Balance: $coinBalance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[900],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
