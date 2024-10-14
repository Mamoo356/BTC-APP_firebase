import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class BookManagementScreen extends StatefulWidget {
  const BookManagementScreen({super.key});

  @override
  _BookManagementScreenState createState() => _BookManagementScreenState();
}

class _BookManagementScreenState extends State<BookManagementScreen> {
  File? _bookCoverImage;
  String _bookTitle = '';
  String _bookDescription = '';
  String _bookGenre = 'Comic';  // กำหนดค่าเริ่มต้นเป็น 'Comic'
  String _authorName = '';
  double _bookPrice = 0.0;
  bool _isPublished = false;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Management'),
        backgroundColor: Colors.brown,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBookDialog(),
        backgroundColor: Colors.brown,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('books')
            .where('authorId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var books = snapshot.data!.docs;
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              var book = books[index];
              return ListTile(
                leading: Image.network(book['coverUrl'], width: 50),
                title: Text(book['title']),
                subtitle: Text(book['isPublished'] ? 'Published' : 'Draft'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteBook(book.id, book['coverUrl']),
                ),
                onTap: () => _showEditBookDialog(book),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddBookDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Book'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Title', (value) => _bookTitle = value),
                _buildTextField('Description', (value) => _bookDescription = value),
                _buildTextField('Price', (value) => _bookPrice = double.parse(value)),

                // Radio Button สำหรับเลือกหมวดหมู่หนังสือ (การ์ตูน และ นิยาย)
                RadioListTile<String>(
                  title: const Text('Comic'),
                  value: 'Comic',
                  groupValue: _bookGenre,
                  onChanged: (value) {
                    setState(() {
                      _bookGenre = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Novel'),
                  value: 'Novel',
                  groupValue: _bookGenre,
                  onChanged: (value) {
                    setState(() {
                      _bookGenre = value!;
                    });
                  },
                ),

                _buildTextField('Author Name', (value) => _authorName = value),
                SwitchListTile(
                  title: const Text('Publish'),
                  value: _isPublished,
                  onChanged: (val) => setState(() => _isPublished = val),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _pickImage,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            onPressed: _saveNewBook,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _bookCoverImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildTextField(String label, Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter $label';
        return null;
      },
    );
  }

  Future<void> _saveNewBook() async {
    if (_formKey.currentState!.validate() && _bookCoverImage != null) {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String coverImageUrl = await _uploadCoverImage();

      await FirebaseFirestore.instance.collection('books').add({
        'authorId': userId,
        'title': _bookTitle,
        'description': _bookDescription,
        'genre': _bookGenre,  // บันทึกหมวดหมู่หนังสือ
        'authorName': _authorName,
        'price': _bookPrice,
        'coverUrl': coverImageUrl,
        'isPublished': _isPublished,
      });

      Navigator.pop(context);
    }
  }

  Future<String> _uploadCoverImage() async {
    String fileName = 'bookCovers/${DateTime.now().millisecondsSinceEpoch}.jpg';
    UploadTask uploadTask = FirebaseStorage.instance.ref().child(fileName).putFile(_bookCoverImage!);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

Future<void> _showEditBookDialog(DocumentSnapshot book) {
  final bookData = book.data() as Map<String, dynamic>?; // แปลงข้อมูลให้เป็น Map

  if (bookData != null) {
    _bookTitle = bookData['title']?.toString() ?? '';
    _bookDescription = bookData['description']?.toString() ?? '';
    _bookGenre = bookData['genre']?.toString() ?? 'Comic';
    _authorName = bookData['authorName']?.toString() ?? '';
    _bookPrice = (bookData['price'] as num?)?.toDouble() ?? 0.0;
    _isPublished = bookData['isPublished'] ?? false;
  }

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Book'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Title', (value) => _bookTitle = value),
              _buildTextField('Description', (value) => _bookDescription = value),
              _buildTextField('Price', (value) => _bookPrice = double.parse(value)),
              RadioListTile<String>(
                title: const Text('Comic'),
                value: 'Comic',
                groupValue: _bookGenre,
                onChanged: (value) {
                  setState(() {
                    _bookGenre = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Novel'),
                value: 'Novel',
                groupValue: _bookGenre,
                onChanged: (value) {
                  setState(() {
                    _bookGenre = value!;
                  });
                },
              ),
              _buildTextField('Author Name', (value) => _authorName = value),
              SwitchListTile(
                title: const Text('Publish'),
                value: _isPublished,
                onChanged: (val) => setState(() => _isPublished = val),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: _pickImage,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('Save'),
          onPressed: () => _saveEditedBook(book.id),
        ),
      ],
    ),
  );
}




  Future<void> _saveEditedBook(String bookId) async {
    if (_formKey.currentState!.validate()) {
      String coverImageUrl = _bookCoverImage != null ? await _uploadCoverImage() : '';

      await FirebaseFirestore.instance.collection('books').doc(bookId).update({
        'title': _bookTitle,
        'description': _bookDescription,
        'genre': _bookGenre,
        'authorName': _authorName,
        'price': _bookPrice,
        'isPublished': _isPublished,
        if (coverImageUrl.isNotEmpty) 'coverUrl': coverImageUrl,
      });

      Navigator.pop(context);
    }
  }

  Future<void> _deleteBook(String bookId, String coverUrl) async {
    await FirebaseFirestore.instance.collection('books').doc(bookId).delete();
    await FirebaseStorage.instance.refFromURL(coverUrl).delete();
  }
}
