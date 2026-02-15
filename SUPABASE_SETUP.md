# Supabase Setup Guide for Field CRM

Since we have switched to Supabase as the backend, follow these steps to configure your project.

## 1. Database Schema

Run the following SQL in your Supabase **SQL Editor** to create the necessary tables. This schema matches the Flutter data models.

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Contacts
CREATE TABLE contacts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  company TEXT,
  position TEXT,
  address TEXT,
  notes TEXT,
  status TEXT DEFAULT 'lead', 
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_contacted TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  avatar_url TEXT
);

-- 2. Leads
CREATE TABLE leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  source TEXT,
  status TEXT DEFAULT 'newLead',
  assigned_to TEXT, -- Storing email or name for now, or UUID if you sync users table
  estimated_value NUMERIC(15, 2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Deals
CREATE TABLE deals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  contact_id UUID REFERENCES contacts(id),
  company_name TEXT,
  value NUMERIC(15, 2),
  stage TEXT DEFAULT 'qualification',
  assigned_to TEXT,
  expected_close_date DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Tasks
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  due_date TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'pending',
  priority TEXT DEFAULT 'medium',
  assigned_to TEXT,
  related_entity_id UUID,
  related_entity_type TEXT, 
  related_entity_name TEXT, -- Denormalized for simpler UI
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Row Level Security (RLS)
-- For development, you might want to enable public access or set up policies.
-- Ideally, create policies that allow authenticated users to view/edit.
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Example Policy (Allow all authenticated users full access)
CREATE POLICY "Enable all for users" ON contacts FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all for users" ON leads FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all for users" ON deals FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all for users" ON tasks FOR ALL USING (auth.role() = 'authenticated');
```

## 2. Authentication & Roles

The app uses `user_metadata` to determine the user's Role (Admin, Manager, Employee, etc.).

When creating a user in Supabase Authentication:
1.  Go to **Authentication** > **Users**.
2.  Add a user.
3.  (Important) You cannot easily set metadata in the UI for *new* users directly without a script, BUT for testing:
    *   Register via the App (if registration is implemented).
    *   OR, use the SQL editor to update the user's metadata after creation:

```sql
-- Update a user to be an Admin
UPDATE auth.users
SET raw_user_meta_data = '{"role": "admin", "name": "Admin User"}'
WHERE email = 'your.email@example.com';
```

Supported Roles:
*   `superAdmin`
*   `admin`
*   `manager`
*   `employee`
*   `viewer`

## 3. Storage (Optional)

If you use avatars:
1.  Create a storage bucket named `avatars`.
2.  Add RLS policies to allow public read or authenticated upload.

## 4. Run the App

The app is already configured with your Supabase URL and Anon Key in `main.dart`. Just run:

```bash
flutter run
```
