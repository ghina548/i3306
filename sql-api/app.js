const express = require('express');
const oracledb = require('oracledb');
const bcrypt = require('bcrypt');

const app = express();
app.use(express.json());

// Enable CORS for frontend communication
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS'); // ← Add this
  
  // Handle preflight
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  
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
// Get all books for homepage
// Get all books for homepage
app.get('/books', async (req, res) => {
  let connection;
  try {
    connection = await oracledb.getConnection(dbConfig);
    
    const result = await connection.execute(
      `SELECT 
        b.BOOK_ID,
        b.TITLE,
        b.PUB_YEAR,
        b.PAGES,
        b.PRICE_PER_MONTH,
        b.STOCK,
        (b.STOCK - COUNT(CASE WHEN l.status IN ('ongoing', 'overdue') THEN 1 END)) as AVAILABLE,
        b.GENRE_ID,
        g.NAME as GENRE_NAME,
        b.SERIES_NAME,
        b.SERIES_NUMBER,
        b.COVER_URL,
        DBMS_LOB.SUBSTR(b.SUMMARY, 4000, 1) as SUMMARY,
        LISTAGG(DISTINCT a.NAME, ', ') WITHIN GROUP (ORDER BY a.NAME) as AUTHORS,
        MIN(a.AUTHOR_ID) as AUTHOR_ID
      FROM BOOK b
      LEFT JOIN GENRE g ON b.GENRE_ID = g.GENRE_ID
      LEFT JOIN BOOK_AUTHOR ba ON b.BOOK_ID = ba.BOOK_ID
      LEFT JOIN AUTHOR a ON ba.AUTHOR_ID = a.AUTHOR_ID
      LEFT JOIN LOAN l ON b.BOOK_ID = l.BOOK_ID AND l.status IN ('ongoing', 'overdue')
      GROUP BY b.BOOK_ID, b.TITLE, b.PUB_YEAR, b.PAGES, 
               b.PRICE_PER_MONTH, b.STOCK, b.GENRE_ID, g.NAME, 
               b.SERIES_NAME, b.SERIES_NUMBER, b.COVER_URL, 
               DBMS_LOB.SUBSTR(b.SUMMARY, 4000, 1)
      ORDER BY b.TITLE`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json({
      success: true,
      books: result.rows
    });

  } catch (error) {
    console.error('Error fetching books:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching books',
      error: error.message
    });
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error('Error closing connection:', err);
      }
    }
  }
});
// Get average rating for each book
app.get('/ratings', async (req, res) => {
  let connection;
  try {
    connection = await oracledb.getConnection(dbConfig);
    
    const result = await connection.execute(
      `SELECT 
        BOOK_ID,
        ROUND(AVG(RATING), 1) as AVG_RATING,
        COUNT(*) as RATING_COUNT
      FROM RATING
      GROUP BY BOOK_ID`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json({
      success: true,
      ratings: result.rows
    });

  } catch (error) {
    console.error('Error fetching ratings:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching ratings'
    });
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error('Error closing connection:', err);
      }
    }
  }
});

