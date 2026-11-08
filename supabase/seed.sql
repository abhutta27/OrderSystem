-- ==============================================================================
-- OrderSystem: Demo Seed Data with Reference Screen Items & Modifiers
-- ==============================================================================

-- 1. Insert Sample Stores
INSERT INTO stores (id, name, slug, store_code, logo_url, primary_color, secondary_color, is_active, is_busy)
VALUES
    (
        '11111111-1111-1111-1111-111111111111',
        'Burger & Pizza House',
        'burger-pizza-house',
        'FAST123',
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
        '#1E88E5', -- Crisp Blue from Reference Screen
        '#FF9800', -- Orange accent
        true,
        false
    ),
    (
        '22222222-2222-2222-2222-222222222222',
        'Pizza Planet',
        'pizza-planet',
        'PIZZA01',
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
        '#388E3C',
        '#FBC02D',
        true,
        true -- Busy Mode On for testing
    ),
    (
        '33333333-3333-3333-3333-333333333333',
        'Suspended Cafe',
        'suspended-cafe',
        'LOCKED01',
        'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400',
        '#616161',
        '#9E9E9E',
        false, -- Remote Suspension / License Locked
        false
    )
ON CONFLICT (id) DO UPDATE 
SET 
    name = EXCLUDED.name,
    slug = EXCLUDED.slug,
    store_code = EXCLUDED.store_code,
    primary_color = EXCLUDED.primary_color,
    secondary_color = EXCLUDED.secondary_color,
    is_active = EXCLUDED.is_active,
    is_busy = EXCLUDED.is_busy;

-- 2. Insert Products matching Reference Screen
INSERT INTO products (id, store_id, title, description, price, image_url, is_available, category, modifiers)
VALUES
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-111111111111',
        '11111111-1111-1111-1111-111111111111',
        'Zinger Burger (No Onion)',
        'Crispy fried chicken breast fillet with spicy mayo, shredded iceberg, and secret seasoning.',
        450.00,
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
        true,
        'Burgers',
        '[
            {"name": "ایکسٹرا پنیر / Extra Cheese", "price": 50},
            {"name": "کوک / Coke (345ml)", "price": 80},
            {"name": "فرائیز / French Fries", "price": 120}
        ]'::jsonb
    ),
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-222222222222',
        '11111111-1111-1111-1111-111111111111',
        'Pizza Large',
        'Stone-baked pizza crust topped with rich marinara sauce, imported mozzarella, and savory toppings.',
        950.00,
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
        false, -- Initialized as Unavailable to showcase "ابھی دستیاب نہیں ہے" badge!
        'Pizza',
        '[
            {"name": "ایکسٹرا پنیر / Extra Cheese", "price": 100},
            {"name": "ڈپ ساس / Garlic Mayo Dip", "price": 50},
            {"name": "ڈرنک 1.5 لٹر / 1.5L Drink", "price": 180}
        ]'::jsonb
    ),
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-333333333333',
        '11111111-1111-1111-1111-111111111111',
        'Classic Burger',
        'Juicy grilled beef patty with melt cheese, pickles, lettuce, and barbecue glaze.',
        450.00,
        'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=400',
        true,
        'Burgers',
        '[
            {"name": "ایکسٹرا پنیر / Extra Cheese", "price": 50},
            {"name": "کوک / Coke (345ml)", "price": 80}
        ]'::jsonb
    ),
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-444444444444',
        '11111111-1111-1111-1111-111111111111',
        'Coke (1.5L)',
        'Chilled 1.5 liter Coca-Cola bottle.',
        180.00,
        'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400',
        false, -- Unavailable badge: "ابھی دستیاب نہیں ہے"
        'Beverages',
        '[]'::jsonb
    )
ON CONFLICT (id) DO UPDATE 
SET 
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    price = EXCLUDED.price,
    image_url = EXCLUDED.image_url,
    is_available = EXCLUDED.is_available,
    category = EXCLUDED.category,
    modifiers = EXCLUDED.modifiers;

-- 3. Insert Demo Active Orders with Table Numbers
INSERT INTO orders (id, store_id, customer_name, customer_phone, delivery_address, total_amount, order_type, status, table_number, items, payment_method, payment_status)
VALUES
    (
        'cccccccc-cccc-cccc-cccc-111111111111',
        '11111111-1111-1111-1111-111111111111',
        'Table 04 Guest',
        '+923001234567',
        'Table 04 - Dine In',
        1600.00,
        'delivery',
        'pending',
        '04',
        '[
            {
                "product_id": "aaaaaaaa-aaaa-aaaa-aaaa-111111111111",
                "title": "Zinger Burger",
                "price": 450.0,
                "quantity": 1,
                "selected_modifiers": ["Extra Cheese (Rs. 50)"]
            },
            {
                "product_id": "aaaaaaaa-aaaa-aaaa-aaaa-222222222222",
                "title": "Large Pizza",
                "price": 950.0,
                "quantity": 1,
                "selected_modifiers": ["Extra Cheese (Rs. 100)"]
            }
        ]'::jsonb,
        'cash',
        'unpaid'
    ),
    (
        'cccccccc-cccc-cccc-cccc-222222222222',
        '11111111-1111-1111-1111-111111111111',
        'Table 02 Guest',
        '+923129876543',
        'Table 02 - Dine In',
        530.00,
        'delivery',
        'preparing',
        '02',
        '[
            {
                "product_id": "aaaaaaaa-aaaa-aaaa-aaaa-111111111111",
                "title": "Zinger Burger",
                "price": 450.0,
                "quantity": 1,
                "selected_modifiers": ["Cold Drink (Rs. 80)"]
            }
        ]'::jsonb,
        'advance',
        'paid'
    )
ON CONFLICT (id) DO NOTHING;

-- 4. Sample Waiter Call
INSERT INTO waiter_calls (id, store_id, table_number, status)
VALUES
    (
        'dddddddd-dddd-dddd-dddd-111111111111',
        '11111111-1111-1111-1111-111111111111',
        '04',
        'pending'
    )
ON CONFLICT (id) DO NOTHING;
