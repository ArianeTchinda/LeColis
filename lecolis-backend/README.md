# LeColis — Backend API

Backend Express.js + Prisma + PostgreSQL + MinIO pour l'application LeColis.

---

## 🚀 Démarrage rapide

### 1. Prérequis
- Node.js 18+
- Docker + Docker Compose

### 2. Cloner et installer
```bash
cd lecolis-backend
npm install
```

### 3. Créer le fichier `.env`

> ⚠️ **Important — encodage** : le fichier `.env` doit être en **UTF-8 sans BOM**.  
> Ne pas copier-coller depuis un éditeur qui ajoute un BOM (ex : Notepad Windows).

**Sur Windows PowerShell**, créez le `.env` proprement ainsi :

```powershell
$content = @"
PORT=3000
NODE_ENV=development
DATABASE_URL=postgresql://lecolis_user:lecolis_pass@localhost:5432/lecolis_db
JWT_SECRET=lecolis_jwt_secret_change_me_in_production_very_long_key
JWT_EXPIRES_IN=15m
JWT_REFRESH_SECRET=lecolis_refresh_secret_change_me_in_production
JWT_REFRESH_EXPIRES_IN=7d
MINIO_ENDPOINT=localhost
MINIO_PORT=9000
MINIO_USE_SSL=false
MINIO_ACCESS_KEY=lecolis_minio_access
MINIO_SECRET_KEY=lecolis_minio_secret
MINIO_BUCKET_ESCORTS=escorts-photos
MINIO_BUCKET_PUBLICATIONS=publications-images
MINIO_PUBLIC_URL=http://localhost:9000
ADMIN_EMAIL=admin@lecolis.com
ADMIN_PASSWORD=Admin@2025!
CORS_ORIGIN=http://localhost:3001
"@
[System.IO.File]::WriteAllText(".env", $content, [System.Text.UTF8Encoding]::new($false))
```

**Sur Linux / macOS / WSL2** :
```bash
cp .env.example .env
```

### 4. Démarrer l'infrastructure (PostgreSQL + MinIO)
```bash
docker-compose up -d
# Attendre ~15 secondes que les services soient prêts
```

### 5. Initialiser la base de données

> ⚠️ **Problème connu sur Windows** : le Schema Engine de Prisma ne parvient pas à se connecter depuis PowerShell/CMD natif (erreur `P1000`). Utilisez l'une des méthodes ci-dessous selon votre environnement.

---

#### ✅ Méthode A — WSL2 (recommandé sur Windows)

Ouvrez un terminal WSL2 et assurez-vous que le bon `npx` est utilisé :

```bash
wsl
cd /mnt/c/Users/<VotreNom>/Documents/.../lecolis-backend

# Forcer le npx Linux (évite le conflit avec le npx Windows)
export PATH="/usr/bin:$PATH"

# Pousser le schéma
DATABASE_URL="postgresql://lecolis_user:lecolis_pass@127.0.0.1:5432/lecolis_db" /usr/bin/npx prisma db push

# Seeder les données initiales
DATABASE_URL="postgresql://lecolis_user:lecolis_pass@127.0.0.1:5432/lecolis_db" node prisma/seed.js
```

> Si Node.js n'est pas installé dans WSL2 :
> ```bash
> curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
> sudo apt-get install -y nodejs
> npm install
> ```

---

#### ✅ Méthode B — Linux / macOS

```bash
npm run db:generate
npm run db:push
npm run db:seed
```

---

#### ✅ Méthode C — Windows PowerShell (si WSL2 non disponible)

Passez l'URL directement dans la commande :

```powershell
$env:DATABASE_URL="postgresql://lecolis_user:lecolis_pass@127.0.0.1:5432/lecolis_db"
npx prisma db push
npx prisma generate
node prisma/seed.js
```

> Utilisez `127.0.0.1` et non `localhost` pour éviter les problèmes de résolution IPv6 sur Windows.

---

### 6. Démarrer l'API

```bash
npm run dev     # développement (nodemon, hot-reload)
npm start       # production
```

L'API sera disponible sur `http://localhost:3000`

---

## 🗄️ Services Docker

| Service       | URL                      | Identifiants                                    |
|---------------|--------------------------|-------------------------------------------------|
| PostgreSQL     | `localhost:5432`         | `lecolis_user` / `lecolis_pass`                |
| pgAdmin        | `http://localhost:5050`  | `admin@lecolis.com` / `Admin@2025!`            |
| MinIO API      | `http://localhost:9000`  | —                                               |
| MinIO Console  | `http://localhost:9001`  | `lecolis_minio_access` / `lecolis_minio_secret`|

---

## 📡 Routes API

### Auth Escort
| Méthode | Route                | Description          | Auth |
|---------|----------------------|----------------------|------|
| POST    | `/api/auth/register` | Inscription escort   | ❌   |
| POST    | `/api/auth/login`    | Connexion escort     | ❌   |
| POST    | `/api/auth/refresh`  | Renouveler le token  | ❌   |
| POST    | `/api/auth/logout`   | Déconnexion          | ❌   |

