import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AdminManagementPage.dart'; // Import file AdminManagementPage

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();

        if (!doc.exists) {
          // Tạo document mới với thông tin mặc định
          final initialData = {
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
          };

          await docRef.set(initialData);
          print('Created new user document');

          setState(() {
            _userData = initialData;
            _isAdmin = false;
            _isLoading = false;
          });
        } else {
          print('User document exists');
          final data = doc.data();
          setState(() {
            _userData = data;
            _isAdmin = data?['isAdmin'] == true;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error initializing user data: $e');
        setState(() => _isLoading = false);
        _showError('Lỗi tải dữ liệu: ${e.toString()}');
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logout() async {
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
              await _logout();
            }
          },
        ),
        actions: [
          // Hiển thị nút quản lý admin nếu là admin
          if (_isAdmin)
            IconButton(
              icon: Icon(Icons.admin_panel_settings),
              tooltip: 'Quản lý người dùng',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminManagementPage(),
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
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
                        color: _isAdmin ? Colors.orange.shade50 : Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isAdmin ? Icons.admin_panel_settings : Icons.person,
                        size: 80,
                        color: _isAdmin ? Colors.orange : Colors.green,
                      ),
                    ),
                  SizedBox(height: 32),
                  Text(
                    'Thông tin cá nhân',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isAdmin) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Quản trị viên',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                          _buildInfoRow(
                            Icons.person,
                            'Tên',
                            _userData?['displayName']?.toString().isEmpty ?? true
                                ? 'Chưa cập nhật'
                                : _userData!['displayName'],
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.email,
                            'Email',
                            user?.email ?? 'Chưa có email',
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.cake,
                            'Tuổi',
                            _userData?['age']?.toString() ?? 'Chưa cập nhật',
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.wc,
                            'Giới tính',
                            _userData?['gender']?.toString() ?? 'Chưa cập nhật',
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Ngày sinh',
                            _userData?['birthDate']?.toString() ?? 'Chưa cập nhật',
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.login,
                            'Phương thức',
                            loginMethod,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Nút Quản lý người dùng (chỉ hiển thị cho admin)
                  if (_isAdmin)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminManagementPage(),
                          ),
                        );
                      },
                      icon: Icon(Icons.admin_panel_settings),
                      label: Text('Quản lý người dùng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                  if (_isAdmin) SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            userData: _userData ?? {},
                          ),
                        ),
                      );

                      if (result == true) {
                        await _initializeUserData();
                      }
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Chỉnh sửa thông tin'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: Icon(Icons.logout),
                    label: Text('Đăng xuất'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            SizedBox(width: 12),
            Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.only(left: 32),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}

