// Thay thế class AuthWrapper trong main.dart bằng code này
// hoặc tạo file riêng AuthWrapper.dart và import vào main.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'HomePage.dart';
import 'LoginPage.dart';

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm tạo hoặc cập nhật thông tin user trong Firestore
  Future<void> _ensureUserDocument(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        print('Creating new user document for UID: ${user.uid}');

        // Tạo document mới với đầy đủ các trường
        await docRef.set({
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'age': null,
          'gender': null,
          'birthDate': null,
          'isAdmin': false,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('User document created successfully');
      } else {
        print('User document already exists for UID: ${user.uid}');

        // Cập nhật các trường còn thiếu nếu document đã tồn tại
        Map<String, dynamic> updateData = {};
        final data = doc.data() as Map<String, dynamic>;

        if (!data.containsKey('isAdmin')) {
          updateData['isAdmin'] = false;
        }

        if (!data.containsKey('isActive')) {
          updateData['isActive'] = true;
        }

        if (updateData.isNotEmpty) {
          updateData['updatedAt'] = FieldValue.serverTimestamp();
          await docRef.update(updateData);
          print('Updated missing fields: ${updateData.keys.join(', ')}');
        }
      }
    } catch (e) {
      print('Error ensuring user document: $e');
    }
  }

  // Kiểm tra trạng thái tài khoản
  Future<bool> _checkAccountStatus(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        return true; // Cho phép nếu document chưa tồn tại
      }

      final data = doc.data() as Map<String, dynamic>;
      final isActive = data['isActive'] ?? true;

      if (!isActive) {
        // Đăng xuất user
        await FirebaseAuth.instance.signOut();
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking account status: $e');
      return true; // Cho phép đăng nhập nếu có lỗi
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;

          return FutureBuilder<bool>(
            future: Future.wait([
              _ensureUserDocument(user),
              Future.value(true),
            ]).then((_) => _checkAccountStatus(user)),
            builder: (context, accountSnapshot) {
              if (accountSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (accountSnapshot.hasData && accountSnapshot.data == false) {
                // Tài khoản bị vô hiệu hóa
                return _buildDeactivatedScreen();
              }

              return HomePage();
            },
          );
        }

        return LoginPage();
      },
    );
  }

  Widget _buildDeactivatedScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(maxWidth: 500),
              padding: EdgeInsets.all(32),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.block,
                        size: 80,
                        color: Colors.red,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Tài khoản đã bị vô hiệu hóa',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Tài khoản của bạn đã bị vô hiệu hóa bởi quản trị viên. '
                            'Vui lòng liên hệ với quản trị viên để biết thêm thông tin.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        icon: Icon(Icons.logout),
                        label: Text('Đăng xuất'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}