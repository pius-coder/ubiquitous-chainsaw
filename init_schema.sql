-- =====================================================
-- MIGRATION COMPLÈTE - AGENCE MATRIMONIALE
-- Version: 1.0.0
-- Description: Structure complète de la base de données
-- =====================================================

-- =====================================================
-- ÉTAPE 1 : Nettoyage (si besoin de repartir de zéro)
-- =====================================================

DROP TABLE IF EXISTS payment_transactions CASCADE;
DROP TABLE IF EXISTS contact_requests CASCADE;
DROP TABLE IF EXISTS profile_views CASCADE;
DROP TABLE IF EXISTS profile_recommendations CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS messages_sent CASCADE;
DROP TABLE IF EXISTS leads_duplicates CASCADE;
DROP TABLE IF EXISTS agent_errors CASCADE;
DROP TABLE IF EXISTS leads CASCADE;
DROP TABLE IF EXISTS admin_config CASCADE;
DROP TABLE IF EXISTS admin_users CASCADE;
DROP TABLE IF EXISTS knowledge_base CASCADE;

-- =====================================================
-- ÉTAPE 2 : Extensions et configuration système
-- =====================================================

-- Activer PG Vector
CREATE EXTENSION IF NOT EXISTS vector;

-- =====================================================
-- ÉTAPE 3 : Tables de configuration et admin
-- =====================================================

