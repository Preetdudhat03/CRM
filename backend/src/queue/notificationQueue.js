const { Queue } = require('bullmq');
const Redis = require('ioredis');
require('dotenv').config();

// Redis connection - using Upstash URL
const connection = new Redis(process.env.REDIS_URL, {
    maxRetriesPerRequest: null // Required by BullMQ
});

// Create the Notification Queue
const notificationQueue = new Queue('NotificationQueue', {
    connection,
    defaultJobOptions: {
        attempts: 3,           // Retry failed jobs 3 times
        backoff: {
            type: 'exponential',
            delay: 1000        // Backoff starts at 1 second
        }
    }
});

module.exports = notificationQueue;