// Get reviews for a specific book
app.get('/reviews/:bookId', async (req, res) => {
  let connection;
  try {
    connection = await oracledb.getConnection(dbConfig);
    
    const result = await connection.execute(
      `SELECT 
        r.RATING_ID,
        r.RATING,
        TO_CHAR(r.REVIEW_TEXT) as REVIEW_TEXT,
        r.RATING_DATE,
        u.FULL_NAME
      FROM RATING r
      JOIN USERS u ON r.USER_ID = u.USER_ID
      WHERE r.BOOK_ID = :bookId
      ORDER BY r.RATING_DATE DESC`,
      [req.params.bookId],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json({
      success: true,
      reviews: result.rows
    });

  } catch (error) {
    console.error('Error fetching reviews:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching reviews'
    });
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error('Error closing connection:', err);
      }
    }
  }
});
// Add a new review (for clients)
app.post('/reviews', async (req, res) => {
  let conn;
  try {
    const { userId, bookId, rating, reviewText } = req.body;
    
    // Validate input
    if (!userId || !bookId || !rating) {
      return res.status(400).json({ 
        success: false, 
        message: 'User ID, Book ID, and Rating are required' 
      });
    }

    if (rating < 1 || rating > 5) {
      return res.status(400).json({ 
        success: false, 
        message: 'Rating must be between 1 and 5' 
      });
    }
    
    conn = await oracledb.getPool().getConnection();
    
    // Check if user already reviewed this book
    const existingReview = await conn.execute(
      `SELECT rating_id FROM rating WHERE user_id = :userId AND book_id = :bookId`,
      { userId: userId, bookId: bookId },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    if (existingReview.rows.length > 0) {
      return res.status(400).json({ 
        success: false, 
        message: 'You have already reviewed this book' 
      });
    }

    // Get next rating ID
    const maxId = await conn.execute(
      `SELECT NVL(MAX(rating_id), 0) as max_id FROM rating`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const newRatingId = maxId.rows[0].MAX_ID + 1;

    // Insert review
    await conn.execute(
      `INSERT INTO rating (rating_id, user_id, book_id, rating, review_text, rating_date)
       VALUES (:ratingId, :userId, :bookId, :rating, :reviewText, SYSDATE)`,
      {
        ratingId: newRatingId,
        userId: userId,
        bookId: bookId,
        rating: rating,
        reviewText: reviewText || null
      },
      { autoCommit: true }
    );
    
    res.json({ 
      success: true, 
      message: 'Review added successfully!',
      ratingId: newRatingId
    });
  } catch (err) {
    console.error('Error adding review:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  } finally {
    if (conn) await conn.close();
  }
});
// Get all authors for homepage
app.get('/authors', async (req, res) => {
  let connection;
  try {
    connection = await oracledb.getConnection(dbConfig);
    
    const result = await connection.execute(
      `SELECT 
        AUTHOR_ID,
        NAME,
        NATIONALITY,
        TO_CHAR(BIO) as BIO,
        BIRTH_YEAR,
        DEATH_YEAR
      FROM AUTHOR
      ORDER BY NAME`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json({
      success: true,
      authors: result.rows
    });

  } catch (error) {
    console.error('Error fetching authors:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching authors'
    });
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error('Error closing connection:', err);
      }
    }
  }
});
// Client view endpoint - get their own loans
app.get('/client/loans/:userId', async (req, res) => {
  let conn;
  try {
    const { userId } = req.params;
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT loan_id, title, loan_date, due_date, return_date, status, fine_amount
       FROM loan l
       JOIN book b ON l.book_id = b.book_id
       WHERE l.user_id = :userId
       ORDER BY loan_date DESC`,
      { userId: userId },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, loans: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Librarian view endpoint - get all active loans
app.get('/librarian/loans', async (req, res) => {
  let conn;
  try {
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT l.loan_id, u.full_name, u.email, b.title, l.loan_date, l.due_date, l.status
       FROM loan l
       JOIN users u ON l.user_id = u.user_id
       JOIN book b ON l.book_id = b.book_id
       WHERE l.status IN ('ongoing', 'overdue')
       ORDER BY l.due_date ASC`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, loans: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Librarian stats
app.get('/librarian/stats', async (req, res) => {
  let conn;
  try {
    conn = await oracledb.getPool().getConnection();
    
    // Today's loans
    const todayLoans = await conn.execute(
      `SELECT COUNT(*) as total FROM loan WHERE TRUNC(loan_date) = TRUNC(SYSDATE)`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Today's returns
    const todayReturns = await conn.execute(
      `SELECT COUNT(*) as total FROM loan WHERE TRUNC(return_date) = TRUNC(SYSDATE)`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Active loans
    const activeLoans = await conn.execute(
      `SELECT COUNT(*) as total FROM loan WHERE status IN ('ongoing', 'overdue')`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Overdue
    const overdueCount = await conn.execute(
      `SELECT COUNT(*) as total FROM loan WHERE status = 'overdue'`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Pending reservations
    const pendingReservations = await conn.execute(
      `SELECT COUNT(*) as total FROM reservation WHERE status = 'pending'`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json({
      success: true,
      stats: {
        todayLoans: todayLoans.rows[0].TOTAL,
        todayReturns: todayReturns.rows[0].TOTAL,
        activeLoans: activeLoans.rows[0].TOTAL,
        overdueCount: overdueCount.rows[0].TOTAL,
        pendingReservations: pendingReservations.rows[0].TOTAL
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Active loans for librarian
app.get('/librarian/active-loans', async (req, res) => {
  let conn;
  try {
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT l.loan_id, u.full_name, u.email, b.title, l.loan_date, l.due_date, l.status, l.fine_amount
       FROM loan l
       JOIN users u ON l.user_id = u.user_id
       JOIN book b ON l.book_id = b.book_id
       WHERE l.status IN ('ongoing', 'overdue')
       ORDER BY l.due_date ASC`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, loans: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Search user
app.get('/librarian/search-user', async (req, res) => {
  let conn;
  try {
    const query = req.query.q;
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT u.user_id, u.full_name, u.email, u.active,
              COUNT(l.loan_id) as active_loans,
              SUM(l.fine_amount) as total_fines
       FROM users u
       LEFT JOIN loan l ON u.user_id = l.user_id AND l.status IN ('ongoing', 'overdue')
       WHERE u.role = 'client' AND (LOWER(u.full_name) LIKE LOWER(:query) OR LOWER(u.email) LIKE LOWER(:query))
       GROUP BY u.user_id, u.full_name, u.email, u.active`,
      { query: `%${query}%` },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, users: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Search book
app.get('/librarian/search-book', async (req, res) => {
  let conn;
  try {
    const query = req.query.q;
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT b.book_id, b.title, b.stock,
              b.stock - COUNT(CASE WHEN l.status IN ('ongoing', 'overdue') THEN 1 END) as available
       FROM book b
       LEFT JOIN loan l ON b.book_id = l.book_id
       WHERE LOWER(b.title) LIKE LOWER(:query) OR TO_CHAR(b.book_id) LIKE :query
       GROUP BY b.book_id, b.title, b.stock`,
      { query: `%${query}%` },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, books: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Process loan
// Process loan
app.post('/librarian/process-loan', async (req, res) => {
  let conn;
  try {
    const { userEmail, bookId, duration } = req.body;
    
    conn = await oracledb.getPool().getConnection();
    
    // Get user ID
    const userResult = await conn.execute(
      `SELECT user_id FROM users WHERE email = :email`,
      { email: userEmail },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const userId = userResult.rows[0].USER_ID;

    // Check book availability - IMPROVED VERSION
    const bookCheck = await conn.execute(
      `SELECT 
         b.book_id,
         b.stock,
         b.stock - COUNT(CASE WHEN l.status IN ('ongoing', 'overdue') THEN 1 END) as available
       FROM book b
       LEFT JOIN loan l ON b.book_id = l.book_id AND l.status IN ('ongoing', 'overdue')
       WHERE b.book_id = :bookId
       GROUP BY b.book_id, b.stock`,
      { bookId: bookId },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    if (bookCheck.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Book not found' });
    }

    const availableCopies = bookCheck.rows[0].AVAILABLE;
    
    console.log(`Book ${bookId}: Stock=${bookCheck.rows[0].STOCK}, Available=${availableCopies}`);

    if (availableCopies <= 0) {
      return res.status(400).json({ 
        success: false, 
        message: 'Book not available - all copies are currently on loan' 
      });
    }

    // Get next loan ID
    const maxId = await conn.execute(
      `SELECT MAX(loan_id) as max_id FROM loan`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    const newLoanId = (maxId.rows[0].MAX_ID || 0) + 1;

    // Calculate due date
    const dueDate = new Date();
    dueDate.setMonth(dueDate.getMonth() + parseInt(duration));

    // Insert loan (DO NOT UPDATE STOCK)
    await conn.execute(
      `INSERT INTO loan (loan_id, user_id, book_id, loan_date, due_date, status)
       VALUES (:loanId, :userId, :bookId, SYSDATE, :dueDate, 'ongoing')`,
      {
        loanId: newLoanId,
        userId: userId,
        bookId: bookId,
        dueDate: dueDate
      },
      { autoCommit: true }
    );
    
    res.json({ success: true, message: 'Loan processed successfully', loanId: newLoanId });
  } catch (err) {
    console.error('Loan processing error:', err);
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Process return
// Process return
app.post('/librarian/process-return', async (req, res) => {
  let conn;
  try {
    const { loanId, fine } = req.body;
    
    conn = await oracledb.getPool().getConnection();
    
    await conn.execute(
      `UPDATE loan 
       SET return_date = SYSDATE, 
           status = 'returned',
           fine_amount = :fine
       WHERE loan_id = :loanId`,
      { loanId: loanId, fine: fine || 0 },
      { autoCommit: true }
    );
    
    res.json({ success: true, message: 'Return processed successfully' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Get reservations
app.get('/librarian/reservations', async (req, res) => {
  let conn;
  try {
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT r.reservation_id, u.full_name, u.email, b.title, r.reservation_date, r.status
       FROM reservation r
       JOIN users u ON r.user_id = u.user_id
       JOIN book b ON r.book_id = b.book_id
       WHERE r.status IN ('pending', 'fulfilled')
       ORDER BY r.reservation_date DESC`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, reservations: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Fulfill reservation
app.post('/librarian/reservations/:id/fulfill', async (req, res) => {
  let conn;
  try {
    const { id } = req.params;
    conn = await oracledb.getPool().getConnection();
    
    await conn.execute(
      `UPDATE reservation SET status = 'fulfilled' WHERE reservation_id = :id`,
      { id: id },
      { autoCommit: true }
    );
    
    res.json({ success: true, message: 'Reservation fulfilled' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Cancel reservation
app.post('/librarian/reservations/:id/cancel', async (req, res) => {
  let conn;
  try {
    const { id } = req.params;
    conn = await oracledb.getPool().getConnection();
    
    await conn.execute(
      `UPDATE reservation SET status = 'cancelled' WHERE reservation_id = :id`,
      { id: id },
      { autoCommit: true }
    );
    
    res.json({ success: true, message: 'Reservation cancelled' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Manager view endpoint - get statistics
app.get('/manager/stats', async (req, res) => {
  let conn;
  try {
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT 
          g.name AS genre_name,
          COUNT(l.loan_id) AS total_loans,
          SUM(l.fine_amount) AS total_fines
       FROM genre g
       LEFT JOIN book b ON g.genre_id = b.genre_id
       LEFT JOIN loan l ON b.book_id = l.book_id
       GROUP BY g.name
       ORDER BY total_loans DESC`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, stats: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});
// Get client reservations
app.get('/client/reservations/:userId', async (req, res) => {
  let conn;
  try {
    const { userId } = req.params;
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT r.reservation_id, b.title, r.reservation_date, r.status
       FROM reservation r
       JOIN book b ON r.book_id = b.book_id
       WHERE r.user_id = :userId
       ORDER BY r.reservation_date DESC`,
      { userId: userId },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, reservations: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Get client reading stats
app.get('/client/stats/:userId', async (req, res) => {
  let conn;
  try {
    const { userId } = req.params;
    conn = await oracledb.getPool().getConnection();
    
    // Get books read (returned loans)
    const booksRead = await conn.execute(
      `SELECT COUNT(*) as total FROM loan WHERE user_id = :userId AND return_date IS NOT NULL`,
      { userId: userId },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Get average rating
    const avgRating = await conn.execute(
      `SELECT ROUND(AVG(rating), 1) as avg_rating FROM rating WHERE user_id = :userId`,
      { userId: userId },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Get favorite genre
    const favGenre = await conn.execute(
      `SELECT g.name, COUNT(*) as count
       FROM loan l
       JOIN book b ON l.book_id = b.book_id
       JOIN genre g ON b.genre_id = g.genre_id
       WHERE l.user_id = :userId
       GROUP BY g.name
       ORDER BY count DESC
       FETCH FIRST 1 ROW ONLY`,
      { userId: userId },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ 
      success: true, 
      stats: {
        totalBooksRead: booksRead.rows[0]?.TOTAL || 0,
        averageRating: avgRating.rows[0]?.AVG_RATING || 0,
        favoriteGenre: favGenre.rows[0]?.NAME || 'N/A'
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Manager Overview
app.get('/manager/overview', async (req, res) => {
  let conn;
  try {
    conn = await oracledb.getPool().getConnection();
    
    // Total books
    const totalBooks = await conn.execute(
      `SELECT COUNT(*) as total FROM book`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Total active users
    const totalUsers = await conn.execute(
      `SELECT COUNT(*) as total FROM users WHERE active = 'Y' AND role = 'client'`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Active loans
    const activeLoans = await conn.execute(
      `SELECT COUNT(*) as total FROM loan WHERE status IN ('ongoing', 'overdue')`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Overdue loans
    const overdueLoans = await conn.execute(
      `SELECT COUNT(*) as total FROM loan WHERE status = 'overdue'`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Total revenue (all fines collected)
    const totalRevenue = await conn.execute(
      `SELECT SUM(fine_amount) as total FROM loan WHERE return_date IS NOT NULL`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    // Pending fines
    const pendingFines = await conn.execute(
      `SELECT SUM(fine_amount) as total FROM loan WHERE status IN ('ongoing', 'overdue') AND fine_amount > 0`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    res.json({
      success: true,
      overview: {
        totalBooks: totalBooks.rows[0].TOTAL,
        totalUsers: totalUsers.rows[0].TOTAL,
        activeLoans: activeLoans.rows[0].TOTAL,
        overdueLoans: overdueLoans.rows[0].TOTAL,
        totalRevenue: (totalRevenue.rows[0].TOTAL || 0).toFixed(2),
        pendingFines: (pendingFines.rows[0].TOTAL || 0).toFixed(2)
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Most popular books
app.get('/manager/popular-books', async (req, res) => {
  let conn;
  try {
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT b.title, COUNT(l.loan_id) as loan_count
       FROM book b
       LEFT JOIN loan l ON b.book_id = l.book_id
       GROUP BY b.title
       ORDER BY loan_count DESC
       FETCH FIRST 5 ROWS ONLY`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, books: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Genre statistics (reuse existing manager endpoint)
app.get('/manager/genre-stats', async (req, res) => {
  let conn;
  try {
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT 
          g.name AS genre_name,
          COUNT(l.loan_id) AS total_loans,
          SUM(l.fine_amount) AS total_fines
       FROM genre g
       LEFT JOIN book b ON g.genre_id = b.genre_id
       LEFT JOIN loan l ON b.book_id = l.book_id
       GROUP BY g.name
       ORDER BY total_loans DESC`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, genres: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// All books for management
app.get('/manager/books', async (req, res) => {
  let conn;
  try {
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT book_id, title, pub_year, stock, price_per_month
       FROM book
       ORDER BY title`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, books: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});
// Delete book
// Delete book
app.delete('/manager/books/:bookId', async (req, res) => {
  let conn;
  try {
    const { bookId } = req.params;
    conn = await oracledb.getPool().getConnection();
    
    // First delete from book_author
    await conn.execute(
      `DELETE FROM BOOK_AUTHOR WHERE BOOK_ID = :bookId`,
      { bookId: bookId },
      { autoCommit: false }
    );
    
    // Then delete the book
    await conn.execute(
      `DELETE FROM BOOK WHERE BOOK_ID = :bookId`,
      { bookId: bookId },
      { autoCommit: true }
    );
    
    res.json({ success: true, message: 'Book deleted successfully' });
  } catch (err) {
    console.error('Error deleting book:', err);
    if (conn) {
      try {
        await conn.rollback();
      } catch (rollbackErr) {
        console.error('Rollback error:', rollbackErr);
      }
    }
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// User activity
app.get('/manager/user-activity', async (req, res) => {
  let conn;
  try {
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT u.full_name, b.title, l.loan_date, l.status
       FROM loan l
       JOIN users u ON l.user_id = u.user_id
       JOIN book b ON l.book_id = b.book_id
       ORDER BY l.loan_date DESC
       FETCH FIRST 20 ROWS ONLY`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, activity: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});
// Get single book details for editing
app.get('/manager/books/:bookId', async (req, res) => {
  let conn;
  try {
    const { bookId } = req.params;
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT 
        b.BOOK_ID,
        b.TITLE,
        b.PUB_YEAR,
        b.PAGES,
        b.STOCK,
        b.GENRE_ID,
        b.PRICE_PER_MONTH,
        b.SERIES_NAME,
        b.SERIES_NUMBER,
        DBMS_LOB.SUBSTR(b.SUMMARY, 4000, 1) as SUMMARY,
        a.NAME as AUTHOR_NAME,
        a.NATIONALITY as AUTHOR_NATIONALITY,
        TO_CHAR(a.BIO) as AUTHOR_BIO,
        a.BIRTH_YEAR as AUTHOR_BIRTH_YEAR
      FROM BOOK b
      LEFT JOIN BOOK_AUTHOR ba ON b.BOOK_ID = ba.BOOK_ID
      LEFT JOIN AUTHOR a ON ba.AUTHOR_ID = a.AUTHOR_ID
      WHERE b.BOOK_ID = :bookId`,
      { bookId: bookId },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Book not found' });
    }
    
    res.json({ success: true, book: result.rows[0] });
  } catch (err) {
    console.error('Error fetching book:', err);
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});
// Top users
app.get('/manager/top-users', async (req, res) => {
  let conn;
  try {
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT 
          u.full_name,
          u.email,
          COUNT(l.loan_id) as total_loans,
          SUM(CASE WHEN l.return_date IS NOT NULL THEN 1 ELSE 0 END) as returned_loans,
          SUM(l.fine_amount) as total_fines
       FROM users u
       LEFT JOIN loan l ON u.user_id = l.user_id
       WHERE u.role = 'client'
       GROUP BY u.full_name, u.email
       ORDER BY total_loans DESC
       FETCH FIRST 10 ROWS ONLY`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, users: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Inventory status
app.get('/manager/inventory', async (req, res) => {
  let conn;
  try {
    conn = await oracledb.getPool().getConnection();
    
    const result = await conn.execute(
      `SELECT 
          b.title,
          b.stock as total_stock,
          b.stock - COUNT(CASE WHEN l.status IN ('ongoing', 'overdue') THEN 1 END) as available,
          COUNT(CASE WHEN l.status IN ('ongoing', 'overdue') THEN 1 END) as on_loan
       FROM book b
       LEFT JOIN loan l ON b.book_id = l.book_id
       GROUP BY b.title, b.stock
       ORDER BY available ASC`,
      {},
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    res.json({ success: true, inventory: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// Add new book (UPDATED - handles new authors too)
// Add new book (FIXED - better error handling)
app.post('/manager/books', async (req, res) => {
  let conn;
  try {
    const { 
      bookId,
      title, 
      authorName,
      authorBio,
      authorNationality,
      authorBirthYear,
      genreId, 
      pubYear, 
      pages, 
      stock, 
      pricePerMonth,
      summary,
      coverUrl,
      seriesName,
      seriesNumber
    } = req.body;
    
    console.log('=== ADD BOOK REQUEST ===');
    console.log('Book ID:', bookId);
    console.log('Title:', title);
    console.log('Author Name:', authorName);
    console.log('Author Bio:', authorBio);
    console.log('Genre ID:', genreId);
    
    // Validate required fields
    if (!bookId || !title || !authorName || !genreId || !stock || !pricePerMonth) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields'
      });
    }
    
    conn = await oracledb.getPool().getConnection();
    
    let authorId = null;
    
    // Check if author exists
    console.log('Checking if author exists:', authorName);
    const existingAuthor = await conn.execute(
      `SELECT AUTHOR_ID FROM AUTHOR WHERE UPPER(NAME) = UPPER(:name)`,
      { name: authorName.trim() },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    if (existingAuthor.rows.length > 0) {
      // Use existing author
      authorId = existingAuthor.rows[0].AUTHOR_ID;
      console.log('Found existing author with ID:', authorId);
    } else {
      // Create new author
      console.log('Creating new author...');
      
      const maxAuthorId = await conn.execute(
        `SELECT NVL(MAX(AUTHOR_ID), 110) as MAX_ID FROM AUTHOR`,
        {},
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      authorId = maxAuthorId.rows[0].MAX_ID + 1;
      
      console.log('New author ID will be:', authorId);
      
      await conn.execute(
        `INSERT INTO AUTHOR (AUTHOR_ID, NAME, NATIONALITY, BIO, BIRTH_YEAR)
         VALUES (:id, :name, :nationality, :bio, :birthYear)`,
        {
          id: authorId,
          name: authorName.trim(),
          nationality: authorNationality || null,
          bio: authorBio || null,
          birthYear: authorBirthYear || null
        },
        { autoCommit: false }
      );
      
      console.log('New author created successfully');
    }
    
    // Verify authorId is valid
    if (!authorId) {
      throw new Error('Author ID is null - author creation/lookup failed');
    }
    
    // Check if book ID already exists
    console.log('Checking if book ID exists:', bookId);
    const existingBook = await conn.execute(
      `SELECT BOOK_ID FROM BOOK WHERE BOOK_ID = :id`,
      { id: bookId },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    if (existingBook.rows.length > 0) {
      await conn.rollback();
      return res.status(400).json({ 
        success: false, 
        message: `Book ID ${bookId} already exists. Please use a different ID.` 
      });
    }
    
    console.log('Inserting book...');
    
    // Insert book
    await conn.execute(
      `INSERT INTO BOOK (BOOK_ID, TITLE, PUB_YEAR, PAGES, STOCK, GENRE_ID, PRICE_PER_MONTH, SUMMARY, SERIES_NAME, SERIES_NUMBER, COVER_URL)
       VALUES (:id, :title, :year, :pages, :stock, :genreId, :price, :summary, :seriesName, :seriesNumber, :coverUrl)`,
      {
        id: bookId,
        title: title.trim(),
        year: pubYear || null,
        pages: pages || null,
        stock: stock,
        genreId: genreId,
        price: pricePerMonth,
        summary: summary || null,
        seriesName: seriesName || null,
        seriesNumber: seriesNumber || null,
        coverUrl: coverUrl || null 
      },
      { autoCommit: false }
    );
    
    console.log('Book inserted successfully');

    // Link book to author
    console.log('Linking book to author. Book ID:', bookId, 'Author ID:', authorId);
    
    await conn.execute(
      `INSERT INTO BOOK_AUTHOR (BOOK_ID, AUTHOR_ID) VALUES (:bookId, :authorId)`,
      { 
        bookId: bookId, 
        authorId: authorId 
      },
      { autoCommit: true }
    );
    
    console.log('Book-Author link created successfully');
    console.log('=== BOOK ADDED SUCCESSFULLY ===');
    
    res.json({ 
      success: true, 
      message: 'Book added successfully!',
      bookId: bookId,
      authorId: authorId,
      newAuthor: existingAuthor.rows.length === 0
    });
    
  } catch (err) {
    console.error('=== ERROR ADDING BOOK ===');
    console.error('Error details:', err);
    
    if (conn) {
      try {
        await conn.rollback();
        console.log('Transaction rolled back');
      } catch (rollbackErr) {
        console.error('Rollback error:', rollbackErr);
      }
    }
    
    res.status(500).json({ 
      success: false, 
      message: err.message || 'Error adding book',
      error: err.message
    });
  } finally {
    if (conn) {
      try {
        await conn.close();
      } catch (closeErr) {
        console.error('Connection close error:', closeErr);
      }
    }
  }
});
//Update book endpoint (similar comprehensive update)
app.put('/manager/books/:bookId', async (req, res) => {
  let conn;
  try {
    const { bookId } = req.params;
    const { 
      title, 
      authorName,
      authorBio,
      authorNationality,
      authorBirthYear,
      genreId, 
      pubYear, 
      pages, 
      stock, 
      pricePerMonth,
      summary,
      coverUrl, 
      seriesName,
      seriesNumber
    } = req.body;
    
    conn = await oracledb.getPool().getConnection();
    
    let authorId;
    
    // Check if author exists
    const existingAuthor = await conn.execute(
      `SELECT AUTHOR_ID FROM AUTHOR WHERE UPPER(NAME) = UPPER(:name)`,
      { name: authorName },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    if (existingAuthor.rows.length > 0) {
      authorId = existingAuthor.rows[0].AUTHOR_ID;
    } else {
      // Create new author
      const maxAuthorId = await conn.execute(
        `SELECT MAX(AUTHOR_ID) as MAX_ID FROM AUTHOR`,
        {},
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      authorId = (maxAuthorId.rows[0].MAX_ID || 110) + 1;
      
      await conn.execute(
        `INSERT INTO AUTHOR (AUTHOR_ID, NAME, NATIONALITY, BIO, BIRTH_YEAR)
         VALUES (:id, :name, :nationality, :bio, :birthYear)`,
        {
          id: authorId,
          name: authorName,
          nationality: authorNationality || null,
          bio: authorBio || null,
          birthYear: authorBirthYear || null
        },
        { autoCommit: false }
      );
    }
    
    // Update book
    await conn.execute(
      `UPDATE BOOK 
       SET TITLE = :title,
           PUB_YEAR = :year,
           PAGES = :pages,
           STOCK = :stock,
           GENRE_ID = :genreId,
           PRICE_PER_MONTH = :price,
           SUMMARY = :summary,
           SERIES_NAME = :seriesName,
           SERIES_NUMBER = :seriesNumber,
           COVER_URL = :coverUrl
       WHERE BOOK_ID = :bookId`,
      {
        bookId: bookId,
        title: title,
        year: pubYear || null,
        pages: pages || null,
        stock: stock,
        genreId: genreId,
        price: pricePerMonth,
        summary: summary || null,
        seriesName: seriesName || null,
        seriesNumber: seriesNumber || null,
        coverUrl: coverUrl || null 
      },
      { autoCommit: false }
    );

    // Update author link
    await conn.execute(
      `DELETE FROM BOOK_AUTHOR WHERE BOOK_ID = :bookId`,
      { bookId: bookId },
      { autoCommit: false }
    );
    
    await conn.execute(
      `INSERT INTO BOOK_AUTHOR (BOOK_ID, AUTHOR_ID) VALUES (:bookId, :authorId)`,
      { bookId: bookId, authorId: authorId },
      { autoCommit: true }
    );
    
    res.json({ success: true, message: 'Book updated successfully!' });
  } catch (err) {
    if (conn) {
      try {
        await conn.rollback();
      } catch (rollbackErr) {
        console.error('Rollback error:', rollbackErr);
      }
    }
    res.status(500).json({ success: false, error: err.message });
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