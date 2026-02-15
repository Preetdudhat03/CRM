const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

// Basic test route
app.get('/', (req, res) => {
    res.json({ message: 'Welcome to CRM Backend API' });
});

// Routes will be added here later
// const authRoutes = require('./routes/auth.routes');
// app.use('/api/auth', authRoutes);

module.exports = app;
