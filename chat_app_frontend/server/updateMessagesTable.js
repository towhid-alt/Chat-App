//We need to add a type column to distinguish between text and image messages.
const pool = require('./database');

async function updateTable() {
  try {
    await pool.query(`
      ALTER TABLE messages ADD COLUMN type VARCHAR(10) DEFAULT 'text'
    `);
    console.log('✅ Added type column to messages table');
  } catch (err) {
    console.log('Table already updated or error:', err);
  }
}

updateTable();