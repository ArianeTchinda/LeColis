-- CreateEnum
CREATE TYPE "StatutAbonnement" AS ENUM ('ACTIF', 'EXPIRE', 'ANNULE');

-- CreateEnum
CREATE TYPE "StatutTransaction" AS ENUM ('SUCCES', 'EN_ATTENTE', 'ECHEC');

-- CreateEnum
CREATE TYPE "StatutPublication" AS ENUM ('ACTIVE', 'EXPIREE', 'BROUILLON', 'SUSPENDUE');

-- CreateEnum
CREATE TYPE "StatutSignalement" AS ENUM ('EN_ATTENTE', 'TRAITE', 'IGNORE');

-- CreateEnum
CREATE TYPE "TypeNotification" AS ENUM ('SYSTEME', 'ADMIN', 'ABONNEMENT', 'PUBLICATION');

-- CreateEnum
CREATE TYPE "TypeSanction" AS ENUM ('AVERTISSEMENT', 'BLOCAGE_TEMPORAIRE', 'BANNISSEMENT');

-- CreateEnum
CREATE TYPE "CibleNotification" AS ENUM ('TOUS', 'INDIVIDUEL', 'MULTIPLE');

-- CreateTable
CREATE TABLE "pays" (
    "id" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "drapeau" TEXT NOT NULL,

    CONSTRAINT "pays_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "regions" (
    "id" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "paysId" TEXT NOT NULL,

    CONSTRAINT "regions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "villes" (
    "id" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "regionId" TEXT NOT NULL,

    CONSTRAINT "villes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "quartiers" (
    "id" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "villeId" TEXT NOT NULL,

    CONSTRAINT "quartiers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "groupes_categories" (
    "id" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "ordre" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "groupes_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "categories" (
    "id" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "groupeId" TEXT NOT NULL,

    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "escorts" (
    "id" TEXT NOT NULL,
    "pseudo" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "telephone" TEXT NOT NULL,
    "motDePasseHash" TEXT NOT NULL,
    "photoUrl" TEXT,
    "photoKey" TEXT,
    "estVerifie" BOOLEAN NOT NULL DEFAULT false,
    "estBloque" BOOLEAN NOT NULL DEFAULT false,
    "estBanni" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "escorts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "escortId" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "plans_abonnement" (
    "id" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "prix" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "nbPublications" INTEGER NOT NULL DEFAULT 1,
    "dureeJours" INTEGER NOT NULL DEFAULT 7,
    "accentColor" TEXT NOT NULL DEFAULT '#8A8A9A',
    "icone" TEXT NOT NULL DEFAULT 'star_outline',
    "avantages" TEXT[],
    "estBasique" BOOLEAN NOT NULL DEFAULT false,
    "estBase" BOOLEAN NOT NULL DEFAULT true,
    "ordre" INTEGER NOT NULL DEFAULT 0,
    "actif" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "plans_abonnement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "abonnements" (
    "id" TEXT NOT NULL,
    "escortId" TEXT NOT NULL,
    "planId" TEXT NOT NULL,
    "dateDebut" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "dateFin" TIMESTAMP(3) NOT NULL,
    "statut" "StatutAbonnement" NOT NULL DEFAULT 'ACTIF',
    "nbPublicationsAdm" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "transactionId" TEXT,

    CONSTRAINT "abonnements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transactions" (
    "id" TEXT NOT NULL,
    "escortId" TEXT NOT NULL,
    "planNom" TEXT NOT NULL,
    "montant" DOUBLE PRECISION NOT NULL,
    "methodePaiement" TEXT NOT NULL,
    "statut" "StatutTransaction" NOT NULL DEFAULT 'EN_ATTENTE',
    "taraRef" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "publications" (
    "id" TEXT NOT NULL,
    "escortId" TEXT NOT NULL,
    "titre" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "estDisponible" BOOLEAN NOT NULL DEFAULT true,
    "tarif" DOUBLE PRECISION,
    "statut" "StatutPublication" NOT NULL DEFAULT 'BROUILLON',
    "vues" INTEGER NOT NULL DEFAULT 0,
    "dateExpiration" TIMESTAMP(3) NOT NULL,
    "quartierId" TEXT,
    "villeNom" TEXT NOT NULL,
    "regionNom" TEXT NOT NULL,
    "paysNom" TEXT NOT NULL DEFAULT 'Cameroun',
    "planType" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "publications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "publication_images" (
    "id" TEXT NOT NULL,
    "publicationId" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "ordre" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "publication_images_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "publication_categories" (
    "publicationId" TEXT NOT NULL,
    "categorieId" TEXT NOT NULL,

    CONSTRAINT "publication_categories_pkey" PRIMARY KEY ("publicationId","categorieId")
);

-- CreateTable
CREATE TABLE "avis" (
    "id" TEXT NOT NULL,
    "publicationId" TEXT NOT NULL,
    "note" INTEGER NOT NULL,
    "message" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "avis_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "signalements" (
    "id" TEXT NOT NULL,
    "escortId" TEXT NOT NULL,
    "publicationId" TEXT,
    "motif" TEXT NOT NULL,
    "description" TEXT,
    "statut" "StatutSignalement" NOT NULL DEFAULT 'EN_ATTENTE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "signalements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "escortId" TEXT NOT NULL,
    "type" "TypeNotification" NOT NULL,
    "titre" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "lue" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sanctions" (
    "id" TEXT NOT NULL,
    "escortId" TEXT NOT NULL,
    "type" "TypeSanction" NOT NULL,
    "motif" TEXT NOT NULL,
    "dateDebut" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "dateFin" TIMESTAMP(3),
    "active" BOOLEAN NOT NULL DEFAULT true,
    "adminId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sanctions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "admins" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "motDePasseHash" TEXT NOT NULL,
    "nom" TEXT NOT NULL DEFAULT 'Administrateur',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "admins_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications_admin" (
    "id" TEXT NOT NULL,
    "adminId" TEXT NOT NULL,
    "titre" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "type" "TypeNotification" NOT NULL,
    "cible" "CibleNotification" NOT NULL,
    "escortIds" TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_admin_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "codes_reinit" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "utilise" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "codes_reinit_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "pays_nom_key" ON "pays"("nom");

-- CreateIndex
CREATE UNIQUE INDEX "regions_nom_paysId_key" ON "regions"("nom", "paysId");

-- CreateIndex
CREATE UNIQUE INDEX "villes_nom_regionId_key" ON "villes"("nom", "regionId");

-- CreateIndex
CREATE UNIQUE INDEX "quartiers_nom_villeId_key" ON "quartiers"("nom", "villeId");

-- CreateIndex
CREATE UNIQUE INDEX "groupes_categories_nom_key" ON "groupes_categories"("nom");

-- CreateIndex
CREATE UNIQUE INDEX "categories_nom_key" ON "categories"("nom");

-- CreateIndex
CREATE UNIQUE INDEX "escorts_pseudo_key" ON "escorts"("pseudo");

-- CreateIndex
CREATE UNIQUE INDEX "escorts_email_key" ON "escorts"("email");

-- CreateIndex
CREATE UNIQUE INDEX "escorts_telephone_key" ON "escorts"("telephone");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_key" ON "refresh_tokens"("token");

-- CreateIndex
CREATE UNIQUE INDEX "plans_abonnement_nom_key" ON "plans_abonnement"("nom");

-- CreateIndex
CREATE UNIQUE INDEX "abonnements_transactionId_key" ON "abonnements"("transactionId");

-- CreateIndex
CREATE INDEX "transactions_taraRef_idx" ON "transactions"("taraRef");

-- CreateIndex
CREATE UNIQUE INDEX "admins_email_key" ON "admins"("email");

-- CreateIndex
CREATE INDEX "codes_reinit_email_idx" ON "codes_reinit"("email");

-- AddForeignKey
ALTER TABLE "regions" ADD CONSTRAINT "regions_paysId_fkey" FOREIGN KEY ("paysId") REFERENCES "pays"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "villes" ADD CONSTRAINT "villes_regionId_fkey" FOREIGN KEY ("regionId") REFERENCES "regions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quartiers" ADD CONSTRAINT "quartiers_villeId_fkey" FOREIGN KEY ("villeId") REFERENCES "villes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "categories" ADD CONSTRAINT "categories_groupeId_fkey" FOREIGN KEY ("groupeId") REFERENCES "groupes_categories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_escortId_fkey" FOREIGN KEY ("escortId") REFERENCES "escorts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "abonnements" ADD CONSTRAINT "abonnements_escortId_fkey" FOREIGN KEY ("escortId") REFERENCES "escorts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "abonnements" ADD CONSTRAINT "abonnements_planId_fkey" FOREIGN KEY ("planId") REFERENCES "plans_abonnement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "abonnements" ADD CONSTRAINT "abonnements_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES "transactions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_escortId_fkey" FOREIGN KEY ("escortId") REFERENCES "escorts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "publications" ADD CONSTRAINT "publications_escortId_fkey" FOREIGN KEY ("escortId") REFERENCES "escorts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "publications" ADD CONSTRAINT "publications_quartierId_fkey" FOREIGN KEY ("quartierId") REFERENCES "quartiers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "publication_images" ADD CONSTRAINT "publication_images_publicationId_fkey" FOREIGN KEY ("publicationId") REFERENCES "publications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "publication_categories" ADD CONSTRAINT "publication_categories_publicationId_fkey" FOREIGN KEY ("publicationId") REFERENCES "publications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "publication_categories" ADD CONSTRAINT "publication_categories_categorieId_fkey" FOREIGN KEY ("categorieId") REFERENCES "categories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "avis" ADD CONSTRAINT "avis_publicationId_fkey" FOREIGN KEY ("publicationId") REFERENCES "publications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "signalements" ADD CONSTRAINT "signalements_escortId_fkey" FOREIGN KEY ("escortId") REFERENCES "escorts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "signalements" ADD CONSTRAINT "signalements_publicationId_fkey" FOREIGN KEY ("publicationId") REFERENCES "publications"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_escortId_fkey" FOREIGN KEY ("escortId") REFERENCES "escorts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sanctions" ADD CONSTRAINT "sanctions_escortId_fkey" FOREIGN KEY ("escortId") REFERENCES "escorts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications_admin" ADD CONSTRAINT "notifications_admin_adminId_fkey" FOREIGN KEY ("adminId") REFERENCES "admins"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
