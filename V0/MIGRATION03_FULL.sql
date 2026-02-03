-- ============================================================================
-- MIGRATION V2 - Support AI Router et Tools RAG
-- Agence Matrimoniale Cameroun
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. TABLE DE CONFIGURATION DES WORKFLOWS (pour les variables $vars)
-- ============================================================================

CREATE TABLE IF NOT EXISTS workflow_config (
    id SERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    workflow_id VARCHAR(100) NOT NULL,
    workflow_name VARCHAR(255),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE workflow_config IS 'Configuration des IDs de workflows pour les tools des agents';

-- Index
CREATE INDEX IF NOT EXISTS idx_workflow_config_key ON workflow_config(key);

-- Données initiales (à mettre à jour avec les vrais IDs après création des workflows)
INSERT INTO workflow_config (key, workflow_id, workflow_name, description) VALUES
('WORKFLOW_RAG_KNOWLEDGE', 'TO_BE_SET', 'RAG Knowledge Base', 'Recherche sémantique dans la base de connaissances'),
('WORKFLOW_SEARCH_PROFILES', 'TO_BE_SET', 'Search Profiles', 'Recherche de profils compatibles'),
('WORKFLOW_GET_PROFILE', 'TO_BE_SET', 'Get Profile Details', 'Récupération des détails d''un profil'),
('WORKFLOW_LOG_VIEW', 'TO_BE_SET', 'Log Profile View', 'Enregistrement des vues de profils'),
('WORKFLOW_NOTIFY_ADMIN', 'TO_BE_SET', 'Notify Admin', 'Notification d''escalade vers admin'),
('WORKFLOW_CREATE_REQUEST', 'TO_BE_SET', 'Create Contact Request', 'Création de demande de mise en contact')
ON CONFLICT (key) DO NOTHING;


-- ============================================================================
-- 2. NOUVELLES COLONNES SUR TABLES EXISTANTES
-- ============================================================================

-- Ajout de colonnes sur leads si elles n'existent pas
DO $$
BEGIN
    -- Colonne pour le dernier agent utilisé
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'last_agent') THEN
        ALTER TABLE leads ADD COLUMN last_agent VARCHAR(50);
    END IF;
    
    -- Colonne pour le score de qualification (0-100)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'qualification_score') THEN
        ALTER TABLE leads ADD COLUMN qualification_score SMALLINT DEFAULT 0;
    END IF;
    
    -- Colonne pour le nombre total de messages
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'message_count') THEN
        ALTER TABLE leads ADD COLUMN message_count INTEGER DEFAULT 0;
    END IF;
    
    -- Colonne pour le dernier profil vu (code)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'last_profile_viewed') THEN
        ALTER TABLE leads ADD COLUMN last_profile_viewed VARCHAR(20);
    END IF;
END $$;

-- Ajout de colonnes sur conversations
DO $$
BEGIN
    -- Colonne pour le score de confiance de l'agent
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'conversations' AND column_name = 'confidence_score') THEN
        ALTER TABLE conversations ADD COLUMN confidence_score DECIMAL(3,2);
    END IF;
    
    -- Colonne pour les tokens utilisés
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'conversations' AND column_name = 'tokens_used') THEN
        ALTER TABLE conversations ADD COLUMN tokens_used INTEGER;
    END IF;
    
    -- Colonne pour le temps de réponse en ms
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'conversations' AND column_name = 'response_time_ms') THEN
        ALTER TABLE conversations ADD COLUMN response_time_ms INTEGER;
    END IF;
END $$;


-- ============================================================================
-- 3. TABLE DE LOGS DES TOOLS (appels de sous-workflows)
-- ============================================================================

