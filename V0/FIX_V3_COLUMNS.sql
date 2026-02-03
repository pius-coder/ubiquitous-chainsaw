-- ============================================================================
-- FIX V3 COLUMNS AND TABLES
-- ============================================================================

BEGIN;

-- 1. FIX LEADS COLUMNS (V2)
DO $$
BEGIN
    -- looking_for_gender
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'looking_for_gender') THEN
        ALTER TABLE leads ADD COLUMN looking_for_gender VARCHAR(10);
    END IF;
    
    -- preferred_age_min
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'preferred_age_min') THEN
        ALTER TABLE leads ADD COLUMN preferred_age_min SMALLINT;
    END IF;
    
    -- preferred_age_max
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'preferred_age_max') THEN
        ALTER TABLE leads ADD COLUMN preferred_age_max SMALLINT;
    END IF;
    
    -- preferred_city
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'preferred_city') THEN
        ALTER TABLE leads ADD COLUMN preferred_city VARCHAR(100);
    END IF;
    
    -- qualification_complete
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'qualification_complete') THEN
        ALTER TABLE leads ADD COLUMN qualification_complete BOOLEAN DEFAULT false;
    END IF;
    
    -- conversation_phase
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'conversation_phase') THEN
        ALTER TABLE leads ADD COLUMN conversation_phase VARCHAR(50) DEFAULT 'new';
    END IF;
    
    -- last_profile_shown
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'last_profile_shown') THEN
        ALTER TABLE leads ADD COLUMN last_profile_shown VARCHAR(20);
    END IF;
END $$;

-- 2. FIX LEADS COLUMNS (V3)
DO $$
BEGIN
    -- last_agent
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'last_agent') THEN
        ALTER TABLE leads ADD COLUMN last_agent VARCHAR(50);
    END IF;
    
    -- qualification_score
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'qualification_score') THEN
        ALTER TABLE leads ADD COLUMN qualification_score SMALLINT DEFAULT 0;
    END IF;
    
    -- message_count
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'message_count') THEN
        ALTER TABLE leads ADD COLUMN message_count INTEGER DEFAULT 0;
    END IF;
    
    -- last_profile_viewed
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'leads' AND column_name = 'last_profile_viewed') THEN
        ALTER TABLE leads ADD COLUMN last_profile_viewed VARCHAR(20);
    END IF;
END $$;

-- 3. FIX CONVERSATIONS COLUMNS (V3)
DO $$
BEGIN
    -- confidence_score
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'conversations' AND column_name = 'confidence_score') THEN
        ALTER TABLE conversations ADD COLUMN confidence_score DECIMAL(3,2);
    END IF;
    
    -- tokens_used
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'conversations' AND column_name = 'tokens_used') THEN
        ALTER TABLE conversations ADD COLUMN tokens_used INTEGER;
    END IF;
    
    -- response_time_ms
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'conversations' AND column_name = 'response_time_ms') THEN
        ALTER TABLE conversations ADD COLUMN response_time_ms INTEGER;
    END IF;
END $$;

-- 4. FIX TABLES (V3)
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

CREATE TABLE IF NOT EXISTS search_cache (
    id SERIAL PRIMARY KEY,
    query_hash VARCHAR(64) UNIQUE NOT NULL,
    query_text TEXT NOT NULL,
    query_embedding vector(1024),
    results JSONB,
    result_count INTEGER,
    search_type VARCHAR(30) DEFAULT 'profile',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '1 hour'
);

-- 5. FIX PROFILES COLUMN (for RAG)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'text') THEN
        ALTER TABLE profiles ADD COLUMN text TEXT;
    END IF;
END $$;

COMMIT;
