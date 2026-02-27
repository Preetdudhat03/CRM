const db = require('../config/db');

/**
 * ContactService - Direct PostgreSQL CRUD operations for the contacts table.
 * Mirrors the Supabase schema_v2.sql `contacts` table structure.
 */
class ContactService {

    /**
     * Fetch paginated contacts ordered by created_at DESC
     */
    static async getContacts({ page = 0, pageSize = 20 } = {}) {
        const offset = page * pageSize;
        const result = await db.query(
            `SELECT * FROM contacts
             ORDER BY created_at DESC
             LIMIT $1 OFFSET $2`,
            [pageSize, offset]
        );
        return result.rows;
    }

    /**
     * Get single contact by ID
     */
    static async getContactById(id) {
        const result = await db.query(
            'SELECT * FROM contacts WHERE id = $1',
            [id]
        );
        if (result.rows.length === 0) {
            throw new Error('Contact not found');
        }
        return result.rows[0];
    }

    /**
     * Search contacts by name, email, or company_name
     */
    static async searchContacts(query, { page = 0, pageSize = 20 } = {}) {
        const offset = page * pageSize;
        const searchTerm = `%${query}%`;
        const result = await db.query(
            `SELECT * FROM contacts
             WHERE first_name ILIKE $1
                OR last_name ILIKE $1
                OR email ILIKE $1
                OR company_name ILIKE $1
             ORDER BY created_at DESC
             LIMIT $2 OFFSET $3`,
            [searchTerm, pageSize, offset]
        );
        return result.rows;
    }

    /**
     * Create a new contact
     */
    static async createContact(data) {
        const {
            first_name,
            last_name,
            email,
            phone,
            company_name,
            position,
            address,
            notes,
            assigned_to,
            is_customer = false,
            avatar_url,
            is_favorite = false,
        } = data;

        const result = await db.query(
            `INSERT INTO contacts
                (first_name, last_name, email, phone, company_name, position, address, notes, assigned_to, is_customer, avatar_url, is_favorite)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
             RETURNING *`,
            [first_name, last_name || '', email, phone, company_name, position, address, notes, assigned_to || null, is_customer, avatar_url, is_favorite]
        );
        return result.rows[0];
    }

    /**
     * Update an existing contact
     */
    static async updateContact(id, data) {
        const {
            first_name,
            last_name,
            email,
            phone,
            company_name,
            position,
            address,
            notes,
            assigned_to,
            is_customer,
            avatar_url,
            is_favorite,
            last_contacted,
        } = data;

        const result = await db.query(
            `UPDATE contacts SET
                first_name = COALESCE($1, first_name),
                last_name = COALESCE($2, last_name),
                email = COALESCE($3, email),
                phone = COALESCE($4, phone),
                company_name = COALESCE($5, company_name),
                position = COALESCE($6, position),
                address = COALESCE($7, address),
                notes = COALESCE($8, notes),
                assigned_to = COALESCE($9, assigned_to),
                is_customer = COALESCE($10, is_customer),
                avatar_url = COALESCE($11, avatar_url),
                is_favorite = COALESCE($12, is_favorite),
                last_contacted = COALESCE($13, last_contacted),
                updated_at = NOW()
             WHERE id = $14
             RETURNING *`,
            [first_name, last_name, email, phone, company_name, position, address, notes, assigned_to || null, is_customer, avatar_url, is_favorite, last_contacted, id]
        );

        if (result.rows.length === 0) {
            throw new Error('Contact not found');
        }
        return result.rows[0];
    }

    /**
     * Delete a contact by ID
     */
    static async deleteContact(id) {
        const result = await db.query(
            'DELETE FROM contacts WHERE id = $1 RETURNING id',
            [id]
        );
        if (result.rows.length === 0) {
            throw new Error('Contact not found');
        }
        return { deleted: true, id: result.rows[0].id };
    }

    /**
     * Toggle favorite status
     */
    static async toggleFavorite(id) {
        const result = await db.query(
            `UPDATE contacts
             SET is_favorite = NOT is_favorite, updated_at = NOW()
             WHERE id = $1
             RETURNING *`,
            [id]
        );
        if (result.rows.length === 0) {
            throw new Error('Contact not found');
        }
        return result.rows[0];
    }

    /**
     * Get contact statistics
     */
    static async getStats() {
        const result = await db.query(`
            SELECT
                COUNT(*) AS total,
                COUNT(*) FILTER (WHERE is_customer = false) AS leads,
                COUNT(*) FILTER (WHERE is_customer = true) AS customers,
                COUNT(*) FILTER (WHERE is_favorite = true) AS favorites,
                COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') AS new_this_month
            FROM contacts
        `);
        return result.rows[0];
    }
}

module.exports = ContactService;
