import 'dart:convert';
import 'package:flutter/material.dart';
import 'LoginPage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';


import 'Model.dart';



class AdminOrdersScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminOrdersScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {

  int selectedStatusDropdown = 0;
  String selectedStatus = 'all';
  final searchController = TextEditingController();
  String searchQuery = '';
  final mainBlue = const Color(0xFF0066CC);
  final String apiUrl = 'http://192.168.100.231:3001';
  List<Order> orders = [];

  // Thêm ngay sau khai báo biến
  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  String formatCurrency(double amount) {
    return currencyFormat.format(amount);
  }

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/api/orders'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          orders = data.map((json) => Order.fromJson(json)).toList();
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải dữ liệu: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateOrderStatus(String orderId, int newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/api/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          orders = orders.map((order) {
            if (order.id == orderId) {
              return Order(
                id: order.id,
                customerName: order.customerName,
                phone: order.phone,
                total: order.total,
                status: newStatus,
                date: order.date,
              );
            }
            return order;
          }).toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật trạng thái thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi cập nhật trạng thái: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = orders.where((order) {
      // Lọc theo từ khóa tìm kiếm
      bool matchesSearch = searchQuery.isEmpty ||
          order.id.toString().toLowerCase().contains(searchQuery.toLowerCase());

      // Lọc theo trạng thái
      bool matchesStatus = selectedStatus == 'all' || (() {
        switch (selectedStatus) {
          case 'pending':
            return order.status == 0;
          case 'approved':
            return order.status == 1;
          case 'completed':
            return order.status == 2;
          case 'cancelled':
            return order.status == -1;
          default:
            return true;
        }
      })();

      // Trả về true nếu thỏa mãn cả 2 điều kiện
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: mainBlue,
        elevation: 0,
        title: const Text(
          'Quản lý đơn hàng',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(100, 70, 0, 0),
                items: [
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.admin_panel_settings),
                      title: Text('Thông tin Admin'),
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            TextEditingController nameController =
                                TextEditingController(
                                    text: "${widget.user['username']}");
                            TextEditingController emailController =
                                TextEditingController(
                                    text: "${widget.user['email']}");
                            TextEditingController phoneController =
                                TextEditingController(
                                    text: "${widget.user['phone']}");

                            return AlertDialog(
                              title: Text('Thông tin Admin'),
                              content: Container(
                                height: 250,
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: nameController,
                                      decoration: InputDecoration(
                                        labelText: 'User Name',
                                        icon: Icon(Icons.person),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    TextField(
                                      controller: emailController,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        icon: Icon(Icons.email),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    TextField(
                                      controller: phoneController,
                                      decoration: InputDecoration(
                                        labelText: 'Số điện thoại',
                                        icon: Icon(Icons.phone),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      final response = await http.put(
                                        Uri.parse('$apiUrl/api/users/update'),
                                        headers: {
                                          'Content-Type': 'application/json',
                                        },
                                        body: json.encode({
                                          'username': nameController.text,
                                          'email': emailController.text,
                                          'phone': phoneController.text,
                                        }),
                                      );

                                      if (response.statusCode == 200) {
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Cập nhật thông tin thành công!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Lỗi: ${json.decode(response.body)['message']}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (error) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Đã có lỗi xảy ra: $error'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: Text('Lưu'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Đăng xuất'),
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Xác nhận'),
                              content: Text('Bạn có chắc chắn muốn đăng xuất?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => LoginPage()),
                                    );
                                  },
                                  child: Text(
                                    'Đăng xuất',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              _buildStatCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Tổng đơn hàng',
                value: orders.length.toString(),
                color: mainBlue,
              ),
              _buildStatCard(
                icon: Icons.pending_actions_outlined,
                title: 'Chờ xử lý',
                value: orders.where((order) => order.status == 0).length.toString(),
                color: Colors.orange,
              ),
              _buildStatCard(
                icon: Icons.check_circle_outline,
                title: 'Đã duyệt',
                value: orders.where((order) => order.status == 1).length.toString(),
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.verified_outlined,
                title: 'Hoàn thành',
                value: orders.where((order) => order.status == 2).length.toString(),
                color: Colors.green,
              ),
              _buildStatCard(
                icon: Icons.cancel_outlined,
                title: 'Đã hủy',
                value: orders.where((order) => order.status == -1).length.toString(),
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Text(
                        'Danh sách đơn hàng',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm đơn hàng...',
                            prefixIcon: Icon(Icons.search, color: mainBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: mainBlue, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStatus,
                            hint: const Text('Trạng thái'),
                            style: TextStyle(color: Colors.grey[800], fontSize: 14),
                            onChanged: (value) {
                              setState(() => selectedStatus = value!);
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('Tất cả trạng thái'),
                              ),
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('Chờ xử lý'),
                              ),
                              DropdownMenuItem(
                                value: 'approved',
                                child: Text('Đã duyệt'),
                              ),
                              DropdownMenuItem(
                                value: 'completed',
                                child: Text('Hoàn thành'),
                              ),
                              DropdownMenuItem(
                                value: 'cancelled',
                                child: Text('Đã hủy'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                    dataRowHeight: 70,
                    columns: [
                      DataColumn(
                        label: Text(
                          'Mã đơn',
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Khách hàng',
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Số điện thoại',
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Tổng tiền',
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Trạng thái',
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Ngày đặt',
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ),
                      const DataColumn(label: Text('')),
                    ],
                    rows: filteredOrders.isNotEmpty
                        ? filteredOrders.map((order) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    '${order.id}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                DataCell(Text(order.customerName)),
                                DataCell(Text(order.phone)),
                                DataCell(
                                  Text(
                                    formatCurrency(order.total),  // Thay thế '${order.total.toStringAsFixed(0)}đ'
                                    style: TextStyle(
                                      color: mainBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(_buildStatusBadge(order.status)),
                                DataCell(Text(order.date)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildActionButton(
                                        icon: Icons.edit_outlined,
                                        label: 'Cập nhật',
                                        onPressed: () =>
                                            _showOrderUpdate(context, order),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildActionButton(
                                        icon: Icons.visibility_outlined,
                                        label: 'Chi tiết',
                                        onPressed: () => _showOrderDetails(
                                            context, order, false),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList()
                        : [], // Trả về list rỗng nếu không có đơn hàng,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Hiển thị loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );

          // Thực hiện fetch dữ liệu mới
          await fetchOrders();

          // Đóng loading indicator
          if (context.mounted) {
            Navigator.pop(context);
            // Hiển thị thông báo thành công
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật dữ liệu thành công'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        backgroundColor: mainBlue,
        child: const Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Làm mới dữ liệu',
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStatusBadge(int status) {
    Color color;
    String text;

    switch (status) {
      case 0:
        color = Colors.orange;
        text = 'Chờ xử lý';
        break;
      case 1:
        color = Colors.blue; // Đổi màu cho trạng thái đã duyệt
        text = 'Đã duyệt';
        break;
      case 2: // Thêm case mới cho trạng thái hoàn thành
        color = Colors.green;
        text = 'Hoàn thành';
        break;
      case -1:
        color = Colors.red;
        text = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        text = 'Không xác định';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: mainBlue,
        backgroundColor: Colors.blue[50],
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
      onPressed: onPressed,
    );
  }

  Future<void> _showOrderDetails(BuildContext context, Order order, bool canEdit) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/orders/${order.id}/details'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<OrderDetail> orderDetails = data.map((json) => OrderDetail.fromJson(json)).toList();

        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header với thông tin đơn hàng và nút đóng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chi tiết đơn hàng #${order.id}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ngày đặt: ${order.date}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Thông tin khách hàng
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.person_outline,
                          label: 'Khách hàng',
                          value: order.customerName,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Số điện thoại',
                          value: order.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Ngày đặt',
                          value: order.date,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bảng chi tiết sản phẩm
                  Text(
                    'Chi tiết sản phẩm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      columns: const [
                        DataColumn(label: Text('Tên sản phẩm')),
                        DataColumn(label: Text('Số lượng')),
                        DataColumn(label: Text('Dung lượng')),
                        DataColumn(label: Text('Đơn giá')),
                        DataColumn(label: Text('Thành tiền')),
                      ],
                      rows: orderDetails.map((detail) {
                        return DataRow(
                          cells: [
                            DataCell(Text(detail.name)),
                            DataCell(Text(detail.quantity.toString())),
                            DataCell(Text(detail.storage.toString())),
                            DataCell(Text(formatCurrency(detail.price ?? 0))),  // Thay thế '${detail.price?.toStringAsFixed(0)}đ'
                            DataCell(Text(formatCurrency(detail.total ?? 0))),  // Thay thế '${detail.total?.toStringAsFixed(0)}đ'
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tổng tiền
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: mainBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: mainBlue.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng tiền',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatCurrency(order.total),  // Thay thế '${order.total.toStringAsFixed(0)}đ'
                          style: TextStyle(
                            color: mainBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nút đóng
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Đóng',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        throw Exception('Failed to load order details');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải chi tiết đơn hàng: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }



  void _showOrderUpdate(BuildContext context, Order order) {
    _showUpdate(context, order);
  }



  void _showUpdate(BuildContext context, Order order) {
    // Lấy trạng thái hiện tại của đơn hàng
    int selectedStatus = order.status;

    // Tạo danh sách các trạng thái có thể chuyển đến dựa trên trạng thái hiện tại
    List<DropdownMenuItem<int>> getAvailableStatusItems() {
      if (order.status == 0) {
        // Nếu đang chờ xử lý, chỉ cho phép chuyển sang đã duyệt
        return [
          DropdownMenuItem(
            value: 0,
            child: Text('Chờ xử lý'),
          ),
          DropdownMenuItem(
            value: 1,
            child: Text('Đã duyệt'),
          ),
        ];
      } else {
        // Các trạng thái khác sẽ chỉ hiển thị trạng thái hiện tại và không cho phép thay đổi
        String statusText;
        switch (order.status) {
          case 1:
            statusText = 'Đã duyệt';
            break;
          case 2:
            statusText = 'Hoàn thành';
            break;
          case -1:
            statusText = 'Đã hủy';
            break;
          default:
            statusText = 'Không xác định';
        }
        return [
          DropdownMenuItem(
            value: order.status,
            child: Text(statusText),
            enabled: false,
          ),
        ];
      }
    }

    // Kiểm tra xem có cho phép thay đổi trạng thái không
    bool isEditable = order.status == 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Cập nhật đơn hàng #${order.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Khách hàng: ${order.customerName}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Số điện thoại: ${order.phone}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Ngày đặt: ${order.date}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Trạng thái đơn hàng:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isEditable ? Colors.blue : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    focusColor: Colors.transparent,
                    value: selectedStatus,
                    onChanged: isEditable ? (int? value) {
                      if (value != null) {
                        setState(() {
                          selectedStatus = value;
                        });
                      }
                    } : null,
                    items: getAvailableStatusItems(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Đóng',
                style: TextStyle(color: Colors.grey[800]),
              ),
            ),
            if (isEditable) // Chỉ hiển thị nút cập nhật khi đơn hàng có thể chỉnh sửa
              ElevatedButton(
                onPressed: () async {
                  try {
                    final response = await http.put(
                      Uri.parse('$apiUrl/api/orders/update/${order.id}'),
                      headers: {
                        'Content-Type': 'application/json',
                      },
                      body: json.encode({
                        'status': selectedStatus
                      }),
                    );

                    if (response.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật trạng thái thành công'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                      onUpdateSuccess();
                    } else {
                      throw Exception('Failed to update order status');
                    }
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi khi cập nhật: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cập nhật'),
              ),
          ],
        ),
      ),
    );
  }


  void onUpdateSuccess() {
    setState(() {
      // Gọi lại hàm fetchOrders để lấy danh sách đơn hàng mới
      fetchOrders();
    });
  }




}

