import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinManagement extends StatefulWidget {
  const CoinManagement({super.key});

  @override
  _CoinManagementScreenState createState() => _CoinManagementScreenState();
}

class _CoinManagementScreenState extends State<CoinManagement> {
  int _currentCoins = 0;
  List<Map<String, dynamic>> _coinHistoryList = [];
  List<Map<String, dynamic>> _withdrawalHistoryList = [];
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    getUserRole();
    getCurrentCoinBalance();
    getCoinUsageHistory();
    getWithdrawalHistory();
  }

  // ฟังก์ชันสำหรับการดึง role ของผู้ใช้หรือสร้างเอกสารผู้ใช้ใหม่ใน Firestore ถ้ายังไม่มีเอกสาร
  Future<void> getUserRole() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        _userRole = userDoc['role']; // รับค่า role จาก Firestore
        _isLoading = false;
        print("User role: $_userRole");
      });
    } else {
      // ถ้าไม่มีเอกสารของผู้ใช้ สร้างเอกสารใหม่
      // ตั้งค่า role ของผู้ใช้ในที่นี้
      String role = determineUserRole(); // ฟังก์ชันที่กำหนดบทบาทผู้ใช้ใหม่ เช่น จากอีเมล หรือการสร้างบัญชี
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'role': role,
        'coinBalance': 0, // ตั้งค่าเหรียญเริ่มต้นเป็น 0
      });

      setState(() {
        _userRole = role;
        _isLoading = false;
        print("User role set to: $_userRole");
      });
    }
  }

  // ฟังก์ชันสำหรับการกำหนดบทบาทของผู้ใช้
  String determineUserRole() {
    // ตรวจสอบเงื่อนไขเพื่อกำหนดบทบาท เช่น อาจใช้ email เพื่อตรวจสอบว่าเป็นนักเขียนหรือไม่
    return 'นักอ่าน'; // ตั้งค่าคืนเป็นบทบาทเริ่มต้น
  }

  // ฟังก์ชันสำหรับดึงยอดเหรียญปัจจุบันของผู้ใช้
  Future<void> getCurrentCoinBalance() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        _currentCoins = userDoc['coinBalance'] ?? 0; 
      });
    } else {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'coinBalance': 0,
        'role': _userRole, 
      });

      setState(() {
        _currentCoins = 0; 
      });
    }
  }

  // ดึงประวัติการใช้เหรียญ
  Future<void> getCoinUsageHistory() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot coinHistory = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('coinHistory')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> historyList = coinHistory.docs.map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).toList();

    setState(() {
      _coinHistoryList = historyList;
    });
  }

  // ดึงประวัติการถอนเหรียญ
  Future<void> getWithdrawalHistory() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot withdrawalHistory = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('withdrawalHistory')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> historyList = withdrawalHistory.docs.map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).toList();

    setState(() {
      _withdrawalHistoryList = historyList;
    });
  }

  // อัปเดตยอดเหรียญ
  Future<void> updateCoinBalance(int addedCoins) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot userDoc = await transaction.get(FirebaseFirestore.instance.collection('users').doc(userId));
      int currentCoins = userDoc['coinBalance'] ?? 0;

      transaction.update(userDoc.reference, {
        'coinBalance': currentCoins + addedCoins
      });
    });

    setState(() {
      _currentCoins += addedCoins;
    });
  }

  // ฟังก์ชันสำหรับการเลือกวิธีการชำระเงิน
  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('เลือกวิธีการชำระเงิน'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('บัตรเครดิต'),
                onTap: () {
                  Navigator.pop(context);
                  _processPayment(50); // สมมติเติมเหรียญ 50 เหรียญ
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('พร้อมเพย์'),
                onTap: () {
                  Navigator.pop(context);
                  _processPayment(100); // สมมติเติมเหรียญ 100 เหรียญ
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันสำหรับการประมวลผลการชำระเงิน
  void _processPayment(int addedCoins) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('เติมเหรียญสำเร็จ'),
          content: Text('คุณได้รับ $addedCoins เหรียญ'),
          actions: [
            TextButton(
              child: const Text('ตกลง'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
    updateCoinBalance(addedCoins);
  }

  // ฟังก์ชันสำหรับการถอนเหรียญ
  void _withdrawCoins(int withdrawnCoins) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ถอนเหรียญสำเร็จ'),
          content: Text('คุณได้ถอน $withdrawnCoins เหรียญเข้าสู่บัญชีธนาคารของคุณ'),
          actions: [
            TextButton(
              child: const Text('ตกลง'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
    updateCoinBalance(-withdrawnCoins);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการเหรียญ'),
        backgroundColor: Colors.brown,
      ),
      backgroundColor: Colors.brown[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) 
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'ยอดเหรียญปัจจุบัน: $_currentCoins',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown[800]),
                  ),
                ),
                if (_userRole == 'นักเขียน')
                  ElevatedButton(
                    onPressed: () {
                      _withdrawCoins(50); 
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                    child: const Text(
                      'ถอนเหรียญ',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (_userRole == 'นักอ่าน')
                  ElevatedButton(
                    onPressed: _showPaymentMethodDialog,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.brown), 
                    child: const Text(
                      'เติมเหรียญ',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _userRole == 'นักเขียน' ? _withdrawalHistoryList.length : _coinHistoryList.length,
                    itemBuilder: (context, index) {
                      var history = _userRole == 'นักเขียน'
                          ? _withdrawalHistoryList[index]
                          : _coinHistoryList[index];
                      return ListTile(
                        title: Text('${history['action']}'),
                        subtitle: Text('จำนวน: ${history['amount']}'),
                        trailing: Text('${history['timestamp'].toDate()}'),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
