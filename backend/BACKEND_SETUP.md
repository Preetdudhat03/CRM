# Backend Setup Guide

## Prerequisites
- Node.js installed
- PostgreSQL installed and running

## Database Setup
1. Create a PostgreSQL database named `crm_db` (or update `.env` with your DB name).
2. Run the SQL commands in `schema.sql` to create the tables.
   ```bash
   psql -d crm_db -f schema.sql
   ```

## Configuration
- Update the `.env` file with your database credentials.
  ```
  DB_USER=postgres
  DB_PASSWORD=your_password
  DB_NAME=crm_db
  JWT_SECRET=your_jwt_secret
  ```

## Running the Server
- To start in development mode (with auto-reload):
  ```bash
  npm run dev
  ```
- To start in production mode:
  ```bash
  npm start
  ```

## API Endpoints (To be implemented)
- `POST /auth/login`
- `POST /auth/register`
- `GET /auth/me`
- Routes for Contacts, Leads, Deals, Tasks will be at `/api/contacts`, `/api/leads`, etc.
