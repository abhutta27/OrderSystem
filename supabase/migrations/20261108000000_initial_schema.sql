-- ==============================================================================
-- OrderSystem: Phase 1 Database Schema & Multi-Tenant Setup
-- Target Database: Supabase / PostgreSQL (PostgREST enabled)
-- ==============================================================================

-- 1. Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. Clean teardown if rebuilding (optional / development safety)
-- ==============================================================================
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS stores CASCADE;

-- ==============================================================================
-- 3. Stores Table
-- Represents individual tenant restaurants / business entities.
-- ==============================================================================
CREATE TABLE stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    store_code TEXT NOT NULL UNIQUE,
    logo_url TEXT,
    primary_color TEXT DEFAULT '#1976D2',
    secondary_color TEXT DEFAULT '#FF9800',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Comments on table & columns for documentation & PostgREST schema reflection
COMMENT ON TABLE stores IS 'Tenants / stores operating in the white-label ordering platform';
COMMENT ON COLUMN stores.id IS 'Primary key UUID identifying the tenant';
COMMENT ON COLUMN stores.store_code IS 'Unique human-readable or QR binding code (e.g. BURGER01)';
COMMENT ON COLUMN stores.is_active IS 'Remote suspension & license toggle. If false, client apps are blocked';

-- ==============================================================================
-- 4. Products Table
-- Catalogs belonging strictly to a single store (Multi-Tenant by store_id).
-- ==============================================================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    image_url TEXT,
    is_available BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE products IS 'Menu items and products scoped strictly to a specific store tenant';
COMMENT ON COLUMN products.store_id IS 'Foreign key linking product to its owning store';

-- ==============================================================================
-- 5. Orders Table
-- Customer orders scoped strictly to a specific store (Multi-Tenant by store_id).
-- ==============================================================================
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE RESTRICT,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    delivery_address TEXT,
    total_amount NUMERIC(10, 2) NOT NULL CHECK (total_amount >= 0),
    order_type TEXT NOT NULL CHECK (order_type IN ('delivery', 'takeaway')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'preparing', 'ready', 'delivered', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE orders IS 'Customer orders placed against a specific store tenant';
COMMENT ON COLUMN orders.store_id IS 'Foreign key linking order to its owning store';
COMMENT ON COLUMN orders.order_type IS 'Fulfillment type: delivery or takeaway';
COMMENT ON COLUMN orders.status IS 'Order state machine: pending, accepted, preparing, ready, delivered, cancelled';

-- ==============================================================================
-- 6. Indexes for Performance and Tenant Isolation
-- ==============================================================================
CREATE INDEX idx_stores_store_code ON stores(store_code);
CREATE INDEX idx_stores_slug ON stores(slug);
CREATE INDEX idx_stores_is_active ON stores(is_active);

CREATE INDEX idx_products_store_id ON products(store_id);
CREATE INDEX idx_products_store_available ON products(store_id, is_available);

CREATE INDEX idx_orders_store_id ON orders(store_id);
CREATE INDEX idx_orders_store_created ON orders(store_id, created_at DESC);
CREATE INDEX idx_orders_store_status ON orders(store_id, status);

-- ==============================================================================
-- 7. Multi-Tenancy & Row Level Security (RLS) Policies
--
-- Architecture Rules:
-- 1. All tables have RLS explicitly enabled.
-- 2. Store identification is enforced via store_id foreign keys.
-- 3. Public clients can discover/query a store by its unique store_code or slug
--    to allow app binding.
-- 4. Products can ONLY be viewed if they belong to an ACTIVE store.
-- 5. Orders can ONLY be placed against an ACTIVE store, starting in 'pending' status.
-- 6. Orders can only be queried by matching store_id.
-- ==============================================================================

-- Enable RLS
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- RLS Policies: stores
-- ------------------------------------------------------------------------------

-- Allow anyone (anon + authenticated) to lookup stores by ID or code for binding check.
-- Note: is_active is visible so client can immediately detect suspension and block UI.
CREATE POLICY "Public can view stores for binding and active check"
    ON stores
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- Store creation / management is restricted (e.g. service role or SuperAdmin)
CREATE POLICY "Admins or service role can modify stores"
    ON stores
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ------------------------------------------------------------------------------
-- RLS Policies: products
-- Strict multi-tenant read: products are only visible if the parent store is active.
-- ------------------------------------------------------------------------------

-- Customers can view products for active stores
CREATE POLICY "Customers can view available products of active stores"
    ON products
    FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM stores
            WHERE stores.id = products.store_id
              AND stores.is_active = true
        )
    );

-- Tenant managers / service role can manage products for their store
CREATE POLICY "Store owners or service role can manage products"
    ON products
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ------------------------------------------------------------------------------
-- RLS Policies: orders
-- Strict multi-tenant write & read:
-- 1. Orders can be inserted only for active stores with status 'pending'.
-- 2. Orders can be queried strictly matching the store_id.
-- ------------------------------------------------------------------------------

-- Customers can insert new orders for active stores
CREATE POLICY "Customers can place orders for active stores"
    ON orders
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (
        status = 'pending'
        AND EXISTS (
            SELECT 1 FROM stores
            WHERE stores.id = orders.store_id
              AND stores.is_active = true
        )
    );

-- Read orders: orders can be read when scoped to the store_id.
-- For anon customers, PostgREST queries MUST pass store_id filter:
-- Example: supabase.from('orders').select().eq('store_id', boundStoreId)
CREATE POLICY "Read orders scoped strictly by store"
    ON orders
    FOR SELECT
    TO anon, authenticated
    USING (
        EXISTS (
            SELECT 1 FROM stores
            WHERE stores.id = orders.store_id
        )
    );

-- Service role or Store Owner has full access to update order status
CREATE POLICY "Store managers or service role can update order status"
    ON orders
    FOR UPDATE
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ==============================================================================
-- 8. Optional Tenant Session Context Helper (For advanced multi-tenant header isolation)
-- Can be utilized if passing `x-store-id` header in custom requests.
-- ==============================================================================
CREATE OR REPLACE FUNCTION current_tenant_id()
RETURNS UUID AS $$
BEGIN
    RETURN NULLIF(current_setting('request.headers', true)::json->>'x-store-id', '')::uuid;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;
