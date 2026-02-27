const db = require('../config/db');

/**
 * LeadService - Direct PostgreSQL CRUD operations for the leads table.
 * Mirrors the Supabase schema_v2.sql `leads` table structure.
 */
class LeadService {

    /**
     * Fetch paginated leads ordered by created_at DESC
     */
    static async getLeads({ page = 0, pageSize = 20, status, source } = {}) {
        const offset = page * pageSize;
        let query = 'SELECT * FROM leads';
        const params = [];
        const conditions = [];

        if (status) {
            params.push(status);
            conditions.push(`status = $${params.length}`);
        }
        if (source) {
            params.push(source);
            conditions.push(`lead_source = $${params.length}`);
        }

        if (conditions.length > 0) {
            query += ' WHERE ' + conditions.join(' AND ');
        }

        query += ' ORDER BY created_at DESC';
        params.push(pageSize);
        query += ` LIMIT $${params.length}`;
        params.push(offset);
        query += ` OFFSET $${params.length}`;

        const result = await db.query(query, params);
        return result.rows;
    }

    /**
     * Get single lead by ID
     */
    static async getLeadById(id) {
        const result = await db.query(
            'SELECT * FROM leads WHERE id = $1',
            [id]
        );
        if (result.rows.length === 0) {
            throw new Error('Lead not found');
        }
        return result.rows[0];
    }

    /**
     * Search leads by name, email, or source
     */
    static async searchLeads(query, { page = 0, pageSize = 20 } = {}) {
        const offset = page * pageSize;
        const searchTerm = `%${query}%`;
        const result = await db.query(
            `SELECT * FROM leads
             WHERE first_name ILIKE $1
                OR last_name ILIKE $1
                OR email ILIKE $1
                OR lead_source ILIKE $1
             ORDER BY created_at DESC
             LIMIT $2 OFFSET $3`,
            [searchTerm, pageSize, offset]
        );
        return result.rows;
    }

    /**
     * Create a new lead
     */
    static async createLead(data) {
        const {
            first_name,
            last_name,
            email,
            phone,
            lead_source,
            status = 'new_lead',
            assigned_to,
            notes,
            estimated_value,
        } = data;

        const result = await db.query(
            `INSERT INTO leads
                (first_name, last_name, email, phone, lead_source, status, assigned_to, notes, estimated_value)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
             RETURNING *`,
            [first_name, last_name || '', email, phone, lead_source, status, assigned_to || null, notes, estimated_value]
        );
        return result.rows[0];
    }

    /**
     * Update an existing lead
     */
    static async updateLead(id, data) {
        const {
            first_name,
            last_name,
            email,
            phone,
            lead_source,
            status,
            assigned_to,
            notes,
            estimated_value,
        } = data;

        const result = await db.query(
            `UPDATE leads SET
                first_name = COALESCE($1, first_name),
                last_name = COALESCE($2, last_name),
                email = COALESCE($3, email),
                phone = COALESCE($4, phone),
                lead_source = COALESCE($5, lead_source),
                status = COALESCE($6, status),
                assigned_to = COALESCE($7, assigned_to),
                notes = COALESCE($8, notes),
                estimated_value = COALESCE($9, estimated_value),
                updated_at = NOW()
             WHERE id = $10
             RETURNING *`,
            [first_name, last_name, email, phone, lead_source, status, assigned_to || null, notes, estimated_value, id]
        );

        if (result.rows.length === 0) {
            throw new Error('Lead not found');
        }
        return result.rows[0];
    }

    /**
     * Delete a lead by ID
     */
    static async deleteLead(id) {
        const result = await db.query(
            'DELETE FROM leads WHERE id = $1 RETURNING id',
            [id]
        );
        if (result.rows.length === 0) {
            throw new Error('Lead not found');
        }
        return { deleted: true, id: result.rows[0].id };
    }

    /**
     * Convert a lead to a contact (atomic transaction)
     * Replicates the convert_lead RPC function from schema_v2.sql
     */
    static async convertLead(leadId) {
        const client = await require('../config/db');

        // We need a raw pg client for transactions, so we use the pool directly
        const { Pool } = require('pg');
        require('dotenv').config();
        const pool = new Pool({
            connectionString: process.env.DATABASE_URL,
            ssl: { rejectUnauthorized: false }
        });
        const txClient = await pool.connect();

        try {
            await txClient.query('BEGIN');

            // 1. Lock and fetch the lead
            const leadResult = await txClient.query(
                'SELECT * FROM leads WHERE id = $1 FOR UPDATE',
                [leadId]
            );

            if (leadResult.rows.length === 0) {
                throw new Error('Lead not found');
            }

            const lead = leadResult.rows[0];

            if (lead.status === 'converted') {
                throw new Error('Lead is already converted');
            }

            // 2. Insert into contacts
            const contactResult = await txClient.query(
                `INSERT INTO contacts
                    (first_name, last_name, email, phone, assigned_to, notes, created_from_lead, source_lead_id, is_customer)
                 VALUES ($1, $2, $3, $4, $5, $6, TRUE, $7, FALSE)
                 RETURNING id`,
                [lead.first_name, lead.last_name, lead.email, lead.phone, lead.assigned_to, lead.notes, lead.id]
            );

            const contactId = contactResult.rows[0].id;

            // 3. Update lead as converted
            await txClient.query(
                `UPDATE leads
                 SET status = 'converted',
                     converted_at = NOW(),
                     converted_contact_id = $1,
                     updated_at = NOW()
                 WHERE id = $2`,
                [contactId, leadId]
            );

            await txClient.query('COMMIT');

            return { contactId, leadId };
        } catch (error) {
            await txClient.query('ROLLBACK');
            throw error;
        } finally {
            txClient.release();
            await pool.end();
        }
    }

    /**
     * Get lead pipeline statistics (count per status)
     */
    static async getStats() {
        const result = await db.query(`
            SELECT
                COUNT(*) AS total,
                COUNT(*) FILTER (WHERE status = 'new_lead') AS new_leads,
                COUNT(*) FILTER (WHERE status = 'contacted') AS contacted,
                COUNT(*) FILTER (WHERE status = 'interested') AS interested,
                COUNT(*) FILTER (WHERE status = 'qualified') AS qualified,
                COUNT(*) FILTER (WHERE status = 'lost') AS lost,
                COUNT(*) FILTER (WHERE status = 'converted') AS converted,
                COALESCE(SUM(estimated_value) FILTER (WHERE status != 'lost' AND status != 'converted'), 0) AS pipeline_value,
                COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') AS new_this_month
            FROM leads
        `);
        return result.rows[0];
    }

    /**
     * Get leads assigned to a specific user
     */
    static async getLeadsByAssignee(userId, { page = 0, pageSize = 20 } = {}) {
        const offset = page * pageSize;
        const result = await db.query(
            `SELECT * FROM leads
             WHERE assigned_to = $1
             ORDER BY created_at DESC
             LIMIT $2 OFFSET $3`,
            [userId, pageSize, offset]
        );
        return result.rows;
    }
}

module.exports = LeadService;
