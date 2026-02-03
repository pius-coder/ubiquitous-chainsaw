-- =====================================================
-- AJOUT DE CONNAISSANCES SUPPLÉMENTAIRES
-- Agence Matrimoniale Cameroun (AMC)
-- =====================================================

INSERT INTO knowledge_base (title, content, category, tags, is_active) VALUES
(
    'Conseils pour une première rencontre réussie',
    'Pour votre premier rendez-vous : 1) Choisissez un lieu public et neutre (café, restaurant). 2) Soyez ponctuel et soignez votre présentation. 3) Restez vous-même et soyez honnête sur vos attentes. 4) Écoutez autant que vous parlez. 5) Évitez les sujets trop sensibles (ex-partenaires, finances personnelles) lors du premier contact. L''objectif est de découvrir si une étincelle est possible.',
    'conseils',
    ARRAY['conseils', 'rencontre', 'rendez-vous', 'succès'],
    TRUE
),
(
    'Vérification des profils et documents requis',
    'Pour garantir la sécurité et la sincérité de notre base de données, chaque membre doit fournir : 1) Une copie d''une pièce d''identité valide (CNI ou Passeport). 2) Un justificatif de domicile ou de situation professionnelle. 3) Des photos récentes sans filtres excessifs. Ces documents restent strictement confidentiels et servent uniquement à la validation par nos conseillers.',
    'securite',
    ARRAY['documents', 'vérification', 'cni', 'validation', 'inscription'],
    TRUE
),
(
    'Engagement éthique de l''agence',
    'L''AMC s''engage à : 1) Lutter contre les faux profils et les arnaques. 2) Promouvoir le respect mutuel entre les membres. 3) Ne jamais divulguer de données de contact sans consentement explicite et validation de la demande. 4) Accompagner humainement chaque membre dans sa quête. Nous privilégions la qualité à la quantité.',
    'ethique',
    ARRAY['engagement', 'valeurs', 'respect', 'sérieux'],
    TRUE
),
(
    'Processus après la mise en relation',
    'Une fois la mise en relation validée : 1) Vous recevez le contact WhatsApp/Téléphone du profil. 2) Nous vous conseillons de passer un premier appel vocal avant de vous rencontrer. 3) Un conseiller peut assurer un suivi pour savoir comment s''est passé le premier échange. Si la rencontre ne daboutit pas, nous analysons ensemble vos critères pour affiner les prochaines suggestions.',
    'fonctionnement',
    ARRAY['après', 'contact', 'suivi', 'processus'],
    TRUE
),
(
    'Événements et Rencontres de groupe',
    'En plus des mises en relation individuelles, l''AMC organise trimestriellement des soirées \"Speed Dating\" et des dîners de gala à Douala et Yaoundé. Ces événements sont réservés aux membres validés et permettent de rencontrer plusieurs profils dans un cadre sécurisé et convivial. Les invitations sont envoyées via WhatsApp.',
    'evenements',
    ARRAY['soirée', 'gala', 'speed dating', 'groupe', 'douala', 'yaoundé'],
    TRUE
),
(
    'Différence entre Formule Standard et Premium',
    'La formule Standard (Gratuite) vous permet d''être dans la base et d''être contacté. La formule Premium (15 000 FCFA/mois) vous offre : 1) Une visibilité prioritaire auprès des profils qui vous correspondent. 2) Des recommandations personnalisées par un conseiller dédié. 3) Un accès prioritaire aux événements de l''agence. 4) Une analyse de compatibilité approfondie.',
    'tarifs',
    ARRAY['premium', 'standard', 'abonnement', 'avantages'],
    TRUE
)
ON CONFLICT DO NOTHING;

-- Log de l'ajout
INSERT INTO agent_action_logs (action_type, tool_name, input_data, output_data, success)
VALUES ('knowledge_update', 'manual_script', '{"action": "add_detailed_kb"}', '{"status": "success", "added_entries": 6}', TRUE);
