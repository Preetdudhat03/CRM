const express = require('express');
const router = express.Router();
const NotificationService = require('../services/NotificationService');

router.post('/test/deal-won', async (req, res) => {
    try {
        const { dealId, performerId, value, companyName } = req.body;

        // This pushes to BullMQ
        await NotificationService.sendDealWon(dealId, performerId, value, companyName);

        return res.status(200).json({
            success: true,
            message: 'Deal Won event placed onto Queue! 🚀'
        });
    } catch (error) {
        console.error('Error triggering deal:', error);
        return res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;
