-- Migration pour agrandir les champs de la table leads et recréer les vues dépendantes
BEGIN;

-- 1. Supprimer les vues qui dépendent de la table leads
-- On utilise CASCADE par sécurité, bien que nous les recréions toutes explicitement
DROP VIEW IF EXISTS public.lead_stats CASCADE;
DROP VIEW IF EXISTS public.active_conversations CASCADE;
DROP VIEW IF EXISTS public.dashboard_conversations CASCADE;
DROP VIEW IF EXISTS public.qualified_leads CASCADE;

-- 2. Modifier la table leads
-- Phone: 100 pour supporter les identifiants WhatsApp longs/groupes
-- Name: 200 (était 120)
-- Status: 100 (était 40)
-- Source: 100 (était 50)
-- Conversation Phase: 100 (était 50)
ALTER TABLE public.leads 
    ALTER COLUMN phone TYPE VARCHAR(100),
    ALTER COLUMN name TYPE VARCHAR(200),
    ALTER COLUMN status TYPE VARCHAR(100),
    ALTER COLUMN source TYPE VARCHAR(100),
    ALTER COLUMN conversation_phase TYPE VARCHAR(100);

-- 3. Recréer les vues avec les nouvelles types de colonnes

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

CREATE OR REPLACE VIEW public.dashboard_conversations AS
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

CREATE OR REPLACE VIEW public.qualified_leads AS
SELECT
    NULL::integer AS id,
    NULL::character varying(200) AS name,
    NULL::character varying(100) AS phone,
    NULL::character varying(10) AS looking_for_gender,
    NULL::smallint AS preferred_age_min,
    NULL::smallint AS preferred_age_max,
    NULL::character varying(100) AS preferred_city,
    NULL::boolean AS qualification_complete,
    NULL::character varying(100) AS status,
    NULL::timestamp with time zone AS created_at,
    NULL::bigint AS message_count;

COMMIT;
