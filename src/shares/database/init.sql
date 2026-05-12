-- LeColis.com - Database Schema v2.0
-- Cleanup
DROP TABLE IF EXISTS logo_site CASCADE;
DROP TABLE IF EXISTS signalement CASCADE;
DROP TABLE IF EXISTS notification CASCADE;
DROP TABLE IF EXISTS transaction CASCADE;
DROP TABLE IF EXISTS avis CASCADE;
DROP TABLE IF EXISTS publication_media CASCADE;
DROP TABLE IF EXISTS publication CASCADE;
DROP TABLE IF EXISTS abonnement_plan CASCADE;
DROP TABLE IF EXISTS plan CASCADE;
DROP TABLE IF EXISTS escort CASCADE;
DROP TABLE IF EXISTS localisation CASCADE;
DROP TABLE IF EXISTS utilisateur CASCADE;
DROP TABLE IF EXISTS categorie CASCADE;

DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS user_status CASCADE;
DROP TYPE IF EXISTS verification_status CASCADE;
DROP TYPE IF EXISTS subscription_status CASCADE;
DROP TYPE IF EXISTS publication_status CASCADE;
DROP TYPE IF EXISTS transaction_status CASCADE;
DROP TYPE IF EXISTS report_reason CASCADE;
DROP TYPE IF EXISTS report_status CASCADE;

-- 1.1 Table : utilisateur
CREATE TYPE user_role AS ENUM('client', 'escort', 'admin');
CREATE TYPE user_status AS ENUM('actif', 'suspendu', 'banni');

CREATE TABLE utilisateur (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    pseudonyme VARCHAR(100) UNIQUE NOT NULL,
    age INTEGER NOT NULL,
    description TEXT,
    telephone VARCHAR(20),
    mail VARCHAR(191) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    refresh_token VARCHAR(500),
    role user_role DEFAULT 'client',
    statut user_status DEFAULT 'actif',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 1.2 Table : localisation
CREATE TABLE localisation (
    id SERIAL PRIMARY KEY,
    ville VARCHAR(150) NOT NULL,
    quartier VARCHAR(150),
    pays VARCHAR(100) DEFAULT 'Cameroun'
);

-- 1.3 Table : escort
CREATE TYPE verification_status AS ENUM('non_soumis', 'en_attente', 'verifie', 'rejete');

CREATE TABLE escort (
    id SERIAL PRIMARY KEY,
    utilisateur_id INTEGER UNIQUE NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
    url_image_profil VARCHAR(500),
    localisation_id INTEGER REFERENCES localisation(id) ON DELETE SET NULL,
    url VARCHAR(500),
    tarif DECIMAL(10,2),
    disponible BOOLEAN DEFAULT TRUE,
    verified verification_status DEFAULT 'non_soumis',
    url_cni_recto VARCHAR(500),
    url_cni_verso VARCHAR(500),
    note_admin TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 1.4 Table : plan
CREATE TABLE plan (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    nb_publications INTEGER NOT NULL,
    duree_jours INTEGER NOT NULL,
    prix DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    actif BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Initial Plan
INSERT INTO plan (nom, description, nb_publications, duree_jours, prix, actif)
VALUES ('Standard', 'Plan gratuit offert à la création du compte escort', 1, 7, 0.00, TRUE);

-- 1.5 Table : abonnement_plan
CREATE TYPE subscription_status AS ENUM('actif', 'expiré', 'annulé');

CREATE TABLE abonnement_plan (
    id SERIAL PRIMARY KEY,
    escort_id INTEGER NOT NULL REFERENCES escort(id) ON DELETE CASCADE,
    plan_id INTEGER NOT NULL REFERENCES plan(id) ON DELETE CASCADE,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    nb_publications_utilisees INTEGER DEFAULT 0,
    statut subscription_status DEFAULT 'actif',
    created_at TIMESTAMP DEFAULT NOW()
);

-- 1.6 Table : publication
CREATE TYPE publication_status AS ENUM('actif', 'inactif');

CREATE TABLE publication (
    id SERIAL PRIMARY KEY,
    escort_id INTEGER NOT NULL REFERENCES escort(id) ON DELETE CASCADE,
    abonnement_plan_id INTEGER NOT NULL REFERENCES abonnement_plan(id) ON DELETE CASCADE,
    titre VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    statut publication_status DEFAULT 'actif',
    montant DECIMAL(10,2),
    duree INTEGER, -- en heures
    vh_publication INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 1.7 Table : publication_media
CREATE TABLE publication_media (
    id SERIAL PRIMARY KEY,
    publication_id INTEGER NOT NULL REFERENCES publication(id) ON DELETE CASCADE,
    url VARCHAR(500) NOT NULL,
    ordre SMALLINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 1.8 Table : avis
CREATE TABLE avis (
    id SERIAL PRIMARY KEY,
    utilisateur_id INTEGER NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
    escort_id INTEGER NOT NULL REFERENCES escort(id) ON DELETE CASCADE,
    rate SMALLINT NOT NULL CHECK (rate BETWEEN 1 AND 5),
    message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 1.9 Table : transaction
CREATE TYPE transaction_status AS ENUM('en_attente', 'valide', 'echoue', 'rembourse');

CREATE TABLE transaction (
    id SERIAL PRIMARY KEY,
    escort_id INTEGER NOT NULL REFERENCES escort(id) ON DELETE CASCADE,
    plan_id INTEGER NOT NULL REFERENCES plan(id) ON DELETE CASCADE,
    abonnement_plan_id INTEGER REFERENCES abonnement_plan(id) ON DELETE SET NULL,
    montant DECIMAL(10,2) NOT NULL,
    statut transaction_status DEFAULT 'en_attente',
    reference_paiement VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 1.10 Table : notification
CREATE TABLE notification (
    id SERIAL PRIMARY KEY,
    utilisateur_id INTEGER NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
    titre VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    lu BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 1.11 Table : signalement
CREATE TYPE report_reason AS ENUM('faux_compte', 'spam', 'contenu_inapproprie', 'autre');
CREATE TYPE report_status AS ENUM('en_attente', 'traite', 'rejete');

CREATE TABLE signalement (
    id SERIAL PRIMARY KEY,
    rapporteur_id INTEGER NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
    escort_id INTEGER NOT NULL REFERENCES escort(id) ON DELETE CASCADE,
    motif report_reason NOT NULL,
    description TEXT,
    statut report_status DEFAULT 'en_attente',
    traite_par INTEGER REFERENCES utilisateur(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 1.12 Table : logo_site
CREATE TABLE logo_site (
    id SERIAL PRIMARY KEY,
    url_logo VARCHAR(500) NOT NULL,
    label VARCHAR(150),
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    actif BOOLEAN DEFAULT FALSE,
    created_by INTEGER REFERENCES utilisateur(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Categories (from previous schema)
CREATE TABLE categorie (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) UNIQUE NOT NULL
);