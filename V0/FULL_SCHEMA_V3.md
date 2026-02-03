# Full Database Schema (v3)

## Tables

### `leads`

Stores potential clients contacting via WhatsApp.

| Column                     | Type         | Description                              |
| -------------------------- | ------------ | ---------------------------------------- |
| id                         | SERIAL PK    | Unique identifier                        |
| phone                      | VARCHAR(20)  | WhatsApp phone number (Unique)           |
| name                       | VARCHAR(100) | Name from WhatsApp profile               |
| age                        | INT          | Age of the lead                          |
| gender                     | VARCHAR(10)  | Gender (Male/Female)                     |
| city                       | VARCHAR(100) | City of residence                        |
| status                     | VARCHAR(20)  | e.g. 'nouveau_lead', 'prospect_qualifie' |
| source                     | VARCHAR(50)  | e.g. 'whatsapp_direct'                   |
| **looking_for_gender**     | VARCHAR(10)  | _Added in v3_                            |
| **preferred_age_min**      | SMALLINT     | _Added in v3_                            |
| **preferred_age_max**      | SMALLINT     | _Added in v3_                            |
| **preferred_city**         | VARCHAR(100) | _Added in v3_                            |
| **qualification_complete** | BOOLEAN      | _Added in v3_                            |
| **last_profile_shown**     | VARCHAR(20)  | _Added in v3_ (Profile Code)             |
| **conversation_phase**     | VARCHAR(50)  | _Added in v3_                            |
| created_at                 | TIMESTAMPTZ  | Creation timestamp                       |
| updated_at                 | TIMESTAMPTZ  | Last update timestamp                    |

### `profiles`

The "products" - profiles of people to be matched.

| Column              | Type         | Description                        |
| ------------------- | ------------ | ---------------------------------- |
| id                  | SERIAL PK    | Unique identifier                  |
| code                | VARCHAR(20)  | Unique Code (e.g. MAT-2025-001)    |
| name                | VARCHAR(100) | Full Name (Admin only)             |
| first_name          | VARCHAR(100) | First Name (Public)                |
| age                 | INT          | Age                                |
| gender              | VARCHAR(10)  | Gender                             |
| city                | VARCHAR(100) | City                               |
| neighborhood        | VARCHAR(100) | District/Neighborhood              |
| profession          | VARCHAR(100) | Profession                         |
| description_short   | TEXT         | Short bio                          |
| description_long    | TEXT         | Detailed bio                       |
| hobbies             | TEXT         | Hobbies                            |
| religion            | VARCHAR(50)  | Religion                           |
| children            | INT          | Number of children                 |
| search_age_min      | INT          | Minimum age preference             |
| search_age_max      | INT          | Maximum age preference             |
| search_city         | VARCHAR(100) | City preference                    |
| status              | VARCHAR(20)  | 'active', 'inactive', 'married'    |
| photos              | TEXT[]       | Array of photo URLs                |
| **embedding**       | VECTOR(1536) | _Added in v2_ (Mistral Embeddings) |
| **search_text**     | TEXT         | _Added in v2_ (Full text for RAG)  |
| **vector_metadata** | JSONB        | _Added in v2_                      |
| **indexed_at**      | TIMESTAMPTZ  | _Added in v3_                      |
| created_at          | TIMESTAMPTZ  | Creation timestamp                 |
| updated_at          | TIMESTAMPTZ  | Last update timestamp              |

### `conversations`

History of messages exchanged.

| Column           | Type        | Description                                 |
| ---------------- | ----------- | ------------------------------------------- |
| id               | SERIAL PK   | Unique identifier                           |
| lead_id          | INT         | FK to `leads`                               |
| Column           | Type        | Description                                 |
| ---------------- | ----------- | ------------------------------------------- |
| id               | SERIAL PK   | Unique identifier                           |
| lead_id          | INT         | FK to `leads`                               |
| direction        | VARCHAR(10) | 'in' or 'out'                               |
| content          | TEXT        | Message content                             |
| message_type     | VARCHAR(40) | 'text', 'image', 'audio'                    |
| sender_type      | VARCHAR(20) | 'bot', 'client', 'admin'                    |
| sender_id        | INT         | FK to `admin_users` (if admin)              |
| status           | VARCHAR(40) | 'bot_actif', 'attente_humain', etc.         |
| intent           | VARCHAR(50) | Detected intent/Agent used                  |
| **sentiment**    | VARCHAR(20) | _Added in v2_ (positive, neutral, negative) |
| **profile_code** | VARCHAR(20) | _Added in v2_ (Associated profile)          |
| **metadata**     | JSONB       | _Added in v2_ (Extra data)                  |
| created_at       | TIMESTAMPTZ | Timestamp                                   |

### `knowledge_base`

Q&A for the FAQ Agent.

| Column         | Type         | Description                |
| -------------- | ------------ | -------------------------- |
| id             | SERIAL PK    | Unique identifier          |
| category       | VARCHAR(50)  | Category                   |
| question       | TEXT         | The question               |
| answer         | TEXT         | The answer                 |
| keywords       | TEXT[]       | Keywords for simple search |
| is_active      | BOOLEAN      | Is active                  |
| **title**      | VARCHAR(255) | _Added in v3_              |
| **embedding**  | VECTOR(1536) | _Added in v2_              |
| **indexed_at** | TIMESTAMPTZ  | _Added in v3_              |
| created_at     | TIMESTAMPTZ  | Timestamp                  |

### `agent_logs` (New in v3)

Performance tracking for agents.

| Column         | Type        | Description             |
| -------------- | ----------- | ----------------------- |
| id             | SERIAL PK   | Unique identifier       |
| lead_id        | INT         | FK to `leads`           |
| agent_name     | VARCHAR(50) | Name of the agent used  |
| input_summary  | TEXT        | Snippet of user input   |
| output_summary | TEXT        | Snippet of agent output |
| duration_ms    | INT         | Processing time         |
| success        | BOOLEAN     | Only true/false         |
| error_message  | TEXT        | Error details if any    |
| created_at     | TIMESTAMPTZ | Timestamp               |

### `n8n_chat_histories` (Added in v2)

Memory storage for LangChain conversation chains.

| Column     | Type         | Description        |
| ---------- | ------------ | ------------------ |
| id         | SERIAL PK    | Unique identifier  |
| session_id | VARCHAR(255) | Session ID         |
| message    | JSONB        | The message object |
| created_at | TIMESTAMPTZ  | Timestamp          |

### Other Tables

- `admin_users`: Dashboard access
- `configuration`: System settings (e.g. admin phone)
- `analytics`: Daily aggregations
- `contact_requests`: Requests for contact info
- `transactions`: Payments
- `logs`: System logs

## Views

- `active_conversations`: Latest conversation status for active leads.
- `qualified_leads`: List of fully qualified leads.
- `agent_performance`: Stats on agent usage and success rates.
