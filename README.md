# Documentation Technique — LeColis v2.0

Cette documentation detaille l'architecture, la configuration et l'utilisation du backend de la plateforme LeColis, migre vers la version 2.0.

---

## 1. Architecture Globale
Le projet suit le pattern **Controller-Service-Repository** :
- **Controllers** : Gerent les requetes HTTP et les reponses.
- **Services** : Logique métier (quotas, abonnements, transactions).
- **Repositories** : Acces direct a la base de donnees.
- **Shares** : Middlewares, utilitaires (Minio, Logger, etc.).

---

## 2. Prérequis & Installation

### Installations nécessaires
1. **Node.js** (v18+)
2. **PostgreSQL** (v14+)
3. **Docker** (pour Minio)

### Lancement rapide
1. **Dependances** : `npm install`
2. **Base de donnees** : Executer `src/shares/database/init.sql` puis `seed.sql`.
3. **Services** : `docker compose up -d` (lance Minio).
4. **Backend** : `npm run dev`.

---

## 3. Stockage des Medias (Minio)

### Ou sont stockees les images ?
Minio stocke les fichiers dans des **Buckets**. Pour votre installation :
- **Volume Docker** : Les donnees physiques sont dans le volume `lecolis_minio_data` gere par Docker.
- **Interface (Console)** : [http://localhost:9001](http://localhost:9001) (User/Pass: `minioadmin`).
- **Acces API** : L'API genere des **URLs presignees** temporaires pour afficher les images en toute securite.

---

## 4. Documentation API (Swagger)
Accedez a la documentation interactive pour tester les routes :
- **URL** : [http://localhost:5000/api-docs](http://localhost:5000/api-docs)
- **Authentification** : Utilisez le bouton "Authorize" en haut a droite avec un token JWT genere par le login.

--
