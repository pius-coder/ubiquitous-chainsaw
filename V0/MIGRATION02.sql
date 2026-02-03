-- =====================================================
-- MIGRATION v3.0 - ARCHITECTURE MULTI-AGENTS
-- Run this after init_schema.sql and MIGRATION01.sql
-- =====================================================

-- 1. Colonnes de préférences sur leads
ALTER TABLE leads ADD COLUMN IF NOT EXISTS looking_for_gender VARCHAR(10);
ALTER TABLE leads ADD COLUMN IF NOT EXISTS preferred_age_min SMALLINT;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS preferred_age_max SMALLINT;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS preferred_city VARCHAR(100);
ALTER TABLE leads ADD COLUMN IF NOT EXISTS qualification_complete BOOLEAN DEFAULT FALSE;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS last_profile_shown VARCHAR(20);
ALTER TABLE leads ADD COLUMN IF NOT EXISTS conversation_phase VARCHAR(50) DEFAULT 'new';

-- Index pour qualification
CREATE INDEX IF NOT EXISTS idx_leads_qualification ON leads (qualification_complete);
CREATE INDEX IF NOT EXISTS idx_leads_phase ON leads (conversation_phase);

-- 2. Améliorer knowledge_base
ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS title VARCHAR(255);
ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS indexed_at TIMESTAMPTZ;

-- 3. Ajouter indexed_at sur profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS indexed_at TIMESTAMPTZ;

-- 4. Table de log des agents (pour debug et analytics)
CREATE TABLE IF NOT EXISTS agent_logs (
    id SERIAL PRIMARY KEY,
    lead_id INT REFERENCES leads(id),
    agent_name VARCHAR(50) NOT NULL,
    input_summary TEXT,
    output_summary TEXT,
    duration_ms INT,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agent_logs_lead ON agent_logs (lead_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_agent_logs_agent ON agent_logs (agent_name);
CREATE INDEX IF NOT EXISTS idx_agent_logs_created ON agent_logs (created_at DESC);

-- 5. Vue pour le dashboard des agents
CREATE OR REPLACE VIEW agent_performance AS
SELECT
    agent_name,
    DATE(created_at) as date,
    COUNT(*) as calls,
    AVG(duration_ms) as avg_duration_ms,
    SUM(CASE WHEN success THEN 1 ELSE 0 END)::FLOAT / NULLIF(COUNT(*), 0) as success_rate
FROM agent_logs
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY agent_name, DATE(created_at)
ORDER BY date DESC, agent_name;

-- 6. Fonction pour vérifier si qualification complète
CREATE OR REPLACE FUNCTION check_qualification_complete(lead_id_param INT)
RETURNS BOOLEAN AS $$
DECLARE
    is_complete BOOLEAN;
BEGIN
    SELECT (
        looking_for_gender IS NOT NULL AND
        preferred_age_min IS NOT NULL AND
        preferred_city IS NOT NULL
    ) INTO is_complete
    FROM leads
    WHERE id = lead_id_param;

    RETURN COALESCE(is_complete, FALSE);
END;
$$ LANGUAGE plpgsql;

-- 7. Trigger pour auto-update qualification_complete
CREATE OR REPLACE FUNCTION update_qualification_status()
RETURNS TRIGGER AS $$
BEGIN
    NEW.qualification_complete := (
        NEW.looking_for_gender IS NOT NULL AND
        NEW.preferred_age_min IS NOT NULL AND
        NEW.preferred_city IS NOT NULL
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_qualification_check ON leads;
CREATE TRIGGER trigger_qualification_check
BEFORE UPDATE ON leads
FOR EACH ROW
EXECUTE FUNCTION update_qualification_status();

-- 8. Vue des leads qualifiés
CREATE OR REPLACE VIEW qualified_leads AS
SELECT 
    l.id,
    l.name,
    l.phone,
    l.looking_for_gender,
    l.preferred_age_min,
    l.preferred_age_max,
    l.preferred_city,
    l.qualification_complete,
    l.status,
    l.created_at,
    COUNT(c.id) as message_count
FROM leads l
LEFT JOIN conversations c ON l.id = c.lead_id
WHERE l.qualification_complete = TRUE
GROUP BY l.id
ORDER BY l.created_at DESC;

-- 9. Vue des conversations actives
CREATE OR REPLACE VIEW active_conversations AS
SELECT 
    l.id as lead_id,
    l.name,
    l.phone,
    l.status as lead_status,
    c.status as conv_status,
    c.content as last_message,
    c.sender_type as last_sender,
    c.created_at as last_message_at
FROM leads l
INNER JOIN LATERAL (
    SELECT * FROM conversations 
    WHERE lead_id = l.id 
    ORDER BY created_at DESC 
    LIMIT 1
) c ON TRUE
WHERE c.created_at > NOW() - INTERVAL '24 hours'
ORDER BY c.created_at DESC;

-- Vérification
SELECT 'Migration v3.0 terminée avec succès' AS status;
