const app = require('./src/app');
const db = require('./src/config/db');
require('dotenv').config();

const PORT = process.env.PORT || 5000;

app.listen(PORT, async () => {
    console.log(`Server is running on port ${PORT}.`);

    // Test DB connection
    try {
        const res = await db.query('SELECT NOW()');
        console.log('Database connected successfully:', res.rows[0]);
    } catch (err) {
        console.error('Database connection failed!', err);
    }
});
