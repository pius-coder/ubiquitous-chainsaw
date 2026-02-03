                                             Table "public.leads"
         Column         |           Type           | Collation | Nullable |              Default              
------------------------+--------------------------+-----------+----------+-----------------------------------
 id                     | integer                  |           | not null | nextval('leads_id_seq'::regclass)
 fb_id                  | character varying(64)    |           |          | 
 phone                  | character varying(20)    |           | not null | 
 name                   | character varying(120)   |           | not null | 
 first_name             | character varying(60)    |           |          | 
 last_name              | character varying(60)    |           |          | 
 city                   | character varying(100)   |           |          | 
 age                    | smallint                 |           |          | 
 gender                 | character varying(10)    |           |          | 
 status                 | character varying(40)    |           | not null | 'nouveau_lead'::character varying
 source                 | character varying(50)    |           |          | 'facebook_ads'::character varying
 notes                  | text                     |           |          | 
 assigned_to            | integer                  |           |          | 
 created_at             | timestamp with time zone |           | not null | now()
 updated_at             | timestamp with time zone |           | not null | now()
 looking_for_gender     | character varying(10)    |           |          | 
 preferred_age_min      | smallint                 |           |          | 
 preferred_age_max      | smallint                 |           |          | 
 preferred_city         | character varying(100)   |           |          | 
 qualification_complete | boolean                  |           |          | false
 last_profile_shown     | character varying(20)    |           |          | 
 conversation_phase     | character varying(50)    |           |          | 'new'::character varying
 last_agent             | character varying(50)    |           |          | 
 qualification_score    | smallint                 |           |          | 0
 message_count          | integer                  |           |          | 0
 last_profile_viewed    | character varying(20)    |           |          | 
Indexes:
    "leads_pkey" PRIMARY KEY, btree (id)
    "idx_leads_active" btree (phone, name, status) WHERE status::text = ANY (ARRAY['nouveau_lead'::character varying, 'prospect_actif'::character varying, 'prospect_anonyme'::character varying]::text[])
    "idx_leads_assigned" btree (assigned_to)
    "idx_leads_created" btree (created_at DESC)
    "idx_leads_phase" btree (conversation_phase)
    "idx_leads_phone" btree (phone)
    "idx_leads_qualification" btree (qualification_complete)
    "idx_leads_status" btree (status)
    "leads_fb_id_key" UNIQUE CONSTRAINT, btree (fb_id)
    "leads_phone_key" UNIQUE CONSTRAINT, btree (phone)
Foreign-key constraints:
    "leads_assigned_to_fkey" FOREIGN KEY (assigned_to) REFERENCES admin_users(id)
Referenced by:
    TABLE "agent_action_logs" CONSTRAINT "agent_action_logs_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES leads(id)
    TABLE "agent_logs" CONSTRAINT "agent_logs_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES leads(id)
    TABLE "contact_requests" CONSTRAINT "contact_requests_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE
    TABLE "conversations" CONSTRAINT "conversations_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE
    TABLE "leads_duplicates" CONSTRAINT "leads_duplicates_existing_lead_id_fkey" FOREIGN KEY (existing_lead_id) REFERENCES leads(id) ON DELETE CASCADE
    TABLE "messages_sent" CONSTRAINT "messages_sent_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE SET NULL
    TABLE "payment_transactions" CONSTRAINT "payment_transactions_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE
    TABLE "profile_recommendations" CONSTRAINT "profile_recommendations_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE
    TABLE "profile_views" CONSTRAINT "profile_views_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE
    TABLE "tool_calls" CONSTRAINT "tool_calls_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE SET NULL
Triggers:
    trigger_qualification_check BEFORE UPDATE ON leads FOR EACH ROW EXECUTE FUNCTION update_qualification_status()
    update_leads_updated_at BEFORE UPDATE ON leads FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()

