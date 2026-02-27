const express = require('express');
const router = express.Router();
const LeadService = require('../services/LeadService');
const NotificationService = require('../services/NotificationService');

/**
 * GET /api/leads
 * Fetch paginated leads. Query params: page, pageSize, search, status, source
 */
router.get('/', async (req, res) => {
    try {
        const { page = 0, pageSize = 20, search, status, source } = req.query;

        let leads;
        if (search && search.trim()) {
            leads = await LeadService.searchLeads(search.trim(), {
                page: parseInt(page),
                pageSize: parseInt(pageSize),
            });
        } else {
            leads = await LeadService.getLeads({
                page: parseInt(page),
                pageSize: parseInt(pageSize),
                status: status || undefined,
                source: source || undefined,
            });
        }

        return res.status(200).json({
            success: true,
            data: leads,
            pagination: {
                page: parseInt(page),
                pageSize: parseInt(pageSize),
                count: leads.length,
            },
        });
    } catch (error) {
        console.error('[Leads] GET / error:', error.message);
        return res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * GET /api/leads/stats
 * Get lead pipeline statistics
 */
router.get('/stats', async (req, res) => {
    try {
        const stats = await LeadService.getStats();
        return res.status(200).json({ success: true, data: stats });
    } catch (error) {
        console.error('[Leads] GET /stats error:', error.message);
        return res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * GET /api/leads/assigned/:userId
 * Get leads assigned to a specific user
 */
router.get('/assigned/:userId', async (req, res) => {
    try {
        const { page = 0, pageSize = 20 } = req.query;
        const leads = await LeadService.getLeadsByAssignee(req.params.userId, {
            page: parseInt(page),
            pageSize: parseInt(pageSize),
        });
        return res.status(200).json({ success: true, data: leads });
    } catch (error) {
        console.error('[Leads] GET /assigned error:', error.message);
        return res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * GET /api/leads/:id
 * Get a single lead by ID
 */
router.get('/:id', async (req, res) => {
    try {
        const lead = await LeadService.getLeadById(req.params.id);
        return res.status(200).json({ success: true, data: lead });
    } catch (error) {
        const status = error.message === 'Lead not found' ? 404 : 500;
        return res.status(status).json({ success: false, error: error.message });
    }
});

/**
 * POST /api/leads
 * Create a new lead
 */
router.post('/', async (req, res) => {
    try {
        const lead = await LeadService.createLead(req.body);

        const name = `${lead.first_name || ''} ${lead.last_name || ''}`.trim();
        console.log(`[Leads] Created lead: ${name} (${lead.id})`);

        return res.status(201).json({ success: true, data: lead });
    } catch (error) {
        console.error('[Leads] POST / error:', error.message);
        return res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * PUT /api/leads/:id
 * Update an existing lead
 */
router.put('/:id', async (req, res) => {
    try {
        const lead = await LeadService.updateLead(req.params.id, req.body);

        const name = `${lead.first_name || ''} ${lead.last_name || ''}`.trim();
        console.log(`[Leads] Updated lead: ${name} (${lead.id})`);

        return res.status(200).json({ success: true, data: lead });
    } catch (error) {
        const status = error.message === 'Lead not found' ? 404 : 500;
        return res.status(status).json({ success: false, error: error.message });
    }
});

/**
 * DELETE /api/leads/:id
 * Delete a lead
 */
router.delete('/:id', async (req, res) => {
    try {
        const result = await LeadService.deleteLead(req.params.id);
        console.log(`[Leads] Deleted lead: ${req.params.id}`);
        return res.status(200).json({ success: true, data: result });
    } catch (error) {
        const status = error.message === 'Lead not found' ? 404 : 500;
        return res.status(status).json({ success: false, error: error.message });
    }
});

/**
 * POST /api/leads/:id/convert
 * Convert a lead to a contact (atomic transaction)
 */
router.post('/:id/convert', async (req, res) => {
    try {
        const result = await LeadService.convertLead(req.params.id);

        console.log(`[Leads] Converted lead ${req.params.id} → contact ${result.contactId}`);

        // Enqueue notification for lead conversion
        try {
            await NotificationService.enqueue('lead_converted', {
                leadId: result.leadId,
                contactId: result.contactId,
                performerId: req.body.performerId || null,
            });
        } catch (notifyErr) {
            console.warn('[Leads] Notification enqueue failed (non-blocking):', notifyErr.message);
        }

        return res.status(200).json({
            success: true,
            data: result,
            message: 'Lead converted to contact successfully',
        });
    } catch (error) {
        let status = 500;
        if (error.message === 'Lead not found') status = 404;
        if (error.message === 'Lead is already converted') status = 409;
        return res.status(status).json({ success: false, error: error.message });
    }
});

module.exports = router;
