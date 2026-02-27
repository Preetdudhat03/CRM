const { Worker } = require('bullmq');
const db = require('../config/db'); // Ensure correct db path
const fcm = require('../utils/fcm');

const Redis = require('ioredis');
require('dotenv').config();

// Connect to Redis via Upstash URL
const connection = new Redis(process.env.REDIS_URL, {
    maxRetriesPerRequest: null
});

const notificationWorker = new Worker('NotificationQueue', async job => {

    console.log(`[Notification Worker] Processing job ${job.id} of type ${job.name}`);

    try {
        switch (job.name) {
            case 'deal_won':
                await handleDealWon(job.data);
                break;
            case 'task_assigned':
                await handleTaskAssigned(job.data);
                break;
            case 'lead_converted':
                await handleLeadConverted(job.data);
                break;
            default:
                console.warn(`[Notification Worker] Unknown job type: ${job.name}`);
        }
    } catch (error) {
        console.error(`[Notification Worker] Failed to process job ${job.id}`, error);
        throw error; // Let BullMQ retry
    }

}, { connection });

async function handleLeadConverted(data) {
    const { leadId, contactId, performerId } = data;
    console.log(`[Notification Worker] Lead ${leadId} converted by ${performerId}`);

    const title = 'Lead Converted! 🚀';
    const message = 'A lead was successfully converted to a contact.';

    // 1. Notify Admins
    let targetUsers = [];
    try {
        const adminsResult = await db.query("SELECT id FROM public.profiles WHERE role IN ('Super Admin', 'Admin')");
        targetUsers = adminsResult.rows.map(r => r.id);
    } catch (e) { console.error(e); }

    if (targetUsers.length === 0) return;

    // 2. Insert & Push
    for (let userId of targetUsers) {
        await db.query(`INSERT INTO notifications (user_id, type, title, message, related_type, related_id) VALUES ($1, $2, $3, $4, $5, $6)`,
            [userId, 'lead_converted', title, message, 'contact', contactId]);
    }

    await fcm.sendPushToUsers(targetUsers, title, message, { type: 'lead_converted', contactId: contactId?.toString() });
}

// Helper function to handle a deal being won
async function handleDealWon(data) {
    const { dealId, performerId, value, companyName } = data;
    console.log(`Sending Deal Won notification for deal ${dealId} placed by user ${performerId}! Strategy: notify Admins & Manager.`);

    // 1. Get all users who have `Super Admin` or `Admin` role
    let targetUsers = [];
    try {
        const adminsResult = await db.query(
            "SELECT id FROM public.profiles WHERE role IN ('Super Admin', 'Admin')"
        );

        targetUsers = adminsResult.rows.map(r => r.id);

        // Add performer to also get the notification (for a sense of accomplishment!)
        if (performerId && !targetUsers.includes(performerId)) {
            targetUsers.push(performerId);
        }
    } catch (e) {
        console.error("Failed fetching admins from profiles", e);
    }

    if (targetUsers.length === 0) return;

    // 2. Insert into notifications table for each target user
    const title = 'Deal Won! 🎉';
    const message = `A deal worth $${value ?? 0} was just closed at ${companyName || 'Unknown Company'}.`;

    const insertQuery = `
        INSERT INTO notifications (user_id, type, priority, title, message, related_type, related_id)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
    `;

    for (let userId of targetUsers) {
        try {
            await db.query(insertQuery, [
                userId,
                'deal_won',
                'HIGH',
                title,
                message,
                'deal',
                dealId
            ]);
        } catch (e) {
            console.error(`Failed to insert record for user ${userId}`, e);
        }
    }

    // 3. Send Push Notifications (FCM)
    // This wakes up the app even if closed or in background
    await fcm.sendPushToUsers(targetUsers, title, message, {
        type: 'deal_won',
        dealId: dealId?.toString()
    });
}

// Helper function to handle a task assignment
async function handleTaskAssigned(data) {
    const { taskId, assignedToId, assignedById, title: taskTitle } = data;
    console.log(`Sending Task Assigned notification for task ${taskId} to user ${assignedToId}.`);

    // 1. Query DB to ensure 'assignedToId' exists and get sender name
    let senderName = 'Someone';
    try {
        const senderRes = await db.query("SELECT name FROM public.profiles WHERE id = $1", [assignedById]);
        if (senderRes.rows.length > 0) senderName = senderRes.rows[0].name;
    } catch (e) {
        console.error("Error fetching sender name", e);
    }

    const title = 'New Task Assigned 📋';
    const message = `${senderName} assigned you a task: ${taskTitle}`;

    // 2. Save notification to user ${assignedToId}'s DB
    try {
        await db.query(`
            INSERT INTO notifications (user_id, type, priority, title, message, related_type, related_id, sender_id)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        `, [
            assignedToId,
            'task_assigned',
            'MEDIUM',
            title,
            message,
            'task',
            taskId,
            assignedById
        ]);
    } catch (e) {
        console.error(`Failed to insert task notification for user ${assignedToId}`, e);
    }

    // 3. Push to Firebase
    await fcm.sendPushToUser(assignedToId, title, message, {
        type: 'task_assigned',
        taskId: taskId?.toString()
    });
}

notificationWorker.on('completed', job => {
    console.log(`[Notification Worker] Job ${job.id} has completed!`);
});

notificationWorker.on('failed', (job, err) => {
    console.log(`[Notification Worker] Job ${job.id} has failed with ${err.message}`);
});

module.exports = notificationWorker;
