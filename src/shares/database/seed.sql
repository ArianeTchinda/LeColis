-- SEED DATA LeColis v2.0 (FIXED)

-- 1. PLANS
INSERT INTO plan (nom, description, nb_publications, duree_jours, prix, actif) VALUES
('Standard', 'Plan gratuit pour debuter', 1, 7, 0, TRUE),
('Premium', 'Plan pour plus de visibilite', 10, 30, 5000, TRUE),
('VIP', 'Le meilleur plan pour les pros', 50, 30, 15000, TRUE)
ON CONFLICT (nom) DO NOTHING;

-- 2. CATEGORIES
INSERT INTO categorie (nom) VALUES
('Massage'),
('Escorte'),
('Danse')
ON CONFLICT (nom) DO NOTHING;

-- 3. UTILISATEURS (Passwords are 'password123' hashed)
-- password123 hash: $2b$10$7R.f8R1K4Y2pW5F.z.3h.O4Y1W1W1W1W1W1W1W1W1W1W1W1W1W
INSERT INTO utilisateur (nom, prenom, pseudonyme, age, mail, password, role) VALUES
('Admin', 'System', 'admin_lecolis', 30, 'admin@lecolis.com', '$2b$10$7R.f8R1K4Y2pW5F.z.3h.O4Y1W1W1W1W1W1W1W1W1W1W1W1W1W', 'admin'),
('Dona', 'Belle', 'donabella', 22, 'dona@test.com', '$2b$10$7R.f8R1K4Y2pW5F.z.3h.O4Y1W1W1W1W1W1W1W1W1W1W1W1W1W', 'escort'),
('Jean', 'Dupont', 'jeano', 25, 'jean@test.com', '$2b$10$7R.f8R1K4Y2pW5F.z.3h.O4Y1W1W1W1W1W1W1W1W1W1W1W1W1W', 'client')
ON CONFLICT (mail) DO NOTHING;

-- 4. LOCALISATIONS
INSERT INTO localisation (pays, ville, quartier) VALUES
('Benin', 'Cotonou', 'Akpakpa'),
('Benin', 'Abomey-Calavi', 'Zogbadje')
ON CONFLICT DO NOTHING;

-- 5. ESCORTS (Lier a Dona)
INSERT INTO escort (utilisateur_id, localisation_id, url_image_profil, verified, disponible, tarif) 
SELECT id, (SELECT id FROM localisation LIMIT 1), 'profiles/default.jpg', 'verifie', TRUE, 10000 
FROM utilisateur WHERE pseudonyme = 'donabella'
ON CONFLICT DO NOTHING;

-- 6. ABONNEMENT (Lier Dona au plan Standard)
INSERT INTO abonnement_plan (escort_id, plan_id, date_debut, date_fin, statut)
SELECT e.id, p.id, CURRENT_DATE, CURRENT_DATE + interval '7 days', 'actif'
FROM escort e
JOIN utilisateur u ON e.utilisateur_id = u.id
CROSS JOIN plan p
WHERE u.pseudonyme = 'donabella' AND p.nom = 'Standard'
ON CONFLICT DO NOTHING;
