# 🏗️ Architecture Complète Multi-Agents avec RAG Fonctionnel

Tu as raison, allons encore plus loin avec une architecture robuste à 8 agents spécialisés. Je vais tout t'expliquer en détail.

---

## 📚 COMPRENDRE LE RAG (Retrieval Augmented Generation)

### Comment ça marche ?

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CYCLE DE VIE DU RAG                                  │
└─────────────────────────────────────────────────────────────────────────────┘

PHASE 1 : INDEXATION (Une seule fois, puis quand données changent)
═══════════════════════════════════════════════════════════════════

   Tes données                    Embeddings                    Base Vectorielle
   (texte brut)                   (vecteurs)                    (PostgreSQL + pgvector)
        │                              │                              │
        ▼                              ▼                              ▼
┌───────────────┐            ┌───────────────┐              ┌───────────────┐
│ "Fatou, 26    │  ───────►  │ [0.23, -0.45, │  ───────►   │ profiles      │
│ ans, infirm-  │   LLM      │  0.12, 0.89,  │   INSERT    │ .embedding    │
│ ière douce"   │ Embeddings │  ...]         │             │ = vector      │
└───────────────┘            └───────────────┘              └───────────────┘

   Document texte     →    Transformation en    →    Stockage pour
                           nombres (1024 dims)       recherche rapide


PHASE 2 : RECHERCHE (À chaque requête utilisateur)
══════════════════════════════════════════════════

   Question client              Embedding question            Recherche similarité
        │                              │                              │
        ▼                              ▼                              ▼
┌───────────────┐            ┌───────────────┐              ┌───────────────┐
│ "Je cherche   │  ───────►  │ [0.21, -0.44, │  ───────►   │ SELECT * FROM │
│ une femme     │   LLM      │  0.15, 0.87,  │  pgvector   │ profiles      │
│ douce"        │ Embeddings │  ...]         │  <=>        │ ORDER BY      │
└───────────────┘            └───────────────┘   cosine     │ similarity    │
                                                            └───────────────┘
                                                                   │
                                                                   ▼
                                                            Profils les plus
                                                            similaires retournés
```

### Pourquoi ton RAG ne marche pas ?

**La colonne `embedding` dans tes tables est VIDE (NULL).**

Tu dois **créer un workflow d'indexation** qui :

1. Lit les données de tes tables
2. Génère les embeddings avec Mistral
3. Sauvegarde ces embeddings dans la colonne `embedding`

---

## 🔄 WORKFLOW 1 : INDEXATION (À créer en premier)

### Workflow : "Indexer Knowledge Base"

```
┌─────────────────────────────────────────────────────────────────────────────┐
│               WORKFLOW : INDEXER KNOWLEDGE BASE                              │
│               (À exécuter manuellement ou via Cron)                          │
└─────────────────────────────────────────────────────────────────────────────┘

[Trigger Manuel / Cron Daily]
         │
         ▼
[PostgreSQL: SELECT * FROM knowledge_base WHERE embedding IS NULL]
         │
         ▼
    [Loop Items]
         │
         ├──────────────────────────────────────────────┐
         ▼                                              │
[Mistral Embeddings API]                                │
         │                                              │
         ▼                                              │
[PostgreSQL: UPDATE knowledge_base                      │
 SET embedding = $vector                                │
 WHERE id = $id]                                        │
         │                                              │
         └──────────────────────────────────────────────┘
         │
         ▼
    [FIN - KB Indexée]
```

### Workflow : "Indexer Profiles"

```
┌─────────────────────────────────────────────────────────────────────────────┐
│               WORKFLOW : INDEXER PROFILES                                    │
│               (À exécuter après ajout/modif de profils)                      │
└─────────────────────────────────────────────────────────────────────────────┘

[Trigger Manuel / Webhook après création profil]
         │
         ▼
[PostgreSQL: SELECT * FROM profiles WHERE embedding IS NULL OR updated_at > last_indexed]
         │
         ▼
[Code: Construire le texte à indexer]
    │
    │   Pour chaque profil, créer un texte riche :
    │   "Fatou Diallo, femme de 26 ans, habite Yaoundé.
    │    Profession: infirmière. Douce, attentionnée.
    │    Aime la lecture et la cuisine. Cherche homme
    │    sérieux entre 28 et 38 ans."
    │
         ▼
[Mistral Embeddings API]
         │
         ▼
[PostgreSQL: UPDATE profiles SET embedding = $vector, indexed_at = NOW() WHERE id = $id]
         │
         ▼
    [FIN - Profils Indexés]
