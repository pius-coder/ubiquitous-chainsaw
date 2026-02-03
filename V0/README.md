# ubiquitous-chainsaw

|
{
"nodes": [
{
"parameters": {
"httpMethod": "POST",
"path": "whatsapp-webhook",
"options": {}
},
"type": "n8n-nodes-base.webhook",
"typeVersion": 2.1,
"position": [
-3808,
2040
],
"id": "e07fdf2d-fbfc-497e-b6f6-6bc7aacf63b4",
"name": "1 - Webhook WhatsApp",
"webhookId": "whatsapp-v4"
},
{
"parameters": {
"assignments": {
"assignments": [
{
"id": "phone",
"name": "phone",
"value": "={{ $json.body.data.key.remoteJid.replace('@s.whatsapp.net', '') }}",
"type": "string"
},
{
"id": "phone_formatted",
"name": "phone_formatted",
"value": "=+{{ $json.body.data.key.remoteJid.replace('@s.whatsapp.net', '') }}",
"type": "string"
},
{
"id": "message",
"name": "message",
"value": "={{ $json.body.data.message?.conversation || $json.body.data.message?.extendedTextMessage?.text || '' }}",
"type": "string"
},
{
"id": "from_me",
"name": "from_me",
"value": "={{ $json.body.data.key.fromMe }}",
"type": "boolean"
},
{
"id": "push_name",
"name": "push_name",
"value": "={{ $json.body.data.pushName || 'Utilisateur' }}",
"type": "string"
},
{
"id": "timestamp",
"name": "timestamp",
"value": "={{ Date.now() }}",
"type": "number"
},
{
"id": "412f171e-fe03-4f34-8f0d-89c316872230",
"name": "isGroup",
"value": "={{ $json.body.data.key.remoteJid.includes('@g.us') }}",
"type": "string"
}
]
},
"options": {}
},
"type": "n8n-nodes-base.set",
"typeVersion": 3.4,
"position": [
-3584,
2040
],
"id": "24412b83-b36f-4262-a02a-0555e0c38faf",
"name": "2 - Extract Data"
},
{
"parameters": {
"conditions": {
"options": {
"caseSensitive": true,
"leftValue": "",
"typeValidation": "strict",
"version": 2
},
"conditions": [
{
"id": "c1",
"leftValue": "={{ $json.from_me }}",
"rightValue": false,
"operator": {
"type": "boolean",
"operation": "equals"
}
},
{
"id": "c2",
"leftValue": "={{ $json.message }}",
"rightValue": "",
"operator": {
"type": "string",
"operation": "notEquals"
}
},
{
"id": "74b9fd5d-eeb6-429b-a258-b44ed389e3d0",
"leftValue": "={{ $json.isGroup }}",
"rightValue": "false",
"operator": {
"type": "string",
"operation": "equals",
"name": "filter.operator.equals"
}
}
],
"combinator": "and"
},
"options": {}
},
"type": "n8n-nodes-base.if",
"typeVersion": 2.2,
"position": [
-3360,
2040
],
"id": "80051047-265a-472c-88e7-9b0437f0d54b",
"name": "3 - Message valide?"
},
{
"parameters": {},
"type": "n8n-nodes-base.noOp",
"typeVersion": 1,
"position": [
-3136,
2136
],
"id": "8564f99f-500a-47a7-af7a-513752e77016",
"name": "Ignoré (invalide)"
},
{
"parameters": {
"operation": "executeQuery",
"query": "SELECT value FROM admin*config WHERE key = 'admin_phone' LIMIT 1;",
"options": {}
},
"type": "n8n-nodes-base.postgres",
"typeVersion": 2.6,
"position": [
-3136,
1944
],
"id": "eb139c77-2224-47b9-9dc7-5a39c0c9b0e9",
"name": "4 - Get Admin Phone",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"conditions": {
"options": {
"caseSensitive": true,
"leftValue": "",
"typeValidation": "strict",
"version": 2
},
"conditions": [
{
"id": "c1",
"leftValue": "={{ $('2 - Extract Data').item.json.phone }}",
"rightValue": "={{ $json.value }}3",
"operator": {
"type": "string",
"operation": "notEquals"
}
}
],
"combinator": "and"
},
"options": {}
},
"type": "n8n-nodes-base.if",
"typeVersion": 2.2,
"position": [
-2912,
1944
],
"id": "ed5f5576-456b-4f9f-86f6-1097566b032f",
"name": "5 - Pas Admin?"
},
{
"parameters": {},
"type": "n8n-nodes-base.noOp",
"typeVersion": 1,
"position": [
-2688,
2040
],
"id": "7a6304e1-665c-415f-a054-e12217001818",
"name": "Admin Ignoré"
},
{
"parameters": {
"operation": "executeQuery",
"query": "=SELECT id, phone, name, first_name, city, age, gender, status, looking_for_gender, preferred_age_min, preferred_age_max, preferred_city, qualification_complete, conversation_phase FROM leads WHERE phone = '{{ $('2 - Extract Data').item.json.phone_formatted }}' OR phone = '{{ $('2 - Extract Data').item.json.phone }}' LIMIT 1;",
"options": {}
},
"type": "n8n-nodes-base.postgres",
"typeVersion": 2.6,
"position": [
-2688,
1848
],
"id": "7af11faf-aa3b-478b-8e8d-f603855ce61f",
"name": "6 - Get Lead",
"alwaysOutputData": true,
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"conditions": {
"options": {
"caseSensitive": true,
"leftValue": "",
"typeValidation": "strict",
"version": 2
},
"conditions": [
{
"id": "c1",
"leftValue": "={{ $json.id.toString() || '' }}",
"operator": {
"type": "string",
"operation": "notEmpty",
"singleValue": true
}
}
],
"combinator": "or"
},
"options": {}
},
"type": "n8n-nodes-base.if",
"typeVersion": 2.2,
"position": [
-2464,
1848
],
"id": "210c39bf-9a41-44b0-ab19-99ccc5b40085",
"name": "7 - Lead existe?"
},
{
"parameters": {
"assignments": {
"assignments": [
{
"id": "lead_id",
"name": "lead_id",
"value": "={{ $json.data[0].id }}",
"type": "number"
},
{
"id": "lead_phone",
"name": "lead_phone",
"value": "={{ $json.data[0].phone }}",
"type": "string"
},
{
"id": "lead_name",
"name": "lead_name",
"value": "={{ $json.data[0].name || $('2 - Extract Data').item.json.push_name }}",
"type": "string"
},
{
"id": "user_message",
"name": "user_message",
"value": "={{ $('2 - Extract Data').item.json.message }}",
"type": "string"
},
{
"id": "looking_for_gender",
"name": "looking_for_gender",
"value": "={{ $('6 - Get Lead').item.json.looking_for_gender || '' }}",
"type": "string"
},
{
"id": "preferred_age_min",
"name": "preferred_age_min",
"value": "={{ $('6 - Get Lead').item.json.preferred_age_min || null }}",
"type": "number"
},
{
"id": "preferred_age_max",
"name": "preferred_age_max",
"value": "={{ $('6 - Get Lead').item.json.preferred_age_max || null }}",
"type": "number"
},
{
"id": "preferred_city",
"name": "preferred_city",
"value": "={{ $('6 - Get Lead').item.json.preferred_city || '' }}",
"type": "string"
},
{
"id": "qualification_complete",
"name": "qualification_complete",
"value": "={{ $('6 - Get Lead').item.json.qualification_complete || false }}",
"type": "boolean"
},
{
"id": "is_new_lead",
"name": "is_new_lead",
"value": "={{ !$('6 - Get Lead').item.json.id }}",
"type": "boolean"
},
{
"id": "conversation_phase",
"name": "conversation_phase",
"value": "={{ $('6 - Get Lead').item.json.conversation_phase || 'new' }}",
"type": "string"
}
]
},
"options": {}
},
"type": "n8n-nodes-base.set",
"typeVersion": 3.4,
"position": [
-1792,
1848
],
"id": "066e6b9e-623d-4a7d-ae56-900f0684524a",
"name": "9 - Préparer Contexte"
},
{
"parameters": {
"operation": "executeQuery",
"query": "INSERT INTO conversations (lead_id, direction, content, message_type, sender_type, created_at) VALUES ({{ $json.lead_id }}, 'in', '{{ $json.user_message.replace(/'/g, \"''\").replace(/\\\\/g, \"\\\\\\\\\") }}', 'text', 'client', NOW());",
"options": {}
},
"type": "n8n-nodes-base.postgres",
"typeVersion": 2.6,
"position": [
-1568,
1848
],
"id": "293a10c6-154b-4c51-ad45-fe657c4745ca",
"name": "10 - Log IN",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"operation": "executeQuery",
"query": "=SELECT COALESCE(status, 'bot_actif') as conv_status FROM conversations WHERE lead_id = {{ $('9 - Préparer Contexte').item.json.lead_id }} ORDER BY created_at DESC LIMIT 1;",
"options": {}
},
"type": "n8n-nodes-base.postgres",
"typeVersion": 2.6,
"position": [
-1344,
1848
],
"id": "a965a5e2-af2e-4b27-97a1-aba48defa812",
"name": "11 - Conv Status",
"alwaysOutputData": true,
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"conditions": {
"options": {
"typeValidation": "loose"
},
"conditions": [
{
"id": "c1",
"leftValue": "={{ $json.conv_status }}",
"rightValue": "attente_humain",
"operator": {
"type": "string",
"operation": "notEquals"
}
}
],
"combinator": "and"
},
"options": {}
},
"type": "n8n-nodes-base.if",
"typeVersion": 2.2,
"position": [
-1120,
1848
],
"id": "087cd3c7-90c2-4be9-90df-b0b5c47c92da",
"name": "12 - Bot actif?"
},
{
"parameters": {},
"type": "n8n-nodes-base.noOp",
"typeVersion": 1,
"position": [
-896,
1944
],
"id": "e4eeaa1e-cf78-4581-8e9f-fb6a50c060a1",
"name": "Attente Humain"
},
{
"parameters": {
"operation": "executeQuery",
"query": "=SELECT direction, content, sender_type, intent, created_at FROM conversations WHERE lead_id = {{ $('9 - Préparer Contexte').item.json.lead_id }} ORDER BY created_at DESC LIMIT 10;",
"options": {}
},
"type": "n8n-nodes-base.postgres",
"typeVersion": 2.6,
"position": [
-896,
1752
],
"id": "a3e21be6-704f-476a-9cb6-2f9bf642441b",
"name": "13 - Get History",
"alwaysOutputData": true,
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"jsCode": "// ============================================================================\n// ANALYZE V4 - Analyse complète du contexte\n// ============================================================================\n\nconst msg = $('9 - Préparer Contexte').first().json.user_message.toLowerCase();\nconst current = $('9 - Préparer Contexte').first().json;\nconst history = $('13 - Get History').all();\n\n// ============================================================================\n// 1. EXTRACTION DES CRITÈRES DE QUALIFICATION\n// ============================================================================\n\nlet extracted = {\n  gender: current.looking_for_gender || null,\n  age_min: current.preferred_age_min || null,\n  age_max: current.preferred_age_max || null,\n  city: current.preferred_city || null\n};\n\n// Détection du genre recherché\nif (!extracted.gender) {\n  if (/\\b(femme|fille|dame|épouse|féminin)\\b/i.test(msg)) {\n    extracted.gender = 'femme';\n  } else if (/\\b(homme|garçon|monsieur|époux|mec|masculin)\\b/i.test(msg)) {\n    extracted.gender = 'homme';\n  }\n}\n\n// Détection de la tranche d'âge\nconst ageMatch = msg.match(/(\\d{2})\\s*[-àa]\\s*(\\d{2})/i);\nif (ageMatch) {\n  extracted.age_min = parseInt(ageMatch[1]);\n  extracted.age_max = parseInt(ageMatch[2]);\n} else {\n  // Détection âge simple\n  const singleAge = msg.match(/(?:environ|vers|autour de)?\\s*(\\d{2})\\s*ans/i);\n  if (singleAge && !extracted.age_min) {\n    const age = parseInt(singleAge[1]);\n    extracted.age_min = Math.max(18, age - 3);\n    extracted.age_max = age + 3;\n  }\n}\n\n// Détection de la ville\nconst cities = [\n  { patterns: ['douala'], normalized: 'Douala' },\n  { patterns: ['yaoundé', 'yaounde'], normalized: 'Yaoundé' },\n  { patterns: ['bafoussam'], normalized: 'Bafoussam' },\n  { patterns: ['garoua'], normalized: 'Garoua' },\n  { patterns: ['bamenda'], normalized: 'Bamenda' },\n  { patterns: ['kribi'], normalized: 'Kribi' },\n  { patterns: ['limbé', 'limbe'], normalized: 'Limbé' },\n  { patterns: ['buea'], normalized: 'Buea' },\n  { patterns: ['maroua'], normalized: 'Maroua' },\n  { patterns: ['bertoua'], normalized: 'Bertoua' },\n  { patterns: ['ngaoundéré', 'ngaoundere'], normalized: 'Ngaoundéré' }\n];\n\nfor (const city of cities) {\n  if (city.patterns.some(p => msg.includes(p))) {\n    extracted.city = city.normalized;\n    break;\n  }\n}\n\n// ============================================================================\n// 2. DÉTECTION DE CODE PROFIL\n// ============================================================================\n\nconst profileCodeMatch = msg.match(/MAT-\\d{4}-\\d{3}/i);\nconst hasProfileCode = !!profileCodeMatch;\nconst detectedProfileCode = profileCodeMatch ? profileCodeMatch[0].toUpperCase() : null;\n\n// ============================================================================\n// 3. CALCUL QUALIFICATION COMPLÈTE\n// ============================================================================\n\nconst qualComplete = !!(extracted.gender || current.looking_for_gender) &&\n                     !!(extracted.age_min || current.preferred_age_min) &&\n                     !!(extracted.city || current.preferred_city);\n\n// ============================================================================\n// 4. FORMATAGE DE L'HISTORIQUE\n// ============================================================================\n\nconst formattedHistory = history.slice(0, 8).reverse().map(h => {\n  const role = h.json.sender_type === 'client' ? 'Client' : 'Maya';\n  const content = h.json.content.substring(0, 200);\n  return `${role}: ${content}`;\n}).join('\\n');\n\n// ============================================================================\n// 5. DÉTERMINATION DU PREMIER MESSAGE\n// ============================================================================\n\n// C'est le premier message si:\n// - Le lead vient d'être créé (is_new_lead)\n// - OU il n'y a qu'un seul message dans l'historique (le message actuel)\n// - OU la phase de conversation est 'new'\nconst isFirstMessage = current.is_new_lead || \n                       history.length <= 1 || \n                       current.conversation_phase === 'new';\n\n// ============================================================================\n// 6. DÉTECTION D'INTENTION SPÉCIFIQUE\n// ============================================================================\n\nconst intents = {\n  greeting: /^(bonjour|bonsoir|salut|hello|hey|coucou|bjr|cc)/i.test(msg),\n  farewell: /^(au revoir|bye|à bientôt|merci beaucoup|a\\+)/i.test(msg),\n  faq_tarif: /(tarif|prix|coût|combien|payer|paiement|cout|gratuit)/i.test(msg),\n  faq_how: /(comment|fonctionn|procéd|étape|marche)/i.test(msg),\n  escalation: /(conseiller|humain|contact|appeler|téléphone|parler à quelqu)/i.test(msg),\n  interest: /(intéress|ce profil|celui[- ]ci|celui[- ]là|plus de détail|en savoir plus)/i.test(msg),\n  match_request: /(cherche|recherche|trouv|profil|présent)/i.test(msg) && qualComplete\n};\n\n// ============================================================================\n// 7. ANALYSE DU SENTIMENT (pour pré-escalation)\n// ============================================================================\n\nconst negativeKeywords = [\n  'merde', 'nul', 'pourri', 'arnaque', 'escroquerie', 'voleur',\n  'en ai marre', 'ras le bol', 'frustré', 'énervé', 'agacé',\n  'pas content', 'déçu', 'mauvais service', 'incompétent',\n  'ridicule', 'honteux', 'scandaleux'\n];\n\nconst hasNegativeSentiment = negativeKeywords.some(word => msg.includes(word));\n\n// Comptage frustration dans l'historique\nconst historyText = history.map(h => (h.json.content || '').toLowerCase()).join(' ');\nconst frustrationCount = negativeKeywords.filter(w => historyText.includes(w)).length;\nconst isFrustratedInHistory = frustrationCount >= 2;\n\n// ============================================================================\n// 8. RÉSULTAT FINAL\n// ============================================================================\n\nreturn [{\n  json: {\n    // Identifiants\n    lead_id: current.lead_id,\n    lead_phone: current.lead_phone,\n    lead_name: current.lead_name,\n    \n    // Message\n    user_message: current.user_message,\n    formatted_history: formattedHistory,\n    history_count: history.length,\n    \n    // État conversation\n    is_first_message: isFirstMessage,\n    is_new_lead: current.is_new_lead,\n    conversation_phase: current.conversation_phase,\n    \n    // Profil détecté\n    detected_profile_code: detectedProfileCode,\n    has_profile_code: hasProfileCode,\n    \n    // Qualification\n    qualification_complete: qualComplete,\n    looking_for_gender: extracted.gender || current.looking_for_gender || '',\n    preferred_age_min: extracted.age_min || current.preferred_age_min || null,\n    preferred_age_max: extracted.age_max || current.preferred_age_max || null,\n    preferred_city: extracted.city || current.preferred_city || '',\n    \n    // Intentions détectées\n    intents: intents,\n    primary_intent: Object.entries(intents).find(([k, v]) => v)?.[0] || 'general',\n    \n    // Sentiment\n    has_negative_sentiment: hasNegativeSentiment,\n    is_frustrated_in_history: isFrustratedInHistory,\n    frustration_level: frustrationCount\n  }\n}];"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        -672,
        1752
      ],
      "id": "9487e7e2-92ad-4f2c-bfb2-2062ce2622aa",
      "name": "14 - Analyze"
    },
    {
      "parameters": {
        "operation": "executeQuery",
        "query": "=UPDATE leads SET looking_for_gender = COALESCE(NULLIF('{{ $json.looking_for_gender }}', ''), looking_for_gender), preferred_age_min = COALESCE({{ $json.preferred_age_min || 'NULL' }}, preferred_age_min), preferred_age_max = COALESCE({{ $json.preferred_age_max || 'NULL' }}, preferred_age_max), preferred_city = COALESCE(NULLIF('{{ $json.preferred_city }}', ''), preferred_city), qualification_complete = {{ $json.qualification_complete }}, updated_at = NOW() WHERE id = {{ $json.lead_id }};",
        "options": {}
      },
      "type": "n8n-nodes-base.postgres",
      "typeVersion": 2.6,
      "position": [
        -448,
        1752
      ],
      "id": "a7a41d36-56e7-45e4-b7b1-ad2df4f99801",
      "name": "15 - Update Qual",
      "credentials": {
        "postgres": {
          "id": "Gv2oFLeW3VbnJ0xx",
          "name": "Postgres account"
        }
      }
    },
    {
      "parameters": {
        "jsCode": "// ============================================================================\n// PRE-ESCALATION CHECK - Détection frustration automatique\n// ============================================================================\n\n// On s'assure que context est bien un objet\nconst context = $('14 - Analyze').first().json \nconst msg = (context.user_message || '').toLowerCase();\nconst leadName = context.lead_name || 'cher client';\n\n// ============================================================================\n// 1. VÉRIFICATION DES SIGNAUX DE FRUSTRATION\n// ============================================================================\n\nconst shouldAutoEscalate = !!(context.has_negative_sentiment || context.is_frustrated_in_history);\n\nif (shouldAutoEscalate) {\n  const escalationReason = context.has_negative_sentiment \n    ? 'negative_sentiment' \n    : 'repeated_frustration';\n  \n  const escalationMessage = `Je comprends parfaitement ${leadName}. ` +\n    `Je transfère immédiatement votre demande à un conseiller humain qui vous ` +\n    `contactera dans les 15 prochaines minutes. Merci de votre patience. 🙏`;\n  \n  return [{\n    json: JSON.parse(JSON.stringify({\n      ...context,\n      auto_escalated: true,\n      escalation_reason: escalationReason,\n      final_response: escalationMessage,\n      needs_escalation: true,\n      skip_agent: true\n    }))\n  }];\n}\n\n// ============================================================================\n// 2. VÉRIFICATION DEMANDE EXPLICITE D'ESCALATION\n// ============================================================================\n\nconst explicitEscalation = !!(\n  (context.intents && context.intents.escalation) || \n  /(conseiller|humain|parler à quelqu'un|appeler)/i.test(msg)\n);\n\nif (explicitEscalation) {\n  const escalationMessage = `Bien sûr ${leadName} ! ` +\n    `Je transfère votre demande à un conseiller qui vous contactera très rapidement. ` +\n    `Merci de votre confiance ! 😊`;\n  \n  return [{\n    json: JSON.parse(JSON.stringify({\n      ...context,\n      auto_escalated: true,\n      escalation_reason: 'client_request',\n      final_response: escalationMessage,\n      needs_escalation: true,\n      skip_agent: true\n    }))\n  }];\n}\n\n// ============================================================================\n// 3. CONTINUER VERS L'AGENT\n// ============================================================================\n\nreturn [{\n  json: JSON.parse(JSON.stringify({\n    ...context,\n    auto_escalated: false,\n    skip_agent: false\n  }))\n}];"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        -224,
        1752
      ],
      "id": "05e3f9e5-ec1f-49c0-a255-ac9a3136ff86",
      "name": "16 - Pre-Escalation Check"
    },
    {
      "parameters": {
        "conditions": {
          "options": {
            "caseSensitive": true,
            "leftValue": "",
            "typeValidation": "strict",
            "version": 2
          },
          "conditions": [
            {
              "id": "skip",
              "leftValue": "={{ $json.skip_agent }}",
              "rightValue": true,
              "operator": {
                "type": "boolean",
                "operation": "equals"
              }
            }
          ],
          "combinator": "and"
        },
        "options": {}
      },
      "type": "n8n-nodes-base.if",
      "typeVersion": 2.2,
      "position": [
        0,
        1752
      ],
      "id": "1fc76a29-6090-4429-be20-d8a130303777",
      "name": "17 - Skip Agent?"
    },
    {
      "parameters": {
        "jsCode": "// ============================================================================\n// POST-PROCESSOR V4 - Nettoyage final sécurisé\n// ============================================================================\n\nconst items = $input.all();\nlet context = {};\nlet response = '';\n\n// ============================================================================\n// 1. EXTRACTION INTELLIGENTE DES DONNÉES (Fix Agrégation)\n// ============================================================================\n\nfor (const item of items) {\n  const json = item.json;\n  \n  // a) Détecter le Contexte (objet plat avec lead_id)\n  if (json.lead_id) {\n    context = json;\n  }\n  \n  // b) Détecter la Réponse de l'Agent\n  // Format 1: { data: [ { output: \"...\" } ] } (Typique après aggrégation)\n  if (json.data && Array.isArray(json.data) && json.data[0] && json.data[0].output) {\n    response = json.data[0].output;\n  } \n  // Format 2: { output: \"...\" } ou { text: \"...\" } directement\n  else if (json.output || json.text || json.response || json.message) {\n    const candidate = json.output || json.text || json.response || json.message;\n    if (typeof candidate === 'string' && candidate.length > 5) {\n      response = candidate;\n    }\n  }\n}\n\n// Fallback si le contexte n'est pas dans les items (référence directe au nœud amont)\nif (!context.lead_id) {\n  try {\n    context = $('16 - Pre-Escalation Check').first().json;\n  } catch (e) {\n    context = items[0]?.json || {};\n  }\n}\n\n// ============================================================================\n// 2. LOGIQUE D'ESCALATION OU GESTION DU VIDE\n// ============================================================================\n\n// Si escalation automatique activée (skip_agent=true)\nif (context.skip_agent && context.final_response) {\n  response = context.final_response;\n}\n\n// Message par défaut si vide ou trop court\nif (!response || response.length < 10) {\n  if (context.is_first_message) {\n    response = `Bonjour ${context.lead_name || 'cher client'} ! 😊 Je suis Maya de l'Agence Matrimoniale Cameroun. Je suis là pour vous aider à trouver l'âme sœur. Vous recherchez un homme ou une femme ?`;\n  } else {\n    response = `Je suis là pour vous aider. Que recherchez-vous ?`;\n  }\n}\n\n// ============================================================================\n// 3. NETTOYAGE RIGOUREUX (SANS LLM)\n// ============================================================================\n\n// Supprimer les blocs de code et markdown headers\nresponse = response\n  .replace(/```[\\s\\S]*?```/g, '')\n  .replace(/^#+\\s+/gm, '')\n  .replace(/\\*\\*([^*]+)\\*\\*/g, '*$1*') // Bold Markdown -> Petit bold WhatsApp\n  .replace(/\\n{3,}/g, '\\n\\n')          // Max 2 sauts de ligne\n  .replace(/  +/g, ' ');               // Pas de doubles espaces\n\n// Supprimer les traces de \"pensée\" de l'IA (Tooling/Database)\nresponse = response\n  .replace(/J'ai (utilisé|cherché dans|consulté) (l'outil|la base|ma base)[^.]*\\./gi, '')\n  .replace(/Selon (ma base de données|mes informations|l'outil|la recherche)[^.]*,?\\s*/gi, '')\n  .replace(/\\[Utilisation de l'outil[^\\]]*\\]/gi, '')\n  .replace(/\\*\\*Outil utilisé[^*]*\\*\\*/gi, '');\n\n// ============================================================================\n// 4. NETTOYAGE DES SALUTATIONS (Sauf premier message)\n// ============================================================================\n\nif (!context.is_first_message) {\n  response = response\n    .replace(/^(Bonjour|Bonsoir|Salut|Hello|Hey|Coucou)[\\s,!.]*([A-Z][a-zéèêë]+)?[\\s,!.]*/i, '')\n    .replace(/^(Je suis Maya|C'est Maya|Ici Maya|Maya ici)[^.!?]*[.!?]?\\s*/i, '')\n    .trim();\n  \n  if (response && /^[a-z]/.test(response)) {\n    response = response.charAt(0).toUpperCase() + response.slice(1);\n  }\n}\n\n// ============================================================================\n// 5. LIMITATION ET PONCTUATION\n// ============================================================================\n\nconst MAX_LENGTH = 700;\nif (response.length > MAX_LENGTH) {\n  response = response.substring(0, MAX_LENGTH - 3) + '...';\n}\n\nif (response && !/[.!?😊🙏💕]$/.test(response)) {\n response += '.';\n}\n\n// ============================================================================\n// 6. DÉTECTION BESOIN D'ESCALATION (Tool calls)\n// ============================================================================\n\nlet needsEscalation = !!(context.needs_escalation || context.auto_escalated);\n\nfor (const item of items) {\n const data = item.json;\n if (data.toolCalls || (data.data && data.data[0] && data.data[0].toolCalls)) {\n needsEscalation = true;\n break;\n }\n}\n\n// ============================================================================\n// 7. RÉSULTAT FINAL (Objet plat prêt pour WhatsApp)\n// ============================================================================\n\nreturn [{\n json: {\n final_response: response.trim(),\n needs_escalation: needsEscalation,\n escalation_reason: context.escalation_reason || (needsEscalation ? 'agent_decision' : null),\n lead_id: context.lead_id || null,\n lead_phone: context.lead_phone || null,\n lead_name: context.lead_name || 'Client',\n is_first_message: !!context.is_first_message,\n qualification_complete: !!context.qualification_complete\n }\n}];"
},
"type": "n8n-nodes-base.code",
"typeVersion": 2,
"position": [
1680,
1752
],
"id": "0f4b5631-a4f6-44cc-996f-514d8f0ba47c",
"name": "20 - Process Final"
},
{
"parameters": {
"operation": "executeQuery",
"query": "=INSERT INTO conversations (lead_id, direction, content, message_type, sender_type, intent, created_at) VALUES ({{ $json.lead_id }}, 'out', '{{ $json.final_response.replace(/'/g, \"''\").replace(/\\\\/g, \"\\\\\\\\\") }}', 'text', 'bot', '{{ $json.needs_escalation ? 'escalation' : 'response' }}', NOW());",
"options": {}
},
"type": "n8n-nodes-base.postgres",
"typeVersion": 2.6,
"position": [
1904,
1752
],
"id": "8c09857b-5c48-458d-8913-71cbd3a3897b",
"name": "21 - Log OUT",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"conditions": {
"options": {
"caseSensitive": true,
"leftValue": "",
"typeValidation": "strict",
"version": 2
},
"conditions": [
{
"id": "escalation",
"leftValue": "={{ $('20 - Process Final').item.json.needs_escalation }}",
"rightValue": true,
"operator": {
"type": "boolean",
"operation": "equals"
}
}
],
"combinator": "and"
},
"options": {}
},
"type": "n8n-nodes-base.if",
"typeVersion": 2.2,
"position": [
2128,
1752
],
"id": "c27e9a27-2cc4-485d-a3a6-89d3387289ed",
"name": "22 - Escalation?"
},
{
"parameters": {
"method": "POST",
"url": "=https://n8n.home.local/webhook/notify-admin",
"sendBody": true,
"bodyParameters": {
"parameters": [
{
"name": "lead_id",
"value": "={{ $('20 - Process Final').item.json.lead_id }}"
},
{
"name": "lead_name",
"value": "={{ $('20 - Process Final').item.json.lead_name }}"
},
{
"name": "lead_phone",
"value": "={{ $('20 - Process Final').item.json.lead_phone }}"
},
{
"name": "reason",
"value": "={{ $('20 - Process Final').item.json.escalation_reason || 'Escalade depuis bot' }}"
},
{
"name": "last_message",
"value": "={{ $('14 - Analyze').item.json.user_message }}"
}
]
},
"options": {
"timeout": 10000
}
},
"type": "n8n-nodes-base.httpRequest",
"typeVersion": 4.2,
"position": [
2352,
1680
],
"id": "bfc42bc7-ec84-4ee4-b867-87c953328f87",
"name": "23 - Notify Admin"
},
{
"parameters": {
"operation": "executeQuery",
"query": "=UPDATE conversations SET status = 'attente_humain' WHERE lead_id = {{ $('20 - Process Final').first().json.lead_id }} AND created_at >= NOW() - INTERVAL '1 hour';",
"options": {}
},
"type": "n8n-nodes-base.postgres",
"typeVersion": 2.6,
"position": [
2576,
1680
],
"id": "b6a93d00-48c0-4efa-a526-fdb18d4999a3",
"name": "24 - Update Status",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"resource": "messages-api",
"instanceName": "new",
"remoteJid": "={{ $('2 - Extract Data').first().json.phone }}",
"messageText": "={{ $('20 - Process Final').first().json.final_response }}",
"options_message": {}
},
"type": "n8n-nodes-evolution-api-en.evolutionApi",
"typeVersion": 1,
"position": [
2800,
1752
],
"id": "ea969bc6-24ba-4d91-a11e-0b789f8ede15",
"name": "25 - Send WhatsApp",
"credentials": {
"evolutionApi": {
"id": "V1jMvwrsC7FPvBug",
"name": "Evolution account"
}
}
},
{
"parameters": {
"operation": "executeQuery",
"query": "=UPDATE leads SET status = CASE WHEN status IN ('nouveau_lead', 'prospect_anonyme') THEN 'prospect_actif' WHEN '{{ $('16 - Pre-Escalation Check').first().json.needs_escalation }}' = 'true' THEN 'en_attente' ELSE status END, conversation_phase = CASE WHEN '{{ $('16 - Pre-Escalation Check').first().json.needs_escalation }}' = 'true' THEN 'escalation' WHEN '{{ $('16 - Pre-Escalation Check').first().json.qualification_complete }}' = 'true' THEN 'qualified' ELSE 'qualifying' END, updated_at = NOW() WHERE id = {{ $('16 - Pre-Escalation Check').first().json.lead_id }};",
"options": {}
},
"type": "n8n-nodes-base.postgres",
"typeVersion": 2.6,
"position": [
3024,
1752
],
"id": "40b36b13-60b9-42dd-bcdd-b6a23733ee99",
"name": "26 - Update Lead",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {},
"type": "n8n-nodes-base.noOp",
"typeVersion": 1,
"position": [
3248,
1752
],
"id": "1bf1bc3f-ece9-4b07-a73c-0ab7f9a2a01a",
"name": "✅ FIN"
},
{
"parameters": {
"operation": "executeQuery",
"query": "INSERT INTO leads (phone, name, status, source, conversation_phase, created_at, updated_at) VALUES ('{{ $('2 - Extract Data').item.json.phone_formatted }}', '{{ $('2 - Extract Data').item.json.push_name.replace(/'/g, \"''\") }}', 'prospect_anonyme', 'whatsapp_direct', 'new', NOW(), NOW()) RETURNING id, phone, name, status, city, age, gender, looking_for_gender, preferred_age_min, preferred_age_max, preferred_city, qualification_complete, conversation_phase;",
"options": {}
},
"type": "n8n-nodes-base.postgres",
"typeVersion": 2.6,
"position": [
-2240,
1920
],
"id": "3da51c9f-f7f0-44ee-a529-6f6229ed79e8",
"name": "8 - Créer Lead1",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"aggregate": "aggregateAllItemData",
"options": {}
},
"type": "n8n-nodes-base.aggregate",
"typeVersion": 1,
"position": [
1456,
1752
],
"id": "8b338479-9ece-44ad-ac24-2e693687084f",
"name": "Aggregate"
},
{
"parameters": {
"aggregate": "aggregateAllItemData",
"options": {}
},
"type": "n8n-nodes-base.aggregate",
"typeVersion": 1,
"position": [
-2016,
1848
],
"id": "5e24c7d9-ca18-4325-a45d-033d1a3ccba1",
"name": "Aggregate1"
},
{
"parameters": {
"promptType": "define",
"text": "=## 👤 CONTEXTE CLIENT\nNom : {{ $json.lead_name }}\nTéléphone : {{ $json.lead_phone }}\nPremier message : {{ $json.is_first_message ? 'OUI' : 'NON' }}\nQualification complète : {{ $json.qualification_complete ? 'OUI' : 'NON' }}\n\n## 🎯 CRITÈRES DE RECHERCHE\nGenre recherché : {{ $json.looking_for_gender || '❌ Non renseigné' }}\nTranche d'âge : {{ $json.preferred_age_min ? $json.preferred_age_min + '-' + $json.preferred_age_max + ' ans' : '❌ Non renseigné' }}\nVille : {{ $json.preferred_city || '❌ Non renseignée' }}\n\n## 💬 MESSAGE DU CLIENT\n\"{{ $json.user_message }}\"\n\n## 📜 HISTORIQUE (derniers échanges)\n{{ $json.formatted_history || 'Premier contact - pas d\\'historique' }}\n\n---\n\n**Instructions spéciales :**\n{{ $json.is_first_message ? '✅ C\\'EST LE PREMIER MESSAGE → Dis bonjour et présente-toi brièvement !' : '❌ Ce n\\'est PAS le premier message → NE DIS PAS bonjour, continue directement la conversation' }}\n\n{{ $json.has_profile_code ? '🔍 Le client mentionne le profil ' + $json.detected_profile_code + ' → Utilise l\\'outil get_profile_details' : '' }}\n\n{{ !$json.qualification_complete ? '📋 Qualification incomplète → Collecte les critères manquants (1 question à la fois)' : '✅ Qualification complète → Tu peux proposer des profils avec search_profiles' }}\n\n{{ $json.intents.faq_tarif || $json.intents.faq_how ? '❓ Question FAQ détectée → Utilise l\\'outil search_faq' : '' }}\n\n{{ $json.intents.interest ? '💕 Intérêt pour un profil → Utilise escalate_to_human pour organiser la mise en relation' : '' }}\n\n\nIMPORTANT : Après avoir utilisé un outil, résume le résultat pour le client en une phrase simple. NE FAIS PAS DE BOUCLE.",
"options": {
"systemMessage": "Tu es Maya, assistante virtuelle professionnelle de l'Agence Matrimoniale.\n\n🎯 TON RÔLE PRINCIPAL :\nTu es le CHEF D'ORCHESTRE de la conversation avec le client. Tu gères la qualification, proposes des profils, et coordonnes avec ton assistant spécialisé pour les recherches en base de données.\n\n📊 TU AS UN ASSISTANT SPÉCIALISÉ :\n- Un \"Agent de Recherche DB\" qui gère TOUTES les interrogations de base de données\n- Tu LUI DÉLÈGUES toutes les recherches d'informations (profils, historique, stats...)\n- Il te revient avec les résultats structurés\n- Tu INTERPRÈTES ces résultats et les présentes au client de façon naturelle\n\n🔄 MODE OPÉRATOIRE :\n1. Lis le message du client\n2. Détermine l'action nécessaire :\n - Recherche d'info en DB ? → Délègue à ton assistant (tool AI Agent)\n - Question simple/qualification ? → Réponds directement\n - Multiple recherches nécessaires ? → Fais plusieurs appels à ton assistant\n3. Synthétise les résultats pour le client\n4. STOP (ne simule jamais la réponse du client)\n\n🎓 SCÉNARIOS DE DÉLÉGATION :\n\n**Client : \"Quels profils ai-je consultés ?\"**\n→ TU DÉLÈGUES : \"Récupère les profils consultés par ce lead\"\n→ Assistant te revient avec la liste\n→ TU RÉPONDS : \"Vous avez consulté 3 profils : Marie (28 ans), Sophie (30 ans)...\"\n\n**Client : \"Parle-moi du profil F025\"**\n→ TU DÉLÈGUES : \"Récupère les détails du profil F025\"\n→ Assistant te revient avec les infos complètes\n→ TU RÉPONDS : \"F025 est Marie, 28 ans, enseignante à Yaoundé...\"\n\n**Client : \"Montrez-moi des femmes de 25-35 ans à Yaoundé\"**\n→ TU DÉLÈGUES : \"Recherche des profils femmes, 25-35 ans, Yaoundé\"\n→ Assistant te revient avec 5 profils\n→ TU RÉPONDS : \"J'ai trouvé 5 profils correspondants. Voici les 3 premiers...\"\n\n**Client : \"Où en sont mes demandes ?\"**\n→ TU DÉLÈGUES : \"Récupère les demandes de contact de ce lead\"\n→ Assistant te revient avec les statuts\n→ TU RÉPONDS : \"Votre demande REQ001 pour Marie est en cours...\"\n\n📋 QUALIFICATION DES LEADS :\nCollecte ces informations (UNE question à la fois) :\n1. Genre recherché (homme/femme)\n2. Tranche d'âge (min-max)\n3. Ville préférée\n\nUne fois qualifié → Propose des profils via ton assistant\n\n💬 STYLE DE COMMUNICATION :\n- PREMIER MESSAGE → \"Bonjour [Nom] ! 👋\"\n- AUTRES MESSAGES → Continue naturellement sans \"bonjour\"\n- Sois concis, professionnel et chaleureux\n- Une question à la fois\n- Utilise des emojis avec parcimonie (👀 💕 ✨)\n\n🚫 INTERDICTIONS STRICTES :\n- Ne JAMAIS révéler de coordonnées avant paiement\n- Ne JAMAIS inventer des informations\n- Ne JAMAIS simuler la réponse du client\n- Ne JAMAIS continuer la conversation après ta réponse\n\n✅ WORKFLOW TYPIQUE :\n\nExemple conversation :\n1. Client : \"Bonjour\"\n Maya : \"Bonjour Jean ! Je suis Maya. Vous recherchez un homme ou une femme ?\"\n\n2. Client : \"Une femme\"\n Maya : \"Parfait ! Quelle tranche d'âge vous intéresse ?\"\n\n3. Client : \"25 à 35 ans\"\n Maya : \"Et dans quelle ville ?\"\n\n4. Client : \"Yaoundé\"\n Maya : [DÉLÈGUE la recherche à l'assistant]\n Maya : \"Super ! J'ai trouvé 5 profils de femmes de 25-35 ans à Yaoundé. Voici les 3 premiers...\"\n\n5. Client : \"Parle-moi de F025\"\n Maya : [DÉLÈGUE récupération détails F025]\n Maya : \"F025 est Marie, 28 ans, enseignante... Elle recherche...\"\n\n🎯 RAPPEL IMPORTANT :\nTu es l'interface client. Ton assistant est ton bras droit pour la base de données.\n→ Tu DÉLÈGUES les recherches\n→ Tu INTERPRÈTES les résultats\n→ Tu COMMUNIQUES avec le client\n\nSTOP après chaque réponse. Attends le prochain message client."
}
},
"type": "@n8n/n8n-nodes-langchain.agent",
"typeVersion": 3.1,
"position": [
456,
1928
],
"id": "3e4065c0-259e-483b-bc9a-6e430816fdab",
"name": "18 - Agent MAYA"
},
{
"parameters": {
"sessionIdType": "customKey",
"sessionKey": "=maya_session*{{ $('14 - Analyze').first().json.lead_id }}",
"contextWindowLength": 12
},
"type": "@n8n/n8n-nodes-langchain.memoryPostgresChat",
"typeVersion": 1.3,
"position": [
528,
2152
],
"id": "5dc6111d-e3db-4b61-a5dd-f79bcdfb2b21",
"name": "Memory Maya",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"model": "mistral-large-latest",
"options": {}
},
"type": "@n8n/n8n-nodes-langchain.lmChatMistralCloud",
"typeVersion": 1,
"position": [
400,
2152
],
"id": "fa86a2a1-c440-45e1-952d-6c362a88c176",
"name": "Mistral Cloud Chat Model",
"credentials": {
"mistralCloudApi": {
"id": "oTAUAlLG4h6S0uVq",
"name": "Mistral Cloud account"
}
}
},
{
"parameters": {
"operation": "executeQuery",
"query": "SELECT \n p.id,\n p.code,\n p.name,\n p.age,\n p.gender,\n p.city,\n p.neighborhood,\n p.profession,\n p.education*level,\n p.marital_status,\n p.description_short,\n p.height,\n p.body_type\nFROM profiles p\nWHERE p.status = 'published'\n AND LOWER(p.gender) = LOWER('{{ $fromAI('gender', 'Genre: homme ou femme', 'string') }}')\n AND p.age >= {{ $fromAI('age_min', 'Âge minimum ex: 25', 'number') }}\n AND p.age <= {{ $fromAI('age_max', 'Âge maximum ex: 35', 'number') }}\nORDER BY p.created_at DESC\nLIMIT {{ $fromAI('search_limit', 'Nombre de résultats 1-10', 'number') }}",
"options": {}
},
"type": "n8n-nodes-base.postgresTool",
"typeVersion": 2.6,
"position": [
480,
2360
],
"id": "c602e2f2-6b45-4bf9-811b-4f43364b206b",
"name": "Tool: Search Profiles",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"model": "mistral-large-latest",
"options": {}
},
"type": "@n8n/n8n-nodes-langchain.lmChatMistralCloud",
"typeVersion": 1,
"position": [
224,
2360
],
"id": "39ecead0-9bd0-4a5d-8be4-63c667feaf06",
"name": "Mistral Cloud Chat Model Analyst 2",
"credentials": {
"mistralCloudApi": {
"id": "oTAUAlLG4h6S0uVq",
"name": "Mistral Cloud account"
}
}
},
{
"parameters": {
"operation": "executeQuery",
"query": "=SELECT \n l.id,\n l.phone,\n l.name,\n l.city,\n l.age,\n l.gender,\n l.status,\n l.looking_for_gender,\n l.preferred_age_min,\n l.preferred_age_max,\n l.preferred_city,\n l.qualification_complete,\n l.qualification_score,\n l.conversation_phase,\n l.message_count,\n l.last_profile_viewed,\n l.created_at,\n COUNT(DISTINCT pv.id) as profiles_viewed_count,\n COUNT(DISTINCT cr.id) as contact_requests_count\nFROM leads l\nLEFT JOIN profile_views pv ON l.id = pv.lead_id\nLEFT JOIN contact_requests cr ON l.id = cr.lead_id\nWHERE l.phone = '{{ $fromAI('lead_phone', 'Numéro de téléphone du lead au format +237XXXXXXXXX', 'string') }}'\nGROUP BY l.id",
"options": {}
},
"type": "n8n-nodes-base.postgresTool",
"typeVersion": 2.6,
"position": [
608,
2360
],
"id": "58e687b5-0bef-4239-8f08-c138afbfe43b",
"name": "Tool: Get Lead Info",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"operation": "executeQuery",
"query": "=SELECT \n p.id,\n p.code,\n p.name,\n p.age,\n p.gender,\n p.city,\n p.neighborhood,\n p.profession,\n p.education_level,\n p.marital_status,\n p.description_short,\n p.description_long,\n p.height,\n p.body_type,\n p.looking_for_gender,\n p.looking_for_age_min,\n p.looking_for_age_max,\n COUNT(DISTINCT pv.id) as view_count,\n COUNT(DISTINCT cr.id) as contact_request_count\nFROM profiles p\nLEFT JOIN profile_views pv ON p.id = pv.profile_id\nLEFT JOIN contact_requests cr ON p.id = cr.profile_id\nWHERE p.code = '{{ $fromAI('profile_code', 'Code du profil au format H001 ou F025', 'string') }}'\nGROUP BY p.id",
"options": {}
},
"type": "n8n-nodes-base.postgresTool",
"typeVersion": 2.6,
"position": [
736,
2360
],
"id": "e255da3b-7f89-4935-ab36-5419922ec3c7",
"name": "Tool: Get Profile By Code",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"operation": "executeQuery",
"query": "=SELECT \n c.id,\n c.direction,\n c.content,\n c.message_type,\n c.sender_type,\n c.intent,\n c.sentiment,\n c.profile_code,\n c.created_at,\n p.name as mentioned_profile_name\nFROM conversations c\nJOIN leads l ON c.lead_id = l.id\nLEFT JOIN profiles p ON c.profile_code = p.code\nWHERE l.phone = '{{ $fromAI('conv_phone', 'Numéro de téléphone du lead au format +237XXXXXXXXX', 'string') }}'\nORDER BY c.created_at DESC\nLIMIT {{ $fromAI('conv_limit', 'Nombre de messages à retourner ex: 10', 'number') }}",
"options": {}
},
"type": "n8n-nodes-base.postgresTool",
"typeVersion": 2.6,
"position": [
864,
2360
],
"id": "633f360d-6cf3-4ca3-b0c2-f9f9c9c23ba6",
"name": "Tool: Get Lead Conversations",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"operation": "executeQuery",
"query": "=SELECT \n pv.id,\n pv.viewed_at,\n p.code,\n p.name,\n p.age,\n p.gender,\n p.city,\n p.profession,\n p.description_short,\n EXISTS(\n SELECT 1 FROM contact_requests cr \n WHERE cr.lead_id = pv.lead_id AND cr.profile_id = p.id\n ) as already_requested\nFROM profile_views pv\nJOIN leads l ON pv.lead_id = l.id\nJOIN profiles p ON pv.profile_id = p.id\nWHERE l.phone = '{{ $fromAI('views_phone', 'Numéro de téléphone du lead au format +237XXXXXXXXX', 'string') }}'\nORDER BY pv.viewed_at DESC\nLIMIT {{ $fromAI('views_limit', 'Nombre de profils à retourner ex: 10', 'number') }}",
"options": {}
},
"type": "n8n-nodes-base.postgresTool",
"typeVersion": 2.6,
"position": [
992,
2360
],
"id": "5075c0cc-4562-4c21-85bc-4795260c2bf0",
"name": "Tool: Get Lead Profile Views",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"operation": "executeQuery",
"query": "=SELECT \n cr.id,\n cr.request_code,\n cr.status,\n cr.payment_status,\n cr.payment_amount,\n cr.created_at,\n cr.updated_at,\n cr.completed_at,\n p.code as profile_code,\n p.name as profile_name,\n p.age as profile_age,\n p.city as profile_city,\n au.full_name as assigned_admin\nFROM contact_requests cr\nJOIN leads l ON cr.lead_id = l.id\nJOIN profiles p ON cr.profile_id = p.id\nLEFT JOIN admin_users au ON cr.assigned_to = au.id\nWHERE l.phone = '{{ $fromAI('requests_phone', 'Numéro de téléphone du lead au format +237XXXXXXXXX', 'string') }}'\nORDER BY cr.created_at DESC\nLIMIT {{ $fromAI('requests_limit', 'Nombre de demandes à retourner ex: 10', 'number') }}",
"options": {}
},
"type": "n8n-nodes-base.postgresTool",
"typeVersion": 2.6,
"position": [
1120,
2360
],
"id": "d97b40f4-f900-4fdf-a9e6-879f0677c135",
"name": "Tool: Get Contact Requests",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"operation": "executeQuery",
"query": "=SELECT \n p.id,\n p.code,\n p.name,\n p.age,\n p.gender,\n p.city,\n p.neighborhood,\n p.profession,\n p.education_level,\n p.marital_status,\n p.description_short,\n p.height,\n p.body_type\nFROM profiles p\nWHERE p.status = 'published'\n AND LOWER(p.gender) = LOWER('{{ $fromAI('city_search_gender', 'Genre recherché: homme ou femme', 'string') }}')\n AND p.age >= {{ $fromAI('city_search_age_min', 'Âge minimum ex: 25', 'number') }}\n AND p.age <= {{ $fromAI('city_search_age_max', 'Âge maximum ex: 35', 'number') }}\n AND LOWER(p.city) LIKE LOWER('%' || '{{ $fromAI('city_search_name', 'Nom de la ville ex: Yaoundé', 'string') }}' || '%')\nORDER BY p.created_at DESC\nLIMIT {{ $fromAI('city_search_limit', 'Nombre de résultats entre 1 et 10', 'number') }}",
"options": {}
},
"type": "n8n-nodes-base.postgresTool",
"typeVersion": 2.6,
"position": [
1248,
2360
],
"id": "0eeb8a6f-806d-4d65-9be8-afa9ef0d45c8",
"name": "Tool: Search Profiles By City",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
},
{
"parameters": {
"toolDescription": "Agent de recherche base de données. Utilise-le pour:\n- Chercher des profils par critères (genre, âge, ville)\n- Obtenir les détails d'un profil par son code\n- Récupérer les infos d'un lead par son téléphone\n- Voir les profils consultés par un lead\n- Voir les demandes de contact d'un lead",
"text": "={{ $fromAI('db_query', 'Décris ta recherche. Ex: Cherche 5 femmes de 25-35 ans à Yaoundé OU Détails du profil F025 OU Infos du lead +237690000000', 'string') }}",
"options": {
"systemMessage": "Tu es un assistant base de données. Tu exécutes des requêtes SQL via les outils disponibles.\n\n# OUTILS DISPONIBLES\n\n## 1. Tool: Get Lead Info\nUsage: Récupérer toutes les infos d'un lead\nParamètre:\n- lead_phone (string): numéro au format +237XXXXXXXXX\n\n## 2. Tool: Get Profile By Code\nUsage: Récupérer les détails complets d'un profil\nParamètre:\n- profile_code (string): code au format H001 ou F025\n\n## 3. Tool: Get Lead Conversations\nUsage: Historique des messages d'un lead\nParamètres:\n- conv_phone (string): numéro au format +237XXXXXXXXX\n- conv_limit (number): nombre de messages ex: 10\n\n## 4. Tool: Get Lead Profile Views\nUsage: Profils consultés par un lead\nParamètres:\n- views_phone (string): numéro au format +237XXXXXXXXX\n- views_limit (number): nombre de profils ex: 10\n\n## 5. Tool: Get Contact Requests\nUsage: Demandes de contact d'un lead\nParamètres:\n- requests_phone (string): numéro au format +237XXXXXXXXX\n- requests_limit (number): nombre de demandes ex: 10\n\n## 6. Tool: Search Profiles (SANS ville)\nUsage: Chercher des profils dans TOUTES les villes\nParamètres:\n- search_gender (string): \"homme\" ou \"femme\"\n- search_age_min (number): âge minimum ex: 25\n- search_age_max (number): âge maximum ex: 35\n- search_limit (number): nombre de résultats ex: 5\n\n## 7. Tool: Search Profiles By City (AVEC ville)\nUsage: Chercher des profils dans UNE ville spécifique\nParamètres:\n- city_search_gender (string): \"homme\" ou \"femme\"\n- city_search_age_min (number): âge minimum ex: 25\n- city_search_age_max (number): âge maximum ex: 35\n- city_search_name (string): nom de la ville ex: \"Yaoundé\"\n- city_search_limit (number): nombre de résultats ex: 5\n\n# PROCÉDURE\n\n1. Analyse la demande\n2. Choisis l'outil approprié\n3. Appelle l'outil avec les paramètres corrects\n4. Formate les résultats\n5. Écris FIN et arrête-toi\n\n# EXEMPLES\n\nDemande: \"Cherche 5 femmes de 25-35 ans à Yaoundé\"\n→ Appelle: Search Profiles By City\n city_search_gender=\"femme\"\n city_search_age_min=25\n city_search_age_max=35\n city_search_name=\"Yaoundé\"\n city_search_limit=5\n\nDemande: \"Cherche des hommes de 30-40 ans\"\n→ Appelle: Search Profiles\n search_gender=\"homme\"\n search_age_min=30\n search_age_max=40\n search_limit=5\n\nDemande: \"Détails du profil F025\"\n→ Appelle: Get Profile By Code\n profile_code=\"F025\"\n\nDemande: \"Infos du lead +237690000000\"\n→ Appelle: Get Lead Info\n lead_phone=\"+237690000000\"\n\nDemande: \"Profils vus par +237690000000\"\n→ Appelle: Get Lead Profile Views\n views_phone=\"+237690000000\"\n views_limit=10\n\n# FORMAT RÉPONSE\n\nRÉSULTAT: [N] trouvé(s)\n[Données formatées]\nFIN\n\nIMPORTANT: Toujours terminer par FIN."
}
},
"type": "@n8n/n8n-nodes-langchain.agentTool",
"typeVersion": 3,
"position": [
656,
2152
],
"id": "6d824367-de97-4c61-abc8-c4690d48cad6",
"name": "AI Agent DB Specialist"
},
{
"parameters": {
"sessionIdType": "customKey",
"sessionKey": "=maya_session*{{ $('14 - Analyze').first().json.lead_id }}",
"tableName": "n8n_chat_analyst",
"contextWindowLength": 12
},
"type": "@n8n/n8n-nodes-langchain.memoryPostgresChat",
"typeVersion": 1.3,
"position": [
352,
2360
],
"id": "78ee4077-e455-4e6a-9630-4e5fa1a42c95",
"name": "Memory DB Specialist",
"credentials": {
"postgres": {
"id": "Gv2oFLeW3VbnJ0xx",
"name": "Postgres account"
}
}
}
],
"connections": {
"1 - Webhook WhatsApp": {
"main": [
[
{
"node": "2 - Extract Data",
"type": "main",
"index": 0
}
]
]
},
"2 - Extract Data": {
"main": [
[
{
"node": "3 - Message valide?",
"type": "main",
"index": 0
}
]
]
},
"3 - Message valide?": {
"main": [
[
{
"node": "4 - Get Admin Phone",
"type": "main",
"index": 0
}
],
[
{
"node": "Ignoré (invalide)",
"type": "main",
"index": 0
}
]
]
},
"4 - Get Admin Phone": {
"main": [
[
{
"node": "5 - Pas Admin?",
"type": "main",
"index": 0
}
]
]
},
"5 - Pas Admin?": {
"main": [
[
{
"node": "6 - Get Lead",
"type": "main",
"index": 0
}
],
[
{
"node": "Admin Ignoré",
"type": "main",
"index": 0
}
]
]
},
"6 - Get Lead": {
"main": [
[
{
"node": "7 - Lead existe?",
"type": "main",
"index": 0
}
]
]
},
"7 - Lead existe?": {
"main": [
[
{
"node": "Aggregate1",
"type": "main",
"index": 0
}
],
[
{
"node": "8 - Créer Lead1",
"type": "main",
"index": 0
}
]
]
},
"9 - Préparer Contexte": {
"main": [
[
{
"node": "10 - Log IN",
"type": "main",
"index": 0
}
]
]
},
"10 - Log IN": {
"main": [
[
{
"node": "11 - Conv Status",
"type": "main",
"index": 0
}
]
]
},
"11 - Conv Status": {
"main": [
[
{
"node": "12 - Bot actif?",
"type": "main",
"index": 0
}
]
]
},
"12 - Bot actif?": {
"main": [
[
{
"node": "13 - Get History",
"type": "main",
"index": 0
}
],
[
{
"node": "Attente Humain",
"type": "main",
"index": 0
}
]
]
},
"13 - Get History": {
"main": [
[
{
"node": "14 - Analyze",
"type": "main",
"index": 0
}
]
]
},
"14 - Analyze": {
"main": [
[
{
"node": "15 - Update Qual",
"type": "main",
"index": 0
}
]
]
},
"15 - Update Qual": {
"main": [
[
{
"node": "16 - Pre-Escalation Check",
"type": "main",
"index": 0
}
]
]
},
"16 - Pre-Escalation Check": {
"main": [
[
{
"node": "17 - Skip Agent?",
"type": "main",
"index": 0
}
]
]
},
"17 - Skip Agent?": {
"main": [
[
{
"node": "Aggregate",
"type": "main",
"index": 0
}
],
[
{
"node": "18 - Agent MAYA",
"type": "main",
"index": 0
}
]
]
},
"20 - Process Final": {
"main": [
[
{
"node": "21 - Log OUT",
"type": "main",
"index": 0
}
]
]
},
"21 - Log OUT": {
"main": [
[
{
"node": "22 - Escalation?",
"type": "main",
"index": 0
}
]
]
},
"22 - Escalation?": {
"main": [
[
{
"node": "23 - Notify Admin",
"type": "main",
"index": 0
}
],
[
{
"node": "25 - Send WhatsApp",
"type": "main",
"index": 0
}
]
]
},
"23 - Notify Admin": {
"main": [
[
{
"node": "24 - Update Status",
"type": "main",
"index": 0
}
]
]
},
"24 - Update Status": {
"main": [
[
{
"node": "25 - Send WhatsApp",
"type": "main",
"index": 0
}
]
]
},
"25 - Send WhatsApp": {
"main": [
[
{
"node": "26 - Update Lead",
"type": "main",
"index": 0
}
]
]
},
"26 - Update Lead": {
"main": [
[
{
"node": "✅ FIN",
"type": "main",
"index": 0
}
]
]
},
"8 - Créer Lead1": {
"main": [
[
{
"node": "Aggregate1",
"type": "main",
"index": 0
}
]
]
},
"Aggregate": {
"main": [
[
{
"node": "20 - Process Final",
"type": "main",
"index": 0
}
]
]
},
"Aggregate1": {
"main": [
[
{
"node": "9 - Préparer Contexte",
"type": "main",
"index": 0
}
]
]
},
"18 - Agent MAYA": {
"main": [
[
{
"node": "Aggregate",
"type": "main",
"index": 0
}
]
]
},
"Memory Maya": {
"ai_memory": [
[
{
"node": "18 - Agent MAYA",
"type": "ai_memory",
"index": 0
}
]
]
},
"Mistral Cloud Chat Model": {
"ai_languageModel": [
[
{
"node": "18 - Agent MAYA",
"type": "ai_languageModel",
"index": 0
}
]
]
},
"Tool: Search Profiles": {
"ai_tool": [
[
{
"node": "AI Agent DB Specialist",
"type": "ai_tool",
"index": 0
}
]
]
},
"Mistral Cloud Chat Model Analyst 2": {
"ai_languageModel": [
[
{
"node": "AI Agent DB Specialist",
"type": "ai_languageModel",
"index": 0
}
]
]
},
"Tool: Get Lead Info": {
"ai_tool": [
[
{
"node": "AI Agent DB Specialist",
"type": "ai_tool",
"index": 0
}
]
]
},
"Tool: Get Profile By Code": {
"ai_tool": [
[
{
"node": "AI Agent DB Specialist",
"type": "ai_tool",
"index": 0
}
]
]
},
"Tool: Get Lead Conversations": {
"ai_tool": [
[
{
"node": "AI Agent DB Specialist",
"type": "ai_tool",
"index": 0
}
]
]
},
"Tool: Get Lead Profile Views": {
"ai_tool": [
[
{
"node": "AI Agent DB Specialist",
"type": "ai_tool",
"index": 0
}
]
]
},
"Tool: Get Contact Requests": {
"ai_tool": [
[
{
"node": "AI Agent DB Specialist",
"type": "ai_tool",
"index": 0
}
]
]
},
"Tool: Search Profiles By City": {
"ai_tool": [
[
{
"node": "AI Agent DB Specialist",
"type": "ai_tool",
"index": 0
}
]
]
},
"AI Agent DB Specialist": {
"ai_tool": [
[
{
"node": "18 - Agent MAYA",
"type": "ai_tool",
"index": 0
}
]
]
},
"Memory DB Specialist": {
"ai_memory": [
[
{
"node": "AI Agent DB Specialist",
"type": "ai_memory",
"index": 0
}
]
]
}
},
"pinData": {},
"meta": {
"templateCredsSetupCompleted": true,
"instanceId": "52f86ab16199129cc9f17f47caf79594a565b44b7f742ae7b5f8b1862d8953cd"
}
}