-- Table des utilisateurs admin (dashboard)
CREATE TABLE IF NOT EXISTS admin_users (
    id              SERIAL      PRIMARY KEY,
    username        VARCHAR(50) NOT NULL UNIQUE,
    email           VARCHAR(120) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(120),
    phone           VARCHAR(20),
    role            VARCHAR(30) NOT NULL DEFAULT 'admin',  -- admin, super_admin, conseiller
    status          VARCHAR(20) NOT NULL DEFAULT 'actif',  -- actif, inactif, suspendu
    last_login      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour login rapide
CREATE INDEX idx_admin_users_username ON admin_users (username);
CREATE INDEX idx_admin_users_email ON admin_users (email);

-- Insérer admin par défaut (mot de passe: admin123 - À CHANGER EN PRODUCTION)
INSERT INTO admin_users (username, email, password_hash, full_name, role, status)
VALUES (
    'admin',
    'admin@agence-matrimoniale.com',
    '$2b$10$rF8qN5Z5Z5Z5Z5Z5Z5Z5Z.Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z',  -- Hash de "admin123"
    'Administrateur Principal',
    'super_admin',
    'actif'
)
ON CONFLICT (username) DO NOTHING;


-- Table de configuration dynamique (clé/valeur)
CREATE TABLE IF NOT EXISTS admin_config (
    key         VARCHAR(100) PRIMARY KEY,
    value       TEXT         NOT NULL,
    description TEXT,
    category    VARCHAR(50),  -- system, whatsapp, payment, etc.
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by  INT REFERENCES admin_users(id)
);

-- Index par catégorie
CREATE INDEX idx_admin_config_category ON admin_config (category);

-- Configurations par défaut
INSERT INTO admin_config (key, value, description, category) VALUES
    ('admin_phone', '237657526695', 'Numéro WhatsApp de l''administrateur principal', 'whatsapp'),
    ('welcome_message_enabled', 'true', 'Activer le message de bienvenue automatique', 'system'),
    ('bot_auto_response_enabled', 'true', 'Activer les réponses automatiques du bot', 'system'),
    ('contact_request_fee', '5000', 'Frais de mise en relation (en FCFA)', 'payment'),
    ('group_whatsapp_link', 'https://chat.whatsapp.com/xxxxx', 'Lien du groupe WhatsApp des profils', 'whatsapp'),
    ('group_facebook_link', 'https://facebook.com/groups/xxxxx', 'Lien du groupe Facebook des profils', 'facebook'),
    ('business_name', 'Agence Matrimoniale Premium', 'Nom de l''agence', 'system'),
    ('business_phone', '237657526695', 'Numéro de contact principal', 'system'),
    ('business_email', 'contact@agence-matrimoniale.com', 'Email de contact', 'system')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;


-- =====================================================
-- ÉTAPE 3 : Tables des leads (prospects)
-- =====================================================

-- Table principale des leads
CREATE TABLE IF NOT EXISTS leads (
    id              SERIAL      PRIMARY KEY,
    fb_id           VARCHAR(64) UNIQUE,           -- ID Facebook Lead Ads (si capturé via FB)
    phone           VARCHAR(20) NOT NULL UNIQUE,  -- Numéro normalisé (+237...)
    name            VARCHAR(120) NOT NULL,
    first_name      VARCHAR(60),
    last_name       VARCHAR(60),
    city            VARCHAR(100),
    age             SMALLINT,
    gender          VARCHAR(10),                  -- homme, femme
    status          VARCHAR(40) NOT NULL DEFAULT 'nouveau_lead',  
    -- Statuts possibles: nouveau_lead, prospect_anonyme, prospect_actif, client_qualifie, client_inactif
    source          VARCHAR(50) DEFAULT 'facebook_ads',  -- facebook_ads, whatsapp_direct, referral, etc.
    notes           TEXT,                         -- Notes admin
    assigned_to     INT REFERENCES admin_users(id),  -- Conseiller assigné
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index sur phone pour recherches rapides
CREATE INDEX idx_leads_phone ON leads (phone);
CREATE INDEX idx_leads_status ON leads (status);
CREATE INDEX idx_leads_created ON leads (created_at DESC);
CREATE INDEX idx_leads_assigned ON leads (assigned_to);


-- Table de log des doublons détectés
CREATE TABLE IF NOT EXISTS leads_duplicates (
    id                  SERIAL      PRIMARY KEY,
    fb_id               VARCHAR(64) NOT NULL,
    phone               VARCHAR(20) NOT NULL,
    existing_lead_id    INT         NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    detected_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour dashboard admin
CREATE INDEX idx_leads_duplicates_existing ON leads_duplicates (existing_lead_id);
CREATE INDEX idx_leads_duplicates_detected ON leads_duplicates (detected_at DESC);


-- =====================================================
-- ÉTAPE 4 : Tables des profils (personnes cherchant partenaire)
-- =====================================================

-- Table principale des profils
CREATE TABLE IF NOT EXISTS profiles (
    id                  SERIAL      PRIMARY KEY,
    code                VARCHAR(20) NOT NULL UNIQUE,  -- MAT-2025-042
    
    -- Informations de base
    name                VARCHAR(120) NOT NULL,
    first_name          VARCHAR(60),
    last_name           VARCHAR(60),
    age                 SMALLINT    NOT NULL,
    gender              VARCHAR(10) NOT NULL,         -- homme, femme
    city                VARCHAR(100) NOT NULL,
    neighborhood        VARCHAR(100),                 -- Quartier
    
    -- Informations professionnelles
    profession          VARCHAR(150),
    workplace           VARCHAR(150),
    education_level     VARCHAR(100),                 -- Bac, Licence, Master, Doctorat, etc.
    
    -- Informations personnelles
    religion            VARCHAR(50),
    religious_practice  VARCHAR(50),                  -- pratiquant, non-pratiquant, modéré
    marital_status      VARCHAR(50),                  -- célibataire, divorcé(e), veuf(ve)
    has_children        BOOLEAN     DEFAULT FALSE,
    children_count      SMALLINT,
    height              SMALLINT,                     -- en cm
    body_type           VARCHAR(30),                  -- mince, athlétique, moyenne, forte
    
    -- Descriptions
    description_short   TEXT,                         -- Pour publication publique
    description_long    TEXT,                         -- Détails complets
    personality_traits  TEXT,                         -- Traits de personnalité
    hobbies             TEXT,                         -- Loisirs et centres d'intérêt
    lifestyle           TEXT,                         -- Style de vie
    
    -- Critères de recherche
    search_age_min      SMALLINT,
    search_age_max      SMALLINT,
    search_city         VARCHAR(100),
    search_religion     VARCHAR(50),
    search_education    VARCHAR(100),
    search_criteria     TEXT,                         -- Autres critères
    
    -- Médias
    photo_main_url      TEXT,                         -- Photo principale
    photo_urls          TEXT[],                       -- Tableau d'URLs des photos
    
    -- Contact (CONFIDENTIEL - jamais exposé au bot)
    phone               VARCHAR(20) NOT NULL,
    whatsapp            VARCHAR(20),
    email               VARCHAR(120),
    
    -- Métadonnées
    status              VARCHAR(40) NOT NULL DEFAULT 'actif',  
    -- Statuts: actif, inactif, en_relation, retiré, archivé
    publication_count   INT DEFAULT 0,                -- Nombre de fois publié
    view_count          INT DEFAULT 0,                -- Nombre de consultations
    contact_request_count INT DEFAULT 0,              -- Nombre de demandes de contact
    
    created_by          INT REFERENCES admin_users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    published_at        TIMESTAMPTZ,                  -- Date dernière publication
    archived_at         TIMESTAMPTZ,
    embedding           VECTOR(1024)
);

-- Index sur code pour recherche rapide
CREATE INDEX idx_profiles_code ON profiles (code);
CREATE INDEX idx_profiles_status ON profiles (status);
CREATE INDEX idx_profiles_gender ON profiles (gender);
CREATE INDEX idx_profiles_city ON profiles (city);
CREATE INDEX idx_profiles_age ON profiles (age);
CREATE INDEX idx_profiles_created ON profiles (created_at DESC);
CREATE INDEX idx_profiles_published ON profiles (published_at DESC);

-- Index composé pour recherches avancées
CREATE INDEX idx_profiles_search ON profiles (status, gender, city, age);

-- Index HNSW pour recherche vectorielle sur les profils
CREATE INDEX idx_profiles_embedding ON profiles USING hnsw (embedding vector_cosine_ops);


-- =====================================================
-- ÉTAPE 5 : Tables des conversations
-- =====================================================

-- Table de l'historique des conversations
CREATE TABLE IF NOT EXISTS conversations (
    id              SERIAL      PRIMARY KEY,
    lead_id         INT         NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    direction       VARCHAR(10) NOT NULL,  -- 'in' (client → bot/admin) ou 'out' (bot/admin → client)
    content         TEXT        NOT NULL,
    message_type    VARCHAR(40) DEFAULT 'text',  -- text, image, video, document, audio
    sender_type     VARCHAR(20) DEFAULT 'bot',   -- bot, admin, system
    sender_id       INT REFERENCES admin_users(id),  -- Si admin a répondu manuellement
    
    status          VARCHAR(40) DEFAULT 'bot_actif',  
    -- Statuts: bot_actif, attente_humain, humain_actif, clos, archivé
    
    profile_code    VARCHAR(20) REFERENCES profiles(code),  -- Si message lié à un profil
    intent          VARCHAR(50),  -- demande_info, demande_contact, question_tarif, etc.
    sentiment       VARCHAR(20),  -- positif, neutre, négatif (analyse future)
    
    metadata        JSONB,        -- Données brutes WhatsApp/Messenger
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour récupération rapide de l'historique
CREATE INDEX idx_conversations_lead ON conversations (lead_id, created_at DESC);
CREATE INDEX idx_conversations_status ON conversations (status);
CREATE INDEX idx_conversations_profile ON conversations (profile_code);
CREATE INDEX idx_conversations_intent ON conversations (intent);
CREATE INDEX idx_conversations_created ON conversations (created_at DESC);

-- Index GIN pour recherche dans metadata JSON
CREATE INDEX idx_conversations_metadata ON conversations USING GIN (metadata);


-- =====================================================
-- ÉTAPE 6 : Tables de tracking et analytics
-- =====================================================

-- Table de tracking des profils consultés
CREATE TABLE IF NOT EXISTS profile_views (
    id              SERIAL      PRIMARY KEY,
    lead_id         INT         NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    profile_id      INT         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    conversation_id INT REFERENCES conversations(id) ON DELETE SET NULL,
    view_type       VARCHAR(30) DEFAULT 'detail',  -- group_post, detail, recommendation
    viewed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour analytics
CREATE INDEX idx_profile_views_lead ON profile_views (lead_id);
CREATE INDEX idx_profile_views_profile ON profile_views (profile_id);
CREATE INDEX idx_profile_views_date ON profile_views (viewed_at DESC);

-- Index composé pour éviter doublons
CREATE INDEX idx_profile_views_unique ON profile_views (lead_id, profile_id, viewed_at DESC);


-- Table des recommandations de profils
CREATE TABLE IF NOT EXISTS profile_recommendations (
    id              SERIAL      PRIMARY KEY,
    lead_id         INT         NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    profile_id      INT         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    recommended_by  VARCHAR(20) DEFAULT 'ai_agent',  -- ai_agent, admin, algorithm
    admin_id        INT REFERENCES admin_users(id),
    score           DECIMAL(3,2),  -- Score de compatibilité (0.00 à 1.00)
    reason          TEXT,          -- Raison de la recommandation
    status          VARCHAR(30) DEFAULT 'suggested',  -- suggested, viewed, contacted, rejected
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour dashboard et analytics
CREATE INDEX idx_recommendations_lead ON profile_recommendations (lead_id);
CREATE INDEX idx_recommendations_profile ON profile_recommendations (profile_id);
CREATE INDEX idx_recommendations_status ON profile_recommendations (status);
CREATE INDEX idx_recommendations_score ON profile_recommendations (score DESC);


-- =====================================================
-- ÉTAPE 7 : Tables de gestion commerciale
-- =====================================================

-- Table des demandes de mise en relation
CREATE TABLE IF NOT EXISTS contact_requests (
    id                  SERIAL      PRIMARY KEY,
    request_code        VARCHAR(20) NOT NULL UNIQUE,  -- REQ-2025-001
    
    lead_id             INT         NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    profile_id          INT         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    status              VARCHAR(40) NOT NULL DEFAULT 'pending',  
    -- Statuts: pending, admin_review, payment_pending, paid, contact_shared, completed, cancelled
    
    payment_status      VARCHAR(30) DEFAULT 'unpaid',  -- unpaid, partial, paid, refunded
    payment_amount      DECIMAL(10,2),
    payment_method      VARCHAR(30),  -- momo, om, cash, bank_transfer
    
    admin_notes         TEXT,
    contact_shared_at   TIMESTAMPTZ,  -- Quand le contact a été transmis
    
    assigned_to         INT REFERENCES admin_users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at        TIMESTAMPTZ
);

-- Index pour gestion admin
CREATE INDEX idx_contact_requests_code ON contact_requests (request_code);
CREATE INDEX idx_contact_requests_lead ON contact_requests (lead_id);
CREATE INDEX idx_contact_requests_profile ON contact_requests (profile_id);
CREATE INDEX idx_contact_requests_status ON contact_requests (status);
CREATE INDEX idx_contact_requests_payment ON contact_requests (payment_status);
CREATE INDEX idx_contact_requests_created ON contact_requests (created_at DESC);


-- Table des transactions de paiement
CREATE TABLE IF NOT EXISTS payment_transactions (
    id                  SERIAL      PRIMARY KEY,
    transaction_code    VARCHAR(30) NOT NULL UNIQUE,  -- TXN-2025-001
    
    contact_request_id  INT         NOT NULL REFERENCES contact_requests(id) ON DELETE CASCADE,
    lead_id             INT         NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    
    amount              DECIMAL(10,2) NOT NULL,
    currency            VARCHAR(10) DEFAULT 'XAF',  -- FCFA
    payment_method      VARCHAR(30) NOT NULL,       -- momo, om, cash, bank_transfer
    payment_reference   VARCHAR(100),               -- Référence externe (MoMo, OM, etc.)
    
    status              VARCHAR(30) NOT NULL DEFAULT 'pending',  
    -- Statuts: pending, processing, completed, failed, refunded
    
    provider            VARCHAR(50),  -- MTN, Orange, Moov, etc.
    provider_reference  VARCHAR(100),
    
    notes               TEXT,
    verified_by         INT REFERENCES admin_users(id),
    verified_at         TIMESTAMPTZ,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour recherche et réconciliation
CREATE INDEX idx_payment_txn_code ON payment_transactions (transaction_code);
CREATE INDEX idx_payment_request ON payment_transactions (contact_request_id);
CREATE INDEX idx_payment_lead ON payment_transactions (lead_id);
CREATE INDEX idx_payment_status ON payment_transactions (status);
CREATE INDEX idx_payment_reference ON payment_transactions (payment_reference);
CREATE INDEX idx_payment_created ON payment_transactions (created_at DESC);


-- =====================================================
-- ÉTAPE 8 : Tables de logs et erreurs
-- =====================================================

-- Table de log des messages envoyés
CREATE TABLE IF NOT EXISTS messages_sent (
    id              SERIAL      PRIMARY KEY,
    lead_id         INT REFERENCES leads(id) ON DELETE SET NULL,
    channel         VARCHAR(20) NOT NULL,           -- whatsapp, sms, email, facebook
    message_type    VARCHAR(40) NOT NULL,           -- bienvenue, notif_admin, rappel, etc.
    content         TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'sent',  -- sent, failed, pending, delivered
    error_message   TEXT,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour monitoring
CREATE INDEX idx_messages_sent_lead ON messages_sent (lead_id);
CREATE INDEX idx_messages_sent_type ON messages_sent (message_type);
CREATE INDEX idx_messages_sent_status ON messages_sent (status);
CREATE INDEX idx_messages_sent_date ON messages_sent (sent_at DESC);


-- Table des erreurs d'agent IA
CREATE TABLE IF NOT EXISTS agent_errors (
    id              SERIAL      PRIMARY KEY,
    phone           VARCHAR(20) NOT NULL,
    error_type      VARCHAR(50) DEFAULT 'country_code',  -- country_code, api_failure, parsing_error
    pays_saisi      VARCHAR(100),
    agent_response  TEXT,
    stack_trace     TEXT,
    resolved        BOOLEAN DEFAULT FALSE,
    resolved_by     INT REFERENCES admin_users(id),
    resolved_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour monitoring et résolution
CREATE INDEX idx_agent_errors_phone ON agent_errors (phone);
CREATE INDEX idx_agent_errors_type ON agent_errors (error_type);
CREATE INDEX idx_agent_errors_resolved ON agent_errors (resolved);
CREATE INDEX idx_agent_errors_date ON agent_errors (created_at DESC);


-- =====================================================
-- ÉTAPE 9 : Table de la Base de Connaissances (RAG)
-- =====================================================

CREATE TABLE IF NOT EXISTS knowledge_base (
    id          SERIAL PRIMARY KEY,
    content     TEXT NOT NULL,
    metadata    JSONB,
    embedding   VECTOR(1024),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index HNSW pour recherche vectorielle rapide
-- Note : Utilisez vector_cosine_ops pour Mistral Embeddings
-- Index HNSW pour recherche vectorielle rapide
-- Note : Utilisez vector_cosine_ops pour Mistral Embeddings
CREATE INDEX idx_kb_embedding ON knowledge_base USING hnsw (embedding vector_cosine_ops);

-- =====================================================
-- ÉTAPE 9.1 : Table de Mémoire Conversationnelle (Vector Memory)
-- =====================================================

CREATE TABLE IF NOT EXISTS conversation_memory (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    text        TEXT NOT NULL,
    metadata    JSONB,
    embedding   VECTOR(1024),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index HNSW pour la mémoire
CREATE INDEX idx_memory_embedding ON conversation_memory USING hnsw (embedding vector_cosine_ops);
CREATE INDEX idx_memory_metadata ON conversation_memory USING GIN (metadata);

-- =====================================================
-- ÉTAPE 10 : Fonctions utiles et triggers
-- =====================================================

-- Fonction pour générer le code profil automatique
CREATE OR REPLACE FUNCTION generate_profile_code()
RETURNS TRIGGER AS $$
DECLARE
    year_part TEXT;
    sequence_num INT;
    new_code TEXT;
BEGIN
    -- Extraire l'année
    year_part := TO_CHAR(NOW(), 'YYYY');
    
    -- Trouver le dernier numéro de séquence pour cette année
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(code FROM 'MAT-' || year_part || '-(.*)') AS INTEGER)
    ), 0) + 1
    INTO sequence_num
    FROM profiles
    WHERE code LIKE 'MAT-' || year_part || '-%';
    
    -- Générer le nouveau code
    new_code := 'MAT-' || year_part || '-' || LPAD(sequence_num::TEXT, 3, '0');
    
    NEW.code := new_code;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour auto-générer le code profil
CREATE TRIGGER trigger_generate_profile_code
BEFORE INSERT ON profiles
FOR EACH ROW
WHEN (NEW.code IS NULL OR NEW.code = '')
EXECUTE FUNCTION generate_profile_code();


-- Fonction pour générer le code demande de contact
CREATE OR REPLACE FUNCTION generate_request_code()
RETURNS TRIGGER AS $$
DECLARE
    year_part TEXT;
    sequence_num INT;
    new_code TEXT;
BEGIN
    year_part := TO_CHAR(NOW(), 'YYYY');
    
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(request_code FROM 'REQ-' || year_part || '-(.*)') AS INTEGER)
    ), 0) + 1
    INTO sequence_num
    FROM contact_requests
    WHERE request_code LIKE 'REQ-' || year_part || '-%';
    
    new_code := 'REQ-' || year_part || '-' || LPAD(sequence_num::TEXT, 3, '0');
    
    NEW.request_code := new_code;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour auto-générer le code demande
CREATE TRIGGER trigger_generate_request_code
BEFORE INSERT ON contact_requests
FOR EACH ROW
WHEN (NEW.request_code IS NULL OR NEW.request_code = '')
EXECUTE FUNCTION generate_request_code();


-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers pour updated_at
CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contact_requests_updated_at BEFORE UPDATE ON contact_requests
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_transactions_updated_at BEFORE UPDATE ON payment_transactions
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON admin_users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- Fonction pour incrémenter le compteur de vues
CREATE OR REPLACE FUNCTION increment_profile_view_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE profiles
    SET view_count = view_count + 1
    WHERE id = NEW.profile_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour auto-incrémenter view_count
CREATE TRIGGER trigger_increment_view_count
AFTER INSERT ON profile_views
FOR EACH ROW
EXECUTE FUNCTION increment_profile_view_count();


-- =====================================================
-- ÉTAPE 10 : Vues (views) pour analytics et dashboard
-- =====================================================

-- Vue des statistiques par profil
CREATE OR REPLACE VIEW profile_stats AS
SELECT 
    p.id,
    p.code,
    p.name,
    p.age,
    p.city,
    p.status,
    p.view_count,
    p.contact_request_count,
    COUNT(DISTINCT pv.lead_id) AS unique_viewers,
    COUNT(DISTINCT cr.id) AS total_requests,
    COUNT(DISTINCT cr.id) FILTER (WHERE cr.status = 'completed') AS completed_requests,
    MAX(pv.viewed_at) AS last_viewed_at,
    p.created_at,
    p.published_at
FROM profiles p
LEFT JOIN profile_views pv ON p.id = pv.profile_id
LEFT JOIN contact_requests cr ON p.id = cr.profile_id
GROUP BY p.id, p.code, p.name, p.age, p.city, p.status, p.view_count, 
         p.contact_request_count, p.created_at, p.published_at;


-- Vue des statistiques par lead
CREATE OR REPLACE VIEW lead_stats AS
SELECT 
    l.id,
    l.phone,
    l.name,
    l.city,
    l.status,
    l.source,
    COUNT(DISTINCT c.id) AS total_messages,
    COUNT(DISTINCT c.id) FILTER (WHERE c.direction = 'in') AS messages_received,
    COUNT(DISTINCT c.id) FILTER (WHERE c.direction = 'out') AS messages_sent,
    COUNT(DISTINCT pv.profile_id) AS profiles_viewed,
    COUNT(DISTINCT cr.id) AS contact_requests,
    MAX(c.created_at) AS last_interaction_at,
    l.created_at,
    l.assigned_to
FROM leads l
LEFT JOIN conversations c ON l.id = c.lead_id
LEFT JOIN profile_views pv ON l.id = pv.lead_id
LEFT JOIN contact_requests cr ON l.id = cr.lead_id
GROUP BY l.id, l.phone, l.name, l.city, l.status, l.source, l.created_at, l.assigned_to;


-- Vue des conversations actives
CREATE OR REPLACE VIEW active_conversations AS
SELECT 
    l.id AS lead_id,
    l.phone,
    l.name AS lead_name,
    l.city,
    l.status AS lead_status,
    c.status AS conversation_status,
    COUNT(c.id) AS message_count,
    MAX(c.created_at) AS last_message_at,
    STRING_AGG(
        c.direction || ': ' || LEFT(c.content, 50),
        ' | '
        ORDER BY c.created_at DESC
    ) AS recent_messages
FROM leads l
INNER JOIN conversations c ON l.id = c.lead_id
WHERE c.status IN ('bot_actif', 'attente_humain', 'humain_actif')
GROUP BY l.id, l.phone, l.name, l.city, l.status, c.status
HAVING MAX(c.created_at) > NOW() - INTERVAL '7 days';


-- =====================================================
-- ÉTAPE 11 : Données de test (optionnel)
-- =====================================================

-- Insérer quelques profils de test
INSERT INTO profiles (
    name, first_name, last_name, age, gender, city, profession, education_level,
    religion, marital_status, has_children, description_short, description_long,
    search_age_min, search_age_max, phone, status, created_by
) VALUES
    (
        'Marie Kouassi', 'Marie', 'Kouassi', 28, 'femme', 'Abidjan',
        'Enseignante', 'Licence', 'Chrétienne', 'célibataire', FALSE,
        'Enseignante passionnée, aime la lecture et la natation',
        'Jeune femme dynamique de 28 ans, enseignante dans une école privée à Cocody. Passionnée de lecture, notamment les romans africains. Pratique la natation régulièrement. Recherche une relation sérieuse avec un homme respectueux et ambitieux.',
        25, 35, '237650111111', 'actif', 1
    ),
    (
        'Jean Mbarga', 'Jean', 'Mbarga', 32, 'homme', 'Douala',
        'Ingénieur informatique', 'Master', 'Chrétien', 'célibataire', FALSE,
        'Ingénieur passionné de technologie et de voyages',
        'Ingénieur informatique de 32 ans travaillant pour une multinationale. Passionné de nouvelles technologies, voyages et sport. Recherche une femme cultivée pour construire une famille.',
        25, 32, '237650222222', 'actif', 1
    ),
    (
        'Fatou Diallo', 'Fatou', 'Diallo', 26, 'femme', 'Yaoundé',
        'Infirmière', 'Licence', 'Musulmane', 'célibataire', FALSE,
        'Infirmière dévouée, famille importante',
        'Infirmière de 26 ans exerçant dans un hôpital de la place. Très attachée aux valeurs familiales et religieuses. Aime la cuisine et les activités en famille. Recherche un homme sérieux et pratiquant.',
        28, 38, '237650333333', 'actif', 1
    )
ON CONFLICT (code) DO NOTHING;


-- =====================================================
-- FIN DE LA MIGRATION
-- =====================================================

-- Vérification finale
SELECT 'Migration terminée avec succès!' AS status;

-- Afficher le nombre de tables créées
SELECT COUNT(*) AS tables_count 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE';