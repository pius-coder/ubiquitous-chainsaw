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