Voici mes avis par rapport a ce worflow
Il sagit dune agence matrimoniale pour relier deux personne
Le souci ici cest que mon agent est trop stricte il napplique pas les techniques de marketing moi jaimerais donc ajouter un nouvel agent tool qui aura access a une base de connaissance en psychologie et a lhistorique de outes la conversation afin de pouvoir expliquer coment persuader le client jai 12 livres pdf de marketing en ma possession deja

Et aussi il faudrais pousser le client a explorer et non que lageent lui dise que desole il y a pas ce profiel dans notre base de donnees sa fait fuire le client alors que je penses que si on a une sorte de boucle ou lagent discute avec lui meme et un noeuds shloudl i reply to user or reply to specific agent
Excellente analyse ! Vous avez identifié deux problèmes majeurs :

1. **Agent trop rigide** → manque de techniques de persuasion/marketing
2. **Réponses négatives brutales** → "désolé, pas de profil" fait fuir les clients

Je vais vous proposer une architecture améliorée avec un système multi-agents.

---

## 🏗️ Architecture Proposée : Système Multi-Agents

```
┌─────────────────────────────────────────────────────────────────────┐
│                         MAYA (Agent Principal)                       │
│                    Chef d'orchestre conversationnel                  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
            ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
            │ DB Specialist │ │  Persuasion  │ │   Router     │
            │   (existant)  │ │    Coach     │ │  (nouveau)   │
            │               │ │  (nouveau)   │ │              │
            └──────────────┘ └──────────────┘ └──────────────┘
                    │               │               │
                    │        ┌──────┴──────┐        │
                    │        ▼             ▼        │
                    │   [RAG: 12 PDFs] [Historique] │
                    │                               │
                    └───────────────────────────────┘
```