// EditProfilePage class giữ nguyên như cũ
class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  EditProfilePage({required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _birthDateController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  String? _selectedGender;
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.userData['displayName']?.toString() ?? '');
    _ageController = TextEditingController(
        text: widget.userData['age']?.toString() ?? '');
    _birthDateController = TextEditingController(
        text: widget.userData['birthDate']?.toString() ?? '');
    _selectedGender = widget.userData['gender']?.toString();

    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _birthDateController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text =
        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<bool> _reauthenticate(String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return false;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print('Reauthentication error: $e');
      return false;
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Không tìm thấy người dùng');
        setState(() => _isLoading = false);
        return;
      }

      print('Saving user data for UID: ${user.uid}');

      // Chuẩn bị dữ liệu cập nhật
      final updateData = {
        'displayName': _nameController.text.trim(),
        'age': _ageController.text.trim().isNotEmpty
            ? int.tryParse(_ageController.text.trim())
            : null,
        'gender': _selectedGender,
        'birthDate': _birthDateController.text.trim().isNotEmpty
            ? _birthDateController.text.trim()
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('Update data: $updateData');

      // Cập nhật Firestore
      await _firestore.collection('users').doc(user.uid).update(updateData);
      print('Firestore updated successfully');

      // Cập nhật display name trong Firebase Auth
      if (_nameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(_nameController.text.trim());
        print('Display name updated in Auth');
      }

      // Đổi mật khẩu nếu có
      if (_isChangingPassword && _oldPasswordController.text.isNotEmpty) {
        print('Attempting to change password');

        // Xác thực lại người dùng
        final isAuthenticated = await _reauthenticate(
          _oldPasswordController.text,
        );

        if (!isAuthenticated) {
          _showError('Mật khẩu cũ không đúng');
          setState(() => _isLoading = false);
          return;
        }

        // Đổi mật khẩu
        await user.updatePassword(_newPasswordController.text);
        print('Password updated successfully');
        _showSuccess('Đổi mật khẩu thành công');
      }

      _showSuccess('Cập nhật thông tin thành công');
      await Future.delayed(Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      String message = 'Đã xảy ra lỗi';

      if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu';
      } else if (e.code == 'requires-recent-login') {
        message = 'Vui lòng đăng nhập lại để đổi mật khẩu';
      } else if (e.code == 'wrong-password') {
        message = 'Mật khẩu cũ không đúng';
      }

      _showError(message);
    } on FirebaseException catch (e) {
      print('FirebaseException: ${e.code} - ${e.message}');
      _showError('Lỗi cập nhật: ${e.message}');
    } catch (e) {
      print('Error: $e');
      _showError('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isEmailPassword = user?.providerData.any(
            (info) => info.providerId == 'password'
    ) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chỉnh sửa thông tin'),
        elevation: 0,
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
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(maxWidth: 600),
              padding: EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                            Text(
                              'Thông tin cá nhân',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Họ và tên',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập tên';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _ageController,
                              decoration: InputDecoration(
                                labelText: 'Tuổi',
                                hintText: 'Nhập tuổi của bạn',
                                prefixIcon: Icon(Icons.cake),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final age = int.tryParse(value);
                                  if (age == null || age < 1 || age > 150) {
                                    return 'Tuổi không hợp lệ';
                                  }
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Giới tính',
                                prefixIcon: Icon(Icons.wc),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: ['Nam', 'Nữ', 'Khác']
                                  .map((gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _selectedGender = value);
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _birthDateController,
                              decoration: InputDecoration(
                                labelText: 'Ngày sinh',
                                hintText: 'DD/MM/YYYY',
                                prefixIcon: Icon(Icons.calendar_today),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              readOnly: true,
                              onTap: _selectDate,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isEmailPassword) ...[
                      SizedBox(height: 24),
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
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Đổi mật khẩu',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Switch(
                                    value: _isChangingPassword,
                                    onChanged: (value) {
                                      setState(() {
                                        _isChangingPassword = value;
                                        if (!value) {
                                          _oldPasswordController.clear();
                                          _newPasswordController.clear();
                                          _confirmPasswordController.clear();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (_isChangingPassword) ...[
                                SizedBox(height: 24),
                                TextFormField(
                                  controller: _oldPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu cũ',
                                    prefixIcon: Icon(Icons.lock_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureOldPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscureOldPassword =
                                        !_obscureOldPassword);
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  obscureText: _obscureOldPassword,
                                  validator: (value) {
                                    if (_isChangingPassword &&
                                        (value == null || value.isEmpty)) {
                                      return 'Vui lòng nhập mật khẩu cũ';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _newPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu mới',
                                    prefixIcon: Icon(Icons.lock_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNewPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscureNewPassword =
                                        !_obscureNewPassword);
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  obscureText: _obscureNewPassword,
                                  validator: (value) {
                                    if (_isChangingPassword) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng nhập mật khẩu mới';
                                      }
                                      if (value.length < 6) {
                                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Xác nhận mật khẩu mới',
                                    prefixIcon: Icon(Icons.lock_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() =>
                                        _obscureConfirmPassword =
                                        !_obscureConfirmPassword);
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  obscureText: _obscureConfirmPassword,
                                  validator: (value) {
                                    if (_isChangingPassword) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng xác nhận mật khẩu';
                                      }
                                      if (value != _newPasswordController.text) {
                                        return 'Mật khẩu không khớp';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
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
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
                        'Lưu thay đổi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    );
  }
}