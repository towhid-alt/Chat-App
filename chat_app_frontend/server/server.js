const express = require('express')
const pool = require('./database')
const app = express()
const cors = require('cors')

//URL -> http://localhost:8383
const PORT = 8383

//Middleware
app.use(cors()) // Allows your flutter app to connect
app.use(express.json())

// Temporary storage (we'll replace with database later)
let users = []

// Route for testing
app.get('/api/test', (req, res) => {
    res.json({ message: 'Server is working!' })
})


app.post('/api/signup', async (req, res) => {
    const { username, password } = req.body

   try {
    // Check if user exists
    const userExists = await pool.query(
      'SELECT * FROM users WHERE username = $1',
      [username]
    )

    if (userExists.rows.length > 0) {
      return res.status(400).json({ error: 'User already exists' })
    }

    // Insert new user (we'll hash password later)
    const newUser = await pool.query(
      'INSERT INTO users (username, password) VALUES ($1, $2) RETURNING id, username',
      [username, password]
    )

    console.log('New user signed up:', username)
    res.status(201).json({ 
      message: 'User created successfully',
      user: newUser.rows[0]
    })
  } catch (err) {
    console.log('Database error:', err)
    res.status(500).json({ error: 'Internal server error' })
  }
})

app.post('/api/login', async (req, res) => {
    const { username, password } = req.body

     try {
    // Find user
    const user = await pool.query(
      'SELECT * FROM users WHERE username = $1',
      [username]
    )

    if (user.rows.length === 0) {
      return res.status(400).json({ error: 'User not found' })
    }

    // Check password (plain text for now - we'll hash later)
    if (user.rows[0].password !== password) {
      return res.status(400).json({ error: 'Invalid password' })
    }

    console.log('User logged in:', username)
    res.json({ 
      message: 'Login successful', 
      user: { 
        id: user.rows[0].id, 
        username: user.rows[0].username 
      } 
    })
  } catch (err) {
    console.log('Database error:', err)
    res.status(500).json({ error: 'Internal server error' })
  }
})


//Route to view all users
app.get('/api/users', async (req, res) => {
  try {
    // Get all users from database
    const allUsers = await pool.query(
      'SELECT id, username FROM users ORDER BY username'
    )
    
    res.json({
      users: allUsers.rows
    })
  } catch (err) {
    console.log('Error fetching users:', err)
    res.status(500).json({ error: 'Failed to fetch users' })
  }
})

app.listen(PORT, () => console.log(`Server has started on: ${PORT}`))