---

## 📚 Étape 1 : Créer la Base de Connaissances RAG (12 PDFs)

### 1.1 Nouveau Workflow : Indexation des PDFs

```json
{
  "nodes": [
    {
      "parameters": {
        "path": "index-marketing-pdfs",
        "httpMethod": "POST",
        "options": {}
      },
      "type": "n8n-nodes-base.webhook",
      "name": "Trigger Indexation",
      "position": [0, 0]
    },
    {
      "parameters": {
        "operation": "list",
        "folderPath": "/marketing-books/"
      },
      "type": "n8n-nodes-base.googleDrive",
      "name": "List PDFs",
      "position": [220, 0]
    },
    {
      "parameters": {
        "operation": "download"
      },
      "type": "n8n-nodes-base.googleDrive",
      "name": "Download PDF",
      "position": [440, 0]
    },
    {
      "parameters": {
        "operation": "extractFromPdf"
      },
      "type": "n8n-nodes-base.extractFromFile",
      "name": "Extract Text",
      "position": [660, 0]
    },
    {
      "parameters": {
        "chunkSize": 1000,
        "chunkOverlap": 200
      },
      "type": "@n8n/n8n-nodes-langchain.textSplitterRecursiveCharacterTextSplitter",
      "name": "Text Splitter",
      "position": [880, 0]
    },
    {
      "parameters": {
        "tableName": "marketing_knowledge",
        "options": {}
      },
      "type": "@n8n/n8n-nodes-langchain.vectorStoreSupabase",
      "name": "Store in Supabase",
      "position": [1100, 0]
    }
  ]
}
```

