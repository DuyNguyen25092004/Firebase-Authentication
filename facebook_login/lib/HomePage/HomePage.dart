
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final providerData = user?.providerData.first;
    String loginMethod = 'Email/Password';

    if (providerData?.providerId == 'google.com') {
      loginMethod = 'Google';
    } else if (providerData?.providerId == 'facebook.com') {
      loginMethod = 'Facebook';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Trang chủ'),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: 'Quay lại',
          onPressed: () async {
            // Hiển thị dialog xác nhận
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Xác nhận'),
                content: Text('Bạn có muốn đăng xuất không?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Đăng xuất'),
                  ),
                ],
              ),
            );

            if (shouldLogout == true) {
              try {
                final GoogleSignIn googleSignIn = GoogleSignIn();
                await googleSignIn.signOut();
              } catch (e) {
                print('Google sign out error: $e');
              }

              try {
                await FacebookAuth.instance.logOut();
              } catch (e) {
                print('Facebook logout error: $e');
              }

              await FirebaseAuth.instance.signOut();
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              try {
                final GoogleSignIn googleSignIn = GoogleSignIn();
                await googleSignIn.signOut();
              } catch (e) {
                print('Google sign out error: $e');
              }

              try {
                await FacebookAuth.instance.logOut();
              } catch (e) {
                print('Facebook logout error: $e');
              }

              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 600),
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user?.photoURL != null)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user!.photoURL!),
                    backgroundColor: Colors.grey[200],
                  )
                else
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green,
                    ),
                  ),
                SizedBox(height: 32),
                Text(
                  'Đăng nhập thành công!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user?.displayName != null) ...[
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.blue),
                              SizedBox(width: 12),
                              Text(
                                'Tên:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            user?.displayName ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Icon(Icons.email, color: Colors.blue),
                            SizedBox(width: 12),
                            Text(
                              'Email:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.login, color: Colors.blue),
                            SizedBox(width: 12),
                            Text(
                              'Phương thức:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          loginMethod,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final GoogleSignIn googleSignIn = GoogleSignIn();
                      await googleSignIn.signOut();
                    } catch (e) {
                      print('Google sign out error: $e');
                    }

                    try {
                      await FacebookAuth.instance.logOut();
                    } catch (e) {
                      print('Facebook logout error: $e');
                    }

                    await FirebaseAuth.instance.signOut();
                  },
                  icon: Icon(Icons.logout),
                  label: Text('Đăng xuất'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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
    );
  }
}