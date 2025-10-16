const express = require('express')
const pool = require('./database')
const app = express()
const cors = require('cors')
const http = require('http')
const { Server } = require('socket.io')

// Create HTTP server
const server = http.createServer(app)

// Socket.io setup
const io = new Server(server, {
  cors: {
    origin: "*", // Allow all origins for now
    // Allows connections from ANY website/domain
    methods: ["GET", "POST"]//Only allow GET and POST requests
  }
})

//URL -> http://localhost:8383
const PORT = 8383

//Middleware
app.use(cors()) // Allows your flutter app to connect
app.use(express.json())

// Socket.io connection handling
io.on('connection', (socket) => {
  console.log('User connected:', socket.id)

   // Join a room based on user ID
  socket.on('join_chat', (userId) => {
    socket.join(userId)
    console.log(`User ${userId} joined their room`)

     socket.on('send_message', async (data) => {
    try {
      // Save to database
      const newMessage = await pool.query(
        'INSERT INTO messages (sender_id, receiver_id, message) VALUES ($1, $2, $3) RETURNING *',
        [data.senderId, data.receiverId, data.message]
      )

      // Emit to both users
      io.to(data.senderId.toString()).emit('receive_message', newMessage.rows[0])
      io.to(data.receiverId.toString()).emit('receive_message', newMessage.rows[0])
      
      console.log('Message sent and broadcasted')
    }  catch (err) {
      console.log('Error sending message:', err)
    }
})
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id)
  })
})

// Change app.listen to server.listen
server.listen(PORT, () => console.log(`Server running on: ${PORT}`))

})

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

app.post('/api/messages', async (req, res) => {
  const { sender_id, receiver_id, message } = req.body;

  try {
    const newMessage = await pool.query(
      'INSERT INTO messages (sender_id, receiver_id, message) VALUES ($1, $2, $3) RETURNING *',
      [sender_id, receiver_id, message]
    );

    res.status(201).json({
      message: 'Message sent successfully',
      sentMessage: newMessage.rows[0]
    });
  } catch (err) {
    console.log('Error sending message:', err);
    res.status(500).json({ error: 'Failed to send message' });
  }
});

app.get('/api/messages/:user1_id/:user2_id', async (req, res) => {
  const { user1_id, user2_id } = req.params;

  try {
    const messages = await pool.query(`
      SELECT * FROM messages 
      WHERE (sender_id = $1 AND receiver_id = $2) 
         OR (sender_id = $2 AND receiver_id = $1)
      ORDER BY timestamp ASC
    `, [user1_id, user2_id]);

    res.json({
      messages: messages.rows
    });
  } catch (err) {
    console.log('Error fetching messages:', err);
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
});