### 1.2 Configuration Postgres/Supabase pour le Vector Store

```sql
-- Extension pour les vecteurs
CREATE EXTENSION IF NOT EXISTS vector;

-- Table pour stocker les connaissances marketing
CREATE TABLE marketing_knowledge (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    embedding vector(1536), -- ou 768 selon votre modèle
    source_file VARCHAR(255),
    chunk_index INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Index pour recherche rapide
CREATE INDEX ON marketing_knowledge
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Table pour l'historique complet des conversations (pour analyse)
CREATE TABLE conversation_analysis (
    id SERIAL PRIMARY KEY,
    lead_id INTEGER REFERENCES leads(id),
    full_conversation TEXT,
    client_personality_traits JSONB,
    recommended_strategies JSONB,
    analyzed_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🧠 Étape 2 : Agent Persuasion Coach (Nouveau)

### 2.1 Nœud Agent Tool - Persuasion Coach

Ajoutez ce nœud comme tool pour Maya :

```json
{
  "parameters": {
    "toolDescription": "Coach en persuasion et psychologie client. Utilise-le quand:\n- Le client hésite ou montre des objections\n- Tu dois reformuler une réponse négative positivement\n- Tu veux des techniques pour engager le client\n- Tu cherches comment relancer un client passif",
    "text": "={{ $fromAI('persuasion_query', 'Décris la situation: profil client, objection/blocage, historique récent. Ex: Client hésite sur le prix, déjà vu 3 profils, semble intéressé mais passif', 'string') }}",
    "options": {
      "systemMessage": "Tu es un expert en psychologie de la vente et persuasion éthique pour une agence matrimoniale.\n\n# TON RÔLE\nAnalyser la situation client et fournir des stratégies de communication adaptées.\n\n# TU AS ACCÈS À\n1. Base de connaissances marketing (12 livres de référence)\n2. Historique complet des conversations du client\n3. Profil psychologique déduit du client\n\n# PRINCIPES FONDAMENTAUX\n- Persuasion ÉTHIQUE uniquement (pas de manipulation)\n- Focus sur la VALEUR pour le client\n- Créer de l'ENGAGEMENT émotionnel\n- Transformer les objections en OPPORTUNITÉS\n\n# FORMAT DE RÉPONSE\n\n## ANALYSE RAPIDE\n[2 lignes max sur le profil psychologique du client]\n\n## STRATÉGIE RECOMMANDÉE\n[Technique spécifique à utiliser]\n\n## PHRASE CLÉ À UTILISER\n\"[Phrase exacte que Maya peut dire]\"\n\n## ALTERNATIVE SI ÉCHEC\n[Plan B]\n\n# TECHNIQUES DISPONIBLES\n\n1. **Rareté positive** : \"Ce profil reçoit beaucoup d'intérêt...\"\n2. **Projection future** : \"Imaginez votre premier rendez-vous...\"\n3. **Validation émotionnelle** : \"Je comprends votre prudence, c'est important...\"\n4. **Pivot élégant** : Transformer \"pas de profil\" en \"opportunité d'affiner\"\n5. **Engagement progressif** : Petits oui avant le grand oui\n6. **Preuve sociale** : \"Beaucoup de nos clients dans votre situation...\"\n7. **Réciprocité** : Donner avant de demander\n8. **Cadrage positif** : Reformuler le négatif en positif\n\n# EXEMPLES\n\nSituation: Client dit \"pas de femme de 25-30 ans à Kribi\"\n❌ Mauvais: \"Désolé, nous n'avons pas ce profil\"\n✅ Bon: \"Kribi est une ville romantique ! J'ai quelques profils dans les villes proches. Et entre nous, certaines de nos plus belles rencontres sont nées quand les critères ont légèrement évolué... Seriez-vous ouvert à découvrir Douala ? C'est à 2h et j'ai 3 profils magnifiques.\"\n\nIMPORTANT: Toujours terminer par une ACTION concrète pour le client."
    }
  },
  "type": "@n8n/n8n-nodes-langchain.agentTool",
  "name": "Persuasion Coach"
}
```

### 2.2 Sub-Nodes pour le Persuasion Coach

```json
{
  "nodes": [
    {
      "parameters": {
        "operation": "retrieve",
        "tableName": "marketing_knowledge",
        "topK": 5
      },
      "type": "@n8n/n8n-nodes-langchain.vectorStoreRetriever",
      "name": "RAG Marketing Books"
    },
    {
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT c.content, c.direction, c.created_at, c.sentiment FROM conversations c WHERE c.lead_id = {{ $fromAI('lead_id_for_history', 'ID du lead', 'number') }} ORDER BY c.created_at ASC"
      },
      "type": "n8n-nodes-base.postgresTool",
      "name": "Tool: Full Conversation History"
    },
    {
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT client_personality_traits, recommended_strategies FROM conversation_analysis WHERE lead_id = {{ $fromAI('lead_id_analysis', 'ID du lead', 'number') }} ORDER BY analyzed_at DESC LIMIT 1"
      },
      "type": "n8n-nodes-base.postgresTool",
      "name": "Tool: Client Psychology Profile"
    }
  ]
}
```

---

## 🔄 Étape 3 : Router Intelligent (Should I Reply?)

### 3.1 Nouveau Nœud Code : Internal Dialogue Router

Ce nœud remplace la logique linéaire par une boucle de réflexion :

```javascript
// ============================================================================
// INTERNAL DIALOGUE ROUTER - Décision de routage intelligent
// ============================================================================

