-- ==============================================================================
-- OrderSystem: Phase 2 & 3 Database Schema Upgrades
-- Adds support for:
-- 1. Table QR binding and table_number in orders
-- 2. Store "Busy Mode" toggle
-- 3. Product modifiers/add-ons and category indexing
-- 4. Cart items JSONB snapshot and payment method (Cash / Advance)
-- 5. "Call Waiter" table alerts
-- ==============================================================================

-- 1. Update stores table for Busy Mode toggle
ALTER TABLE stores 
ADD COLUMN IF NOT EXISTS is_busy BOOLEAN NOT NULL DEFAULT false;

-- 2. Update products table for Categories and Modifiers (JSONB)
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'General',
ADD COLUMN IF NOT EXISTS modifiers JSONB DEFAULT '[]'::jsonb;

-- 3. Update orders table for Table Number, Detailed Items JSONB, and Payment Mode
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS table_number TEXT DEFAULT '01',
ADD COLUMN IF NOT EXISTS items JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'cash' CHECK (payment_method IN ('cash', 'advance')),
ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid'));

-- 4. Create waiter_calls table for "Call Waiter" alerts
CREATE TABLE IF NOT EXISTS waiter_calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    table_number TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'resolved')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_waiter_calls_store ON waiter_calls(store_id, status);

-- 5. RLS for waiter_calls
ALTER TABLE waiter_calls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can call waiter for active stores"
    ON waiter_calls
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM stores 
            WHERE stores.id = waiter_calls.store_id 
              AND stores.is_active = true
        )
    );

CREATE POLICY "Read waiter calls scoped by store"
    ON waiter_calls
    FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM stores 
            WHERE stores.id = waiter_calls.store_id
        )
    );

CREATE POLICY "Service role / store staff can update waiter calls"
    ON waiter_calls
    FOR UPDATE
    TO service_role
    USING (true)
    WITH CHECK (true);
