-- Insert test user for notifications testing
INSERT INTO public.user_profiles (
    id, 
    email, 
    full_name, 
    selected_problematiques,
    notification_time,
    notifications_enabled,
    reminder_notifications_enabled
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    'test@dailygrowth.com',
    'Test User',
    ARRAY['devenir plus charismatique et développer mon réseau'],
    '16:00:00',
    true,
    true
);