const context = $("16 - Pre-Escalation Check").first().json;
const msg = (context.user_message || "").toLowerCase();
const dbResult = $input.first().json; // Résultat du DB Specialist

// ============================================================================
// 1. ANALYSE DU RÉSULTAT DB
// ============================================================================

const hasResults = !!(
  (dbResult.profiles && dbResult.profiles.length > 0) ||
  (dbResult.data && dbResult.data.length > 0) ||
  (typeof dbResult === "string" &&
    !dbResult.includes("aucun") &&
    !dbResult.includes("0 trouvé"))
);

const isNegativeResult =
  !hasResults ||
  /aucun|pas de|0 trouvé|vide|introuvable/i.test(JSON.stringify(dbResult));

// ============================================================================
// 2. DÉTECTION DES SIGNAUX CLIENT
// ============================================================================

const clientSignals = {
  // Objections
  hesitation: /(peut-être|je sais pas|hm+|euh|bof|pas sûr)/i.test(msg),
  priceObjection: /(cher|coût|prix|budget|argent|payer)/i.test(msg),
  trustIssue: /(arnaque|confiance|vrai|sérieux|fiable)/i.test(msg),

  // Engagement positif
  interest: /(intéress|ce profil|plus de détail|photo|voir)/i.test(msg),
  excitement: /(super|génial|parfait|exactement|waou)/i.test(msg),

  // Désengagement
  passive: msg.length < 10 && !/intéress|oui|ok/.test(msg),
  wantToLeave: /(au revoir|stop|arrêt|plus tard|réfléchir)/i.test(msg),
};

