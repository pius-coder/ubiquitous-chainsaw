-- =====================================================
-- MIGRATION MISE À JOUR - AGENCE MATRIMONIALE
-- Version: 2.0.0
-- Description: Corrections et améliorations pour n8n
-- =====================================================

-- =====================================================
-- ÉTAPE 1 : Table pour la mémoire de chat n8n
-- =====================================================

-- Table de mémoire de chat n8n (format attendu par le node)
CREATE TABLE IF NOT EXISTS n8n_chat_histories (
    id              SERIAL PRIMARY KEY,
    session_id      VARCHAR(255) NOT NULL,
    message         JSONB NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour récupération rapide par session
CREATE INDEX IF NOT EXISTS idx_chat_histories_session 
ON n8n_chat_histories (session_id, created_at DESC);

-- =====================================================
-- ÉTAPE 2 : Amélioration de la table profiles pour RAG
-- =====================================================

-- Ajouter colonne pour le texte de recherche sémantique
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS search_text TEXT;

-- Ajouter colonne pour les métadonnées du vecteur
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS vector_metadata JSONB;

-- Fonction pour générer automatiquement le search_text
CREATE OR REPLACE FUNCTION generate_profile_search_text()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_text := COALESCE(NEW.name, '') || ' ' ||
                       COALESCE(NEW.first_name, '') || ' ' ||
                       COALESCE(NEW.age::TEXT, '') || ' ans ' ||
                       COALESCE(NEW.gender, '') || ' ' ||
                       COALESCE(NEW.city, '') || ' ' ||
                       COALESCE(NEW.profession, '') || ' ' ||
                       COALESCE(NEW.education_level, '') || ' ' ||
                       COALESCE(NEW.religion, '') || ' ' ||
                       COALESCE(NEW.marital_status, '') || ' ' ||
                       COALESCE(NEW.description_short, '') || ' ' ||
                       COALESCE(NEW.description_long, '') || ' ' ||
                       COALESCE(NEW.personality_traits, '') || ' ' ||
                       COALESCE(NEW.hobbies, '');
    
    NEW.vector_metadata := jsonb_build_object(
        'code', NEW.code,
        'name', NEW.name,
        'age', NEW.age,
        'gender', NEW.gender,
        'city', NEW.city,
        'profession', NEW.profession,
        'status', NEW.status
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour auto-générer search_text
DROP TRIGGER IF EXISTS trigger_generate_search_text ON profiles;
CREATE TRIGGER trigger_generate_search_text
BEFORE INSERT OR UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION generate_profile_search_text();

-- Mettre à jour les profils existants
UPDATE profiles SET 
    search_text = COALESCE(name, '') || ' ' ||
                  COALESCE(first_name, '') || ' ' ||
                  COALESCE(age::TEXT, '') || ' ans ' ||
                  COALESCE(gender, '') || ' ' ||
                  COALESCE(city, '') || ' ' ||
                  COALESCE(profession, '') || ' ' ||
                  COALESCE(education_level, '') || ' ' ||
                  COALESCE(religion, '') || ' ' ||
                  COALESCE(marital_status, '') || ' ' ||
                  COALESCE(description_short, '') || ' ' ||
                  COALESCE(description_long, '') || ' ' ||
                  COALESCE(personality_traits, '') || ' ' ||
                  COALESCE(hobbies, ''),
    vector_metadata = jsonb_build_object(
        'code', code,
        'name', name,
        'age', age,
        'gender', gender,
        'city', city,
        'profession', profession,
        'status', status
    )
WHERE search_text IS NULL;

-- =====================================================
-- ÉTAPE 3 : Amélioration de la table knowledge_base
-- =====================================================

-- Ajouter colonnes manquantes
ALTER TABLE knowledge_base 
ADD COLUMN IF NOT EXISTS title VARCHAR(255),
ADD COLUMN IF NOT EXISTS category VARCHAR(100),
ADD COLUMN IF NOT EXISTS tags TEXT[],
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Index pour recherche par catégorie
CREATE INDEX IF NOT EXISTS idx_kb_category ON knowledge_base (category);
CREATE INDEX IF NOT EXISTS idx_kb_active ON knowledge_base (is_active);
CREATE INDEX IF NOT EXISTS idx_kb_tags ON knowledge_base USING GIN (tags);

-- =====================================================
-- ÉTAPE 4 : Contenu initial de la knowledge_base
-- =====================================================

INSERT INTO knowledge_base (title, content, category, tags, is_active) VALUES
(
    'Présentation de l''agence',
    'L''Agence Matrimoniale Cameroun (AMC) est une agence sérieuse spécialisée dans la mise en relation de personnes cherchant une relation durable. Nous opérons principalement au Cameroun et en Afrique centrale. Notre mission est d''aider les célibataires à trouver leur partenaire idéal de manière sécurisée et professionnelle.',
    'presentation',
    ARRAY['agence', 'présentation', 'qui sommes nous'],
    TRUE
),
(
    'Fonctionnement de l''agence',
    'Comment ça marche ? 1) Inscrivez-vous en nous contactant. 2) Un conseiller vous appelle pour comprendre vos attentes. 3) Nous créons votre profil anonyme (code MAT-XXXX-XXX). 4) Nous vous présentons des profils compatibles. 5) Si un profil vous intéresse, vous demandez une mise en relation. 6) Après paiement, nous facilitons le premier contact.',
    'fonctionnement',
    ARRAY['comment', 'marche', 'processus', 'étapes'],
    TRUE
),
(
    'Tarifs et frais',
    'Les tarifs varient selon les services : - Inscription : Gratuite. - Consultation de profils : Gratuite. - Frais de mise en relation : 5000 FCFA par contact. - Abonnement premium (recommandations prioritaires) : 15000 FCFA/mois. Pour les tarifs exacts et les promotions en cours, contactez un conseiller.',
    'tarifs',
    ARRAY['prix', 'tarif', 'coût', 'paiement', 'combien'],
    TRUE
),
(
    'Modes de paiement',
    'Nous acceptons les paiements suivants : - Mobile Money (MTN MoMo, Orange Money) - Virement bancaire - Espèces (en agence). Pour effectuer un paiement, contactez notre conseiller qui vous guidera.',
    'paiement',
    ARRAY['payer', 'momo', 'orange money', 'paiement'],
    TRUE
),
(
    'Confidentialité et sécurité',
    'Votre vie privée est notre priorité. Vos informations personnelles (téléphone, adresse) ne sont JAMAIS partagées sans votre accord. Chaque profil est identifié par un code anonyme (MAT-XXXX-XXX). La mise en relation nécessite le consentement des deux parties.',
    'securite',
    ARRAY['confidentialité', 'sécurité', 'privé', 'données'],
    TRUE
),
(
    'Critères de profils',
    'Nos profils incluent des informations comme : âge, ville, profession, niveau d''études, religion, situation matrimoniale, description physique, centres d''intérêt, et critères de recherche. Tous les profils sont vérifiés par notre équipe.',
    'profils',
    ARRAY['profil', 'critère', 'recherche', 'femme', 'homme'],
    TRUE
),
(
    'Villes couvertes',
    'Nous avons des profils dans les principales villes du Cameroun : Douala, Yaoundé, Bafoussam, Bamenda, Garoua, Maroua, Kribi, Limbé, Buéa. Nous développons aussi notre présence en Afrique centrale.',
    'geographie',
    ARRAY['ville', 'douala', 'yaoundé', 'cameroun', 'où'],
    TRUE
),
(
    'Contacter un conseiller',
    'Pour parler à un conseiller humain, vous pouvez : - Demander une escalade dans cette conversation. - Appeler directement notre ligne. - Nous envoyer un email. Un conseiller vous recontactera dans les 24h ouvrées.',
    'contact',
    ARRAY['conseiller', 'humain', 'appeler', 'contacter'],
    TRUE
)
ON CONFLICT DO NOTHING;

-- =====================================================
-- ÉTAPE 5 : Table de logs améliorée
-- =====================================================

-- Table de logs des actions de l'agent
CREATE TABLE IF NOT EXISTS agent_action_logs (
    id              SERIAL PRIMARY KEY,
    lead_id         INT REFERENCES leads(id),
    action_type     VARCHAR(50) NOT NULL,  -- tool_call, response, error, escalation
    tool_name       VARCHAR(100),
    input_data      JSONB,
    output_data     JSONB,
    duration_ms     INT,
    success         BOOLEAN DEFAULT TRUE,
    error_message   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour analyse
CREATE INDEX IF NOT EXISTS idx_agent_logs_lead ON agent_action_logs (lead_id);
CREATE INDEX IF NOT EXISTS idx_agent_logs_action ON agent_action_logs (action_type);
CREATE INDEX IF NOT EXISTS idx_agent_logs_tool ON agent_action_logs (tool_name);
CREATE INDEX IF NOT EXISTS idx_agent_logs_date ON agent_action_logs (created_at DESC);

-- =====================================================
-- ÉTAPE 6 : Vue pour le dashboard des conversations
-- =====================================================

CREATE OR REPLACE VIEW dashboard_conversations AS
SELECT 
    l.id AS lead_id,
    l.phone,
    l.name AS lead_name,
    l.city,
    l.status AS lead_status,
    (
        SELECT c.status 
        FROM conversations c 
        WHERE c.lead_id = l.id 
        ORDER BY c.created_at DESC 
        LIMIT 1
    ) AS conversation_status,
    (
        SELECT COUNT(*) 
        FROM conversations c 
        WHERE c.lead_id = l.id
    ) AS message_count,
    (
        SELECT c.created_at 
        FROM conversations c 
        WHERE c.lead_id = l.id 
        ORDER BY c.created_at DESC 
        LIMIT 1
    ) AS last_message_at,
    (
        SELECT c.content 
        FROM conversations c 
        WHERE c.lead_id = l.id AND c.direction = 'in'
        ORDER BY c.created_at DESC 
        LIMIT 1
    ) AS last_client_message,
    l.created_at AS lead_created_at
FROM leads l
WHERE EXISTS (
    SELECT 1 FROM conversations c 
    WHERE c.lead_id = l.id 
    AND c.created_at > NOW() - INTERVAL '7 days'
)
ORDER BY (
    SELECT c.created_at 
    FROM conversations c 
    WHERE c.lead_id = l.id 
    ORDER BY c.created_at DESC 
    LIMIT 1
) DESC NULLS LAST;

-- =====================================================
-- ÉTAPE 7 : Fonction pour recherche vectorielle des profils
-- =====================================================

CREATE OR REPLACE FUNCTION search_similar_profiles(
    query_embedding VECTOR(1024),
    limit_count INT DEFAULT 5,
    gender_filter VARCHAR DEFAULT NULL,
    city_filter VARCHAR DEFAULT NULL,
    min_age INT DEFAULT NULL,
    max_age INT DEFAULT NULL
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
        1 - (p.embedding <=> query_embedding) AS similarity
    FROM profiles p
    WHERE p.status = 'actif'
        AND p.embedding IS NOT NULL
        AND (gender_filter IS NULL OR p.gender = gender_filter)
        AND (city_filter IS NULL OR p.city ILIKE '%' || city_filter || '%')
        AND (min_age IS NULL OR p.age >= min_age)
        AND (max_age IS NULL OR p.age <= max_age)
    ORDER BY p.embedding <=> query_embedding
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ÉTAPE 8 : Index additionnels pour performance
-- =====================================================

-- Index composés pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_conversations_lead_date 
ON conversations (lead_id, created_at DESC);

-- Index partiel pour les leads actifs (FIXED: removed invalid index with NOW())
CREATE INDEX IF NOT EXISTS idx_profiles_active_search 
ON profiles (status, gender, city, age) 
WHERE status = 'actif';

CREATE INDEX IF NOT EXISTS idx_leads_active 
ON leads (phone, name, status) 
WHERE status IN ('nouveau_lead', 'prospect_actif', 'prospect_anonyme');

-- =====================================================
-- ÉTAPE 9 : Nettoyage et maintenance
-- =====================================================

-- Fonction de nettoyage des anciennes conversations
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
BEGIN
    -- Archiver les conversations de plus de 90 jours
    UPDATE conversations 
    SET status = 'archivé'
    WHERE status != 'archivé' 
    AND created_at < NOW() - INTERVAL '90 days';
    
    -- Supprimer les logs de plus de 180 jours
    DELETE FROM agent_action_logs 
    WHERE created_at < NOW() - INTERVAL '180 days';
    
    -- Supprimer les anciennes entrées de mémoire de chat
    DELETE FROM n8n_chat_histories 
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    RAISE NOTICE 'Cleanup completed at %', NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VÉRIFICATION FINALE
-- =====================================================

DO $$
DECLARE
    table_count INT;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE';
    
    RAISE NOTICE '✅ Migration terminée avec succès!';
    RAISE NOTICE '📊 Nombre de tables: %', table_count;
END $$;

-- Afficher les tables créées
SELECT table_name, 
       (SELECT COUNT(*) FROM information_schema.columns c 
        WHERE c.table_name = t.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;