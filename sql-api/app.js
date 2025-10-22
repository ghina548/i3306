const express = require('express');
const oracledb = require('oracledb');
const bcrypt = require('bcrypt');

const app = express();
app.use(express.json());

// Enable CORS for frontend communication
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  next();
});

// Your Oracle connection details
const dbConfig = {
  user: "GZlibrary",
  password: "GZ158196",
  connectString: "localhost:1521/XEPDB1"
};

// Existing genres endpoint
app.get('/genres', async (req, res) => {
  let conn;
  try {
    conn = await oracledb.getPool().getConnection();
    const result = await conn.execute(`SELECT * FROM genre`);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Login endpoint
app.post('/login', async (req, res) => {
  let conn;
  try {
    const { email, password } = req.body;

    console.log('Login attempt for:', email); // Debug log

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ 
        success: false, 
        message: 'Email and password are required' 
      });
    }

    // Get connection from pool
    conn = await oracledb.getPool().getConnection();

    // Query to find user by email
    const result = await conn.execute(
      `SELECT user_id, full_name, email, password_hash, role, active 
       FROM users 
       WHERE email = :email`,
      { email: email },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    console.log('Query result:', result.rows.length, 'users found'); // Debug log

    // Check if user exists
    if (result.rows.length === 0) {
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid email or password' 
      });
    }

    const user = result.rows[0];
    console.log('User found:', user.EMAIL); // Debug log

    // Check if account is active
    if (user.ACTIVE === 'N') {
      return res.status(403).json({ 
        success: false, 
        message: 'Account is inactive. Please contact support.' 
      });
    }

    // Compare password with hashed password in database
    console.log('Comparing passwords...'); // Debug log
    const passwordMatch = await bcrypt.compare(password, user.PASSWORD_HASH);
    console.log('Password match:', passwordMatch); // Debug log

    if (!passwordMatch) {
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid email or password' 
      });
    }

    // Login successful - return user data (without password)
    res.json({ 
      success: true, 
      message: 'Login successful',
      user: {
        userId: user.USER_ID,
        fullName: user.FULL_NAME,
        email: user.EMAIL,
        role: user.ROLE
      }
    });

  } catch (err) {
    console.error('Login error:', err); // Full error log
    res.status(500).json({ 
      success: false, 
      message: 'Server error during login',
      error: err.message // Include error message for debugging
    });
  } finally {
    if (conn) await conn.close();
  }
});

// Start server
async function start() {
  try {
    // Create connection pool
    await oracledb.createPool(dbConfig);
    console.log('Connected to Oracle Database!');
    
    // Start listening
    app.listen(3000, () => {
      console.log('Server running on http://localhost:3000');
    });
  } catch (err) {
    console.error('Connection failed:', err);
  }
}

start();