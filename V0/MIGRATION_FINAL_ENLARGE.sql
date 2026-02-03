-- Migration finale pour agrandir les colonnes de la table leads
-- Basé sur le schéma actuel extrait dans lead.sql et view.sql

BEGIN;

-- 1. Supprimer les vues dépendantes
DROP VIEW IF EXISTS public.lead_stats CASCADE;
DROP VIEW IF EXISTS public.active_conversations CASCADE;
DROP VIEW IF EXISTS public.dashboard_conversations CASCADE;
DROP VIEW IF EXISTS public.qualified_leads CASCADE;

-- 2. Agrandir les colonnes de la table leads
ALTER TABLE public.leads 
    ALTER COLUMN phone TYPE VARCHAR(100),
    ALTER COLUMN name TYPE VARCHAR(200),
    ALTER COLUMN status TYPE VARCHAR(100),
    ALTER COLUMN source TYPE VARCHAR(100),
    ALTER COLUMN conversation_phase TYPE VARCHAR(100);

-- 3. Recréer les vues avec leurs définitions originales exactes

-- View: active_conversations
CREATE OR REPLACE VIEW public.active_conversations AS
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

-- View: dashboard_conversations
CREATE OR REPLACE VIEW public.dashboard_conversations AS
 SELECT l.id AS lead_id,
    l.phone,
    l.name AS lead_name,
    l.city,
    l.status AS lead_status,
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
    l.created_at AS lead_created_at
   FROM public.leads l
  WHERE (EXISTS ( SELECT 1
           FROM public.conversations c
          WHERE ((c.lead_id = l.id) AND (c.created_at > (now() - '7 days'::interval)))))
  ORDER BY ( SELECT c.created_at
           FROM public.conversations c
          WHERE (c.lead_id = l.id)
          ORDER BY c.created_at DESC
         LIMIT 1) DESC NULLS LAST;

-- View: lead_stats
CREATE OR REPLACE VIEW public.lead_stats AS
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

-- View: qualified_leads
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

COMMIT;