// ============================================================================
// 3. DÉCISION DE ROUTAGE
// ============================================================================

let routingDecision = {
  nextAgent: "direct_response", // Par défaut: répondre directement
  reason: "",
  internalThought: "",
  shouldConsultPersuasion: false,
  shouldReformulate: false,
};

// CAS 1: Résultat négatif de la DB → Consulter Persuasion Coach
if (isNegativeResult) {
  routingDecision = {
    nextAgent: "persuasion_coach",
    reason: "negative_db_result",
    internalThought: `La recherche n'a rien donné. Je dois reformuler positivement et proposer des alternatives.`,
    shouldConsultPersuasion: true,
    shouldReformulate: true,
    reformulationContext: {
      originalQuery: context.user_message,
      whatWasMissing: dbResult,
      clientCriteria: {
        gender: context.looking_for_gender,
        ageRange: `${context.preferred_age_min}-${context.preferred_age_max}`,
        city: context.preferred_city,
      },
    },
  };
}

// CAS 2: Client hésite ou objection → Consulter Persuasion Coach
else if (
  clientSignals.hesitation ||
  clientSignals.priceObjection ||
  clientSignals.trustIssue
) {
  routingDecision = {
    nextAgent: "persuasion_coach",
    reason: "client_objection",
    internalThought: `Le client montre des signes d'hésitation. Je dois le rassurer et l'engager.`,
    shouldConsultPersuasion: true,
    objectionType: clientSignals.priceObjection
      ? "price"
      : clientSignals.trustIssue
        ? "trust"
        : "general_hesitation",
  };
}

