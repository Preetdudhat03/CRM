const { Worker } = require('bullmq');
const db = require('../config/db'); // Ensure correct db path

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
            // Add other notification handlers here
            default:
                console.warn(`[Notification Worker] Unknown job type: ${job.name}`);
        }
    } catch (error) {
        console.error(`[Notification Worker] Failed to process job ${job.id}`, error);
        throw error; // Let BullMQ retry
    }

}, { connection });

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
                'Deal Won! 🎉',
                `A deal worth $${value ?? 0} was just closed at ${companyName || 'Unknown Company'}.`,
                'deal',
                dealId
            ]);
        } catch (e) {
            console.error(`Failed to insert notification for user ${userId}`, e);
        }
    }
}

// Helper function to handle a task assignment
async function handleTaskAssigned(data) {
    const { taskId, assignedToId, assignedById, title } = data;
    console.log(`Sending Task Assigned notification for task ${taskId} to user ${assignedToId}.`);

    // TODO: 1. Query DB to ensure 'assignedToId' isn't the same as 'assignedById'
    // TODO: 2. Save notification to user ${assignedToId}'s DB
    // TODO: 3. Push to Firebase
}

notificationWorker.on('completed', job => {
    console.log(`[Notification Worker] Job ${job.id} has completed!`);
});

notificationWorker.on('failed', (job, err) => {
    console.log(`[Notification Worker] Job ${job.id} has failed with ${err.message}`);
});

module.exports = notificationWorker;
