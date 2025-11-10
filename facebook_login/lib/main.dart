// main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'HomePage.dart';
import 'LoginPage.dart';

// Cấu hình Firebase cho Web
const firebaseConfig = FirebaseOptions(
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(options: firebaseConfig);
  } else {
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      home: AuthWrapper(),
    );
  }
}

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
          'isAdmin': false, // Mặc định không phải admin
          'isActive': true, // Mặc định tài khoản hoạt động
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('User document created successfully');
      } else {
        print('User document already exists for UID: ${user.uid}');

        // Cập nhật các trường còn thiếu nếu document đã tồn tại
        Map<String, dynamic> updateData = {};
        final data = doc.data() as Map<String, dynamic>;

        // Kiểm tra và thêm trường isAdmin nếu chưa có
        if (!data.containsKey('isAdmin')) {
          updateData['isAdmin'] = false;
        }

        // Kiểm tra và thêm trường isActive nếu chưa có
        if (!data.containsKey('isActive')) {
          updateData['isActive'] = true;
        }

        // Cập nhật nếu có trường cần thêm
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

  // Kiểm tra xem provider có yêu cầu xác thực email không
  bool _requiresEmailVerification(User user) {
    // Chỉ yêu cầu xác thực email cho tài khoản đăng ký bằng email/password
    final providerIds = user.providerData.map((e) => e.providerId).toList();

    // Nếu user đăng nhập bằng Google hoặc Facebook, không cần xác thực
    if (providerIds.contains('google.com') || providerIds.contains('facebook.com')) {
      return false;
    }

    // Nếu đăng nhập bằng email/password, cần xác thực
    return providerIds.contains('password');
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

          // Kiểm tra xem có cần xác thực email không
          if (_requiresEmailVerification(user) && !user.emailVerified) {
            return _buildEmailVerificationScreen(user);
          }

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

  Widget _buildEmailVerificationScreen(User user) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
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
                        Icons.mark_email_unread,
                        size: 80,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Xác thực email của bạn',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Chúng tôi đã gửi một email xác thực đến:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        user.email ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Vui lòng kiểm tra hộp thư đến (và cả thư mục spam) của bạn và nhấn vào link xác thực để tiếp tục.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await user.reload();
                          final currentUser = FirebaseAuth.instance.currentUser;

                          if (currentUser != null && currentUser.emailVerified) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Email đã được xác thực thành công!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            // Trigger rebuild để vào HomePage
                            setState(() {});
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Email chưa được xác thực. Vui lòng kiểm tra email.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.refresh),
                        label: Text('Tôi đã xác thực'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await user.sendEmailVerification();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã gửi lại email xác thực'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            String message = 'Lỗi gửi email';
                            if (e.toString().contains('too-many-requests')) {
                              message = 'Vui lòng đợi một chút trước khi gửi lại';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.send),
                        label: Text('Gửi lại email'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: Text('Đăng xuất'),
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