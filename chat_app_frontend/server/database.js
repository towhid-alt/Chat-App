const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres', //database username
  host: 'localhost',
  database: 'postgres', // Use default database first
  password: 'sheik7pro', // Use the password you set during installation
  port: 5432,
});

// Test connection with better error handling
pool.on('connect', () => {
  console.log('✅ Database connected successfully');
});

pool.on('error', (err) => {
  console.log('❌ Database connection error:', err);
});

// Test connection
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.log('Database test query failed:', err);
  } else {
    console.log('Database test query successful at:', res.rows[0].now);
  }
});

module.exports = pool;