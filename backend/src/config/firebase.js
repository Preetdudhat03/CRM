const admin = require('firebase-admin');
require('dotenv').config();

const firebaseConfig = {
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: process.env.FIREBASE_PRIVATE_KEY ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n') : undefined,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
};

if (firebaseConfig.projectId && firebaseConfig.privateKey && firebaseConfig.clientEmail) {
    try {
        admin.initializeApp({
            credential: admin.credential.cert(firebaseConfig),
        });
        console.log('[Firebase Admin] Initialized successfully');
    } catch (error) {
        console.error('[Firebase Admin] Initialization error:', error);
    }
} else {
    console.warn('[Firebase Admin] Missing credentials in .env. Push notifications will be disabled.');
}

module.exports = admin;