// CAS 3: Client passif → Stratégie de réengagement
else if (clientSignals.passive && !context.is_first_message) {
  routingDecision = {
    nextAgent: "persuasion_coach",
    reason: "passive_client",
    internalThought: `Le client est passif. Je dois créer de l'engagement avec une question ouverte ou une proposition attractive.`,
    shouldConsultPersuasion: true,
    engagementStrategy: "reactivation",
  };
}

// CAS 4: Client veut partir → Dernière chance
else if (clientSignals.wantToLeave) {
  routingDecision = {
    nextAgent: "persuasion_coach",
    reason: "exit_intent",
    internalThought: `Le client veut partir. Dernière tentative de rétention douce.`,
    shouldConsultPersuasion: true,
    retentionMode: true,
  };
}

// CAS 5: Client engagé positivement → Réponse directe optimisée
else if (clientSignals.interest || clientSignals.excitement) {
  routingDecision = {
    nextAgent: "direct_response",
    reason: "positive_engagement",
    internalThought: `Le client est engagé positivement. Je continue sur cette lancée.`,
    shouldConsultPersuasion: false,
    amplifyPositive: true,
  };
}

// ============================================================================
// 4. ENRICHISSEMENT DU CONTEXTE
// ============================================================================

return [
  {
    json: {
      ...context,
      routing: routingDecision,
      dbResult: dbResult,
      clientSignals: clientSignals,
      conversationMomentum: clientSignals.excitement
        ? "high"
        : clientSignals.passive
          ? "low"
          : "medium",
    },
  },
];
```

### 3.2 Nœud Switch : Router les Agents

```json
{
  "parameters": {
    "rules": {
      "rules": [
        {
          "conditions": {
            "conditions": [
              {
                "leftValue": "={{ $json.routing.nextAgent }}",
                "rightValue": "persuasion_coach",
                "operator": {
                  "type": "string",
                  "operation": "equals"
                }
              }
            ]
          },
          "renameOutput": "Persuasion Coach"
        },
        {
          "conditions": {
            "conditions": [
              {
                "leftValue": "={{ $json.routing.nextAgent }}",
                "rightValue": "direct_response",
                "operator": {
                  "type": "string",
                  "operation": "equals"
                }
              }
            ]
          },
          "renameOutput": "Direct Response"
        }
      ]
    }
  },
  "type": "n8n-nodes-base.switch",
  "name": "Route to Agent"
}
```

---

## 🔄 Étape 4 : Boucle de Réflexion Interne

### 4.1 Workflow de Réflexion (Self-Loop)

```javascript
// ============================================================================
// MAYA INTERNAL LOOP - Réflexion avant réponse
// ============================================================================

const MAX_ITERATIONS = 3;
const currentIteration = $json.iteration || 0;
const context = $json;

// ============================================================================
// 1. ÉVALUATION DE LA QUALITÉ DE RÉPONSE
// ============================================================================

const proposedResponse = $json.draft_response || "";

