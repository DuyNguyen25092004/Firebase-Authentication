// AdminManagementPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminManagementPage extends StatefulWidget {
  @override
  _AdminManagementPageState createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleAdminStatus(String userId, bool currentStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showSuccess(
        !currentStatus ? 'Đã cấp quyền admin' : 'Đã gỡ quyền admin',
      );
    } catch (e) {
      _showError('Lỗi cập nhật quyền: ${e.toString()}');
    }
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showSuccess(
        !currentStatus ? 'Đã kích hoạt tài khoản' : 'Đã vô hiệu hóa tài khoản',
      );
    } catch (e) {
      _showError('Lỗi cập nhật trạng thái: ${e.toString()}');
    }
  }

  Future<void> _deleteUser(String userId, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa người dùng "$email"?\n\nLưu ý: Thao tác này chỉ xóa dữ liệu trong Firestore. Để xóa hoàn toàn tài khoản Firebase Auth, cần sử dụng Admin SDK từ backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore.collection('users').doc(userId).delete();
      _showSuccess('Đã xóa người dùng khỏi cơ sở dữ liệu');
    } catch (e) {
      _showError('Lỗi xóa người dùng: ${e.toString()}');
    }
  }

  void _showUserDetails(Map<String, dynamic> userData, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết người dùng'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', userId),
              _buildDetailRow('Tên', userData['displayName'] ?? 'Chưa cập nhật'),
              _buildDetailRow('Email', userData['email'] ?? 'Không có'),
              _buildDetailRow('Tuổi', userData['age']?.toString() ?? 'Chưa cập nhật'),
              _buildDetailRow('Giới tính', userData['gender'] ?? 'Chưa cập nhật'),
              _buildDetailRow('Ngày sinh', userData['birthDate'] ?? 'Chưa cập nhật'),
              _buildDetailRow(
                'Quyền admin',
                userData['isAdmin'] == true ? 'Có' : 'Không',
              ),
              _buildDetailRow(
                'Trạng thái',
                userData['isActive'] != false ? 'Hoạt động' : 'Vô hiệu hóa',
              ),
              if (userData['createdAt'] != null)
                _buildDetailRow(
                  'Ngày tạo',
                  _formatTimestamp(userData['createdAt']),
                ),
              if (userData['updatedAt'] != null)
                _buildDetailRow(
                  'Cập nhật lần cuối',
                  _formatTimestamp(userData['updatedAt']),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Không có';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
      }
      return 'Không hợp lệ';
    } catch (e) {
      return 'Lỗi định dạng';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý người dùng'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => setState(() {}),
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
        child: Column(
          children: [
            // Search bar
            Container(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên hoặc email...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),

            // User list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Không có người dùng nào',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  var users = snapshot.data!.docs;

                  // Filter users based on search query
                  if (_searchQuery.isNotEmpty) {
                    users = users.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['displayName'] ?? '').toString().toLowerCase();
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery) || email.contains(_searchQuery);
                    }).toList();
                  }

                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Không tìm thấy kết quả',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final doc = users[index];
                      final userData = doc.data() as Map<String, dynamic>;
                      final userId = doc.id;
                      final isCurrentUser = userId == currentUser?.uid;
                      final isAdmin = userData['isAdmin'] == true;
                      final isActive = userData['isActive'] != false;

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor: isAdmin
                                ? Colors.orange.shade100
                                : Colors.blue.shade100,
                            backgroundImage: userData['photoURL'] != null
                                ? NetworkImage(userData['photoURL'])
                                : null,
                            child: userData['photoURL'] == null
                                ? Icon(
                              isAdmin ? Icons.admin_panel_settings : Icons.person,
                              color: isAdmin ? Colors.orange : Colors.blue,
                            )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  userData['displayName'] ?? 'Không có tên',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    decoration: isActive ? null : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              if (isAdmin)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Admin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (isCurrentUser)
                                Container(
                                  margin: EdgeInsets.only(left: 8),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Bạn',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Text(
                                userData['email'] ?? 'Không có email',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    isActive ? Icons.check_circle : Icons.cancel,
                                    size: 16,
                                    color: isActive ? Colors.green : Colors.red,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    isActive ? 'Hoạt động' : 'Vô hiệu hóa',
                                    style: TextStyle(
                                      color: isActive ? Colors.green : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              switch (value) {
                                case 'view':
                                  _showUserDetails(userData, userId);
                                  break;
                                case 'toggleAdmin':
                                  if (!isCurrentUser) {
                                    await _toggleAdminStatus(userId, isAdmin);
                                  }
                                  break;
                                case 'toggleStatus':
                                  if (!isCurrentUser) {
                                    await _toggleUserStatus(userId, isActive);
                                  }
                                  break;
                                case 'delete':
                                  if (!isCurrentUser) {
                                    await _deleteUser(userId, userData['email'] ?? '');
                                  }
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 20),
                                    SizedBox(width: 12),
                                    Text('Xem chi tiết'),
                                  ],
                                ),
                              ),
                              if (!isCurrentUser) ...[
                                PopupMenuItem(
                                  value: 'toggleAdmin',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(isAdmin ? 'Gỡ quyền admin' : 'Cấp quyền admin'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'toggleStatus',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isActive ? Icons.block : Icons.check_circle,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20, color: Colors.red),
                                      SizedBox(width: 12),
                                      Text('Xóa', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}