```

---

## 🎭 ARCHITECTURE À 8 AGENTS SPÉCIALISÉS

### Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ARCHITECTURE 8 AGENTS SPÉCIALISÉS                         │
│                    "Chaque expert dans son domaine"                          │
└─────────────────────────────────────────────────────────────────────────────┘

                              ┌─────────────────┐
                              │    WEBHOOK      │
                              │   WhatsApp      │
                              └────────┬────────┘
                                       │
                              ┌────────▼────────┐
                              │  PREPROCESSING  │
                              │   PIPELINE      │
                              └────────┬────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
           ┌────────────────┐ ┌────────────────┐ ┌────────────────┐
           │  📊 ANALYZER   │ │  📜 HISTORY    │ │  👤 LEAD       │
           │  Contexte      │ │  Manager       │ │  Profiler      │
           └────────┬───────┘ └────────┬───────┘ └────────┬───────┘
                    │                  │                  │
                    └──────────────────┼──────────────────┘
                                       │
                              ┌────────▼────────┐
                              │   🧠 ROUTER     │
                              │   Intelligent   │
                              │   (Classifieur) │
                              └────────┬────────┘
                                       │
       ┌───────────────┬───────────────┼───────────────┬───────────────┐
       │               │               │               │               │
       ▼               ▼               ▼               ▼               ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ 🤝 AGENT    │ │ 💕 AGENT    │ │ 📋 AGENT    │ │ ❓ AGENT    │ │ 🚨 AGENT    │
│ GREETER     │ │ MATCHMAKER  │ │ PRESENTER   │ │ FAQ         │ │ ESCALATION  │
│             │ │             │ │             │ │             │ │             │
│ Accueil &   │ │ Recherche   │ │ Présente    │ │ Questions   │ │ Transfert   │
│ Salutations │ │ Profils     │ │ Profils     │ │ Agence      │ │ Humain      │
└──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
       │               │               │               │               │
       │               │               │               │               │
       │       ┌───────┴───────┐       │       ┌───────┴───────┐       │
       │       │               │       │       │               │       │
       │       ▼               ▼       │       ▼               ▼       │
       │  ┌─────────┐    ┌─────────┐   │  ┌─────────┐    ┌─────────┐   │
       │  │ 🔍 TOOL │    │ 📊 TOOL │   │  │ 📚 TOOL │    │ 🗄️ TOOL │   │
       │  │ Profile │    │ SQL     │   │  │ RAG KB  │    │ History │   │
       │  │ RAG     │    │ Search  │   │  │ Search  │    │ Search  │   │
       │  └─────────┘    └─────────┘   │  └─────────┘    └─────────┘   │
       │                               │                               │
       └───────────────┬───────────────┴───────────────┬───────────────┘
                       │                               │
                       ▼                               ▼
              ┌────────────────┐              ┌────────────────┐
              │ 🎨 AGENT       │              │ ✅ AGENT       │
              │ HUMANIZER      │              │ QUALIFIER      │
              │                │              │                │
              │ Reformule      │              │ Pose questions │
              │ naturellement  │              │ qualification  │
              └────────┬───────┘              └────────┬───────┘
                       │                               │
                       └───────────────┬───────────────┘
                                       │
                              ┌────────▼────────┐
                              │  POST-PROCESS   │
                              │  Validation     │
                              └────────┬────────┘
                                       │
                              ┌────────▼────────┐
                              │  SEND MESSAGE   │
                              └─────────────────┘
```

---

## 📋 DÉTAIL DE CHAQUE AGENT

### 🧠 AGENT 0 : ROUTER (Cerveau Central)

**Rôle :** Analyser le message et router vers le bon agent

**Input :**