const qualityChecks = {
  // Est-ce que la réponse est positive/engageante ?
  isPositive: !/désolé|malheureusement|pas de|aucun|impossible/i.test(
    proposedResponse,
  ),

  // Est-ce qu'elle contient une action pour le client ?
  hasCallToAction: /\?|souhaitez|voulez|aimeriez|proposer|découvrir/i.test(
    proposedResponse,
  ),

  // Est-ce qu'elle est assez personnalisée ?
  isPersonalized:
    proposedResponse.includes(context.lead_name) ||
    proposedResponse.includes(context.preferred_city || ""),

  // Est-ce qu'elle ouvre des possibilités ?
  opensOptions: /alternative|aussi|également|autre|possibilité/i.test(
    proposedResponse,
  ),

  // Longueur appropriée (pas trop court, pas trop long)
  appropriateLength:
    proposedResponse.length > 50 && proposedResponse.length < 500,
};

const qualityScore = Object.values(qualityChecks).filter(Boolean).length;
const isQualityAcceptable = qualityScore >= 3;

// ============================================================================
// 2. DÉCISION : CONTINUER LA BOUCLE OU ENVOYER
// ============================================================================

if (isQualityAcceptable || currentIteration >= MAX_ITERATIONS) {
  // Sortir de la boucle
  return [
    {
      json: {
        ...context,
        final_response: proposedResponse,
        quality_score: qualityScore,
        iterations_used: currentIteration,
        quality_checks: qualityChecks,
        loop_complete: true,
      },
    },
  ];
}

// Continuer la boucle avec des instructions d'amélioration
const improvementInstructions = [];

if (!qualityChecks.isPositive) {
  improvementInstructions.push(
    "Reformule de manière plus positive, sans mots négatifs",
  );
}
if (!qualityChecks.hasCallToAction) {
  improvementInstructions.push(
    "Ajoute une question ou proposition pour engager le client",
  );
}
if (!qualityChecks.isPersonalized) {
  improvementInstructions.push(
    "Personnalise davantage avec le nom ou les critères du client",
  );
}
if (!qualityChecks.opensOptions) {
  improvementInstructions.push(
    "Propose des alternatives ou élargis les possibilités",
  );
}

return [
  {
    json: {
      ...context,
      iteration: currentIteration + 1,
      improvement_needed: improvementInstructions,
      previous_draft: proposedResponse,
      loop_complete: false,
    },
  },
];
```

---

## 📝 Étape 5 : Mise à jour du System Prompt de Maya

Remplacez le system prompt actuel par celui-ci :

```
Tu es Maya, assistante virtuelle experte de l'Agence Matrimoniale Cameroun.

# 🎯 TA MISSION
Accompagner chaque client vers sa rencontre idéale avec empathie, professionnalisme et une touche de magie.

# 🧠 TES COMPÉTENCES UNIQUES
1. **Écoute empathique** : Tu comprends les désirs profonds derrière les mots
2. **Positivité contagieuse** : Tu transformes chaque obstacle en opportunité
3. **Créativité relationnelle** : Tu trouves toujours une solution

# 🤝 TON ÉQUIPE D'ASSISTANTS
Tu diriges une équipe de spécialistes :

1. **DB Specialist** → Recherche en base de données
2. **Persuasion Coach** → Stratégies d'engagement et reformulation positive

# 🔄 TON PROCESSUS DE RÉFLEXION

Avant chaque réponse, tu te poses ces questions :
1. "Est-ce que ma réponse est POSITIVE ?" (jamais de "désolé, pas de profil")
2. "Est-ce que j'ENGAGE le client vers l'action suivante ?"
3. "Est-ce que je crée de l'ÉMOTION positive ?"
4. "Est-ce que j'OUVRE des possibilités plutôt que fermer des portes ?"

# ⚡ RÈGLE D'OR : JAMAIS DE RÉPONSE NÉGATIVE BRUTE

❌ INTERDIT : "Désolé, nous n'avons pas de profil correspondant"
✅ OBLIGATOIRE : Transformer en opportunité

## Exemple de transformation :

Situation : Pas de femme de 25-30 ans à Kribi

❌ "Je suis désolée, nous n'avons actuellement pas de profils de femmes de 25-30 ans à Kribi dans notre base."

✅ "Kribi, quelle belle ville romantique ! 🌊 J'ai une idée : nos profils les plus demandés viennent de Douala et Yaoundé, à quelques heures. Certaines seraient ravies de découvrir Kribi avec le bon partenaire... Voulez-vous que je vous présente 3 profils exceptionnels qui pourraient vous surprendre ?"

# 📊 STRATÉGIES DE PERSUASION ÉTHIQUE

1. **Pivot géographique** : Élargir la zone avec enthousiasme
2. **Pivot d'âge** : "+/- 5 ans peut révéler des trésors cachés"
3. **Projection émotionnelle** : "Imaginez votre première rencontre..."
4. **Preuve sociale** : "Nos couples les plus heureux..."
5. **Rareté positive** : "Ces profils reçoivent beaucoup d'attention..."
6. **Curiosité** : "J'ai un profil qui pourrait vous intriguer..."

# 💬 STRUCTURE DE TES RÉPONSES

1. **Validation** (1 phrase) : Reconnais le client
2. **Pivot positif** (1-2 phrases) : Transforme ou enrichis
3. **Proposition concrète** (1-2 phrases) : Action claire
4. **Question engageante** (1 phrase) : Maintiens le dialogue

# 🚫 MOTS INTERDITS
- "Désolé/Malheureusement"
- "Pas de profil/Aucun résultat"
- "Impossible/Nous ne pouvons pas"
- "Il faudra attendre"

# ✅ MOTS MAGIQUES
- "J'ai une idée..."
- "Et si je vous proposais..."
- "Vous allez adorer..."
- "J'ai exactement ce qu'il vous faut..."
- "Laissez-moi vous surprendre..."

# 🎭 EXEMPLE DE DIALOGUE PARFAIT

Client : "Je cherche une femme de 28-32 ans à Bafoussam"

[Tu consultes DB Specialist → 0 résultat]
[Tu consultes Persuasion Coach → Stratégie pivot]

Maya : "Bafoussam, le cœur de l'Ouest ! 💚 J'adore votre choix. Nos profils de cette région sont souvent des femmes avec des valeurs familiales fortes. J'ai 3 profils magnifiques : deux à Bafoussam même (34 et 35 ans, des perles !) et une à Douala originaire de l'Ouest (30 ans). La différence de 2-3 ans a souvent créé nos plus beaux couples... Laquelle vous intrigue le plus ?"

# 🔁 QUAND CONSULTER TES ASSISTANTS

→ **DB Specialist** : Pour toute recherche de données
→ **Persuasion Coach** : TOUJOURS après un résultat négatif ou une hésitation client

RAPPEL FINAL : Tu ne dis JAMAIS "pas de profil". Tu trouves TOUJOURS une alternative enthousiaste.
```

---

## 🔌 Étape 6 : Intégration dans le Workflow Existant

### 6.1 Modifications à apporter

Remplacez le nœud `17 - Skip Agent?` → `18 - Agent MAYA` par cette nouvelle structure :

```
[16 - Pre-Escalation]
        │
        ▼
[17 - Skip Agent?] ──── OUI ──→ [Aggregate] → [20 - Process Final]
        │
       NON
        │
        ▼
[18 - Agent MAYA] ←──────────────────────────┐
        │                                     │
        ▼                                     │
[19 - Internal Router] ──→ [Persuasion Coach]┘
        │
        ▼
[19b - Quality Check Loop]
        │
        ▼ (si quality OK)
[Aggregate] → [20 - Process Final]
```

### 6.2 Connexions des nouveaux nœuds

```json
{
  "connections": {
    "18 - Agent MAYA": {
      "main": [
        [
          {
            "node": "19 - Internal Router",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "19 - Internal Router": {
      "main": [
        [
          {
            "node": "Persuasion Coach",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "19b - Quality Check",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Persuasion Coach": {
      "main": [
        [
          {
            "node": "18 - Agent MAYA",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "19b - Quality Check": {
      "main": [
        [
          {
            "node": "18 - Agent MAYA",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Aggregate",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

---

## 📊 Étape 7 : Monitoring et Amélioration Continue

### 7.1 Table pour tracker les performances

```sql
CREATE TABLE persuasion_analytics (
    id SERIAL PRIMARY KEY,
    lead_id INTEGER REFERENCES leads(id),
    conversation_id INTEGER REFERENCES conversations(id),

    -- Contexte
    original_request TEXT,
    db_result_empty BOOLEAN,

    -- Stratégie utilisée
    persuasion_strategy VARCHAR(50),
    pivot_type VARCHAR(50), -- 'geographic', 'age', 'criteria'

    -- Résultat
    client_response_sentiment VARCHAR(20), -- 'positive', 'neutral', 'negative'
    led_to_profile_view BOOLEAN,
    led_to_contact_request BOOLEAN,

    -- Métriques
    response_time_ms INTEGER,
    iterations_used INTEGER,
    quality_score INTEGER,

    created_at TIMESTAMP DEFAULT NOW()
);

-- Vue pour analyser l'efficacité
CREATE VIEW persuasion_effectiveness AS
SELECT
    persuasion_strategy,
    COUNT(*) as total_uses,
    AVG(CASE WHEN led_to_profile_view THEN 1 ELSE 0 END) * 100 as view_rate,
    AVG(CASE WHEN led_to_contact_request THEN 1 ELSE 0 END) * 100 as conversion_rate,
    AVG(quality_score) as avg_quality
FROM persuasion_analytics
GROUP BY persuasion_strategy
ORDER BY conversion_rate DESC;
```

---

## 🚀 Résumé des Fichiers à Créer/Modifier

| Fichier/Nœud                | Action   | Description                       |
| --------------------------- | -------- | --------------------------------- |
| `index-marketing-pdfs.json` | CRÉER    | Workflow d'indexation des 12 PDFs |
| `marketing_knowledge`       | CRÉER    | Table PostgreSQL + embeddings     |
| `Persuasion Coach`          | AJOUTER  | Nouveau Agent Tool                |
| `19 - Internal Router`      | AJOUTER  | Nœud Code de routage              |
| `19b - Quality Check`       | AJOUTER  | Nœud Code boucle qualité          |
| `18 - Agent MAYA`           | MODIFIER | Nouveau system prompt             |
| Connexions                  | MODIFIER | Nouvelle architecture             |

---

## ✅ Checklist d'Implémentation

1. [ ] Indexer les 12 PDFs dans le vector store
2. [ ] Créer les nouvelles tables SQL
3. [ ] Ajouter le Persuasion Coach comme Agent Tool
4. [ ] Implémenter le Router interne
5. [ ] Implémenter la boucle de qualité
6. [ ] Mettre à jour le system prompt de Maya
7. [ ] Reconnecter les nœuds
8. [ ] Tester avec des scénarios de "résultat vide"
9. [ ] Monitorer les métriques de conversion
       |
       JE VEUX UNIQUEMENT LES CODE DES WORFLOW COMPLETS
