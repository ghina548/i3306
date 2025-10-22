const oracledb = require('oracledb');
const bcrypt = require('bcrypt');

const dbConfig = {
  user: "GZlibrary",
  password: "GZ158196",
  connectString: "localhost:1521/XEPDB1"
};

async function hashExistingPasswords() {
  let conn;
  try {
    // Connect to database
    conn = await oracledb.getConnection(dbConfig);
    console.log('✅ Connected to Oracle Database!');

    // Get all users with their current passwords
    const result = await conn.execute(
      `SELECT user_id, full_name, email, password_hash FROM users WHERE password_hash IS NOT NULL`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    console.log(`\n📊 Found ${result.rows.length} users with passwords to hash...\n`);

    if (result.rows.length === 0) {
      console.log('❌ No users found with passwords! Make sure password_hash column has data.');
      return;
    }

    // Hash each password and update
    let updatedCount = 0;
    for (const user of result.rows) {
      const currentPassword = user.PASSWORD_HASH;
      
      // Check if password is already hashed (bcrypt hashes start with $2b$ or $2a$)
      if (currentPassword.startsWith('$2b$') || currentPassword.startsWith('$2a$')) {
        console.log(`⏭️  Skipping ${user.EMAIL} - already hashed`);
        continue;
      }

      // Hash the plain text password
      const hashedPassword = await bcrypt.hash(currentPassword, 10);

      // Update the user's password in database
      await conn.execute(
        `UPDATE users 
         SET password_hash = :hashedPassword 
         WHERE user_id = :userId`,
        { 
          hashedPassword: hashedPassword, 
          userId: user.USER_ID 
        },
        { autoCommit: true }
      );

      updatedCount++;
      console.log(`✅ Hashed password for: ${user.FULL_NAME} (${user.EMAIL})`);
    }

    console.log(`\n🎉 Successfully hashed ${updatedCount} password(s)!`);

  } catch (err) {
    console.error('\n❌ Error:', err.message);
  } finally {
    if (conn) {
      await conn.close();
      console.log('\n🔌 Connection closed.');
    }
  }
}

// Run the script
hashExistingPasswords();