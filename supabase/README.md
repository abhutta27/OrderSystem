# Supabase Database Setup & Multi-Tenant RLS Guide

This directory contains the database migration scripts and sample seed data for **OrderSystem** (Phase 1).

## Architecture Highlights
- **Multi-Tenant Tables**: `stores`, `products`, `orders`.
- **Foreign Key Cascade / Isolation**: All child resources point directly to `stores.id`.
- **Remote Suspension & License Verification**: The `stores.is_active` flag controls client app availability.
- **Strict RLS**: Row Level Security is active on all tables. Inactive stores have product catalog access blocked and cannot accept orders.

## Files
1. `migrations/20261108000000_initial_schema.sql` - Core table definitions, constraints, indexes, and RLS policies.
2. `seed.sql` - Demo stores (BURGER01, PIZZA01, and LOCKED01 for suspension testing), sample products, and sample orders.

## Applying in Supabase Dashboard
1. Go to your Supabase project dashboard (https://supabase.com/dashboard).
2. Open the **SQL Editor** from the left navigation bar.
3. Paste and run the contents of `migrations/20261108000000_initial_schema.sql`.
4. (Optional) Paste and run the contents of `seed.sql` to populate sample data for testing.
5. In your project settings (**Settings -> API**), copy:
   - **Project URL**
   - **Anon Public API Key**
6. Paste these into `lib/core/config/supabase_config.dart`.
