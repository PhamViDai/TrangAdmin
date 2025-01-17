// server.js
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Kết nối database
const connection = mysql.createConnection({
    host: 'monorail.proxy.rlwy.net',
    port: 33332,
    user: 'root',
    password: 'EdpRdJrtNGOTaGPPydqPCRtbkMNZlNjj',
    database: 'railway'
});

connection.connect((err) => {
  if (err) {
    console.error('Error connecting to database:', err);
    return;
  }
  console.log('Connected to database');
});

// API đăng nhập
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;

  try {
    const [rows] = await connection.promise().query(
      'SELECT * FROM Users WHERE username = ? AND password = ?',
      [username, password]
    );

    if (rows.length === 0) {
      return res.status(401).json({ message: 'Users hoặc mật khẩu không đúng' });
    }

    const user = rows[0];

    res.json({
      message: 'Đăng nhập thành công',
      user: {
        username: user.username,
        email: user.email,
        phone: user.phone
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// API lấy chi tiết đơn hàng
app.get('/api/orders/:user_id/details', async (req, res) => {
  try {
    const user_id = req.params.user_id;

    const [orderDetails] = await connection.promise().query(`
      SELECT
              railway.Products.name,
              railway.OrdersDetail.quantity,
              railway.OrdersDetail.storage,
              railway.OrdersDetail.price,
              SUM(railway.OrdersDetail.quantity*railway.OrdersDetail.price) as TongTien
            FROM railway.Orders
            INNER JOIN railway.OrdersDetail ON railway.Orders.order_id = railway.OrdersDetail.order_id
            INNER JOIN railway.ProductDetail ON railway.OrdersDetail.product_detail_id = railway.ProductDetail.product_detail_id
            INNER JOIN railway.Products ON railway.ProductDetail.product_id = railway.Products.product_id
            WHERE railway.Orders.user_id = ?
            GROUP BY
              railway.Products.name,
              railway.OrdersDetail.quantity,
              railway.OrdersDetail.storage,
              railway.OrdersDetail.price
    `, [user_id]);

    // Format dữ liệu trả về
    const formattedDetails = orderDetails.map(detail => ({
      name: detail.name,
      quantity: detail.quantity,
      storage: detail.storage,
      price: parseFloat(detail.price),
      total: parseFloat(detail.TongTien)
    }));

    res.json(formattedDetails);

  } catch (error) {
    console.error('Error fetching order details:', error);
    res.status(500).json({ message: 'Lỗi server khi lấy chi tiết đơn hàng' });
  }
});

// API cập nhật thông tin user
app.put('/api/users/update', async (req, res) => {
  const { username, email, phone } = req.body;

  try {
    const [result] = await connection.promise().query(
      'UPDATE Users SET email = ?, phone = ? WHERE username = ?',
      [email, phone, username]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    }

    res.json({
      message: 'Cập nhật thông tin thành công',
      user: { username, email, phone }
    });
  } catch (error) {
    console.error('Update error:', error);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

app.put('/api/orders/update/:user_id', async (req, res) => {
  const user_id = req.params.user_id;
  const { status } = req.body;  // Lấy status từ request body

  try {
    const [result] = await connection.promise().query(
      'UPDATE Orders SET status_order = ? WHERE user_id = ?',
      [status, user_id]  // Truyền cả status và user_id vào query
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: `Không tìm thấy người dùng ${user_id}` });
    }

    res.json({
      message: `Cập nhật trạng thái thành công cho người dùng ${user_id}`,
      status: status
    });
  } catch (error) {
    console.error('Update error:', error);
    res.status(500).json({
      message: `Lỗi server khi cập nhật người dùng ${user_id}`,
      error: error.message
    });
  }
});

// API lấy danh sách đơn hàng
// Thêm vào file server.js

// API lấy danh sách đơn hàng
app.get('/api/orders', async (req, res) => {
  try {
    const [orders] = await connection.promise().query(`
      SELECT
              a.user_id,
              b.full_name as customerName,
              b.phone,
              a.status_order as status,
              a.order_date as date,
              SUM(c.quantity * c.price) as total
            FROM railway.Orders a
            INNER JOIN railway.Users b ON a.user_id = b.user_id
            INNER JOIN railway.OrdersDetail c ON a.order_id = c.order_id
            INNER JOIN railway.ProductDetail d ON c.product_detail_id = d.product_detail_id
            GROUP BY
              a.user_id,
              b.full_name,
              b.phone,
              a.status_order,
              a.order_date;
    `);

    // Format dữ liệu trả về
    const formattedOrders = orders.map(order => ({
      id: order.user_id,
      customerName: order.customerName,
      phone: order.phone,
      status: order.status,
      date: order.date.toISOString().split('T')[0],
      total: parseFloat(order.total)
    }));

    res.json(formattedOrders);

  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ message: 'Lỗi server khi lấy danh sách đơn hàng' });
  }
});



// API test kết nối
app.get('/api/test', (req, res) => {
  res.json({ message: 'Server is running!' });
});

const PORT = 3001;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});