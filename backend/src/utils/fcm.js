const admin = require('../config/firebase');
const db = require('../config/db');

/**
 * Send a push notification to a specific user
 * @param {string} userId - UUID of the target user
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {Object} data - Extra data payload (optional)
 */
async function sendPushToUser(userId, title, body, data = {}) {
    try {
        // 1. Get FCM token for the user
        const res = await db.query(
            "SELECT token FROM public.fcm_tokens WHERE user_id = $1",
            [userId]
        );

        if (res.rows.length === 0) {
            console.warn(`[FCM] No token found for user ${userId}`);
            return;
        }

        const token = res.rows[0].token;

        // 2. Prepare message
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: {
                ...data,
                click_action: 'FLUTTER_NOTIFICATION_CLICK', // Required for older Flutter versions
            },
            token: token,
        };

        // 3. Send via Firebase Admin
        const response = await admin.messaging().send(message);
        console.log(`[FCM] Successfully sent message to user ${userId}:`, response);
        return response;
    } catch (error) {
        console.error(`[FCM] Error sending message to user ${userId}:`, error);

        // Handle invalid tokens (cleanup database)
        if (error.code === 'messaging/registration-token-not-registered' ||
            error.code === 'messaging/invalid-registration-token') {
            console.log(`[FCM] Cleaning up invalid token for user ${userId}`);
            await db.query("DELETE FROM public.fcm_tokens WHERE user_id = $1", [userId]);
        }
    }
}

/**
 * Broadcast a notification to multiple users
 * @param {string[]} userIds - Array of UUIDs
 * @param {string} title 
 * @param {string} body 
 * @param {Object} data 
 */
async function sendPushToUsers(userIds, title, body, data = {}) {
    const promises = userIds.map(id => sendPushToUser(id, title, body, data));
    return Promise.all(promises);
}

module.exports = {
    sendPushToUser,
    sendPushToUsers
};
