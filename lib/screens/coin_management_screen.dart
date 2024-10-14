import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinManagementScreen extends StatefulWidget {
  const CoinManagementScreen({super.key});

  @override
  _CoinManagementScreenState createState() => _CoinManagementScreenState();
}

class _CoinManagementScreenState extends State<CoinManagementScreen> {
  int _currentCoins = 0;
  List<Map<String, dynamic>> _transactionHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    getCurrentCoinBalance();
    getTransactionHistory();
  }

  // ฟังก์ชันสำหรับดึงยอดเหรียญปัจจุบันของนักเขียน
  Future<void> getCurrentCoinBalance() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('writers').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        _currentCoins = userDoc['coinBalance'] ?? 0;
      });
    } else {
      await FirebaseFirestore.instance.collection('writers').doc(userId).set({
        'coinBalance': 0,
      });

      setState(() {
        _currentCoins = 0;
      });
    }
  }

  // ฟังก์ชันสำหรับดึงประวัติการทำธุรกรรม
  Future<void> getTransactionHistory() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot transactionSnapshot = await FirebaseFirestore.instance
        .collection('writers')
        .doc(userId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> historyList = transactionSnapshot.docs.map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).toList();

    setState(() {
      _transactionHistory = historyList;
      _isLoading = false;
    });
  }

  // ฟังก์ชันสำหรับการยืนยันรหัสผ่านก่อนถอนเหรียญ
  Future<void> _verifyPasswordAndWithdraw(int amount) async {
    TextEditingController passwordController = TextEditingController();
    bool passwordVerified = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.brown[100],
        title: Text('Verify Password', style: TextStyle(color: Colors.brown[800])),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please enter your password to proceed with the withdrawal.', style: TextStyle(color: Colors.brown[700])),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.brown[700]),
                filled: true,
                fillColor: Colors.brown[50],
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String password = passwordController.text;

              // ยืนยันรหัสผ่านของผู้ใช้
              User? user = FirebaseAuth.instance.currentUser;
              AuthCredential credential = EmailAuthProvider.credential(
                  email: user!.email!, password: password);
              try {
                await user.reauthenticateWithCredential(credential);
                passwordVerified = true;
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Password verification failed. Please try again.'),
                ));
              }
            },
            style: TextButton.styleFrom(backgroundColor: Colors.brown),
            child: const Text('Verify', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel', style: TextStyle(color: Colors.brown[700])),
          ),
        ],
      ),
    );

    if (passwordVerified) {
      // ถ้าการยืนยันรหัสผ่านสำเร็จให้ทำการถอนเหรียญ
      withdrawCoins(amount);
    }
  }

  // ฟังก์ชันสำหรับการถอนเหรียญ
  Future<void> withdrawCoins(int amount) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    if (amount > _currentCoins) {
      // ตรวจสอบยอดเหรียญไม่พอ
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ยอดเหรียญไม่เพียงพอสำหรับการถอน'),
      ));
      return;
    }

    // ลดเหรียญใน Firebase และเพิ่มรายการถอน
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot userDoc = await transaction.get(FirebaseFirestore.instance.collection('writers').doc(userId));
      int currentCoins = userDoc['coinBalance'] ?? 0;

      transaction.update(userDoc.reference, {
        'coinBalance': currentCoins - amount,
      });

      transaction.set(
        FirebaseFirestore.instance
            .collection('writers')
            .doc(userId)
            .collection('transactions')
            .doc(),
        {
          'action': 'Withdraw',
          'amount': amount,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );
    });

    setState(() {
      _currentCoins -= amount;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('ถอนเหรียญสำเร็จ'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Management', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown[800],
      ),
      backgroundColor: Colors.brown[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.brown[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Current Coins: $_currentCoins',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _verifyPasswordAndWithdraw(50); // ตัวอย่างถอน 50 เหรียญ
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[800], // สีพื้นหลังของปุ่ม
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24), // การกำหนด padding
                    foregroundColor: Colors.white, // กำหนดสีตัวอักษรให้เป็นสีขาว
                    textStyle: const TextStyle(
                      fontSize: 18, // กำหนดขนาดตัวอักษร
                    ),
                  ),
                  child: const Text('Withdraw Coins'),
                ),
                const SizedBox(height: 20), // เพิ่ม SizedBox หลังจากปุ่ม
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.brown[100],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ListView.builder(
                      itemCount: _transactionHistory.length,
                      itemBuilder: (context, index) {
                        var transaction = _transactionHistory[index];
                        return Card(
                          color: Colors.brown[50],
                          child: ListTile(
                            title: Text(transaction['action'], style: TextStyle(color: Colors.brown[700])),
                            subtitle: Text('Amount: ${transaction['amount']}', style: TextStyle(color: Colors.brown[500])),
                            trailing: Text(
                              transaction['timestamp'].toDate().toString(),
                              style: TextStyle(color: Colors.brown[500]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
