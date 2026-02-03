        viewname         |                                                                         definition                                                                         
-------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------
 lead_stats              |  SELECT l.id,                                                                                                                                             +
                         |     l.phone,                                                                                                                                              +
                         |     l.name,                                                                                                                                               +
                         |     l.city,                                                                                                                                               +
                         |     l.status,                                                                                                                                             +
                         |     l.source,                                                                                                                                             +
                         |     count(DISTINCT c.id) AS total_messages,                                                                                                               +
                         |     count(DISTINCT c.id) FILTER (WHERE ((c.direction)::text = 'in'::text)) AS messages_received,                                                          +
                         |     count(DISTINCT c.id) FILTER (WHERE ((c.direction)::text = 'out'::text)) AS messages_sent,                                                             +
                         |     count(DISTINCT pv.profile_id) AS profiles_viewed,                                                                                                     +
                         |     count(DISTINCT cr.id) AS contact_requests,                                                                                                            +
                         |     max(c.created_at) AS last_interaction_at,                                                                                                             +
                         |     l.created_at,                                                                                                                                         +
                         |     l.assigned_to                                                                                                                                         +
                         |    FROM (((leads l                                                                                                                                        +
                         |      LEFT JOIN conversations c ON ((l.id = c.lead_id)))                                                                                                   +
                         |      LEFT JOIN profile_views pv ON ((l.id = pv.lead_id)))                                                                                                 +
                         |      LEFT JOIN contact_requests cr ON ((l.id = cr.lead_id)))                                                                                              +
                         |   GROUP BY l.id, l.phone, l.name, l.city, l.status, l.source, l.created_at, l.assigned_to;
 active_conversations    |  SELECT l.id AS lead_id,                                                                                                                                  +
                         |     l.phone,                                                                                                                                              +
                         |     l.name AS lead_name,                                                                                                                                  +
                         |     l.city,                                                                                                                                               +
                         |     l.status AS lead_status,                                                                                                                              +
                         |     c.status AS conversation_status,                                                                                                                      +
                         |     count(c.id) AS message_count,                                                                                                                         +
                         |     max(c.created_at) AS last_message_at,                                                                                                                 +
                         |     string_agg((((c.direction)::text || ': '::text) || "left"(c.content, 50)), ' | '::text ORDER BY c.created_at DESC) AS recent_messages                 +
                         |    FROM (leads l                                                                                                                                          +
                         |      JOIN conversations c ON ((l.id = c.lead_id)))                                                                                                        +
                         |   WHERE ((c.status)::text = ANY ((ARRAY['bot_actif'::character varying, 'attente_humain'::character varying, 'humain_actif'::character varying])::text[]))+
                         |   GROUP BY l.id, l.phone, l.name, l.city, l.status, c.status                                                                                              +
                         |  HAVING (max(c.created_at) > (now() - '7 days'::interval));
 dashboard_conversations |  SELECT id AS lead_id,                                                                                                                                    +
                         |     phone,                                                                                                                                                +
                         |     name AS lead_name,                                                                                                                                    +
                         |     city,                                                                                                                                                 +
                         |     status AS lead_status,                                                                                                                                +
                         |     ( SELECT c.status                                                                                                                                     +
                         |            FROM conversations c                                                                                                                           +
                         |           WHERE (c.lead_id = l.id)                                                                                                                        +
                         |           ORDER BY c.created_at DESC                                                                                                                      +
                         |          LIMIT 1) AS conversation_status,                                                                                                                 +
                         |     ( SELECT count(*) AS count                                                                                                                            +
                         |            FROM conversations c                                                                                                                           +
                         |           WHERE (c.lead_id = l.id)) AS message_count,                                                                                                     +
                         |     ( SELECT c.created_at                                                                                                                                 +
                         |            FROM conversations c                                                                                                                           +
                         |           WHERE (c.lead_id = l.id)                                                                                                                        +
                         |           ORDER BY c.created_at DESC                                                                                                                      +
                         |          LIMIT 1) AS last_message_at,                                                                                                                     +
                         |     ( SELECT c.content                                                                                                                                    +
                         |            FROM conversations c                                                                                                                           +
                         |           WHERE ((c.lead_id = l.id) AND ((c.direction)::text = 'in'::text))                                                                               +
                         |           ORDER BY c.created_at DESC                                                                                                                      +
                         |          LIMIT 1) AS last_client_message,                                                                                                                 +
                         |     created_at AS lead_created_at                                                                                                                         +
                         |    FROM leads l                                                                                                                                           +
                         |   WHERE (EXISTS ( SELECT 1                                                                                                                                +
                         |            FROM conversations c                                                                                                                           +
                         |           WHERE ((c.lead_id = l.id) AND (c.created_at > (now() - '7 days'::interval)))))                                                                  +
                         |   ORDER BY ( SELECT c.created_at                                                                                                                          +
                         |            FROM conversations c                                                                                                                           +
                         |           WHERE (c.lead_id = l.id)                                                                                                                        +
                         |           ORDER BY c.created_at DESC                                                                                                                      +
                         |          LIMIT 1) DESC NULLS LAST;
 qualified_leads         |  SELECT l.id,                                                                                                                                             +
                         |     l.name,                                                                                                                                               +
                         |     l.phone,                                                                                                                                              +
                         |     l.looking_for_gender,                                                                                                                                 +
                         |     l.preferred_age_min,                                                                                                                                  +
                         |     l.preferred_age_max,                                                                                                                                  +
                         |     l.preferred_city,                                                                                                                                     +
                         |     l.qualification_complete,                                                                                                                             +
                         |     l.status,                                                                                                                                             +
                         |     l.created_at,                                                                                                                                         +
                         |     count(c.id) AS message_count                                                                                                                          +
                         |    FROM (leads l                                                                                                                                          +
                         |      LEFT JOIN conversations c ON ((l.id = c.lead_id)))                                                                                                   +
                         |   WHERE (l.qualification_complete = true)                                                                                                                 +
                         |   GROUP BY l.id                                                                                                                                           +
                         |   ORDER BY l.created_at DESC;
(4 rows)

