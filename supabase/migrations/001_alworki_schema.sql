-- Alworki — esquema completo para Supabase (PostgreSQL)
-- Ejecutar en SQL Editor de Supabase o con: supabase db push

-- Extensiones
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Usuarios de aplicación (vinculados opcionalmente a auth.users de Supabase)
CREATE TABLE IF NOT EXISTS app_users (
    id SERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT,
    auth_uuid UUID UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
    firstname TEXT NOT NULL DEFAULT '',
    lastname TEXT NOT NULL DEFAULT '',
    role TEXT NOT NULL DEFAULT 'user',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_app_users_email ON app_users (LOWER(email));
CREATE INDEX IF NOT EXISTS idx_app_users_auth_uuid ON app_users (auth_uuid);

-- Perfiles (JSON flexible como en SQLite)
CREATE TABLE IF NOT EXISTS profiles (
    user_id INTEGER PRIMARY KEY REFERENCES app_users(id) ON DELETE CASCADE,
    data_json JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS cards (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT NOT NULL,
    category TEXT NOT NULL,
    price INTEGER NOT NULL DEFAULT 1,
    rating REAL NOT NULL DEFAULT 4.5,
    reviews_count INTEGER NOT NULL DEFAULT 0,
    last_updated TEXT NOT NULL,
    owner_user_id INTEGER REFERENCES app_users(id) ON DELETE SET NULL,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS feed_posts (
    id SERIAL PRIMARY KEY,
    user_json JSONB NOT NULL,
    image_url TEXT NOT NULL,
    description TEXT NOT NULL,
    likes INTEGER NOT NULL DEFAULT 0,
    comments INTEGER NOT NULL DEFAULT 0,
    cost INTEGER NOT NULL DEFAULT 1,
    cost_type TEXT NOT NULL DEFAULT 'favor',
    card_id INTEGER REFERENCES cards(id) ON DELETE SET NULL,
    card_title TEXT,
    location TEXT,
    category TEXT,
    timestamp TEXT NOT NULL,
    liked INTEGER NOT NULL DEFAULT 0,
    saved INTEGER NOT NULL DEFAULT 0,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS stories (
    id SERIAL PRIMARY KEY,
    user_json JSONB NOT NULL,
    caption TEXT NOT NULL,
    image_url TEXT NOT NULL,
    card_id INTEGER REFERENCES cards(id) ON DELETE SET NULL,
    card_title TEXT,
    timestamp TEXT NOT NULL,
    duration INTEGER NOT NULL DEFAULT 5,
    viewed INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS exchange_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'pendiente',
    post_id INTEGER,
    card_id INTEGER,
    offer_title TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'planificacion',
    partner_name TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS quotes (
    id SERIAL PRIMARY KEY,
    provider_id INTEGER NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    client_id INTEGER REFERENCES app_users(id) ON DELETE SET NULL,
    tracking_number TEXT NOT NULL UNIQUE,
    services_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    materials_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    quote_date TEXT NOT NULL,
    time_slot TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pendiente',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    title TEXT NOT NULL DEFAULT '',
    provider_name TEXT NOT NULL DEFAULT '',
    provider_avatar TEXT NOT NULL DEFAULT 'users/user.jpg',
    line_items_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    requirements_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    activities_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    delivery_json JSONB,
    total_al INTEGER NOT NULL DEFAULT 0,
    shipping_cost INTEGER NOT NULL DEFAULT 0,
    delivery_date TEXT,
    order_start_date TEXT,
    client_review_json JSONB,
    provider_review_json JSONB
);

CREATE TABLE IF NOT EXISTS reports (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES app_users(id) ON DELETE SET NULL,
    provider_id INTEGER REFERENCES app_users(id) ON DELETE SET NULL,
    tracking_number TEXT NOT NULL,
    action TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    from_user_json JSONB,
    message TEXT NOT NULL,
    time_ago TEXT NOT NULL,
    is_recent INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS message_threads (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    peer_json JSONB NOT NULL,
    last_message TEXT NOT NULL DEFAULT '',
    time_label TEXT NOT NULL DEFAULT '',
    unread INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS contact_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    requester_json JSONB NOT NULL,
    subtitle TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS blocked_contacts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    blocked_json JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_messages (
    id SERIAL PRIMARY KEY,
    thread_id INTEGER NOT NULL REFERENCES message_threads(id) ON DELETE CASCADE,
    sender TEXT NOT NULL,
    message_type TEXT NOT NULL DEFAULT 'text',
    body TEXT NOT NULL,
    meta_json JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger: crear perfil al registrar usuario en app_users
CREATE OR REPLACE FUNCTION public.handle_new_app_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (user_id, data_json)
    VALUES (
        NEW.id,
        jsonb_build_object(
            'id', NEW.id,
            'name', COALESCE(NULLIF(TRIM(NEW.firstname || ' ' || NEW.lastname), ''), split_part(NEW.email, '@', 1)),
            'verified', false,
            'avatar', 'users/user.jpg',
            'contacts', 0,
            'professions', '[]'::jsonb,
            'localContacts', 0,
            'remoteContacts', 0,
            'localAvailable', true,
            'remoteAvailable', true,
            'skills', '[]'::jsonb,
            'materials', '[]'::jsonb,
            'portfolio', '[]'::jsonb,
            'reviews', '[]'::jsonb,
            'redCoins', 2,
            'blueCoins', 1,
            'quoteCost', 1
        )
    )
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_app_user_created ON app_users;
CREATE TRIGGER on_app_user_created
    AFTER INSERT ON app_users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_app_user();

-- RLS
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE exchange_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Políticas: lectura pública de catálogo
CREATE POLICY cards_public_read ON cards FOR SELECT USING (true);
CREATE POLICY feed_public_read ON feed_posts FOR SELECT USING (true);
CREATE POLICY stories_public_read ON stories FOR SELECT USING (true);
CREATE POLICY profiles_public_read ON profiles FOR SELECT USING (true);

-- Políticas: usuario autenticado accede a sus datos
CREATE POLICY app_users_self ON app_users
    FOR ALL USING (auth_uuid = auth.uid());

CREATE POLICY profiles_self ON profiles
    FOR ALL USING (
        user_id IN (SELECT id FROM app_users WHERE auth_uuid = auth.uid())
    );

CREATE POLICY exchange_own ON exchange_requests
    FOR ALL USING (
        user_id IN (SELECT id FROM app_users WHERE auth_uuid = auth.uid())
    );

CREATE POLICY projects_own ON projects
    FOR ALL USING (
        user_id IN (SELECT id FROM app_users WHERE auth_uuid = auth.uid())
    );

CREATE POLICY quotes_participant ON quotes
    FOR ALL USING (
        provider_id IN (SELECT id FROM app_users WHERE auth_uuid = auth.uid())
        OR client_id IN (SELECT id FROM app_users WHERE auth_uuid = auth.uid())
    );

CREATE POLICY notifications_own ON notifications
    FOR ALL USING (
        user_id IN (SELECT id FROM app_users WHERE auth_uuid = auth.uid())
    );

CREATE POLICY threads_own ON message_threads
    FOR ALL USING (
        user_id IN (SELECT id FROM app_users WHERE auth_uuid = auth.uid())
    );

CREATE POLICY messages_thread ON chat_messages
    FOR ALL USING (
        thread_id IN (
            SELECT id FROM message_threads
            WHERE user_id IN (SELECT id FROM app_users WHERE auth_uuid = auth.uid())
        )
    );

CREATE POLICY contact_requests_own ON contact_requests
    FOR ALL USING (
        user_id IN (SELECT id FROM app_users WHERE auth_uuid = auth.uid())
    );

CREATE POLICY blocked_own ON blocked_contacts
    FOR ALL USING (
        user_id IN (SELECT id FROM app_users WHERE auth_uuid = auth.uid())
    );

-- El backend Flask usa service_role / DATABASE_URL y omite RLS.
