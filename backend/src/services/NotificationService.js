const notificationQueue = require('../queue/notificationQueue');

/**
 * Service to handle enqueueing notifications
 * Abstracts away the BullMQ dependency from the rest of the application.
 */
class NotificationService {

    /**
     * Helper to enqueue a generic event
     * @param {string} eventType - The type of event (e.g., 'deal_won', 'task_assigned')
     * @param {Object} payload - The data payload for the worker
     * @param {Object} options - BullMQ job options (delay, priority, etc)
     */
    static async enqueue(eventType, payload, options = {}) {
        try {
            console.log(`[Notification Service] Enqueueing event: ${eventType}`);
            const job = await notificationQueue.add(eventType, payload, options);
            return job;
        } catch (error) {
            console.error(`[Notification Service] Failed to enqueue event: ${eventType}`, error);
            // Non-blocking for the API, but log it heavily
        }
    }

    /**
     * Send a Deal Won notification
     */
    static async sendDealWon(dealId, performerId, value, companyName) {
        return this.enqueue('deal_won', {
            dealId,
            performerId,
            value,
            companyName
        });
    }

    /**
     * Send Task Assigned notification
     */
    static async sendTaskAssigned(taskId, assignedToId, assignedById, title) {
        return this.enqueue('task_assigned', {
            taskId,
            assignedToId,
            assignedById,
            title
        });
    }

    /**
     * Schedule an escalation warning
     * @param {number} delayHours - How long to wait before checking
     */
    static async scheduleTaskEscalation(taskId, delayHours = 48) {
        const delayMs = delayHours * 60 * 60 * 1000;
        return this.enqueue('check_task_escalation', { taskId }, { delay: delayMs });
    }
}

module.exports = NotificationService;
