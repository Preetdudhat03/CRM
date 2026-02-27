const express = require('express');
const router = express.Router();
const ContactService = require('../services/ContactService');
const NotificationService = require('../services/NotificationService');

/**
 * GET /api/contacts
 * Fetch paginated contacts. Query params: page, pageSize, search
 */
router.get('/', async (req, res) => {
    try {
        const { page = 0, pageSize = 20, search } = req.query;

        let contacts;
        if (search && search.trim()) {
            contacts = await ContactService.searchContacts(search.trim(), {
                page: parseInt(page),
                pageSize: parseInt(pageSize),
            });
        } else {
            contacts = await ContactService.getContacts({
                page: parseInt(page),
                pageSize: parseInt(pageSize),
            });
        }

        return res.status(200).json({
            success: true,
            data: contacts,
            pagination: {
                page: parseInt(page),
                pageSize: parseInt(pageSize),
                count: contacts.length,
            },
        });
    } catch (error) {
        console.error('[Contacts] GET / error:', error.message);
        return res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * GET /api/contacts/stats
 * Get contact statistics
 */
router.get('/stats', async (req, res) => {
    try {
        const stats = await ContactService.getStats();
        return res.status(200).json({ success: true, data: stats });
    } catch (error) {
        console.error('[Contacts] GET /stats error:', error.message);
        return res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * GET /api/contacts/:id
 * Get a single contact by ID
 */
router.get('/:id', async (req, res) => {
    try {
        const contact = await ContactService.getContactById(req.params.id);
        return res.status(200).json({ success: true, data: contact });
    } catch (error) {
        const status = error.message === 'Contact not found' ? 404 : 500;
        return res.status(status).json({ success: false, error: error.message });
    }
});

/**
 * POST /api/contacts
 * Create a new contact
 */
router.post('/', async (req, res) => {
    try {
        const contact = await ContactService.createContact(req.body);

        // Log activity (fire-and-forget)
        const name = `${contact.first_name || ''} ${contact.last_name || ''}`.trim();
        console.log(`[Contacts] Created contact: ${name} (${contact.id})`);

        return res.status(201).json({ success: true, data: contact });
    } catch (error) {
        console.error('[Contacts] POST / error:', error.message);
        return res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * PUT /api/contacts/:id
 * Update an existing contact
 */
router.put('/:id', async (req, res) => {
    try {
        const contact = await ContactService.updateContact(req.params.id, req.body);

        const name = `${contact.first_name || ''} ${contact.last_name || ''}`.trim();
        console.log(`[Contacts] Updated contact: ${name} (${contact.id})`);

        return res.status(200).json({ success: true, data: contact });
    } catch (error) {
        const status = error.message === 'Contact not found' ? 404 : 500;
        return res.status(status).json({ success: false, error: error.message });
    }
});

/**
 * DELETE /api/contacts/:id
 * Delete a contact
 */
router.delete('/:id', async (req, res) => {
    try {
        const result = await ContactService.deleteContact(req.params.id);
        console.log(`[Contacts] Deleted contact: ${req.params.id}`);
        return res.status(200).json({ success: true, data: result });
    } catch (error) {
        const status = error.message === 'Contact not found' ? 404 : 500;
        return res.status(status).json({ success: false, error: error.message });
    }
});

/**
 * PATCH /api/contacts/:id/favorite
 * Toggle favorite status
 */
router.patch('/:id/favorite', async (req, res) => {
    try {
        const contact = await ContactService.toggleFavorite(req.params.id);
        return res.status(200).json({
            success: true,
            data: contact,
            message: contact.is_favorite ? 'Added to favorites' : 'Removed from favorites',
        });
    } catch (error) {
        const status = error.message === 'Contact not found' ? 404 : 500;
        return res.status(status).json({ success: false, error: error.message });
    }
});

module.exports = router;
