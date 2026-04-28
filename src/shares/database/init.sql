-- Phase 1 : Tables de base (Indépendantes)
CREATE TABLE admin (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100),
    prenom VARCHAR(100),
    password TEXT NOT NULL
);

CREATE TABLE localisation (
    id SERIAL PRIMARY KEY,
    pay VARCHAR(100),
    ville VARCHAR(100),
    quatiers VARCHAR(100)
);

CREATE TABLE plan (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100),
    duree INTEGER, -- Nombre de jours de validité
    nb_publication INTEGER
);

CREATE TABLE categorie (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) UNIQUE
);

-- Phase 2 : Profil Escort (Dépend de localisation)
CREATE TABLE escort (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100),
    pseudo VARCHAR(100) UNIQUE,
    age INTEGER,
    description TEXT,
    telephone VARCHAR(30),
    mail VARCHAR(150) UNIQUE,
    password TEXT NOT NULL,
    status VARCHAR(50),
    -- On stocke ici uniquement les URLs des images
    recto_card TEXT, 
    verso_card TEXT,
    id_localisation INTEGER REFERENCES localisation(id) ON DELETE SET NULL
);

-- Phase 3 : Activités et Interactions (Dépendent d'Escort/Admin/Plan)
CREATE TABLE publication (
    id SERIAL PRIMARY KEY,
    titre VARCHAR(255),
    description TEXT,
    status VARCHAR(50),
    id_categorie INTEGER REFERENCES categorie(id) ON DELETE SET NULL,
    id_escort INTEGER REFERENCES escort(id) ON DELETE CASCADE
);

CREATE TABLE souscription (
    id SERIAL PRIMARY KEY,
    date_debut DATE DEFAULT CURRENT_DATE,
    date_fin DATE,
    montant DECIMAL(10, 2),
    status VARCHAR(50),
    moyen_payement VARCHAR(100),
    id_escort INTEGER REFERENCES escort(id) ON DELETE CASCADE,
    id_plan INTEGER REFERENCES plan(id) ON DELETE SET NULL
);

CREATE TABLE avis (
    id SERIAL PRIMARY KEY,
    message TEXT,
    date DATE DEFAULT CURRENT_DATE,
    rate INTEGER CHECK (rate BETWEEN 0 AND 5),
    id_escort INTEGER REFERENCES escort(id) ON DELETE CASCADE
);

CREATE TABLE signalisation (
    id SERIAL PRIMARY KEY,
    raison TEXT,
    id_admin INTEGER REFERENCES admin(id) ON DELETE SET NULL,
    id_escort INTEGER REFERENCES escort(id) ON DELETE CASCADE
);

CREATE TABLE notification (
    id SERIAL PRIMARY KEY,
    message TEXT,
    id_escort INTEGER REFERENCES escort(id) ON DELETE CASCADE,
    id_admin INTEGER REFERENCES admin(id) ON DELETE SET NULL
);  

-- Phase 4 : Contenu lié aux publications
CREATE TABLE media (
    id SERIAL PRIMARY KEY,
    url TEXT NOT NULL, -- URL de la photo ou vidéo
    id_publication INTEGER REFERENCES publication(id) ON DELETE CASCADE
);