**Corps register :**
```json
{
  "pseudo": "Sofia_K",
  "email": "sofia@proton.me",
  "telephone": "+237600000001",
  "motDePasse": "monMotDePasse123"
}
```

**Corps login :**
```json
{ "email": "sofia@proton.me", "motDePasse": "monMotDePasse123" }
```

**Réponse login/register :**
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "escort": { "id": "...", "pseudo": "Sofia_K", "email": "...", ... }
}
```

---

### Profil Escort (🔐 Bearer Token requis)
| Méthode | Route                                          | Description                    |
|---------|------------------------------------------------|--------------------------------|
| GET     | `/api/profil`                                  | Mes infos + abonnement actif   |
| PUT     | `/api/profil`                                  | Modifier pseudo/téléphone      |
| PUT     | `/api/profil/photo`                            | Changer photo (multipart `photo`) |
| PUT     | `/api/profil/mot-de-passe`                     | Changer mot de passe           |
| GET     | `/api/profil/notifications`                    | Mes notifications              |
| PUT     | `/api/profil/notifications/:id/lue`            | Marquer comme lue              |
| GET     | `/api/profil/transactions`                     | Mes paiements                  |
| GET     | `/api/profil/abonnement`                       | Mon abonnement actif + quotas  |
| GET     | `/api/profil/historique-abonnements`           | Historique des abonnements     |
| GET     | `/api/profil/publications`                     | Mes publications               |
| POST    | `/api/profil/publications`                     | Créer une publication          |
| PUT     | `/api/profil/publications/:id`                 | Modifier une publication       |
| DELETE  | `/api/profil/publications/:id`                 | Supprimer une publication      |
| POST    | `/api/profil/publications/:id/images`          | Ajouter images (multipart `images[]`) |
| DELETE  | `/api/profil/publications/:id/images/:imageId` | Supprimer une image            |

**Corps POST /profil/publications :**
```json
{
  "titre": "Disponible ce soir",
  "description": "Moment de qualité...",
  "estDisponible": true,
  "tarif": 30000,
  "quartierId": "cuid_du_quartier",
  "villeNom": "Yaoundé",
  "regionNom": "Centre",
  "paysNom": "Cameroun",
  "categorieIds": ["cuid_cat1", "cuid_cat2"]
}
```

---

### Publications (public)
| Méthode | Route                              | Description                  |
|---------|------------------------------------|------------------------------|
| GET     | `/api/publications`                | Liste filtrée + paginée      |
| GET     | `/api/publications/:id`            | Détail (incrémente les vues) |
| POST    | `/api/publications/:id/avis`       | Laisser un avis (anonyme)    |
| POST    | `/api/publications/:id/signaler`   | Signaler une publication     |

**Query params GET /publications :**
```
?categorie=Milf&ville=Yaoundé&region=Centre&pays=Cameroun
&planType=premium&disponible=true&tarifMin=10000&tarifMax=50000
&page=1&limite=20
```

---

### Abonnements
| Méthode | Route                        | Description            | Auth |
|---------|------------------------------|------------------------|------|
| GET     | `/api/abonnements/plans`     | Liste des plans actifs | ❌   |
| POST    | `/api/abonnements/souscrire` | Souscrire à un plan    | 🔐   |

**Corps POST /abonnements/souscrire :**
```json
{ "planId": "cuid_du_plan", "methodePaiement": "MTN MoMo" }
```

---

### Référentiel (public)
| Méthode | Route                         | Description              |
|---------|-------------------------------|--------------------------|
| GET     | `/api/localisation/pays`      | Tous les pays + régions  |
| GET     | `/api/localisation/regions`   | `?paysId=` ou `?paysNom=` |
| GET     | `/api/localisation/villes`    | `?regionId=` ou `?regionNom=` |
| GET     | `/api/localisation/quartiers` | `?villeId=` ou `?villeNom=` |
| GET     | `/api/categories`             | Par groupes              |
| GET     | `/api/categories/flat`        | Liste plate              |

---

### Admin (🔐 Bearer Token admin requis)
| Méthode | Route                                  | Description                  |
|---------|----------------------------------------|------------------------------|
| POST    | `/api/admin/login`                     | Connexion admin              |
| GET     | `/api/admin/dashboard`                 | Stats générales              |
| GET     | `/api/admin/escorts`                   | Liste escorts + filtres      |
| GET     | `/api/admin/escorts/:id`               | Détail escort complet        |
| PUT     | `/api/admin/escorts/:id/verifier`      | Vérifier/désvérifier         |
| POST    | `/api/admin/escorts/:id/sanctionner`   | Appliquer une sanction       |
| PUT     | `/api/admin/escorts/:id/debloquer`     | Débloquer un compte          |
| GET     | `/api/admin/signalements`              | Liste signalements           |
| PUT     | `/api/admin/signalements/:id`          | Traiter un signalement       |
| GET     | `/api/admin/plans`                     | Liste des plans              |
| PUT     | `/api/admin/plans/:id`                 | Modifier un plan             |
| PUT     | `/api/admin/abonnements/:id/ajuster`   | Ajuster quota/date           |
| POST    | `/api/admin/notifications/envoyer`     | Envoyer notification         |
| GET     | `/api/admin/transactions`              | Liste transactions           |
| GET     | `/api/admin/publications`              | Liste publications           |
| PUT     | `/api/admin/publications/:id/statut`   | Changer statut publication   |

**Admin login par défaut :**
```json
{ "email": "admin@lecolis.com", "motDePasse": "Admin@2025!" }
```

---

## 🗂️ Structure du projet

```
lecolis-backend/
├── docker-compose.yml        # PostgreSQL + pgAdmin + MinIO
├── .env.example              # Variables d'environnement (modèle)
├── package.json
├── prisma/
│   ├── schema.prisma         # Schéma complet de la BDD
│   └── seed.js               # Données initiales
└── src/
    ├── index.js              # Point d'entrée Express
    ├── config/
    │   ├── prisma.js         # Client Prisma singleton
    │   ├── minio.js          # Client MinIO + helpers
    │   └── jwt.js            # Utilitaires JWT
    ├── middlewares/
    │   ├── auth.js           # authEscort + authAdmin
    │   ├── upload.js         # Multer (mémoire → MinIO)
    │   └── errorHandler.js   # Gestionnaire erreurs global
    ├── services/
    │   └── imageService.js   # Resize (sharp) + upload MinIO
    ├── controllers/
    │   ├── authController.js
    │   ├── profilController.js
    │   ├── publicationController.js
    │   ├── abonnementController.js
    │   ├── adminController.js
    │   └── referentielController.js
    └── routes/
        ├── auth.js
        ├── profil.js
        ├── publications.js
        ├── abonnements.js
        ├── admin.js
        └── referentiel.js
