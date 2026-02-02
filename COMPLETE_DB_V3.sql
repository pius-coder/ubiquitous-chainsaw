--
-- PostgreSQL database dump
--

\restrict Opz3eKBnQRiVK1BKy1D05OO9n8MdJv0lkiF0nnxjGwOXLFexpMdYX3atIxIflnL

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


--
-- Name: check_qualification_complete(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_qualification_complete(lead_id_param integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: cleanup_old_data(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cleanup_old_data() RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: generate_profile_code(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_profile_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: generate_profile_search_text(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_profile_search_text() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: generate_request_code(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_request_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: increment_profile_view_count(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.increment_profile_view_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE profiles
    SET view_count = view_count + 1
    WHERE id = NEW.profile_id;
    
    RETURN NEW;
END;
$$;


--
-- Name: search_similar_profiles(public.vector, integer, character varying, character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.search_similar_profiles(query_embedding public.vector, limit_count integer DEFAULT 5, gender_filter character varying DEFAULT NULL::character varying, city_filter character varying DEFAULT NULL::character varying, min_age integer DEFAULT NULL::integer, max_age integer DEFAULT NULL::integer) RETURNS TABLE(code character varying, name character varying, age smallint, gender character varying, city character varying, profession character varying, description_short text, similarity double precision)
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: update_qualification_status(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_qualification_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.qualification_complete := (
        NEW.looking_for_gender IS NOT NULL AND
        NEW.preferred_age_min IS NOT NULL AND
        NEW.preferred_city IS NOT NULL
    );
    RETURN NEW;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id integer NOT NULL,
    lead_id integer NOT NULL,
    direction character varying(10) NOT NULL,
    content text NOT NULL,
    message_type character varying(40) DEFAULT 'text'::character varying,
    sender_type character varying(20) DEFAULT 'bot'::character varying,
    sender_id integer,
    status character varying(40) DEFAULT 'bot_actif'::character varying,
    profile_code character varying(20),
    intent character varying(50),
    sentiment character varying(20),
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: leads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leads (
    id integer NOT NULL,
    fb_id character varying(64),
    phone character varying(20) NOT NULL,
    name character varying(120) NOT NULL,
    first_name character varying(60),
    last_name character varying(60),
    city character varying(100),
    age smallint,
    gender character varying(10),
    status character varying(40) DEFAULT 'nouveau_lead'::character varying NOT NULL,
    source character varying(50) DEFAULT 'facebook_ads'::character varying,
    notes text,
    assigned_to integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    looking_for_gender character varying(10),
    preferred_age_min smallint,
    preferred_age_max smallint,
    preferred_city character varying(100),
    qualification_complete boolean DEFAULT false,
    last_profile_shown character varying(20),
    conversation_phase character varying(50) DEFAULT 'new'::character varying
);


--
-- Name: active_conversations; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.active_conversations AS
 SELECT l.id AS lead_id,
    l.phone,
    l.name AS lead_name,
    l.city,
    l.status AS lead_status,
    c.status AS conversation_status,
    count(c.id) AS message_count,
    max(c.created_at) AS last_message_at,
    string_agg((((c.direction)::text || ': '::text) || "left"(c.content, 50)), ' | '::text ORDER BY c.created_at DESC) AS recent_messages
   FROM (public.leads l
     JOIN public.conversations c ON ((l.id = c.lead_id)))
  WHERE ((c.status)::text = ANY ((ARRAY['bot_actif'::character varying, 'attente_humain'::character varying, 'humain_actif'::character varying])::text[]))
  GROUP BY l.id, l.phone, l.name, l.city, l.status, c.status
 HAVING (max(c.created_at) > (now() - '7 days'::interval));


--
-- Name: admin_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_config (
    key character varying(100) NOT NULL,
    value text NOT NULL,
    description text,
    category character varying(50),
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by integer
);


--
-- Name: admin_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_users (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(120) NOT NULL,
    password_hash character varying(255) NOT NULL,
    full_name character varying(120),
    phone character varying(20),
    role character varying(30) DEFAULT 'admin'::character varying NOT NULL,
    status character varying(20) DEFAULT 'actif'::character varying NOT NULL,
    last_login timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: admin_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_users_id_seq OWNED BY public.admin_users.id;


--
-- Name: agent_action_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_action_logs (
    id integer NOT NULL,
    lead_id integer,
    action_type character varying(50) NOT NULL,
    tool_name character varying(100),
    input_data jsonb,
    output_data jsonb,
    duration_ms integer,
    success boolean DEFAULT true,
    error_message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: agent_action_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_action_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_action_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_action_logs_id_seq OWNED BY public.agent_action_logs.id;


--
-- Name: agent_errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_errors (
    id integer NOT NULL,
    phone character varying(20) NOT NULL,
    error_type character varying(50) DEFAULT 'country_code'::character varying,
    pays_saisi character varying(100),
    agent_response text,
    stack_trace text,
    resolved boolean DEFAULT false,
    resolved_by integer,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: agent_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_errors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_errors_id_seq OWNED BY public.agent_errors.id;


--
-- Name: agent_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_logs (
    id integer NOT NULL,
    lead_id integer,
    agent_name character varying(50) NOT NULL,
    input_summary text,
    output_summary text,
    duration_ms integer,
    success boolean DEFAULT true,
    error_message text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: agent_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_logs_id_seq OWNED BY public.agent_logs.id;


--
-- Name: agent_performance; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.agent_performance AS
 SELECT agent_name,
    date(created_at) AS date,
    count(*) AS calls,
    avg(duration_ms) AS avg_duration_ms,
    ((sum(
        CASE
            WHEN success THEN 1
            ELSE 0
        END))::double precision / (NULLIF(count(*), 0))::double precision) AS success_rate
   FROM public.agent_logs
  WHERE (created_at > (now() - '7 days'::interval))
  GROUP BY agent_name, (date(created_at))
  ORDER BY (date(created_at)) DESC, agent_name;


--
-- Name: contact_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contact_requests (
    id integer NOT NULL,
    request_code character varying(20) NOT NULL,
    lead_id integer NOT NULL,
    profile_id integer NOT NULL,
    status character varying(40) DEFAULT 'pending'::character varying NOT NULL,
    payment_status character varying(30) DEFAULT 'unpaid'::character varying,
    payment_amount numeric(10,2),
    payment_method character varying(30),
    admin_notes text,
    contact_shared_at timestamp with time zone,
    assigned_to integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone
);


--
-- Name: contact_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contact_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contact_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contact_requests_id_seq OWNED BY public.contact_requests.id;


--
-- Name: conversation_memory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_memory (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    text text NOT NULL,
    metadata jsonb,
    embedding public.vector(1024),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversations_id_seq OWNED BY public.conversations.id;


--
-- Name: dashboard_conversations; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.dashboard_conversations AS
 SELECT id AS lead_id,
    phone,
    name AS lead_name,
    city,
    status AS lead_status,
    ( SELECT c.status
           FROM public.conversations c
          WHERE (c.lead_id = l.id)
          ORDER BY c.created_at DESC
         LIMIT 1) AS conversation_status,
    ( SELECT count(*) AS count
           FROM public.conversations c
          WHERE (c.lead_id = l.id)) AS message_count,
    ( SELECT c.created_at
           FROM public.conversations c
          WHERE (c.lead_id = l.id)
          ORDER BY c.created_at DESC
         LIMIT 1) AS last_message_at,
    ( SELECT c.content
           FROM public.conversations c
          WHERE ((c.lead_id = l.id) AND ((c.direction)::text = 'in'::text))
          ORDER BY c.created_at DESC
         LIMIT 1) AS last_client_message,
    created_at AS lead_created_at
   FROM public.leads l
  WHERE (EXISTS ( SELECT 1
           FROM public.conversations c
          WHERE ((c.lead_id = l.id) AND (c.created_at > (now() - '7 days'::interval)))))
  ORDER BY ( SELECT c.created_at
           FROM public.conversations c
          WHERE (c.lead_id = l.id)
          ORDER BY c.created_at DESC
         LIMIT 1) DESC NULLS LAST;


--
-- Name: knowledge_base; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_base (
    id integer NOT NULL,
    content text NOT NULL,
    metadata jsonb,
    embedding public.vector(1024),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    title character varying(255),
    category character varying(100),
    tags text[],
    is_active boolean DEFAULT true,
    updated_at timestamp with time zone DEFAULT now(),
    indexed_at timestamp with time zone
);


--
-- Name: knowledge_base_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.knowledge_base_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knowledge_base_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.knowledge_base_id_seq OWNED BY public.knowledge_base.id;


--
-- Name: profile_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_views (
    id integer NOT NULL,
    lead_id integer NOT NULL,
    profile_id integer NOT NULL,
    conversation_id integer,
    view_type character varying(30) DEFAULT 'detail'::character varying,
    viewed_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: lead_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.lead_stats AS
 SELECT l.id,
    l.phone,
    l.name,
    l.city,
    l.status,
    l.source,
    count(DISTINCT c.id) AS total_messages,
    count(DISTINCT c.id) FILTER (WHERE ((c.direction)::text = 'in'::text)) AS messages_received,
    count(DISTINCT c.id) FILTER (WHERE ((c.direction)::text = 'out'::text)) AS messages_sent,
    count(DISTINCT pv.profile_id) AS profiles_viewed,
    count(DISTINCT cr.id) AS contact_requests,
    max(c.created_at) AS last_interaction_at,
    l.created_at,
    l.assigned_to
   FROM (((public.leads l
     LEFT JOIN public.conversations c ON ((l.id = c.lead_id)))
     LEFT JOIN public.profile_views pv ON ((l.id = pv.lead_id)))
     LEFT JOIN public.contact_requests cr ON ((l.id = cr.lead_id)))
  GROUP BY l.id, l.phone, l.name, l.city, l.status, l.source, l.created_at, l.assigned_to;


--
-- Name: leads_duplicates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leads_duplicates (
    id integer NOT NULL,
    fb_id character varying(64) NOT NULL,
    phone character varying(20) NOT NULL,
    existing_lead_id integer NOT NULL,
    detected_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: leads_duplicates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leads_duplicates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leads_duplicates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leads_duplicates_id_seq OWNED BY public.leads_duplicates.id;


--
-- Name: leads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leads_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leads_id_seq OWNED BY public.leads.id;


--
-- Name: messages_sent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages_sent (
    id integer NOT NULL,
    lead_id integer,
    channel character varying(20) NOT NULL,
    message_type character varying(40) NOT NULL,
    content text,
    status character varying(20) DEFAULT 'sent'::character varying NOT NULL,
    error_message text,
    sent_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: messages_sent_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_sent_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_sent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_sent_id_seq OWNED BY public.messages_sent.id;


--
-- Name: n8n_chat_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.n8n_chat_histories (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    message jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: n8n_chat_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.n8n_chat_histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: n8n_chat_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.n8n_chat_histories_id_seq OWNED BY public.n8n_chat_histories.id;


--
-- Name: payment_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_transactions (
    id integer NOT NULL,
    transaction_code character varying(30) NOT NULL,
    contact_request_id integer NOT NULL,
    lead_id integer NOT NULL,
    amount numeric(10,2) NOT NULL,
    currency character varying(10) DEFAULT 'XAF'::character varying,
    payment_method character varying(30) NOT NULL,
    payment_reference character varying(100),
    status character varying(30) DEFAULT 'pending'::character varying NOT NULL,
    provider character varying(50),
    provider_reference character varying(100),
    notes text,
    verified_by integer,
    verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: payment_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_transactions_id_seq OWNED BY public.payment_transactions.id;


--
-- Name: profile_recommendations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_recommendations (
    id integer NOT NULL,
    lead_id integer NOT NULL,
    profile_id integer NOT NULL,
    recommended_by character varying(20) DEFAULT 'ai_agent'::character varying,
    admin_id integer,
    score numeric(3,2),
    reason text,
    status character varying(30) DEFAULT 'suggested'::character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: profile_recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profile_recommendations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profile_recommendations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profile_recommendations_id_seq OWNED BY public.profile_recommendations.id;


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id integer NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(120) NOT NULL,
    first_name character varying(60),
    last_name character varying(60),
    age smallint NOT NULL,
    gender character varying(10) NOT NULL,
    city character varying(100) NOT NULL,
    neighborhood character varying(100),
    profession character varying(150),
    workplace character varying(150),
    education_level character varying(100),
    religion character varying(50),
    religious_practice character varying(50),
    marital_status character varying(50),
    has_children boolean DEFAULT false,
    children_count smallint,
    height smallint,
    body_type character varying(30),
    description_short text,
    description_long text,
    personality_traits text,
    hobbies text,
    lifestyle text,
    search_age_min smallint,
    search_age_max smallint,
    search_city character varying(100),
    search_religion character varying(50),
    search_education character varying(100),
    search_criteria text,
    photo_main_url text,
    photo_urls text[],
    phone character varying(20) NOT NULL,
    whatsapp character varying(20),
    email character varying(120),
    status character varying(40) DEFAULT 'actif'::character varying NOT NULL,
    publication_count integer DEFAULT 0,
    view_count integer DEFAULT 0,
    contact_request_count integer DEFAULT 0,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    published_at timestamp with time zone,
    archived_at timestamp with time zone,
    embedding public.vector(1024),
    search_text text,
    vector_metadata jsonb,
    indexed_at timestamp with time zone
);


--
-- Name: profile_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.profile_stats AS
 SELECT p.id,
    p.code,
    p.name,
    p.age,
    p.city,
    p.status,
    p.view_count,
    p.contact_request_count,
    count(DISTINCT pv.lead_id) AS unique_viewers,
    count(DISTINCT cr.id) AS total_requests,
    count(DISTINCT cr.id) FILTER (WHERE ((cr.status)::text = 'completed'::text)) AS completed_requests,
    max(pv.viewed_at) AS last_viewed_at,
    p.created_at,
    p.published_at
   FROM ((public.profiles p
     LEFT JOIN public.profile_views pv ON ((p.id = pv.profile_id)))
     LEFT JOIN public.contact_requests cr ON ((p.id = cr.profile_id)))
  GROUP BY p.id, p.code, p.name, p.age, p.city, p.status, p.view_count, p.contact_request_count, p.created_at, p.published_at;


--
-- Name: profile_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profile_views_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profile_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profile_views_id_seq OWNED BY public.profile_views.id;


--
-- Name: profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profiles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profiles_id_seq OWNED BY public.profiles.id;


--
-- Name: qualified_leads; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.qualified_leads AS
SELECT
    NULL::integer AS id,
    NULL::character varying(120) AS name,
    NULL::character varying(20) AS phone,
    NULL::character varying(10) AS looking_for_gender,
    NULL::smallint AS preferred_age_min,
    NULL::smallint AS preferred_age_max,
    NULL::character varying(100) AS preferred_city,
    NULL::boolean AS qualification_complete,
    NULL::character varying(40) AS status,
    NULL::timestamp with time zone AS created_at,
    NULL::bigint AS message_count;


--
-- Name: admin_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users ALTER COLUMN id SET DEFAULT nextval('public.admin_users_id_seq'::regclass);


--
-- Name: agent_action_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_action_logs ALTER COLUMN id SET DEFAULT nextval('public.agent_action_logs_id_seq'::regclass);


--
-- Name: agent_errors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_errors ALTER COLUMN id SET DEFAULT nextval('public.agent_errors_id_seq'::regclass);


--
-- Name: agent_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_logs ALTER COLUMN id SET DEFAULT nextval('public.agent_logs_id_seq'::regclass);


--
-- Name: contact_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_requests ALTER COLUMN id SET DEFAULT nextval('public.contact_requests_id_seq'::regclass);


--
-- Name: conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations ALTER COLUMN id SET DEFAULT nextval('public.conversations_id_seq'::regclass);


--
-- Name: knowledge_base id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_base ALTER COLUMN id SET DEFAULT nextval('public.knowledge_base_id_seq'::regclass);


--
-- Name: leads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads ALTER COLUMN id SET DEFAULT nextval('public.leads_id_seq'::regclass);


--
-- Name: leads_duplicates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads_duplicates ALTER COLUMN id SET DEFAULT nextval('public.leads_duplicates_id_seq'::regclass);


--
-- Name: messages_sent id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages_sent ALTER COLUMN id SET DEFAULT nextval('public.messages_sent_id_seq'::regclass);


--
-- Name: n8n_chat_histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.n8n_chat_histories ALTER COLUMN id SET DEFAULT nextval('public.n8n_chat_histories_id_seq'::regclass);


--
-- Name: payment_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_transactions ALTER COLUMN id SET DEFAULT nextval('public.payment_transactions_id_seq'::regclass);


--
-- Name: profile_recommendations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_recommendations ALTER COLUMN id SET DEFAULT nextval('public.profile_recommendations_id_seq'::regclass);


--
-- Name: profile_views id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_views ALTER COLUMN id SET DEFAULT nextval('public.profile_views_id_seq'::regclass);


--
-- Name: profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles ALTER COLUMN id SET DEFAULT nextval('public.profiles_id_seq'::regclass);


--
-- Name: admin_config admin_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_config
    ADD CONSTRAINT admin_config_pkey PRIMARY KEY (key);


--
-- Name: admin_users admin_users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_email_key UNIQUE (email);


--
-- Name: admin_users admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: admin_users admin_users_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_username_key UNIQUE (username);


--
-- Name: agent_action_logs agent_action_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_action_logs
    ADD CONSTRAINT agent_action_logs_pkey PRIMARY KEY (id);


--
-- Name: agent_errors agent_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_errors
    ADD CONSTRAINT agent_errors_pkey PRIMARY KEY (id);


--
-- Name: agent_logs agent_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_logs
    ADD CONSTRAINT agent_logs_pkey PRIMARY KEY (id);


--
-- Name: contact_requests contact_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_requests
    ADD CONSTRAINT contact_requests_pkey PRIMARY KEY (id);


--
-- Name: contact_requests contact_requests_request_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_requests
    ADD CONSTRAINT contact_requests_request_code_key UNIQUE (request_code);


--
-- Name: conversation_memory conversation_memory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_memory
    ADD CONSTRAINT conversation_memory_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: knowledge_base knowledge_base_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_base
    ADD CONSTRAINT knowledge_base_pkey PRIMARY KEY (id);


--
-- Name: leads_duplicates leads_duplicates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads_duplicates
    ADD CONSTRAINT leads_duplicates_pkey PRIMARY KEY (id);


--
-- Name: leads leads_fb_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_fb_id_key UNIQUE (fb_id);


--
-- Name: leads leads_phone_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_phone_key UNIQUE (phone);


--
-- Name: leads leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (id);


--
-- Name: messages_sent messages_sent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages_sent
    ADD CONSTRAINT messages_sent_pkey PRIMARY KEY (id);


--
-- Name: n8n_chat_histories n8n_chat_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.n8n_chat_histories
    ADD CONSTRAINT n8n_chat_histories_pkey PRIMARY KEY (id);


--
-- Name: payment_transactions payment_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_pkey PRIMARY KEY (id);


--
-- Name: payment_transactions payment_transactions_transaction_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_transaction_code_key UNIQUE (transaction_code);


--
-- Name: profile_recommendations profile_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_recommendations
    ADD CONSTRAINT profile_recommendations_pkey PRIMARY KEY (id);


--
-- Name: profile_views profile_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_views
    ADD CONSTRAINT profile_views_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_code_key UNIQUE (code);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: idx_admin_config_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_config_category ON public.admin_config USING btree (category);


--
-- Name: idx_admin_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_users_email ON public.admin_users USING btree (email);


--
-- Name: idx_admin_users_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_users_username ON public.admin_users USING btree (username);


--
-- Name: idx_agent_errors_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_errors_date ON public.agent_errors USING btree (created_at DESC);


--
-- Name: idx_agent_errors_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_errors_phone ON public.agent_errors USING btree (phone);


--
-- Name: idx_agent_errors_resolved; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_errors_resolved ON public.agent_errors USING btree (resolved);


--
-- Name: idx_agent_errors_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_errors_type ON public.agent_errors USING btree (error_type);


--
-- Name: idx_agent_logs_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_logs_action ON public.agent_action_logs USING btree (action_type);


--
-- Name: idx_agent_logs_agent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_logs_agent ON public.agent_logs USING btree (agent_name);


--
-- Name: idx_agent_logs_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_logs_created ON public.agent_logs USING btree (created_at DESC);


--
-- Name: idx_agent_logs_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_logs_date ON public.agent_action_logs USING btree (created_at DESC);


--
-- Name: idx_agent_logs_lead; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_logs_lead ON public.agent_action_logs USING btree (lead_id);


--
-- Name: idx_agent_logs_tool; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_logs_tool ON public.agent_action_logs USING btree (tool_name);


--
-- Name: idx_chat_histories_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_chat_histories_session ON public.n8n_chat_histories USING btree (session_id, created_at DESC);


--
-- Name: idx_contact_requests_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contact_requests_code ON public.contact_requests USING btree (request_code);


--
-- Name: idx_contact_requests_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contact_requests_created ON public.contact_requests USING btree (created_at DESC);


--
-- Name: idx_contact_requests_lead; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contact_requests_lead ON public.contact_requests USING btree (lead_id);


--
-- Name: idx_contact_requests_payment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contact_requests_payment ON public.contact_requests USING btree (payment_status);


--
-- Name: idx_contact_requests_profile; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contact_requests_profile ON public.contact_requests USING btree (profile_id);


--
-- Name: idx_contact_requests_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contact_requests_status ON public.contact_requests USING btree (status);


--
-- Name: idx_conversations_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_created ON public.conversations USING btree (created_at DESC);


--
-- Name: idx_conversations_intent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_intent ON public.conversations USING btree (intent);


--
-- Name: idx_conversations_lead; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_lead ON public.conversations USING btree (lead_id, created_at DESC);


--
-- Name: idx_conversations_lead_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_lead_date ON public.conversations USING btree (lead_id, created_at DESC);


--
-- Name: idx_conversations_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_metadata ON public.conversations USING gin (metadata);


--
-- Name: idx_conversations_profile; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_profile ON public.conversations USING btree (profile_code);


--
-- Name: idx_conversations_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_status ON public.conversations USING btree (status);


--
-- Name: idx_kb_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kb_active ON public.knowledge_base USING btree (is_active);


--
-- Name: idx_kb_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kb_category ON public.knowledge_base USING btree (category);


--
-- Name: idx_kb_embedding; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kb_embedding ON public.knowledge_base USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: idx_kb_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kb_tags ON public.knowledge_base USING gin (tags);


--
-- Name: idx_leads_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_active ON public.leads USING btree (phone, name, status) WHERE ((status)::text = ANY ((ARRAY['nouveau_lead'::character varying, 'prospect_actif'::character varying, 'prospect_anonyme'::character varying])::text[]));


--
-- Name: idx_leads_assigned; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_assigned ON public.leads USING btree (assigned_to);


--
-- Name: idx_leads_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_created ON public.leads USING btree (created_at DESC);


--
-- Name: idx_leads_duplicates_detected; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_duplicates_detected ON public.leads_duplicates USING btree (detected_at DESC);


--
-- Name: idx_leads_duplicates_existing; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_duplicates_existing ON public.leads_duplicates USING btree (existing_lead_id);


--
-- Name: idx_leads_phase; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_phase ON public.leads USING btree (conversation_phase);


--
-- Name: idx_leads_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_phone ON public.leads USING btree (phone);


--
-- Name: idx_leads_qualification; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_qualification ON public.leads USING btree (qualification_complete);


--
-- Name: idx_leads_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_status ON public.leads USING btree (status);


--
-- Name: idx_memory_embedding; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_memory_embedding ON public.conversation_memory USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: idx_memory_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_memory_metadata ON public.conversation_memory USING gin (metadata);


--
-- Name: idx_messages_sent_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_sent_date ON public.messages_sent USING btree (sent_at DESC);


--
-- Name: idx_messages_sent_lead; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_sent_lead ON public.messages_sent USING btree (lead_id);


--
-- Name: idx_messages_sent_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_sent_status ON public.messages_sent USING btree (status);


--
-- Name: idx_messages_sent_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_sent_type ON public.messages_sent USING btree (message_type);


--
-- Name: idx_payment_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_created ON public.payment_transactions USING btree (created_at DESC);


--
-- Name: idx_payment_lead; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_lead ON public.payment_transactions USING btree (lead_id);


--
-- Name: idx_payment_reference; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_reference ON public.payment_transactions USING btree (payment_reference);


--
-- Name: idx_payment_request; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_request ON public.payment_transactions USING btree (contact_request_id);


--
-- Name: idx_payment_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_status ON public.payment_transactions USING btree (status);


--
-- Name: idx_payment_txn_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_txn_code ON public.payment_transactions USING btree (transaction_code);


--
-- Name: idx_profile_views_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profile_views_date ON public.profile_views USING btree (viewed_at DESC);


--
-- Name: idx_profile_views_lead; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profile_views_lead ON public.profile_views USING btree (lead_id);


--
-- Name: idx_profile_views_profile; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profile_views_profile ON public.profile_views USING btree (profile_id);


--
-- Name: idx_profile_views_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profile_views_unique ON public.profile_views USING btree (lead_id, profile_id, viewed_at DESC);


--
-- Name: idx_profiles_active_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_active_search ON public.profiles USING btree (status, gender, city, age) WHERE ((status)::text = 'actif'::text);


--
-- Name: idx_profiles_age; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_age ON public.profiles USING btree (age);


--
-- Name: idx_profiles_city; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_city ON public.profiles USING btree (city);


--
-- Name: idx_profiles_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_code ON public.profiles USING btree (code);


--
-- Name: idx_profiles_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_created ON public.profiles USING btree (created_at DESC);


--
-- Name: idx_profiles_embedding; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_embedding ON public.profiles USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: idx_profiles_gender; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_gender ON public.profiles USING btree (gender);


--
-- Name: idx_profiles_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_published ON public.profiles USING btree (published_at DESC);


--
-- Name: idx_profiles_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_search ON public.profiles USING btree (status, gender, city, age);


--
-- Name: idx_profiles_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_status ON public.profiles USING btree (status);


--
-- Name: idx_recommendations_lead; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recommendations_lead ON public.profile_recommendations USING btree (lead_id);


--
-- Name: idx_recommendations_profile; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recommendations_profile ON public.profile_recommendations USING btree (profile_id);


--
-- Name: idx_recommendations_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recommendations_score ON public.profile_recommendations USING btree (score DESC);


--
-- Name: idx_recommendations_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recommendations_status ON public.profile_recommendations USING btree (status);


--
-- Name: qualified_leads _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.qualified_leads AS
 SELECT l.id,
    l.name,
    l.phone,
    l.looking_for_gender,
    l.preferred_age_min,
    l.preferred_age_max,
    l.preferred_city,
    l.qualification_complete,
    l.status,
    l.created_at,
    count(c.id) AS message_count
   FROM (public.leads l
     LEFT JOIN public.conversations c ON ((l.id = c.lead_id)))
  WHERE (l.qualification_complete = true)
  GROUP BY l.id
  ORDER BY l.created_at DESC;


--
-- Name: profiles trigger_generate_profile_code; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_generate_profile_code BEFORE INSERT ON public.profiles FOR EACH ROW WHEN (((new.code IS NULL) OR ((new.code)::text = ''::text))) EXECUTE FUNCTION public.generate_profile_code();


--
-- Name: contact_requests trigger_generate_request_code; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_generate_request_code BEFORE INSERT ON public.contact_requests FOR EACH ROW WHEN (((new.request_code IS NULL) OR ((new.request_code)::text = ''::text))) EXECUTE FUNCTION public.generate_request_code();


--
-- Name: profiles trigger_generate_search_text; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_generate_search_text BEFORE INSERT OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.generate_profile_search_text();


--
-- Name: profile_views trigger_increment_view_count; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_increment_view_count AFTER INSERT ON public.profile_views FOR EACH ROW EXECUTE FUNCTION public.increment_profile_view_count();


--
-- Name: leads trigger_qualification_check; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_qualification_check BEFORE UPDATE ON public.leads FOR EACH ROW EXECUTE FUNCTION public.update_qualification_status();


--
-- Name: admin_users update_admin_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON public.admin_users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: contact_requests update_contact_requests_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_contact_requests_updated_at BEFORE UPDATE ON public.contact_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: leads update_leads_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON public.leads FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: payment_transactions update_payment_transactions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_payment_transactions_updated_at BEFORE UPDATE ON public.payment_transactions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: profiles update_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: admin_config admin_config_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_config
    ADD CONSTRAINT admin_config_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.admin_users(id);


--
-- Name: agent_action_logs agent_action_logs_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_action_logs
    ADD CONSTRAINT agent_action_logs_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id);


--
-- Name: agent_errors agent_errors_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_errors
    ADD CONSTRAINT agent_errors_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.admin_users(id);


--
-- Name: agent_logs agent_logs_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_logs
    ADD CONSTRAINT agent_logs_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id);


--
-- Name: contact_requests contact_requests_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_requests
    ADD CONSTRAINT contact_requests_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.admin_users(id);


--
-- Name: contact_requests contact_requests_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_requests
    ADD CONSTRAINT contact_requests_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: contact_requests contact_requests_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_requests
    ADD CONSTRAINT contact_requests_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: conversations conversations_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: conversations conversations_profile_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_profile_code_fkey FOREIGN KEY (profile_code) REFERENCES public.profiles(code);


--
-- Name: conversations conversations_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.admin_users(id);


--
-- Name: leads leads_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.admin_users(id);


--
-- Name: leads_duplicates leads_duplicates_existing_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads_duplicates
    ADD CONSTRAINT leads_duplicates_existing_lead_id_fkey FOREIGN KEY (existing_lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: messages_sent messages_sent_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages_sent
    ADD CONSTRAINT messages_sent_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE SET NULL;


--
-- Name: payment_transactions payment_transactions_contact_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_contact_request_id_fkey FOREIGN KEY (contact_request_id) REFERENCES public.contact_requests(id) ON DELETE CASCADE;


--
-- Name: payment_transactions payment_transactions_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: payment_transactions payment_transactions_verified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES public.admin_users(id);


--
-- Name: profile_recommendations profile_recommendations_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_recommendations
    ADD CONSTRAINT profile_recommendations_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admin_users(id);


--
-- Name: profile_recommendations profile_recommendations_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_recommendations
    ADD CONSTRAINT profile_recommendations_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: profile_recommendations profile_recommendations_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_recommendations
    ADD CONSTRAINT profile_recommendations_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: profile_views profile_views_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_views
    ADD CONSTRAINT profile_views_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE SET NULL;


--
-- Name: profile_views profile_views_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_views
    ADD CONSTRAINT profile_views_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: profile_views profile_views_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_views
    ADD CONSTRAINT profile_views_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.admin_users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict Opz3eKBnQRiVK1BKy1D05OO9n8MdJv0lkiF0nnxjGwOXLFexpMdYX3atIxIflnL

--
-- PostgreSQL database dump
--

\restrict 9Zytijd1sxxj7xEtkKdddZagV6eTjbo8LRjdFTdoSc3HnYBVAYdTometrL06SBh

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: admin_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_config (key, value, description, category, updated_at, updated_by) FROM stdin;
admin_phone	237657526695	Numéro WhatsApp de l'administrateur principal	whatsapp	2026-02-02 09:42:16.930614+01	\N
welcome_message_enabled	true	Activer le message de bienvenue automatique	system	2026-02-02 09:42:16.930614+01	\N
bot_auto_response_enabled	true	Activer les réponses automatiques du bot	system	2026-02-02 09:42:16.930614+01	\N
contact_request_fee	5000	Frais de mise en relation (en FCFA)	payment	2026-02-02 09:42:16.930614+01	\N
group_whatsapp_link	https://chat.whatsapp.com/xxxxx	Lien du groupe WhatsApp des profils	whatsapp	2026-02-02 09:42:16.930614+01	\N
group_facebook_link	https://facebook.com/groups/xxxxx	Lien du groupe Facebook des profils	facebook	2026-02-02 09:42:16.930614+01	\N
business_name	Agence Matrimoniale Premium	Nom de l'agence	system	2026-02-02 09:42:16.930614+01	\N
business_phone	237657526695	Numéro de contact principal	system	2026-02-02 09:42:16.930614+01	\N
business_email	contact@agence-matrimoniale.com	Email de contact	system	2026-02-02 09:42:16.930614+01	\N
\.


--
-- Data for Name: knowledge_base; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_base (id, content, metadata, embedding, created_at, title, category, tags, is_active, updated_at, indexed_at) FROM stdin;
1	L'Agence Matrimoniale Cameroun (AMC) est une agence sérieuse spécialisée dans la mise en relation de personnes cherchant une relation durable. Nous opérons principalement au Cameroun et en Afrique centrale. Notre mission est d'aider les célibataires à trouver leur partenaire idéal de manière sécurisée et professionnelle.	\N	\N	2026-02-02 09:42:23.870248+01	Présentation de l'agence	presentation	{agence,présentation,"qui sommes nous"}	t	2026-02-02 09:42:23.870248+01	\N
2	Comment ça marche ? 1) Inscrivez-vous en nous contactant. 2) Un conseiller vous appelle pour comprendre vos attentes. 3) Nous créons votre profil anonyme (code MAT-XXXX-XXX). 4) Nous vous présentons des profils compatibles. 5) Si un profil vous intéresse, vous demandez une mise en relation. 6) Après paiement, nous facilitons le premier contact.	\N	\N	2026-02-02 09:42:23.870248+01	Fonctionnement de l'agence	fonctionnement	{comment,marche,processus,étapes}	t	2026-02-02 09:42:23.870248+01	\N
3	Les tarifs varient selon les services : - Inscription : Gratuite. - Consultation de profils : Gratuite. - Frais de mise en relation : 5000 FCFA par contact. - Abonnement premium (recommandations prioritaires) : 15000 FCFA/mois. Pour les tarifs exacts et les promotions en cours, contactez un conseiller.	\N	\N	2026-02-02 09:42:23.870248+01	Tarifs et frais	tarifs	{prix,tarif,coût,paiement,combien}	t	2026-02-02 09:42:23.870248+01	\N
4	Nous acceptons les paiements suivants : - Mobile Money (MTN MoMo, Orange Money) - Virement bancaire - Espèces (en agence). Pour effectuer un paiement, contactez notre conseiller qui vous guidera.	\N	\N	2026-02-02 09:42:23.870248+01	Modes de paiement	paiement	{payer,momo,"orange money",paiement}	t	2026-02-02 09:42:23.870248+01	\N
5	Votre vie privée est notre priorité. Vos informations personnelles (téléphone, adresse) ne sont JAMAIS partagées sans votre accord. Chaque profil est identifié par un code anonyme (MAT-XXXX-XXX). La mise en relation nécessite le consentement des deux parties.	\N	\N	2026-02-02 09:42:23.870248+01	Confidentialité et sécurité	securite	{confidentialité,sécurité,privé,données}	t	2026-02-02 09:42:23.870248+01	\N
6	Nos profils incluent des informations comme : âge, ville, profession, niveau d'études, religion, situation matrimoniale, description physique, centres d'intérêt, et critères de recherche. Tous les profils sont vérifiés par notre équipe.	\N	\N	2026-02-02 09:42:23.870248+01	Critères de profils	profils	{profil,critère,recherche,femme,homme}	t	2026-02-02 09:42:23.870248+01	\N
7	Nous avons des profils dans les principales villes du Cameroun : Douala, Yaoundé, Bafoussam, Bamenda, Garoua, Maroua, Kribi, Limbé, Buéa. Nous développons aussi notre présence en Afrique centrale.	\N	\N	2026-02-02 09:42:23.870248+01	Villes couvertes	geographie	{ville,douala,yaoundé,cameroun,où}	t	2026-02-02 09:42:23.870248+01	\N
8	Pour parler à un conseiller humain, vous pouvez : - Demander une escalade dans cette conversation. - Appeler directement notre ligne. - Nous envoyer un email. Un conseiller vous recontactera dans les 24h ouvrées.	\N	\N	2026-02-02 09:42:23.870248+01	Contacter un conseiller	contact	{conseiller,humain,appeler,contacter}	t	2026-02-02 09:42:23.870248+01	\N
9	L'Agence Matrimoniale Cameroun (AMC) est une agence sérieuse spécialisée dans la mise en relation de personnes cherchant une relation durable. Nous opérons principalement au Cameroun et en Afrique centrale. Notre mission est d'aider les célibataires à trouver leur partenaire idéal de manière sécurisée et professionnelle.	\N	\N	2026-02-02 09:43:54.626661+01	Présentation de l'agence	presentation	{agence,présentation,"qui sommes nous"}	t	2026-02-02 09:43:54.626661+01	\N
10	Comment ça marche ? 1) Inscrivez-vous en nous contactant. 2) Un conseiller vous appelle pour comprendre vos attentes. 3) Nous créons votre profil anonyme (code MAT-XXXX-XXX). 4) Nous vous présentons des profils compatibles. 5) Si un profil vous intéresse, vous demandez une mise en relation. 6) Après paiement, nous facilitons le premier contact.	\N	\N	2026-02-02 09:43:54.626661+01	Fonctionnement de l'agence	fonctionnement	{comment,marche,processus,étapes}	t	2026-02-02 09:43:54.626661+01	\N
11	Les tarifs varient selon les services : - Inscription : Gratuite. - Consultation de profils : Gratuite. - Frais de mise en relation : 5000 FCFA par contact. - Abonnement premium (recommandations prioritaires) : 15000 FCFA/mois. Pour les tarifs exacts et les promotions en cours, contactez un conseiller.	\N	\N	2026-02-02 09:43:54.626661+01	Tarifs et frais	tarifs	{prix,tarif,coût,paiement,combien}	t	2026-02-02 09:43:54.626661+01	\N
12	Nous acceptons les paiements suivants : - Mobile Money (MTN MoMo, Orange Money) - Virement bancaire - Espèces (en agence). Pour effectuer un paiement, contactez notre conseiller qui vous guidera.	\N	\N	2026-02-02 09:43:54.626661+01	Modes de paiement	paiement	{payer,momo,"orange money",paiement}	t	2026-02-02 09:43:54.626661+01	\N
13	Votre vie privée est notre priorité. Vos informations personnelles (téléphone, adresse) ne sont JAMAIS partagées sans votre accord. Chaque profil est identifié par un code anonyme (MAT-XXXX-XXX). La mise en relation nécessite le consentement des deux parties.	\N	\N	2026-02-02 09:43:54.626661+01	Confidentialité et sécurité	securite	{confidentialité,sécurité,privé,données}	t	2026-02-02 09:43:54.626661+01	\N
14	Nos profils incluent des informations comme : âge, ville, profession, niveau d'études, religion, situation matrimoniale, description physique, centres d'intérêt, et critères de recherche. Tous les profils sont vérifiés par notre équipe.	\N	\N	2026-02-02 09:43:54.626661+01	Critères de profils	profils	{profil,critère,recherche,femme,homme}	t	2026-02-02 09:43:54.626661+01	\N
15	Nous avons des profils dans les principales villes du Cameroun : Douala, Yaoundé, Bafoussam, Bamenda, Garoua, Maroua, Kribi, Limbé, Buéa. Nous développons aussi notre présence en Afrique centrale.	\N	\N	2026-02-02 09:43:54.626661+01	Villes couvertes	geographie	{ville,douala,yaoundé,cameroun,où}	t	2026-02-02 09:43:54.626661+01	\N
16	Pour parler à un conseiller humain, vous pouvez : - Demander une escalade dans cette conversation. - Appeler directement notre ligne. - Nous envoyer un email. Un conseiller vous recontactera dans les 24h ouvrées.	\N	\N	2026-02-02 09:43:54.626661+01	Contacter un conseiller	contact	{conseiller,humain,appeler,contacter}	t	2026-02-02 09:43:54.626661+01	\N
17	Pour votre premier rendez-vous : 1) Choisissez un lieu public et neutre (café, restaurant). 2) Soyez ponctuel et soignez votre présentation. 3) Restez vous-même et soyez honnête sur vos attentes. 4) Écoutez autant que vous parlez. 5) Évitez les sujets trop sensibles (ex-partenaires, finances personnelles) lors du premier contact. L'objectif est de découvrir si une étincelle est possible.	\N	\N	2026-02-02 10:10:12.218181+01	Conseils pour une première rencontre réussie	conseils	{conseils,rencontre,rendez-vous,succès}	t	2026-02-02 10:10:12.218181+01	\N
18	Pour garantir la sécurité et la sincérité de notre base de données, chaque membre doit fournir : 1) Une copie d'une pièce d'identité valide (CNI ou Passeport). 2) Un justificatif de domicile ou de situation professionnelle. 3) Des photos récentes sans filtres excessifs. Ces documents restent strictement confidentiels et servent uniquement à la validation par nos conseillers.	\N	\N	2026-02-02 10:10:12.218181+01	Vérification des profils et documents requis	securite	{documents,vérification,cni,validation,inscription}	t	2026-02-02 10:10:12.218181+01	\N
19	L'AMC s'engage à : 1) Lutter contre les faux profils et les arnaques. 2) Promouvoir le respect mutuel entre les membres. 3) Ne jamais divulguer de données de contact sans consentement explicite et validation de la demande. 4) Accompagner humainement chaque membre dans sa quête. Nous privilégions la qualité à la quantité.	\N	\N	2026-02-02 10:10:12.218181+01	Engagement éthique de l'agence	ethique	{engagement,valeurs,respect,sérieux}	t	2026-02-02 10:10:12.218181+01	\N
20	Une fois la mise en relation validée : 1) Vous recevez le contact WhatsApp/Téléphone du profil. 2) Nous vous conseillons de passer un premier appel vocal avant de vous rencontrer. 3) Un conseiller peut assurer un suivi pour savoir comment s'est passé le premier échange. Si la rencontre ne daboutit pas, nous analysons ensemble vos critères pour affiner les prochaines suggestions.	\N	\N	2026-02-02 10:10:12.218181+01	Processus après la mise en relation	fonctionnement	{après,contact,suivi,processus}	t	2026-02-02 10:10:12.218181+01	\N
21	En plus des mises en relation individuelles, l'AMC organise trimestriellement des soirées \\"Speed Dating\\" et des dîners de gala à Douala et Yaoundé. Ces événements sont réservés aux membres validés et permettent de rencontrer plusieurs profils dans un cadre sécurisé et convivial. Les invitations sont envoyées via WhatsApp.	\N	\N	2026-02-02 10:10:12.218181+01	Événements et Rencontres de groupe	evenements	{soirée,gala,"speed dating",groupe,douala,yaoundé}	t	2026-02-02 10:10:12.218181+01	\N
22	La formule Standard (Gratuite) vous permet d'être dans la base et d'être contacté. La formule Premium (15 000 FCFA/mois) vous offre : 1) Une visibilité prioritaire auprès des profils qui vous correspondent. 2) Des recommandations personnalisées par un conseiller dédié. 3) Un accès prioritaire aux événements de l'agence. 4) Une analyse de compatibilité approfondie.	\N	\N	2026-02-02 10:10:12.218181+01	Différence entre Formule Standard et Premium	tarifs	{premium,standard,abonnement,avantages}	t	2026-02-02 10:10:12.218181+01	\N
\.


--
-- Name: knowledge_base_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.knowledge_base_id_seq', 22, true);


--
-- PostgreSQL database dump complete
--

\unrestrict 9Zytijd1sxxj7xEtkKdddZagV6eTjbo8LRjdFTdoSc3HnYBVAYdTometrL06SBh

