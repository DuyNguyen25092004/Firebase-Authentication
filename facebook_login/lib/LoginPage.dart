import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isWaitingForVerification = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 5),
      ),
    );
  }

  // // Hàm xử lý liên kết tài khoản tự động
  // Future<UserCredential?> _handleAccountLinking(String email, AuthCredential pendingCredential) async {
  //   try {
  //     // Lấy danh sách phương thức đăng nhập cho email này
  //     final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
  //
  //     if (signInMethods.isEmpty) {
  //       // Không có tài khoản nào, đăng nhập bình thường
  //       return await FirebaseAuth.instance.signInWithCredential(pendingCredential);
  //     }
  //
  //     // Hiển thị dialog để người dùng chọn liên kết tài khoản
  //     final shouldLink = await showDialog<bool>(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (context) => AlertDialog(
  //         title: Text('Tài khoản đã tồn tại'),
  //         content: Text(
  //           'Email này đã được đăng ký bằng ${_getProviderName(signInMethods.first)}. '
  //               'Bạn có muốn liên kết tài khoản không?',
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context, false),
  //             child: Text('Hủy'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () => Navigator.pop(context, true),
  //             child: Text('Liên kết'),
  //           ),
  //         ],
  //       ),
  //     );
  //
  //     if (shouldLink != true) return null;
  //
  //     // Đăng nhập bằng phương thức hiện tại để lấy user credential
  //     UserCredential? existingUserCredential;
  //
  //     if (signInMethods.contains('google.com')) {
  //       existingUserCredential = await _signInWithGoogleForLinking();
  //     } else if (signInMethods.contains('facebook.com')) {
  //       existingUserCredential = await _signInWithFacebookForLinking();
  //     } else if (signInMethods.contains('password')) {
  //       existingUserCredential = await _signInWithPasswordForLinking(email);
  //     }
  //
  //     if (existingUserCredential == null || existingUserCredential.user == null) {
  //       _showError('Không thể đăng nhập để liên kết tài khoản');
  //       return null;
  //     }
  //
  //     // Liên kết credential mới vào tài khoản hiện tại
  //     try {
  //       await existingUserCredential.user!.linkWithCredential(pendingCredential);
  //       _showSuccess('Liên kết tài khoản thành công!');
  //       return existingUserCredential;
  //     } catch (linkError) {
  //       print('Link error: $linkError');
  //       _showError('Lỗi liên kết: ${linkError.toString()}');
  //       return existingUserCredential; // Vẫn trả về user hiện tại
  //     }
  //   } catch (e) {
  //     print('Account linking error: $e');
  //     _showError('Lỗi liên kết tài khoản: ${e.toString()}');
  //     return null;
  //   }
  // }

  String _getProviderName(String providerId) {
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'facebook.com':
        return 'Facebook';
      case 'password':
        return 'Email/Password';
      default:
        return providerId;
    }
  }

  // Đăng nhập Google để liên kết
  Future<UserCredential?> _signInWithGoogleForLinking() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Sign out trước để có thể chọn tài khoản khác
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Google sign in for linking error: $e');
      return null;
    }
  }

  // Đăng nhập Facebook để liên kết
  Future<UserCredential?> _signInWithFacebookForLinking() async {
    try {
      // Logout Facebook trước
      await FacebookAuth.instance.logOut();

      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) return null;

      final OAuthCredential credential =
      FacebookAuthProvider.credential(result.accessToken!.token);

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Facebook sign in for linking error: $e');
      return null;
    }
  }

  // Đăng nhập bằng mật khẩu để liên kết
  Future<UserCredential?> _signInWithPasswordForLinking(String email) async {
    final passwordController = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nhập mật khẩu'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) return null;

    try {
      return await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _showError('Mật khẩu không đúng');
      return null;
    }
  }

  // Kiểm tra xác thực email
  Future<void> _checkEmailVerification(User user) async {
    await user.reload();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.emailVerified) {
      setState(() => _isWaitingForVerification = false);
      _showSuccess('Email đã được xác thực thành công!');
    } else {
      _showInfo('Vui lòng kiểm tra email và nhấn vào link xác thực');
    }
  }

  // Gửi lại email xác thực
  Future<void> _resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _showSuccess('Đã gửi lại email xác thực');
      }
    } catch (e) {
      if (e.toString().contains('too-many-requests')) {
        _showError('Vui lòng đợi một chút trước khi gửi lại');
      } else {
        _showError('Lỗi gửi email: ${e.toString()}');
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Đăng nhập
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Kiểm tra xác thực email
        if (userCredential.user != null && !userCredential.user!.emailVerified) {
          setState(() {
            _isWaitingForVerification = true;
            _isLoading = false;
          });

          _showDialog(
            title: 'Email chưa được xác thực',
            content: 'Vui lòng xác thực email của bạn trước khi đăng nhập. Kiểm tra hộp thư đến và spam.',
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  FirebaseAuth.instance.signOut();
                  setState(() => _isWaitingForVerification = false);
                },
                child: Text('Đăng xuất'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _resendVerificationEmail();
                },
                child: Text('Gửi lại email'),
              ),
            ],
          );
          return;
        }
      } else {
        // Đăng ký
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Gửi email xác thực
        if (userCredential.user != null) {
          await userCredential.user!.sendEmailVerification();

          setState(() {
            _isWaitingForVerification = true;
            _isLoading = false;
          });

          _showDialog(
            title: 'Xác thực email',
            content: 'Một email xác thực đã được gửi đến ${_emailController.text.trim()}.\n\n'
                'Vui lòng kiểm tra hộp thư đến (và cả thư mục spam) và nhấn vào link xác thực.',
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  FirebaseAuth.instance.signOut();
                  setState(() => _isWaitingForVerification = false);
                },
                child: Text('Đăng xuất'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _resendVerificationEmail();
                },
                child: Text('Gửi lại email'),
              ),
            ],
          );
          return;
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Đã xảy ra lỗi';

      if (e.code == 'user-not-found') {
        message = 'Không tìm thấy tài khoản';
      } else if (e.code == 'wrong-password') {
        message = 'Sai mật khẩu';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email đã được sử dụng';
      } else if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ';
      } else if (e.code == 'invalid-credential') {
        message = 'Email hoặc mật khẩu không đúng';
      }

      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDialog({required String title, required String content, required List<Widget> actions}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions,
      ),
    );
  }

  // Future<void> _signInWithGoogle() async {
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     final GoogleSignIn googleSignIn = GoogleSignIn();
  //     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  //
  //     if (googleUser == null) {
  //       setState(() => _isLoading = false);
  //       return;
  //     }
  //
  //     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  //
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //
  //     await FirebaseAuth.instance.signInWithCredential(credential);
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == 'account-exists-with-different-credential') {
  //       print('Account exists with different credential');
  //       final email = e.email;
  //       final credential = e.credential;
  //
  //       if (email != null && credential != null) {
  //         await _handleAccountLinking(email, credential);
  //       } else {
  //         _showError('Không thể liên kết tài khoản: Thiếu thông tin');
  //       }
  //     } else {
  //       _showError('Đăng nhập Google thất bại: ${e.message}');
  //     }
  //   } catch (e) {
  //     print('Google sign in error: $e');
  //     _showError('Đăng nhập Google thất bại: ${e.toString()}');
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }
  //
  // Future<void> _signInWithFacebook() async {
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     final LoginResult result = await FacebookAuth.instance.login();
  //
  //     if (result.status == LoginStatus.success) {
  //       final OAuthCredential credential =
  //       FacebookAuthProvider.credential(result.accessToken!.tokenString);
  //
  //       await FirebaseAuth.instance.signInWithCredential(credential);
  //     } else if (result.status == LoginStatus.cancelled) {
  //       _showError('Đăng nhập Facebook bị hủy');
  //     } else {
  //       _showError('Đăng nhập Facebook thất bại');
  //     }
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == 'account-exists-with-different-credential') {
  //       print('Account exists with different credential');
  //       final email = e.email;
  //       final credential = e.credential;
  //
  //       if (email != null && credential != null) {
  //         await _handleAccountLinking(email, credential);
  //       } else {
  //         _showError('Không thể liên kết tài khoản: Thiếu thông tin');
  //       }
  //     } else {
  //       _showError('Lỗi Facebook: ${e.message}');
  //     }
  //   } catch (e) {
  //     print('Facebook sign in error: $e');
  //     _showError('Lỗi Facebook: ${e.toString()}');
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        // Xử lý xung đột tài khoản
        await _handleAccountConflict(e, GoogleAuthProvider.credential(
          accessToken: (await (await GoogleSignIn().signIn())?.authentication)?.accessToken,
          idToken: (await (await GoogleSignIn().signIn())?.authentication)?.idToken,
        ));
      } else {
        _showError('Đăng nhập Google thất bại: ${e.toString()}');
      }
    } catch (e) {
      _showError('Đăng nhập Google thất bại: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);

    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final OAuthCredential credential =
        FacebookAuthProvider.credential(result.accessToken!.token);

        await FirebaseAuth.instance.signInWithCredential(credential);
      } else if (result.status == LoginStatus.cancelled) {
        _showError('Đăng nhập Facebook bị hủy');
      } else {
        _showError('Đăng nhập Facebook thất bại');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        // Xử lý xung đột tài khoản
        final AccessToken? accessToken = await FacebookAuth.instance.accessToken;
        if (accessToken != null) {
          await _handleAccountConflict(
            e,
            FacebookAuthProvider.credential(accessToken.token),
          );
        }
      } else {
        _showError('Lỗi Facebook: ${e.toString()}');
      }
    } catch (e) {
      _showError('Lỗi Facebook: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// Hàm xử lý xung đột tài khoản - thêm vào class
  Future<void> _handleAccountConflict(
      FirebaseAuthException exception,
      AuthCredential? pendingCredential,
      ) async {
    try {
      final email = exception.email;
      if (email == null) {
        _showError('Không thể xác định email');
        return;
      }

      // Lấy danh sách phương thức đăng nhập đã có
      final signInMethods =
      await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      if (signInMethods.isEmpty) {
        _showError('Không tìm thấy phương thức đăng nhập');
        return;
      }

      // Hiển thị dialog cho người dùng
      final provider =
      signInMethods.first.contains('google') ? 'Google' : 'Facebook';

      final shouldLink = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tài khoản đã tồn tại'),
          content: Text(
            'Email "$email" đã được đăng ký bằng $provider.\n\n'
                'Bạn có muốn liên kết các phương thức đăng nhập không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Liên kết'),
            ),
          ],
        ),
      );

      if (shouldLink != true || pendingCredential == null) return;

      // Đăng nhập lại bằng phương thức đã có
      UserCredential? existingUserCredential;

      if (signInMethods.contains('google.com')) {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

        final googleCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        existingUserCredential =
        await FirebaseAuth.instance.signInWithCredential(googleCredential);
      } else if (signInMethods.contains('facebook.com')) {
        final LoginResult result = await FacebookAuth.instance.login();

        if (result.status == LoginStatus.success) {
          final facebookCredential = FacebookAuthProvider.credential(
            result.accessToken!.token,
          );

          existingUserCredential = await FirebaseAuth.instance
              .signInWithCredential(facebookCredential);
        }
      }

      // Liên kết credential mới
      if (existingUserCredential != null) {
        await existingUserCredential.user!.linkWithCredential(pendingCredential);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã liên kết tài khoản thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        _showError('Thông tin đăng nhập đã được sử dụng cho tài khoản khác');
      } else if (e.code == 'provider-already-linked') {
        _showError('Tài khoản đã được liên kết rồi');
      } else {
        _showError('Lỗi liên kết: ${e.message}');
      }
    } catch (e) {
      _showError('Lỗi: ${e.toString()}');
    }
  }
  @override
  Widget build(BuildContext context) {
    // Nếu đang chờ xác thực email, hiển thị màn hình chờ
    if (_isWaitingForVerification) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade400, Colors.purple.shade400],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxWidth: 450),
                margin: EdgeInsets.all(24),
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mark_email_unread, size: 80, color: Colors.blue),
                    SizedBox(height: 24),
                    Text(
                      'Xác thực email',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chúng tôi đã gửi một email xác thực đến:\n${_emailController.text.trim()}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Vui lòng kiểm tra hộp thư đến và cả thư mục spam.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await _checkEmailVerification(user);
                        }
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Kiểm tra xác thực'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _resendVerificationEmail,
                      icon: Icon(Icons.send),
                      label: Text('Gửi lại email'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        setState(() {
                          _isWaitingForVerification = false;
                          _emailController.clear();
                          _passwordController.clear();
                        });
                      },
                      child: Text('Quay lại đăng nhập'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.purple.shade400],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(maxWidth: 450),
              margin: EdgeInsets.all(24),
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      _isLogin ? 'Đăng nhập' : 'Đăng ký',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Chào mừng trở lại!' : 'Tạo tài khoản mới',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),

                    // Social Login Buttons
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: Image.asset(
                        'assets/google_logo.png',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.g_mobiledata, color: Colors.red),
                      ),
                      label: Text('Tiếp tục với Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        elevation: 0,
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithFacebook,
                      icon: Icon(Icons.facebook, color: Colors.white),
                      label: Text('Tiếp tục với Facebook'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),

                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'HOẶC',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Email/Password Fields
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'example@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Nhập mật khẩu',
                        prefixIcon: Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithEmail,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : Text(
                        _isLogin ? 'Đăng nhập' : 'Đăng ký',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                            setState(() => _isLogin = !_isLogin);
                          },
                          child: Text(
                            _isLogin ? 'Đăng ký ngay' : 'Đăng nhập',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}