CREATE TABLE IF NOT EXISTS tool_calls (
    id SERIAL PRIMARY KEY,
    lead_id INTEGER REFERENCES leads(id) ON DELETE SET NULL,
    conversation_id INTEGER REFERENCES conversations(id) ON DELETE SET NULL,
    agent_name VARCHAR(50) NOT NULL,
    tool_name VARCHAR(100) NOT NULL,
    tool_input JSONB,
    tool_output JSONB,
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    duration_ms INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE tool_calls IS 'Logs des appels aux tools (sous-workflows) par les agents';

-- Index pour tool_calls
CREATE INDEX IF NOT EXISTS idx_tool_calls_lead ON tool_calls(lead_id);
CREATE INDEX IF NOT EXISTS idx_tool_calls_agent ON tool_calls(agent_name);
CREATE INDEX IF NOT EXISTS idx_tool_calls_tool ON tool_calls(tool_name);
CREATE INDEX IF NOT EXISTS idx_tool_calls_created ON tool_calls(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tool_calls_success ON tool_calls(success) WHERE success = false;


-- ============================================================================
-- 4. TABLE DE CACHE POUR LES EMBEDDINGS DE RECHERCHE
-- ============================================================================

CREATE TABLE IF NOT EXISTS search_cache (
    id SERIAL PRIMARY KEY,
    query_hash VARCHAR(64) UNIQUE NOT NULL,
    query_text TEXT NOT NULL,
    query_embedding vector(1024),
    results JSONB,
    result_count INTEGER,
    search_type VARCHAR(30) DEFAULT 'profile', -- 'profile' ou 'knowledge'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '1 hour'
);

COMMENT ON TABLE search_cache IS 'Cache des recherches vectorielles pour optimiser les performances';

-- Index
CREATE INDEX IF NOT EXISTS idx_search_cache_hash ON search_cache(query_hash);
CREATE INDEX IF NOT EXISTS idx_search_cache_expires ON search_cache(expires_at);
CREATE INDEX IF NOT EXISTS idx_search_cache_type ON search_cache(search_type);


-- ============================================================================
-- 5. FONCTIONS UTILITAIRES POUR LES SOUS-WORKFLOWS
-- ============================================================================

-- Fonction: Recherche de profils compatibles
CREATE OR REPLACE FUNCTION search_compatible_profiles(
    p_gender VARCHAR DEFAULT NULL,
    p_age_min INTEGER DEFAULT NULL,
    p_age_max INTEGER DEFAULT NULL,
    p_city VARCHAR DEFAULT NULL,
    p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
    code VARCHAR,
    name VARCHAR,
    first_name VARCHAR,
    age SMALLINT,
    gender VARCHAR,
    city VARCHAR,
    profession VARCHAR,
    description_short TEXT,
    hobbies TEXT,
    compatibility_score DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.code,
        p.name,
        p.first_name,
        p.age,
        p.gender,
        p.city,
        p.profession,
        p.description_short,
        p.hobbies,
        -- Score de compatibilité simple basé sur les critères
        (
            CASE WHEN p_gender IS NULL OR p.gender = p_gender THEN 0.4 ELSE 0 END +
            CASE WHEN p_city IS NULL OR LOWER(p.city) = LOWER(p_city) THEN 0.3 ELSE 0.1 END +
            CASE WHEN p_age_min IS NULL OR p.age >= p_age_min THEN 0.15 ELSE 0 END +
            CASE WHEN p_age_max IS NULL OR p.age <= p_age_max THEN 0.15 ELSE 0 END
        )::DECIMAL AS compatibility_score
    FROM profiles p
    WHERE p.status = 'actif'
        AND (p_gender IS NULL OR p.gender = p_gender)
        AND (p_age_min IS NULL OR p.age >= p_age_min)
        AND (p_age_max IS NULL OR p.age <= p_age_max)
        AND (p_city IS NULL OR p.city ILIKE '%' || p_city || '%')
    ORDER BY 
        compatibility_score DESC,
        p.view_count DESC,
        p.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;


-- Fonction: Obtenir les détails complets d'un profil par code
CREATE OR REPLACE FUNCTION get_profile_by_code(p_code VARCHAR)
RETURNS TABLE (
    id INTEGER,
    code VARCHAR,
    name VARCHAR,
    first_name VARCHAR,
    age SMALLINT,
    gender VARCHAR,
    city VARCHAR,
    neighborhood VARCHAR,
    profession VARCHAR,
    education_level VARCHAR,
    religion VARCHAR,
    marital_status VARCHAR,
    has_children BOOLEAN,
    children_count SMALLINT,
    height SMALLINT,
    body_type VARCHAR,
    description_short TEXT,
    description_long TEXT,
    personality_traits TEXT,
    hobbies TEXT,
    lifestyle TEXT,
    search_age_min SMALLINT,
    search_age_max SMALLINT,
    search_city VARCHAR,
    search_criteria TEXT,
    photo_main_url TEXT,
    status VARCHAR,
    view_count INTEGER,
    contact_request_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.code,
        p.name,
        p.first_name,
        p.age,
        p.gender,
        p.city,
        p.neighborhood,
        p.profession,
        p.education_level,
        p.religion,
        p.marital_status,
        p.has_children,
        p.children_count,
        p.height,
        p.body_type,
        p.description_short,
        p.description_long,
        p.personality_traits,
        p.hobbies,
        p.lifestyle,
        p.search_age_min,
        p.search_age_max,
        p.search_city,
        p.search_criteria,
        p.photo_main_url,
        p.status,
        p.view_count,
        p.contact_request_count
    FROM profiles p
    WHERE UPPER(p.code) = UPPER(p_code)
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;


-- Fonction: Enregistrer une vue de profil
CREATE OR REPLACE FUNCTION log_profile_view(
    p_lead_id INTEGER,
    p_profile_code VARCHAR,
    p_conversation_id INTEGER DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_profile_id INTEGER;
BEGIN
    -- Trouver l'ID du profil
    SELECT id INTO v_profile_id 
    FROM profiles 
    WHERE UPPER(code) = UPPER(p_profile_code);
    
    IF v_profile_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Insérer la vue
    INSERT INTO profile_views (lead_id, profile_id, conversation_id, view_type, viewed_at)
    VALUES (p_lead_id, v_profile_id, p_conversation_id, 'detail', NOW());
    
    -- Mettre à jour le dernier profil vu sur le lead
    UPDATE leads 
    SET last_profile_viewed = p_profile_code,
        updated_at = NOW()
    WHERE id = p_lead_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;


-- Fonction: Créer une demande de contact
CREATE OR REPLACE FUNCTION create_contact_request(
    p_lead_id INTEGER,
    p_profile_code VARCHAR
)
RETURNS TABLE (
    request_id INTEGER,
    request_code VARCHAR,
    profile_name VARCHAR,
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_profile_id INTEGER;
    v_profile_name VARCHAR;
    v_existing_request INTEGER;
    v_new_request_id INTEGER;
    v_new_request_code VARCHAR;
BEGIN
    -- Trouver le profil
    SELECT id, name INTO v_profile_id, v_profile_name
    FROM profiles 
    WHERE UPPER(code) = UPPER(p_profile_code) AND status = 'actif';
    
    IF v_profile_id IS NULL THEN
        RETURN QUERY SELECT NULL::INTEGER, NULL::VARCHAR, NULL::VARCHAR, FALSE, 'Profil non trouvé ou inactif'::TEXT;
        RETURN;
    END IF;
    
    -- Vérifier s'il existe déjà une demande en cours
    SELECT id INTO v_existing_request
    FROM contact_requests
    WHERE lead_id = p_lead_id 
      AND profile_id = v_profile_id
      AND status NOT IN ('completed', 'cancelled', 'rejected')
    LIMIT 1;
    
    IF v_existing_request IS NOT NULL THEN
        SELECT request_code INTO v_new_request_code FROM contact_requests WHERE id = v_existing_request;
        RETURN QUERY SELECT v_existing_request, v_new_request_code, v_profile_name, TRUE, 'Demande existante trouvée'::TEXT;
        RETURN;
    END IF;
    
    -- Créer la nouvelle demande
    INSERT INTO contact_requests (lead_id, profile_id, status, payment_status, created_at, updated_at)
    VALUES (p_lead_id, v_profile_id, 'pending', 'unpaid', NOW(), NOW())
    RETURNING id, request_code INTO v_new_request_id, v_new_request_code;
    
    -- Mettre à jour le compteur du profil
    UPDATE profiles 
    SET contact_request_count = contact_request_count + 1
    WHERE id = v_profile_id;
    
    RETURN QUERY SELECT v_new_request_id, v_new_request_code, v_profile_name, TRUE, 'Demande créée avec succès'::TEXT;
END;
$$ LANGUAGE plpgsql;


-- Fonction: Recherche sémantique dans knowledge_base
CREATE OR REPLACE FUNCTION search_knowledge_base(
    p_query_embedding vector(1024),
    p_limit INTEGER DEFAULT 3,
    p_category VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id INTEGER,
    title VARCHAR,
    content TEXT,
    category VARCHAR,
    similarity FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        kb.id,
        kb.title,
        kb.content,
        kb.category,
        (1 - (kb.embedding <=> p_query_embedding))::FLOAT AS similarity
    FROM knowledge_base kb
    WHERE kb.is_active = true
        AND kb.embedding IS NOT NULL
        AND (p_category IS NULL OR kb.category = p_category)
    ORDER BY kb.embedding <=> p_query_embedding
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;


-- Fonction: Recherche sémantique dans profiles
CREATE OR REPLACE FUNCTION search_profiles_semantic(
    p_query_embedding vector(1024),
    p_gender VARCHAR DEFAULT NULL,
    p_city VARCHAR DEFAULT NULL,
    p_age_min INTEGER DEFAULT NULL,
    p_age_max INTEGER DEFAULT NULL,
    p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
    code VARCHAR,
    name VARCHAR,
    age SMALLINT,
    gender VARCHAR,
    city VARCHAR,
    profession VARCHAR,
    description_short TEXT,
    similarity FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.code,
        p.name,
        p.age,
        p.gender,
        p.city,
        p.profession,
        p.description_short,
        (1 - (p.embedding <=> p_query_embedding))::FLOAT AS similarity
    FROM profiles p
    WHERE p.status = 'actif'
        AND p.embedding IS NOT NULL
        AND (p_gender IS NULL OR p.gender = p_gender)
        AND (p_city IS NULL OR p.city ILIKE '%' || p_city || '%')
        AND (p_age_min IS NULL OR p.age >= p_age_min)
        AND (p_age_max IS NULL OR p.age <= p_age_max)
    ORDER BY p.embedding <=> p_query_embedding
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;


-- Fonction: Mettre à jour le score de qualification d'un lead
CREATE OR REPLACE FUNCTION update_qualification_score(p_lead_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_score INTEGER := 0;
    v_lead RECORD;
BEGIN
    SELECT * INTO v_lead FROM leads WHERE id = p_lead_id;
    
    IF v_lead IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Calcul du score (sur 100)
    IF v_lead.looking_for_gender IS NOT NULL THEN v_score := v_score + 25; END IF;
    IF v_lead.preferred_age_min IS NOT NULL THEN v_score := v_score + 20; END IF;
    IF v_lead.preferred_age_max IS NOT NULL THEN v_score := v_score + 5; END IF;
    IF v_lead.preferred_city IS NOT NULL THEN v_score := v_score + 25; END IF;
    IF v_lead.city IS NOT NULL THEN v_score := v_score + 10; END IF;
    IF v_lead.age IS NOT NULL THEN v_score := v_score + 10; END IF;
    IF v_lead.gender IS NOT NULL THEN v_score := v_score + 5; END IF;
    
    -- Mettre à jour le lead
    UPDATE leads 
    SET qualification_score = v_score,
        qualification_complete = (v_score >= 70),
        updated_at = NOW()
    WHERE id = p_lead_id;
    
    RETURN v_score;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- 6. TRIGGERS ADDITIONNELS
-- ============================================================================

-- Trigger: Mise à jour automatique du score de qualification
CREATE OR REPLACE FUNCTION trigger_update_qualification_score()
RETURNS TRIGGER AS $$
BEGIN
    -- Mettre à jour le score si les champs de qualification changent
    IF (OLD.looking_for_gender IS DISTINCT FROM NEW.looking_for_gender) OR
       (OLD.preferred_age_min IS DISTINCT FROM NEW.preferred_age_min) OR
       (OLD.preferred_city IS DISTINCT FROM NEW.preferred_city) THEN
        PERFORM update_qualification_score(NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_lead_qualification_score ON leads;
CREATE TRIGGER trigger_lead_qualification_score
    AFTER UPDATE ON leads
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_qualification_score();


-- Trigger: Incrémenter le compteur de messages
CREATE OR REPLACE FUNCTION trigger_increment_message_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE leads 
    SET message_count = message_count + 1
    WHERE id = NEW.lead_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_conversation_message_count ON conversations;
CREATE TRIGGER trigger_conversation_message_count
    AFTER INSERT ON conversations
    FOR EACH ROW
    WHEN (NEW.direction = 'in')
    EXECUTE FUNCTION trigger_increment_message_count();


-- Trigger: Mettre à jour last_agent sur le lead
CREATE OR REPLACE FUNCTION trigger_update_last_agent()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.sender_type = 'bot' AND NEW.intent IS NOT NULL THEN
        UPDATE leads 
        SET last_agent = NEW.intent,
            updated_at = NOW()
        WHERE id = NEW.lead_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_conversation_last_agent ON conversations;
CREATE TRIGGER trigger_conversation_last_agent
    AFTER INSERT ON conversations
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_last_agent();


-- ============================================================================
-- 7. VUES POUR LE MONITORING ET L'ANALYTICS
-- ============================================================================

-- Vue: Performance des agents
CREATE OR REPLACE VIEW agent_daily_stats AS
SELECT 
    DATE(created_at) as date,
    agent_name,
    COUNT(*) as total_calls,
    SUM(CASE WHEN success THEN 1 ELSE 0 END) as successful_calls,
    ROUND(AVG(duration_ms)::NUMERIC, 2) as avg_duration_ms,
    ROUND((SUM(CASE WHEN success THEN 1 ELSE 0 END)::FLOAT / NULLIF(COUNT(*), 0) * 100)::NUMERIC, 2) as success_rate
FROM agent_logs
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at), agent_name
ORDER BY date DESC, agent_name;


-- Vue: Performance des tools
CREATE OR REPLACE VIEW tool_daily_stats AS
SELECT 
    DATE(created_at) as date,
    tool_name,
    agent_name,
    COUNT(*) as total_calls,
    SUM(CASE WHEN success THEN 1 ELSE 0 END) as successful_calls,
    ROUND(AVG(duration_ms)::NUMERIC, 2) as avg_duration_ms,
    ROUND((SUM(CASE WHEN success THEN 1 ELSE 0 END)::FLOAT / NULLIF(COUNT(*), 0) * 100)::NUMERIC, 2) as success_rate
FROM tool_calls
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at), tool_name, agent_name
ORDER BY date DESC, total_calls DESC;


-- Vue: Funnel de conversion des leads
CREATE OR REPLACE VIEW lead_conversion_funnel AS
SELECT 
    'Nouveaux leads' as stage,
    1 as stage_order,
    COUNT(*) as count
FROM leads 
WHERE created_at >= NOW() - INTERVAL '30 days'
UNION ALL
SELECT 
    'Qualification commencée' as stage,
    2 as stage_order,
    COUNT(*) as count
FROM leads 
WHERE qualification_score > 0 
  AND created_at >= NOW() - INTERVAL '30 days'
UNION ALL
SELECT 
    'Qualification complète' as stage,
    3 as stage_order,
    COUNT(*) as count
FROM leads 
WHERE qualification_complete = true 
  AND created_at >= NOW() - INTERVAL '30 days'
UNION ALL
SELECT 
    'Profils consultés' as stage,
    4 as stage_order,
    COUNT(DISTINCT lead_id) as count
FROM profile_views 
WHERE viewed_at >= NOW() - INTERVAL '30 days'
UNION ALL
SELECT 
    'Demandes de contact' as stage,
    5 as stage_order,
    COUNT(DISTINCT lead_id) as count
FROM contact_requests 
WHERE created_at >= NOW() - INTERVAL '30 days'
UNION ALL
SELECT 
    'Paiements effectués' as stage,
    6 as stage_order,
    COUNT(DISTINCT lead_id) as count
FROM contact_requests 
WHERE payment_status = 'paid' 
  AND created_at >= NOW() - INTERVAL '30 days'
ORDER BY stage_order;


-- Vue: Activité en temps réel
CREATE OR REPLACE VIEW realtime_activity AS
SELECT 
    l.id as lead_id,
    l.name as lead_name,
    l.phone,
    l.status,
    l.qualification_score,
    l.last_agent,
    l.conversation_phase,
    c.content as last_message,
    c.direction as last_direction,
    c.created_at as last_activity,
    EXTRACT(EPOCH FROM (NOW() - c.created_at))/60 as minutes_since_last_activity
FROM leads l
JOIN LATERAL (
    SELECT content, direction, created_at 
    FROM conversations 
    WHERE lead_id = l.id 
    ORDER BY created_at DESC 
    LIMIT 1
) c ON true
WHERE c.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY c.created_at DESC;


-- Vue: Profils les plus populaires
CREATE OR REPLACE VIEW popular_profiles AS
SELECT 
    p.code,
    p.name,
    p.age,
    p.gender,
    p.city,
    p.view_count,
    p.contact_request_count,
    COUNT(DISTINCT pv.lead_id) as unique_viewers_30d,
    COUNT(DISTINCT cr.id) as requests_30d
FROM profiles p
LEFT JOIN profile_views pv ON p.id = pv.profile_id AND pv.viewed_at >= NOW() - INTERVAL '30 days'
LEFT JOIN contact_requests cr ON p.id = cr.profile_id AND cr.created_at >= NOW() - INTERVAL '30 days'
WHERE p.status = 'actif'
GROUP BY p.id, p.code, p.name, p.age, p.gender, p.city, p.view_count, p.contact_request_count
ORDER BY unique_viewers_30d DESC, requests_30d DESC
LIMIT 20;


-- ============================================================================
-- 8. INDEX ADDITIONNELS POUR LES PERFORMANCES
-- ============================================================================

-- Index pour les recherches fréquentes
CREATE INDEX IF NOT EXISTS idx_leads_last_agent ON leads(last_agent);
CREATE INDEX IF NOT EXISTS idx_leads_qualification_score ON leads(qualification_score);
CREATE INDEX IF NOT EXISTS idx_leads_message_count ON leads(message_count);
CREATE INDEX IF NOT EXISTS idx_leads_last_profile ON leads(last_profile_viewed);

-- Index pour les conversations récentes
CREATE INDEX IF NOT EXISTS idx_conversations_recent ON conversations(lead_id, created_at DESC);

-- Index pour le cache de recherche
CREATE INDEX IF NOT EXISTS idx_search_cache_active ON search_cache(query_hash);

-- Index GIN pour les recherches JSONB
CREATE INDEX IF NOT EXISTS idx_tool_calls_input ON tool_calls USING GIN(tool_input);
CREATE INDEX IF NOT EXISTS idx_tool_calls_output ON tool_calls USING GIN(tool_output);


-- ============================================================================
-- 9. DONNÉES DE CONFIGURATION ADDITIONNELLES
-- ============================================================================

-- Ajouter des configurations si elles n'existent pas
INSERT INTO admin_config (key, value, description, category) VALUES
('ai_router_temperature', '0.1', 'Température du modèle pour le routeur AI', 'ai'),
('ai_agent_temperature', '0.5', 'Température par défaut des agents', 'ai'),
('ai_max_tokens', '400', 'Nombre max de tokens pour les réponses', 'ai'),
('qualification_threshold', '70', 'Score minimum pour qualification complète (%)', 'qualification'),
('cache_ttl_minutes', '60', 'Durée de vie du cache de recherche (minutes)', 'performance'),
('max_profiles_per_search', '5', 'Nombre max de profils retournés par recherche', 'search'),
('escalation_keywords', 'conseiller,humain,contact,appeler,numéro,intéresse,rencontrer', 'Mots-clés déclenchant escalade', 'routing')
ON CONFLICT (key) DO NOTHING;


-- ============================================================================
-- 10. PROCÉDURE DE NETTOYAGE DU CACHE
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_search_cache()
RETURNS INTEGER AS $$
DECLARE
    v_deleted INTEGER;
BEGIN
    DELETE FROM search_cache WHERE expires_at < NOW();
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- 11. MISE À JOUR DES SCORES EXISTANTS
-- ============================================================================

-- Mettre à jour les scores de qualification pour tous les leads existants
DO $$
DECLARE
    v_lead RECORD;
BEGIN
    FOR v_lead IN SELECT id FROM leads LOOP
        PERFORM update_qualification_score(v_lead.id);
    END LOOP;
END $$;


-- ============================================================================
-- 12. PERMISSIONS (si nécessaire)
-- ============================================================================

-- Accorder les permissions sur les nouvelles tables/fonctions
-- (Décommenter et adapter selon votre configuration)
-- GRANT SELECT, INSERT, UPDATE ON workflow_config TO n8n_user;
-- GRANT SELECT, INSERT ON tool_calls TO n8n_user;
-- GRANT SELECT, INSERT, DELETE ON search_cache TO n8n_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO n8n_user;


COMMIT;

-- ============================================================================
-- VÉRIFICATION POST-MIGRATION
-- ============================================================================

-- Afficher les nouvelles tables
SELECT table_name, 
       (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_name IN ('workflow_config', 'tool_calls', 'search_cache')
ORDER BY table_name;

-- Afficher les nouvelles fonctions
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'search_compatible_profiles',
    'get_profile_by_code',
    'log_profile_view',
    'create_contact_request',
    'search_knowledge_base',
    'search_profiles_semantic',
    'update_qualification_score',
    'cleanup_search_cache'
  )
ORDER BY routine_name;

-- Afficher le nombre de leads avec score mis à jour
SELECT 
    COUNT(*) as total_leads,
    SUM(CASE WHEN qualification_score > 0 THEN 1 ELSE 0 END) as with_score,
    AVG(qualification_score) as avg_score
FROM leads;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS text TEXT;
