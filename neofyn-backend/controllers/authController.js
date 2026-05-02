const pool = require('../config/db');
const bcrypt = require('bcryptjs');
const { generateAccessToken, generateRefreshToken } = require('../utils/token');

exports.register = async (req, res) => {
  const client = await pool.connect();
  try {
    const { first_name, last_name, email, phone, password, business_name, business_type,
            business_address, city, state, pin_code, aadhaar_number, pan_number } = req.body;

    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await client.query(
      `INSERT INTO users (first_name, last_name, email, phone, password, business_name,
       business_type, business_address, city, state, pin_code, aadhaar_number, pan_number, role)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, 'pending') RETURNING *`,
      [first_name, last_name, email, phone, hashedPassword, business_name,
       business_type, business_address, city, state, pin_code, aadhaar_number, pan_number]
    );

    res.status(201).json({ success: true, message: "Verification pending", user: result.rows[0] });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  } finally { client.release(); }
};


exports.login = async (req, res) => {
  // Add debug logging
  console.log('===== LOGIN REQUEST RECEIVED =====');
  console.log('Request headers:', req.headers);
  console.log('Request body:', req.body);
  console.log('Request body type:', typeof req.body);
  
  // Check if body exists
  if (!req.body) {
    console.log('ERROR: req.body is undefined or null');
    return res.status(400).json({ 
      success: false, 
      message: 'Request body is missing. Please send JSON data.' 
    });
  }
  
  const { phone, password } = req.body;
  
  console.log('Phone extracted:', phone);
  console.log('Password present:', !!password);
  
  if (!phone || !password) {
    console.log('ERROR: Missing phone or password');
    return res.status(400).json({ 
      success: false, 
      message: 'Phone number and password are required' 
    });
  }

  try {
    const result = await pool.query('SELECT * FROM users WHERE phone = $1', [phone]);
    const user = result.rows[0];

    if (!user) {
      console.log('User not found:', phone);
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      console.log('Password mismatch for user:', phone);
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    if (user.role === 'pending') {
      return res.status(403).json({ message: 'Account pending approval' });
    }
    if (user.role === 'rejected') {
      return res.status(403).json({ message: 'Application not approved' });
    }

    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    await pool.query(
      'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, NOW() + interval \'7 days\')',
      [user.id, refreshToken]
    );

    res.status(200).json({
      success: true,
      message: 'Login successful',
      user: {
        id: user.id,
        name: `${user.first_name} ${user.last_name}`,
        email: user.email,
        phone: user.phone,
        role: user.role
      },
      accessToken,
      refreshToken
    });

  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};