const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

// Basic test route
app.get('/', (req, res) => {
    res.json({ message: 'Welcome to CRM Backend API' });
});

// Routes
const notificationRoutes = require('./routes/notification.routes');
const contactRoutes = require('./routes/contact.routes');
const leadRoutes = require('./routes/lead.routes');

app.use('/api/notifications', notificationRoutes);
app.use('/api/contacts', contactRoutes);
app.use('/api/leads', leadRoutes);

// const authRoutes = require('./routes/auth.routes');
// app.use('/api/auth', authRoutes);

module.exports = app;