```

---

## 🔑 Authentification

Toutes les routes protégées nécessitent le header :
```
Authorization: Bearer <accessToken>
```

- **accessToken** : expire en 15 min (configurable via `JWT_EXPIRES_IN`)
- **refreshToken** : expire en 7 jours, rotation à chaque refresh
- Appeler `POST /api/auth/refresh` avec `{ "refreshToken": "..." }` pour renouveler

---

## 🖼️ Upload d'images

- Les images de profil sont redimensionnées à **400×400px** → bucket `escorts-photos`
- Les images de publication sont redimensionnées à **max 1200×900px** → bucket `publications-images`
- Les URLs retournées sont publiques et directement utilisables par le frontend
- Format de sortie : **JPEG** optimisé (qualité 82-85%)

---

## 🔧 Commandes utiles

```bash
# Prisma Studio (interface BDD visuelle)
npm run db:studio

# Reset complet + reseed
npm run db:reset

# Inspecter les logs Docker
docker-compose logs -f postgres
docker-compose logs -f minio
```

---

## 🐛 Dépannage

### Erreur `P1000` — Authentication failed (Windows)

Prisma 6 a un bug connu sur Windows où le Schema Engine n'arrive pas à établir la connexion depuis PowerShell/CMD natif, même avec une URL valide. PostgreSQL ne reçoit aucune tentative de connexion.

**Solution** : utilisez WSL2 (voir Méthode A ci-dessus). C'est la solution la plus fiable.

### Le fichier `.env` semble mal lu

Si vous voyez des caractères corrompus (`â"€`, `Ã©`) dans les logs, le `.env` a été sauvegardé avec un BOM. Recréez-le avec la commande PowerShell de l'étape 3.

### `npx` dans WSL2 utilise le Node.js Windows

```bash
# Vérifier quel npx est utilisé
which npx

# Si /mnt/c/... → forcer le npx Linux
export PATH="/usr/bin:$PATH"

# Rendre permanent
echo 'export PATH="/usr/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Recréer les volumes Docker (reset complet)

```bash
docker-compose down -v
docker-compose up -d
# Attendre 15s puis relancer db:push et db:seed
```

### Accès à pgAdmin

```bash
URL : http://localhost:5050
```
| Champ    | Valeur              |
| -------- | ------------------- |
| Email    | `admin@lecolis.com` |
| Password | `Admin@2025!`       |


| Champ             | Valeur                                                                                                            |
| ----------------- | ----------------------------------------------------------------------------------------------------------------- |
| Host name/address | `postgres` (si pgAdmin est dans Docker) ou `host.docker.internal` (si tu veux pointer vers PostgreSQL sur ton PC) |
| Port              | `5432`                                                                                                            |
| Database          | `lecolis_db`                                                                                                      |
| Username          | `lecolis_user`                                                                                                    |
| Password          | `lecolis_pass`                                                                                                    |
