import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_share/flutter_share.dart'; // ใช้สำหรับแชร์ข้อมูล
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  _MyLibraryScreenState createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? currentUser;
  List<DocumentSnapshot> purchasedBooks = [];

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _loadPurchasedBooks();
    }
  }

  Future<void> _loadPurchasedBooks() async {
    var purchases = await _firestore
        .collection('purchases')
        .where('userId', isEqualTo: currentUser!.uid)
        .get();

    setState(() {
      purchasedBooks = purchases.docs;
    });
  }

  Future<void> _downloadBook(String imageUrl, String title) async {
    // สร้างไดเรกทอรีสำหรับจัดเก็บไฟล์ในเครื่อง
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$title.pdf';

    // ดาวน์โหลดไฟล์จาก URL
    final response = await http.get(Uri.parse(imageUrl));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    // อัปเดตสถานะดาวน์โหลดใน Firestore
    await _firestore.collection('downloads').add({
      'userId': currentUser!.uid,
      'bookTitle': title,
      'downloaded': true,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Downloaded $title successfully!'),
    ));
  }

  Future<void> _shareBook(String title, String description) async {
    await FlutterShare.share(
      title: title,
      text: description,
      chooserTitle: 'Share Book',
    );
  }

  void _showBookDetails(DocumentSnapshot book) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(book['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Author: ${book['author']}'),
              const SizedBox(height: 10),
              Text(book['description']),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showReviewDialog(book.id);
                },
                child: const Text('Rate & Review'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReviewDialog(String bookId) {
    TextEditingController reviewController = TextEditingController();
    int rating = 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rate & Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: rating,
                items: List.generate(5, (index) => index + 1)
                    .map((value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value Stars'),
                        ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    rating = newValue!;
                  });
                },
              ),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(labelText: 'Review'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _submitReview(bookId, rating, reviewController.text);
                Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitReview(String bookId, int rating, String review) async {
    await _firestore.collection('reviews').add({
      'bookId': bookId,
      'userId': currentUser!.uid,
      'rating': rating,
      'review': review,
      'date': DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Review submitted!'),
    ));
  }

  Widget _buildBookCard(DocumentSnapshot book) {
    return Card(
      margin: const EdgeInsets.all(8),
      color: Colors.brown[100],
      child: ListTile(
        leading: Image.network(book['imageUrl'], width: 50),
        title: Text(book['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(book['author']),
        trailing: Column(
          children: [
            ElevatedButton(
              onPressed: () => _downloadBook(book['downloadUrl'], book['title']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              child: const Text('Download'),
            ),
            const SizedBox(height: 5),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.brown),
              onPressed: () => _shareBook(book['title'], book['description']),
            ),
          ],
        ),
        onTap: () => _showBookDetails(book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        backgroundColor: Colors.brown[800],
      ),
      body: purchasedBooks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: purchasedBooks.length,
              itemBuilder: (context, index) {
                return _buildBookCard(purchasedBooks[index]);
              },
            ),
    );
  }
}