- Message utilisateur
- État de la conversation (de l'Analyzer)
- Profil du lead

**Output :** Nom de l'agent à appeler

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ROUTER LOGIC                                    │
└─────────────────────────────────────────────────────────────────────────────┘

DÉCISION TREE :

1. Si nouveau client (0 messages)
   → GREETER

2. Si message = salutation simple (bonjour, salut, hey)
   → GREETER

3. Si qualification incomplète ET demande de profils
   → QUALIFIER

4. Si demande de profils ET qualification complète
   → MATCHMAKER

5. Si message contient code MAT-XXXX-XXX
   → PRESENTER

6. Si message = question sur fonctionnement/agence
   → FAQ

7. Si message = demande tarifs OU contact OU numéro OU "intéressé"
   → ESCALATION

8. Si réponse trop longue détectée
   → HUMANIZER

9. Par défaut
   → GREETER
```

**Implémentation (Code Node) :**

```javascript
const context = $("Context Analyzer").first().json;
const message = $("Prepare Context").first().json.user_message.toLowerCase();

// Patterns de détection
const patterns = {
  greeting: /^(bonjour|bonsoir|salut|hello|hey|coucou|bjr|bsr|hi)\b/i,
  profile_request:
    /(profil|compatible|cherche|liste|quelqu'un|partenaire|femme|homme)/i,
  profile_code: /MAT-\d{4}-\d{3}/i,
  faq: /(comment|fonctionn|marche|agence|processus|étape|inscription)/i,
  pricing: /(tarif|prix|combien|coût|payer|paiement|frais)/i,
  escalation: /(contact|numéro|appeler|intéresse|rencontrer|téléphone)/i,
  simple_response: /^(oui|non|ok|d'accord|merci|super|cool|bien|parfait)$/i,
};

let route = "GREETER"; // Default

// Logique de routing
if (context.is_new_client) {
  route = "GREETER";
} else if (patterns.greeting.test(message) && message.split(" ").length < 5) {
  route = "GREETER";
} else if (patterns.profile_code.test(message)) {
  route = "PRESENTER";
} else if (
  patterns.pricing.test(message) ||
  patterns.escalation.test(message)
) {
  route = "ESCALATION";
} else if (patterns.faq.test(message)) {
  route = "FAQ";
} else if (patterns.profile_request.test(message)) {
  if (context.qualification_complete) {
    route = "MATCHMAKER";
  } else {
    route = "QUALIFIER";
  }
} else if (patterns.simple_response.test(message)) {
  // Regarder le contexte précédent
  if (context.last_agent === "PRESENTER" || context.awaiting_profile_response) {
    route = context.client_interested ? "ESCALATION" : "MATCHMAKER";
  } else if (context.last_agent === "QUALIFIER") {
    route = "QUALIFIER"; // Continuer qualification
  } else {
    route = "GREETER";
  }
}

return [{ json: { route, context, message } }];
```

---

### 🤝 AGENT 1 : GREETER (Accueil)

**Rôle :** Accueillir, saluer, créer le lien humain

**Quand :** Premier message, salutations simples, retour après absence

**Tools :** Aucun (juste la mémoire conversation)

**Prompt (200 mots max) :**

```
Tu es Sarah, 28 ans, conseillère à l'AMC. Style WhatsApp camerounais.

CONTEXTE :
- Client : {{ lead_name }}
- Nouveau : {{ is_new_client }}
- Dernière interaction : {{ last_interaction_ago }}
- Heure actuelle : {{ current_hour }}h

RÈGLES :
• MAX 10 mots
• 0-1 emoji
• Tutoiement
• Pas de liste

SI nouveau client :
→ "Salut ! Ça va ?" ou "Hello ! Bienvenue 😊"

SI client connu revient après >24h :
→ "Hey ! Ça fait un moment, ça va depuis ?"

SI client connu même jour :
→ "Re !" ou "Ah t'es là !"

SI salutation du soir (18h+) :
→ "Bonsoir !" au lieu de "Salut"

Ta réponse (max 10 mots) :
```

---

### ✅ AGENT 2 : QUALIFIER (Qualification)

**Rôle :** Poser les questions pour comprendre ce que cherche le client

**Quand :** Demande de profils mais infos manquantes

**Tools :**

- `update_lead_preferences` : Sauvegarde les réponses dans la DB

**Prompt :**

```
Tu es Sarah. Tu qualifies le client pour trouver son match idéal.

INFOS ACTUELLES DU CLIENT :
- Genre recherché : {{ looking_for_gender || "?" }}
- Âge souhaité : {{ preferred_age_range || "?" }}
- Ville préférée : {{ preferred_city || "?" }}

DERNIÈRE RÉPONSE DU CLIENT :
"{{ user_message }}"

TA MISSION :
Extraire l'info de sa réponse ET poser la PROCHAINE question.

ORDRE DES QUESTIONS :
1. Genre → "Tu cherches un homme ou une femme ?"
2. Âge → "Ok et niveau âge, tu vois quoi ?"
3. Ville → "Côté ville, Douala, Yaoundé, ou ailleurs ?"

SI le client a répondu à une question :
→ Confirme brièvement + pose la suivante

SI toutes les infos sont là :
→ "Ok je regarde ce que j'ai pour toi"

EXEMPLES :
- Client dit "une femme" → "D'accord. Et niveau âge ?"
- Client dit "25-30 ans" → "Ok. Côté ville, tu préfères où ?"
- Client dit "Douala" → "Parfait, je regarde ça"

Ta réponse (max 12 mots) :
```

**Tool : update_lead_preferences**

```javascript
// Workflow sub-tool qui update la DB
const message = $json.user_message.toLowerCase();
const leadId = $json.lead_id;

let updates = {};

// Détecter le genre
if (message.match(/femme|fille|woman/i)) {
  updates.looking_for_gender = "femme";
} else if (message.match(/homme|garçon|man|mec/i)) {
  updates.looking_for_gender = "homme";
}

// Détecter l'âge
const ageMatch = message.match(/(\d{2})\s*[-àa]\s*(\d{2})/);
if (ageMatch) {
  updates.preferred_age_min = parseInt(ageMatch[1]);
  updates.preferred_age_max = parseInt(ageMatch[2]);
}

// Détecter la ville
const cities = ["douala", "yaoundé", "yaounde", "bafoussam", "kribi", "limbe"];
for (const city of cities) {
  if (message.includes(city)) {
    updates.preferred_city = city.charAt(0).toUpperCase() + city.slice(1);
    break;
  }
}

// Update DB si nouvelles infos
if (Object.keys(updates).length > 0) {
  // Exécuter UPDATE SQL
}

return [{ json: { extracted: updates, leadId } }];
```

---

### 💕 AGENT 3 : MATCHMAKER (Recherche de Profils)

**Rôle :** Trouver les profils compatibles avec les critères

**Quand :** Client qualifié demande des profils

**Tools :**

- `search_profiles_sql` : Recherche SQL avec critères
- `search_profiles_rag` : Recherche sémantique (fallback)

**Prompt :**

```
Tu es Sarah. Tu as trouvé des profils pour le client.

CRITÈRES DU CLIENT :
- Cherche : {{ looking_for_gender }}
- Âge : {{ preferred_age_min }}-{{ preferred_age_max }} ans
- Ville : {{ preferred_city }}

PROFILS TROUVÉS :
{{ profiles_found }}

TA MISSION :
Présenter LE PREMIER profil seulement, de manière naturelle.

FORMAT :
"J'ai [Prénom], [âge] ans, [métier] à [ville]. [1 trait]. Ça te dit ?"

EXEMPLES :
- "J'ai Fatou, 26 ans, infirmière à Yaoundé. Elle est douce. Ça te dit ?"
- "Y'a Marie, 28 ans, enseignante à Douala. Posée et sympa. Tu veux voir ?"

SI aucun profil trouvé :
- "J'ai pas grand chose qui matche là. Tu veux élargir un peu les critères ?"

Ta réponse (max 20 mots) :
```

**Tool : search_profiles_sql**

```sql
SELECT
  code,
  name,
  age,
  city,
  profession,
  SUBSTRING(description_short, 1, 50) as short_desc
FROM profiles
WHERE status = 'actif'
  AND gender = $1  -- looking_for_gender
  AND age BETWEEN $2 AND $3  -- age range
  AND ($4 = '' OR city ILIKE '%' || $4 || '%')  -- city
ORDER BY
  CASE WHEN city ILIKE '%' || $4 || '%' THEN 0 ELSE 1 END,
  created_at DESC
LIMIT 5;
```

---

### 📋 AGENT 4 : PRESENTER (Présentation Détaillée)

**Rôle :** Donner les détails d'un profil spécifique

**Quand :** Client mentionne un code MAT-XXXX-XXX ou dit "oui" après suggestion

**Tools :**

- `get_profile_details` : Récupère tous les détails d'un profil
- `log_profile_view` : Enregistre la consultation

**Prompt :**

```
Tu es Sarah. Tu présentes un profil en détail.

PROFIL DEMANDÉ :
- Code : {{ profile.code }}
- Prénom : {{ profile.name }}
- Âge : {{ profile.age }} ans
- Ville : {{ profile.city }}
- Métier : {{ profile.profession }}
- Description : {{ profile.description_short }}
- Loisirs : {{ profile.hobbies }}
- Cherche : {{ profile.search_criteria }}

HISTORIQUE :
- Déjà présenté ? {{ already_shown }}
- Niveau de détail demandé : {{ detail_level }}

TA MISSION :
Présenter de façon progressive :
1. D'abord les infos de base (si première fois)
2. Puis personnalité (si demande plus)
3. Puis critères de recherche (si vraiment intéressé)

FORMAT PREMIÈRE PRÉSENTATION :
"[Prénom], [âge] ans, [métier] à [ville]. [Description courte]. Tu veux en savoir plus ?"

FORMAT DÉTAILS :
"Elle aime [hobbies]. Elle cherche [critères courts]. Ça te correspond ?"

Ta réponse (max 25 mots) :
```

---

### ❓ AGENT 5 : FAQ (Questions Fréquentes)

**Rôle :** Répondre aux questions sur l'agence

**Quand :** Questions sur le fonctionnement, processus, conditions

**Tools :**

- `search_knowledge_base` : RAG sur la base de connaissances
- `get_faq_answer` : Réponses pré-définies (fallback rapide)

**Prompt :**

```
Tu es Sarah. Tu expliques le fonctionnement de l'agence.

QUESTION DU CLIENT :
"{{ user_message }}"

RÉPONSE TROUVÉE DANS LA BASE :
{{ rag_answer || faq_answer }}

TA MISSION :
Reformuler la réponse de façon naturelle et courte.

RÈGLES :
• Max 2 phrases
• Style WhatsApp
• Pas de jargon

EXEMPLES :
- Question: "Comment ça marche ?"
  Réponse: "En gros, on discute pour cerner ce que tu cherches, puis je te propose des profils. Simple."

- Question: "C'est sécurisé ?"
  Réponse: "Oui, tes infos restent confidentielles. On partage jamais ton numéro sans ton ok."

Ta réponse (max 20 mots) :
```

**Tool : get_faq_answer (Code Node - Fallback rapide)**

```javascript
const message = $json.user_message.toLowerCase();

const FAQ_RESPONSES = {
  "comment ça marche|fonctionnement":
    "On discute pour comprendre ce que tu cherches, puis je te propose des profils qui matchent.",

  "inscription|inscrire":
    "L'inscription est gratuite. Tu discutes avec moi et je te propose des profils.",

  "sécurité|confidentiel|privé|données":
    "Tes infos restent confidentielles. On partage jamais ton numéro sans ton accord.",

  "combien de profils|nombre":
    "On a plusieurs centaines de profils actifs dans différentes villes du Cameroun.",

  "délai|temps|combien de temps":
    "Ça dépend de tes critères, mais généralement on trouve des profils intéressants rapidement.",

  "ville|région|où":
    "On couvre Douala, Yaoundé, Bafoussam et d'autres villes du Cameroun.",

  "sérieux|arnaque|vrai":
    "On est une vraie agence avec des vrais profils vérifiés. Pas d'arnaque ici.",
};

let answer = null;
for (const [pattern, response] of Object.entries(FAQ_RESPONSES)) {
  if (message.match(new RegExp(pattern, "i"))) {
    answer = response;
    break;
  }
}

return [{ json: { faq_answer: answer, found: !!answer } }];
```

---

### 🚨 AGENT 6 : ESCALATION (Transfert Humain)

**Rôle :** Gérer les demandes nécessitant un humain

**Quand :** Tarifs, mise en relation, client mécontent, demande de contact

**Tools :**

- `notify_admin` : Envoie notification WhatsApp à l'admin
- `update_conversation_status` : Passe en "attente_humain"

**Prompt :**

```
Tu es Sarah. Tu dois passer le relais à un collègue humain.

RAISON DE L'ESCALADE :
{{ escalation_reason }}
- pricing : Client demande les tarifs
- contact_request : Client veut un numéro/contact
- interested : Client intéressé par un profil
- complaint : Client mécontent
- complex : Question trop complexe

CONTEXTE :
- Profil concerné : {{ profile_code || "Aucun" }}
- Client : {{ lead_name }}

TA MISSION :
Informer le client qu'un collègue va le contacter, de façon naturelle.

RÉPONSES SELON LA RAISON :
- pricing : "Pour les tarifs, ma collègue gère ça. Elle va t'appeler, c'est ok ?"
- contact_request : "Je passe à mon collègue pour le contact. Il te rappelle vite."
- interested : "Super ! Mon collègue va t'appeler pour organiser ça."
- complaint : "Je comprends. Je demande à quelqu'un de t'appeler direct."
- complex : "Là c'est technique, je te passe un collègue."

Ta réponse (max 15 mots) :
```

---

### 🎨 AGENT 7 : HUMANIZER (Reformulation)

**Rôle :** Reformuler les réponses trop longues ou robotiques

**Quand :** Post-processing si réponse > 30 mots ou patterns IA détectés

**Tools :** Aucun

**Prompt :**

```
Tu reformules ce texte en style WhatsApp naturel.

TEXTE À REFORMULER :
"{{ original_response }}"

RÈGLES STRICTES :
• Maximum 15 mots
• Pas de liste
• Pas de gras
• Pas d'emoji ou 1 max
• Style SMS entre potes
• Garde l'info essentielle

EXEMPLES :
- Avant: "Je vais tout de suite vous donner les informations concernant Fatou Diallo qui est une jeune femme de 26 ans..."
  Après: "Fatou, 26 ans, infirmière. Elle est douce. Ça te dit ?"

- Avant: "Merci pour votre patience, je comprends que vous souhaitez avoir les tarifs..."
  Après: "Pour les prix, ma collègue va te rappeler."

Ta version courte :
```

---

### 📊 AGENT 8 : CONTEXT ANALYZER (Pré-processing)

**Rôle :** Analyser le contexte AVANT le routing

**Quand :** À chaque message, avant tout

**Type :** Code Node (pas un LLM)

```javascript
const history = $("Get History").all();
const lead = $("Get Lead").first().json;
const message = $("Extract Data").first().json.message;

// Analyser l'historique
const lastMessages = history.slice(0, 5);
const lastBotMessage = lastMessages.find((m) => m.json.direction === "out");
const lastClientMessage = lastMessages.find((m) => m.json.direction === "in");

// Déterminer l'état de qualification
const qualificationComplete = !!(
  lead.looking_for_gender &&
  lead.preferred_age_min &&
  lead.preferred_city
);

// Détecter si on attend une réponse spécifique
const awaitingProfileResponse = lastBotMessage?.json.content?.match(
  /ça te (dit|parle|intéresse)/i,
);
const awaitingQualificationAnswer = lastBotMessage?.json.content?.match(
  /tu (cherches|préfères|veux|vois)/i,
);

// Détecter le sentiment du message
const isPositive = message.match(/oui|ok|super|bien|parfait|intéresse|j'aime/i);
const isNegative = message.match(/non|pas|jamais|nul|mauvais/i);
const isFrustrated = message.match(/!{2,}|attends|encore|toujours|marre/i);

// Calculer le temps depuis dernière interaction
const lastInteraction = history[0]?.json.created_at;
const hoursSinceLastInteraction = lastInteraction
  ? (Date.now() - new Date(lastInteraction).getTime()) / (1000 * 60 * 60)
  : 999;

// Récupérer le dernier profil montré
const lastProfileShown = history.find(
  (m) => m.json.profile_code && m.json.direction === "out",
)?.json.profile_code;

return [
  {
    json: {
      // État de la conversation
      conversation_state: qualificationComplete
        ? "qualified"
        : "qualification_incomplete",
      qualification_complete: qualificationComplete,

      // Infos manquantes
      missing_info: [
        !lead.looking_for_gender && "gender",
        !lead.preferred_age_min && "age",
        !lead.preferred_city && "city",
      ].filter(Boolean),

      // Contexte de la conversation
      is_new_client: history.length === 0,
      hours_since_last: Math.round(hoursSinceLastInteraction),
      last_profile_shown: lastProfileShown,

      // Attentes
      awaiting_profile_response: !!awaitingProfileResponse,
      awaiting_qualification: !!awaitingQualificationAnswer,

      // Sentiment
      client_mood: isFrustrated
        ? "frustrated"
        : isPositive
          ? "positive"
          : isNegative
            ? "negative"
            : "neutral",
      client_interested: isPositive && awaitingProfileResponse,

      // Dernier agent utilisé (pour continuité)
      last_agent: lastBotMessage?.json.intent || "unknown",

      // Données brutes
      message_length: message.length,
      message_word_count: message.split(" ").length,
    },
  },
];
```

---

## 📐 SCHÉMA COMPLET DU WORKFLOW PRINCIPAL

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                            WORKFLOW PRINCIPAL COMPLET                                    │
└─────────────────────────────────────────────────────────────────────────────────────────┘

[1. Webhook WhatsApp]
         │
         ▼
[2. Extract Data] ──────────────────────────────────────────────────────────────────────┐
         │                                                                               │
         ▼                                                                               │
[3. Validate Message] ─── Invalid ──► [FIN - Ignoré]                                    │
         │ Valid                                                                         │
         ▼                                                                               │
[4. Check Not Admin] ─── Is Admin ──► [FIN - Admin]                                     │
         │ Not Admin                                                                     │
         ▼                                                                               │
[5. Get Lead] ─── Not Found ──► [6. Create Lead] ──┐                                    │
         │ Found                                    │                                    │
         ▼                                          │                                    │
[7. Merge Lead Data] ◄─────────────────────────────┘                                    │
         │                                                                               │
         ▼                                                                               │
[8. Log Message IN]                                                                      │
         │                                                                               │
         ▼                                                                               │
[9. Check Bot Active] ─── Attente Humain ──► [FIN - Attente]                            │
         │ Bot Actif                                                                     │
         ▼                                                                               │
[10. Get History (15 derniers)]                                                          │
         │                                                                               │
         ▼                                                                               │
┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│                        [11. CONTEXT ANALYZER - Code Node]                            │ │
│                                                                                      │ │
│  Analyse : qualification, sentiment, attentes, historique                           │ │
│  Output : conversation_state, missing_info, awaiting_*, client_mood                 │ │
└─────────────────────────────────────────────────────────────────────────────────────┘ │
         │                                                                               │
         ▼                                                                               │
┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│                           [12. ROUTER - Code Node]                                   │ │
│                                                                                      │ │
│  Décide quel agent appeler basé sur :                                               │ │
│  - message_intent (greeting, profiles, faq, pricing, etc.)                          │ │
│  - conversation_state (qualified, incomplete)                                        │ │
│  - awaiting_* flags                                                                  │ │
│                                                                                      │ │
│  Output : { route: "GREETER" | "QUALIFIER" | "MATCHMAKER" | ... }                   │ │
└─────────────────────────────────────────────────────────────────────────────────────┘ │
         │                                                                               │
         ▼                                                                               │
┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│                              [13. SWITCH NODE]                                       │ │
│                                                                                      │ │
│  route == "GREETER"     ──────────────────────────────────► [Agent Greeter]         │ │
│  route == "QUALIFIER"   ──────────────────────────────────► [Agent Qualifier]       │ │
│  route == "MATCHMAKER"  ──────────────────────────────────► [Agent Matchmaker]      │ │
│  route == "PRESENTER"   ──────────────────────────────────► [Agent Presenter]       │ │
│  route == "FAQ"         ──────────────────────────────────► [Agent FAQ]             │ │
│  route == "ESCALATION"  ──────────────────────────────────► [Agent Escalation]      │ │
│  default                ──────────────────────────────────► [Agent Greeter]         │ │
└─────────────────────────────────────────────────────────────────────────────────────┘ │
         │                                                                               │
         ├─────────────────────────────────────────────────────────────────────────────┤ │
         │                                                                             │ │
         ▼                           ▼                           ▼                     │ │
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐           │ │
│  GREETER        │         │  QUALIFIER      │         │  MATCHMAKER     │           │ │
│                 │         │                 │         │                 │           │ │
│ [Prepare Data]  │         │ [Prepare Data]  │         │ [SQL Search]    │           │ │
│       │         │         │       │         │         │       │         │           │ │
│       ▼         │         │       ▼         │         │       ▼         │           │ │
│ [Mini LLM]      │         │ [Mini LLM]      │         │ [Mini LLM]      │           │ │
│  (prompt court) │         │  + Tool Update  │         │                 │           │ │
└────────┬────────┘         └────────┬────────┘         └────────┬────────┘           │ │
         │                           │                           │                     │ │
         ▼                           ▼                           ▼                     │ │
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐           │ │
│  PRESENTER      │         │  FAQ            │         │  ESCALATION     │           │ │
│                 │         │                 │         │                 │           │ │
│ [Get Profile]   │         │ [FAQ Lookup]    │         │ [Notify Admin]  │           │ │
│       │         │         │ [RAG Search]    │         │       │         │           │ │
│       ▼         │         │       │         │         │       ▼         │           │ │
│ [Mini LLM]      │         │       ▼         │         │ [Mini LLM]      │           │ │
│ + Log View Tool │         │ [Mini LLM]      │         │ + Update Status │           │ │
└────────┬────────┘         └────────┬────────┘         └────────┬────────┘           │ │
         │                           │                           │                     │ │
         └───────────────────────────┴───────────────────────────┘                     │ │
                                     │                                                 │ │
                                     ▼                                                 │ │
                    ┌────────────────────────────────────┐                            │ │
                    │     [14. MERGE AGENT OUTPUTS]      │                            │ │
                    └────────────────┬───────────────────┘                            │ │
                                     │                                                 │ │
                                     ▼                                                 │ │
                    ┌────────────────────────────────────┐                            │ │
                    │   [15. POST-PROCESSOR - Code]      │                            │ │
                    │                                    │                            │ │
                    │   • Remove formatting              │                            │ │
                    │   • Remove banned phrases          │                            │ │
                    │   • Truncate if > 150 chars        │                            │ │
                    │   • Check quality                  │                            │ │
                    └────────────────┬───────────────────┘                            │ │
                                     │                                                 │ │
                                     ▼                                                 │ │
                    ┌────────────────────────────────────┐                            │ │
                    │  [16. QUALITY CHECK - IF Node]     │                            │ │
                    │                                    │                            │ │
                    │  Response OK?                      │                            │ │
                    │  (< 30 words, no banned patterns)  │                            │ │
                    └────────────────┬───────────────────┘                            │ │
                              Yes    │    No                                          │ │
                              ┌──────┴──────┐                                         │ │
                              │             │                                         │ │
                              ▼             ▼                                         │ │
                         [Continue]   [17. HUMANIZER]                                 │ │
                              │        (Mini LLM)                                     │ │
                              │             │                                         │ │
                              └──────┬──────┘                                         │ │
                                     │                                                 │ │
                                     ▼                                                 │ │
                    ┌────────────────────────────────────┐                            │ │
                    │  [18. UPDATE LEAD PREFS - IF]      │                            │ │
                    │                                    │                            │ │
                    │  Si QUALIFIER a extrait des infos  │                            │ │
                    │  → UPDATE leads SET prefs...       │                            │ │
                    └────────────────┬───────────────────┘                            │ │
                                     │                                                 │ │
                                     ▼                                                 │ │
                    ┌────────────────────────────────────┐                            │ │
                    │  [19. EXTRACT METADATA - Code]     │                            │ │
                    │                                    │                            │ │
                    │  • Detect escalation keywords      │                            │ │
                    │  • Extract profile_code if any     │                            │ │
                    │  • Determine intent                │                            │ │
                    │  • Set conversation_status         │                            │ │
                    └────────────────┬───────────────────┘                            │ │
                                     │                                                 │ │
                                     ▼                                                 │ │
                    ┌────────────────────────────────────┐                            │ │
                    │    [20. LOG MESSAGE OUT]           │                            │ │
                    └────────────────┬───────────────────┘                            │ │
                                     │                                                 │ │
                                     ▼                                                 │ │
                    ┌────────────────────────────────────┐                            │ │
                    │  [21. CHECK ESCALATION - IF]       │                            │ │
                    │                                    │                            │ │
                    │  conversation_status ==            │                            │ │
                    │  "attente_humain" ?                │                            │ │
                    └────────────────┬───────────────────┘                            │ │
                              Yes    │    No                                          │ │
                              ┌──────┴──────┐                                         │ │
                              │             │                                         │ │
                              ▼             │                                         │ │
                    [22. Update Status]     │                                         │ │
                    [23. Notify Admin Tool] │                                         │ │
                              │             │                                         │ │
                              └──────┬──────┘                                         │ │
                                     │                                                 │ │
                                     ▼                                                 │ │
                    ┌────────────────────────────────────┐                            │ │
                    │    [24. SEND WHATSAPP]             │◄────────────────────────────┘ │
                    │    (Evolution API)                 │    (phone from Extract Data)  │
                    └────────────────┬───────────────────┘                               │
                                     │                                                   │
                                     ▼                                                   │
                    ┌────────────────────────────────────┐                               │
                    │    [25. UPDATE LEAD STATUS]        │                               │
                    └────────────────┬───────────────────┘                               │
                                     │                                                   │
                                     ▼                                                   │
                              [26. FIN ✅]
```

---

## 🗄️ SCHÉMA DES WORKFLOWS AUXILIAIRES

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              WORKFLOWS AUXILIAIRES                                       │
└─────────────────────────────────────────────────────────────────────────────────────────┘

WORKFLOW A : "Index Knowledge Base" (Manuel / Cron quotidien)
═══════════════════════════════════════════════════════════════

[Trigger: Manuel ou Schedule]
         │
         ▼
[SELECT * FROM knowledge_base WHERE embedding IS NULL]
         │
         ▼
[Loop Each Item]
         │
         ▼
[Build Text: title + content]
         │
         ▼
[Mistral Embeddings API]
         │
         ▼
[UPDATE knowledge_base SET embedding = $1 WHERE id = $2]
         │
         ▼
[Log: "Indexed X documents"]


WORKFLOW B : "Index Profiles" (Trigger: après création/modif profil)
═══════════════════════════════════════════════════════════════════════

[Trigger: Webhook après création profil OU Cron horaire]
         │
         ▼
[SELECT * FROM profiles WHERE embedding IS NULL]
         │
         ▼
[Loop Each Item]
         │
         ▼
[Build Rich Text]:
    "{{name}}, {{gender}} de {{age}} ans, habite {{city}}.
     Profession: {{profession}}. {{description_short}}.
     Loisirs: {{hobbies}}. Cherche {{search_criteria}}."
         │
         ▼
[Mistral Embeddings API]
         │
         ▼
[UPDATE profiles SET embedding = $1, indexed_at = NOW() WHERE id = $2]


WORKFLOW C : "Tool - Search Knowledge Base" (Sub-workflow pour Agent FAQ)
════════════════════════════════════════════════════════════════════════════

[Input: query (string)]
         │
         ▼
[Mistral Embeddings API: query → vector]
         │
         ▼
[PostgreSQL:
  SELECT content, title,
         1 - (embedding <=> $1) as similarity
  FROM knowledge_base
  WHERE 1 - (embedding <=> $1) > 0.7
  ORDER BY similarity DESC
  LIMIT 3
]
         │
         ▼
[Merge results into single text]
         │
         ▼
[Output: { rag_results: "..." }]


WORKFLOW D : "Tool - Notify Admin" (Sub-workflow pour escalade)
═══════════════════════════════════════════════════════════════════

[Input: lead_id, lead_name, lead_phone, reason, context]
         │
         ▼
[Get Admin Phone from admin_config]
         │
         ▼
[Build Admin Message]:
    "🔔 ESCALADE
     Client: {{lead_name}}
     Tel: {{lead_phone}}
     Raison: {{reason}}
     Contexte: {{context}}"
         │
         ▼
[Evolution API: Send to Admin]
         │
         ▼
[UPDATE conversations SET status = 'attente_humain' WHERE lead_id = $1]
         │
         ▼
[Output: { notified: true }]


WORKFLOW E : "Tool - Update Lead Preferences" (Sub-workflow pour Qualifier)
════════════════════════════════════════════════════════════════════════════════

[Input: lead_id, extracted_prefs {gender, age_min, age_max, city}]
         │
         ▼
[PostgreSQL:
  UPDATE leads
  SET
    looking_for_gender = COALESCE($1, looking_for_gender),
    preferred_age_min = COALESCE($2, preferred_age_min),
    preferred_age_max = COALESCE($3, preferred_age_max),
    preferred_city = COALESCE($4, preferred_city),
    qualification_complete = (
      $1 IS NOT NULL OR looking_for_gender IS NOT NULL
    ) AND (
      $2 IS NOT NULL OR preferred_age_min IS NOT NULL
    ) AND (
      $4 IS NOT NULL OR preferred_city IS NOT NULL
    )
  WHERE id = $lead_id
]
         │
         ▼
[Output: { updated: true, qualification_complete: bool }]
```

---

## 📊 MIGRATION SQL COMPLÈTE (MISE À JOUR)

```sql
-- =====================================================
-- MIGRATION v3.0 - ARCHITECTURE MULTI-AGENTS
-- =====================================================

-- 1. Colonnes de préférences sur leads
ALTER TABLE leads ADD COLUMN IF NOT EXISTS looking_for_gender VARCHAR(10);
ALTER TABLE leads ADD COLUMN IF NOT EXISTS preferred_age_min SMALLINT;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS preferred_age_max SMALLINT;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS preferred_city VARCHAR(100);
ALTER TABLE leads ADD COLUMN IF NOT EXISTS qualification_complete BOOLEAN DEFAULT FALSE;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS last_profile_shown VARCHAR(20);
ALTER TABLE leads ADD COLUMN IF NOT EXISTS conversation_phase VARCHAR(50) DEFAULT 'new';

-- Index
CREATE INDEX IF NOT EXISTS idx_leads_qualification ON leads (qualification_complete);

-- 2. Améliorer knowledge_base
ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS title VARCHAR(255);
ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS category VARCHAR(100);
ALTER TABLE knowledge_base ADD COLUMN IF NOT EXISTS indexed_at TIMESTAMPTZ;

-- 3. Ajouter indexed_at sur profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS indexed_at TIMESTAMPTZ;

-- 4. Table de log des agents (pour debug)
CREATE TABLE IF NOT EXISTS agent_logs (
    id SERIAL PRIMARY KEY,
    lead_id INT REFERENCES leads(id),
    agent_name VARCHAR(50) NOT NULL,
    input_data JSONB,
    output_data JSONB,
    duration_ms INT,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agent_logs_lead ON agent_logs (lead_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_agent_logs_agent ON agent_logs (agent_name);

-- 5. Insérer contenu FAQ dans knowledge_base (pour RAG)
INSERT INTO knowledge_base (title, content, category, created_at) VALUES
(
    'Fonctionnement de l''agence',
    'L''Agence Matrimoniale Cameroun (AMC) aide les célibataires à trouver leur partenaire idéal. Le processus est simple : vous discutez avec un conseiller pour exprimer vos attentes, puis on vous propose des profils compatibles. Si un profil vous intéresse, on organise une mise en relation sécurisée. L''inscription est gratuite, seule la mise en relation est payante.',
    'fonctionnement',
    NOW()
),
(
    'Sécurité et confidentialité',
    'Vos informations personnelles sont strictement confidentielles. Nous ne partageons jamais votre numéro de téléphone ou vos données sans votre accord explicite. Chaque profil est identifié par un code anonyme (MAT-XXXX-XXX). La mise en relation nécessite le consentement des deux parties.',
    'securite',
    NOW()
),
(
    'Tarifs et paiement',
    'L''inscription et la consultation des profils sont gratuites. Les frais de mise en relation sont de 5000 FCFA par contact. Nous acceptons Mobile Money (MTN MoMo, Orange Money), virement bancaire, et espèces. Contactez un conseiller pour les détails.',
    'tarifs',
    NOW()
),
(
    'Processus de mise en relation',
    'Quand un profil vous intéresse, vous demandez une mise en relation. Un conseiller vous contacte pour confirmer et organiser le premier échange. Après paiement des frais, nous transmettons les contacts aux deux parties. Nous restons disponibles pour vous accompagner.',
    'mise_en_relation',
    NOW()
),
(
    'Couverture géographique',
    'Nous avons des profils dans les principales villes du Cameroun : Douala, Yaoundé, Bafoussam, Bamenda, Garoua, Maroua, Kribi, Limbé, Buéa. Nous développons aussi notre présence en Afrique centrale.',
    'geographie',
    NOW()
),
(
    'Vérification des profils',
    'Tous nos profils sont vérifiés par notre équipe. Nous vérifions l''identité, les photos, et nous nous assurons que les personnes sont réellement à la recherche d''une relation sérieuse. Les profils frauduleux sont immédiatement supprimés.',
    'verification',
    NOW()
),
(
    'Délais de réponse',
    'Nos conseillers répondent généralement dans la journée. Pour les mises en relation, le délai dépend de la disponibilité des deux parties. En moyenne, un premier contact peut être organisé sous 24 à 48 heures après confirmation.',
    'delais',
    NOW()
),
(
    'Types de relations',
    'Notre agence est spécialisée dans les relations sérieuses avec intention de mariage. Nous accompagnons les personnes qui cherchent un partenaire de vie, pas des rencontres occasionnelles.',
    'types_relations',
    NOW()
)
ON CONFLICT DO NOTHING;

-- 6. Vue pour le dashboard des agents
CREATE OR REPLACE VIEW agent_performance AS
SELECT
    agent_name,
    DATE(created_at) as date,
    COUNT(*) as calls,
    AVG(duration_ms) as avg_duration_ms,
    SUM(CASE WHEN success THEN 1 ELSE 0 END)::FLOAT / COUNT(*) as success_rate
FROM agent_logs
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY agent_name, DATE(created_at)
ORDER BY date DESC, agent_name;

-- 7. Fonction pour vérifier si qualification complète
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

-- 8. Trigger pour auto-update qualification_complete
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

-- Vérification
SELECT 'Migration v3.0 terminée' AS status;
```

---

## 📋 RÉSUMÉ DE L'ARCHITECTURE

| Composant            | Rôle                       | Type              | Outils/Tools          |
| -------------------- | -------------------------- | ----------------- | --------------------- |
| **Context Analyzer** | Analyse état conversation  | Code Node         | -                     |
| **Router**           | Décide quel agent appeler  | Code Node         | -                     |
| **Agent GREETER**    | Accueil, salutations       | LLM (prompt 200w) | -                     |
| **Agent QUALIFIER**  | Questions de qualification | LLM (prompt 250w) | update_lead_prefs     |
| **Agent MATCHMAKER** | Recherche profils          | LLM (prompt 300w) | SQL search            |
| **Agent PRESENTER**  | Présente détails profil    | LLM (prompt 300w) | get_profile, log_view |
| **Agent FAQ**        | Répond questions agence    | LLM (prompt 200w) | RAG knowledge_base    |
| **Agent ESCALATION** | Transfert humain           | LLM (prompt 150w) | notify_admin          |
| **Agent HUMANIZER**  | Reformule si trop long     | LLM (prompt 100w) | -                     |
| **Post-Processor**   | Nettoyage final            | Code Node         | -                     |

| Workflow Auxiliaire      | Rôle                      | Trigger               |
| ------------------------ | ------------------------- | --------------------- |
| **Index Knowledge Base** | Génère embeddings KB      | Manuel/Cron           |
| **Index Profiles**       | Génère embeddings profils | Après création profil |
| **Tool - RAG Search**    | Recherche vectorielle     | Sub-workflow          |
| **Tool - Notify Admin**  | Notification WhatsApp     | Sub-workflow          |
| **Tool - Update Prefs**  | Update préférences lead   | Sub-workflow          |

---

## 🚀 ORDRE D'IMPLÉMENTATION RECOMMANDÉ

1. **Jour 1 : Base de données**
   - Exécuter la migration SQL
   - Vérifier les colonnes ajoutées

2. **Jour 2 : Workflows d'indexation**
   - Créer "Index Knowledge Base"
   - Créer "Index Profiles"
   - Exécuter pour remplir les embeddings

3. **Jour 3 : Sub-workflows (Tools)**
   - Tool - RAG Search
   - Tool - Notify Admin
   - Tool - Update Lead Preferences

4. **Jour 4 : Agents individuels**
   - Context Analyzer + Router
   - Agent Greeter
   - Agent Qualifier

5. **Jour 5 : Agents suite**
   - Agent Matchmaker
   - Agent Presenter
   - Agent FAQ

6. **Jour 6 : Finalisation**
   - Agent Escalation
   - Agent Humanizer
   - Post-Processor
   - Tests complets

---

Veux-tu que je te génère maintenant le **JSON complet** d'un des composants ? Je suggère de commencer par :

1. **Workflow "Index Knowledge Base"** (pour que le RAG fonctionne)
2. **Le workflow principal** avec tous les agents

Dis-moi par lequel tu veux commencer !
