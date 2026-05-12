// lib/core/data/location_data.dart
//
// Structure hiérarchique : Pays → Région → Ville → Quartiers
//
// Cameroun : toutes les régions, villes principales et quartiers
// Autres pays : grandes villes (sans quartiers détaillés)

// ─────────────────────────────────────────────────────────
// MODÈLES
// ─────────────────────────────────────────────────────────

class Quartier {
  final String id;
  final String nom;
  const Quartier({required this.id, required this.nom});
}

class Ville {
  final String id;
  final String nom;
  final List<Quartier> quartiers;
  const Ville({required this.id, required this.nom, this.quartiers = const []});
}

class Region {
  final String id;
  final String nom;
  final List<Ville> villes;
  const Region({required this.id, required this.nom, this.villes = const []});
}

class Pays {
  final String id;
  final String nom;
  final String drapeau; // emoji drapeau
  final List<Region> regions;
  const Pays({required this.id, required this.nom, required this.drapeau, this.regions = const []});
}

// ─────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────

List<String> getPays() => locationData.map((p) => p.nom).toList();

List<String> getRegions(String paysNom) {
  final pays = locationData.firstWhere(
    (p) => p.nom == paysNom,
    orElse: () => const Pays(id: '', nom: '', drapeau: ''),
  );
  return pays.regions.map((r) => r.nom).toList();
}

List<String> getVilles(String paysNom, String regionNom) {
  final pays = locationData.firstWhere(
    (p) => p.nom == paysNom,
    orElse: () => const Pays(id: '', nom: '', drapeau: ''),
  );
  final region = pays.regions.firstWhere(
    (r) => r.nom == regionNom,
    orElse: () => const Region(id: '', nom: ''),
  );
  return region.villes.map((v) => v.nom).toList();
}

List<String> getQuartiers(String paysNom, String regionNom, String villeNom) {
  final pays = locationData.firstWhere(
    (p) => p.nom == paysNom,
    orElse: () => const Pays(id: '', nom: '', drapeau: ''),
  );
  final region = pays.regions.firstWhere(
    (r) => r.nom == regionNom,
    orElse: () => const Region(id: '', nom: ''),
  );
  final ville = region.villes.firstWhere(
    (v) => v.nom == villeNom,
    orElse: () => const Ville(id: '', nom: ''),
  );
  return ville.quartiers.map((q) => q.nom).toList();
}

// ─────────────────────────────────────────────────────────
// DONNÉES
// ─────────────────────────────────────────────────────────

const List<Pays> locationData = [

  // ═══════════════════════════════════════════════════════
  // 🇨🇲 CAMEROUN — détaillé complet
  // ═══════════════════════════════════════════════════════
  Pays(
    id: 'cm', nom: 'Cameroun', drapeau: '🇨🇲',
    regions: [

      // ── Centre ──
      Region(id: 'cm_centre', nom: 'Centre', villes: [
        Ville(id: 'cm_yaounde', nom: 'Yaoundé', quartiers: [
          Quartier(id: 'q_bastos', nom: 'Bastos'),
          Quartier(id: 'q_nlongkak', nom: 'Nlongkak'),
          Quartier(id: 'q_omnisport', nom: 'Omnisport'),
          Quartier(id: 'q_mvan', nom: 'Mvan'),
          Quartier(id: 'q_biyem_assi', nom: 'Biyem-Assi'),
          Quartier(id: 'q_mvog_mbi', nom: 'Mvog-Mbi'),
          Quartier(id: 'q_ekounou', nom: 'Ekounou'),
          Quartier(id: 'q_etoudi', nom: 'Etoudi'),
          Quartier(id: 'q_ngousso', nom: 'Ngousso'),
          Quartier(id: 'q_emana', nom: 'Emana'),
          Quartier(id: 'q_elig_essono', nom: 'Elig-Essono'),
          Quartier(id: 'q_mimboman', nom: 'Mimboman'),
          Quartier(id: 'q_simbock', nom: 'Simbock'),
          Quartier(id: 'q_nkoabang', nom: 'Nkoabang'),
          Quartier(id: 'q_tsinga', nom: 'Tsinga'),
          Quartier(id: 'q_mendong', nom: 'Mendong'),
          Quartier(id: 'q_olembe', nom: 'Olembe'),
          Quartier(id: 'q_nkolbisson', nom: 'Nkolbisson'),
          Quartier(id: 'q_messamendongo', nom: 'Messameñdongo'),
          Quartier(id: 'q_odza', nom: 'Odza'),
          Quartier(id: 'q_essos', nom: 'Essos'),
          Quartier(id: 'q_ahala', nom: 'Ahala'),
          Quartier(id: 'q_ngoa_ekelle', nom: 'Ngoa-Ekellé'),
          Quartier(id: 'q_messa', nom: 'Messa'),
          Quartier(id: 'q_kondengui', nom: 'Kondengui'),
          Quartier(id: 'q_mvog_ada', nom: 'Mvog-Ada'),
          Quartier(id: 'q_nsam', nom: 'Nsam'),
        ]),
        Ville(id: 'cm_mbalmayo', nom: 'Mbalmayo', quartiers: [
          Quartier(id: 'q_mba_centre', nom: 'Centre'),
          Quartier(id: 'q_mba_nkolyem', nom: 'Nkolyem'),
          Quartier(id: 'q_mba_elat', nom: 'Elat'),
        ]),
        Ville(id: 'cm_eseka', nom: 'Eséka', quartiers: [
          Quartier(id: 'q_ese_centre', nom: 'Centre'),
          Quartier(id: 'q_ese_ndog', nom: 'Ndog-Passap'),
        ]),
        Ville(id: 'cm_nanga_eboko', nom: 'Nanga-Eboko', quartiers: [
          Quartier(id: 'q_nan_centre', nom: 'Centre ville'),
        ]),
        Ville(id: 'cm_bafia', nom: 'Bafia', quartiers: [
          Quartier(id: 'q_baf_centre', nom: 'Centre'),
          Quartier(id: 'q_baf_marche', nom: 'Marché'),
        ]),
      ]),

      // ── Littoral ──
      Region(id: 'cm_littoral', nom: 'Littoral', villes: [
        Ville(id: 'cm_douala', nom: 'Douala', quartiers: [
          Quartier(id: 'q_akwa', nom: 'Akwa'),
          Quartier(id: 'q_bonanjo', nom: 'Bonanjo'),
          Quartier(id: 'q_deido', nom: 'Deido'),
          Quartier(id: 'q_bassa', nom: 'Bassa'),
          Quartier(id: 'q_bonaberi', nom: 'Bonaberi'),
          Quartier(id: 'q_makepe', nom: 'Makepe'),
          Quartier(id: 'q_kotto', nom: 'Kotto'),
          Quartier(id: 'q_logbaba', nom: 'Logbaba'),
          Quartier(id: 'q_ndokotti', nom: 'Ndokotti'),
          Quartier(id: 'q_bonapriso', nom: 'Bonapriso'),
          Quartier(id: 'q_new_bell', nom: 'New-Bell'),
          Quartier(id: 'q_ange_raphael', nom: 'Ange Raphaël'),
          Quartier(id: 'q_cite_des_palmiers', nom: 'Cité des Palmiers'),
          Quartier(id: 'q_pk10', nom: 'PK10'),
          Quartier(id: 'q_pk14', nom: 'PK14'),
          Quartier(id: 'q_village', nom: 'Village'),
          Quartier(id: 'q_ndog_bong', nom: 'Ndog-Bong'),
          Quartier(id: 'q_bepanda', nom: 'Bepanda'),
          Quartier(id: 'q_ndogpassap', nom: 'Ndogpassap'),
          Quartier(id: 'q_yassa', nom: 'Yassa'),
          Quartier(id: 'q_mboppi', nom: 'Mboppi'),
          Quartier(id: 'q_bonamoussadi', nom: 'Bonamoussadi'),
          Quartier(id: 'q_kake', nom: 'Kaké'),
        ]),
        Ville(id: 'cm_nkongsamba', nom: 'Nkongsamba', quartiers: [
          Quartier(id: 'q_nko_centre', nom: 'Centre ville'),
          Quartier(id: 'q_nko_marche', nom: 'Grand Marché'),
          Quartier(id: 'q_nko_fiango', nom: 'Fiango'),
        ]),
        Ville(id: 'cm_edea', nom: 'Edéa', quartiers: [
          Quartier(id: 'q_ede_centre', nom: 'Centre'),
          Quartier(id: 'q_ede_alucamp', nom: 'Alucamp'),
        ]),
        Ville(id: 'cm_loum', nom: 'Loum', quartiers: [
          Quartier(id: 'q_loum_centre', nom: 'Centre'),
        ]),
      ]),

      // ── Ouest ──
      Region(id: 'cm_ouest', nom: 'Ouest', villes: [
        Ville(id: 'cm_bafoussam', nom: 'Bafoussam', quartiers: [
          Quartier(id: 'q_baf_centre', nom: 'Centre commercial'),
          Quartier(id: 'q_baf_djeleng', nom: 'Djeleng'),
          Quartier(id: 'q_baf_kamkop', nom: 'Kamkop'),
          Quartier(id: 'q_baf_tougang', nom: 'Tougang'),
          Quartier(id: 'q_baf_tamdja', nom: 'Tamdja'),
          Quartier(id: 'q_baf_ngouache', nom: 'Ngouache'),
          Quartier(id: 'q_baf_famla', nom: 'Famla'),
          Quartier(id: 'q_baf_koptchou', nom: 'Koptchou'),
        ]),
        Ville(id: 'cm_dschang', nom: 'Dschang', quartiers: [
          Quartier(id: 'q_dsc_centre', nom: 'Centre'),
          Quartier(id: 'q_dsc_foto', nom: 'Foto'),
          Quartier(id: 'q_dsc_fokoue', nom: 'Fokoué'),
        ]),
        Ville(id: 'cm_mbouda', nom: 'Mbouda', quartiers: [
          Quartier(id: 'q_mbd_centre', nom: 'Centre'),
          Quartier(id: 'q_mbd_marche', nom: 'Marché'),
        ]),
        Ville(id: 'cm_bangangte', nom: 'Bangangté', quartiers: [
          Quartier(id: 'q_ban_centre', nom: 'Centre'),
        ]),
        Ville(id: 'cm_foumban', nom: 'Foumban', quartiers: [
          Quartier(id: 'q_fou_centre', nom: 'Centre'),
          Quartier(id: 'q_fou_palais', nom: 'Quartier Palais'),
        ]),
      ]),

      // ── Nord-Ouest ──
      Region(id: 'cm_nord_ouest', nom: 'Nord-Ouest', villes: [
        Ville(id: 'cm_bamenda', nom: 'Bamenda', quartiers: [
          Quartier(id: 'q_bam_commercial', nom: 'Commercial Avenue'),
          Quartier(id: 'q_bam_up_station', nom: 'Up Station'),
          Quartier(id: 'q_bam_nkwen', nom: 'Nkwen'),
          Quartier(id: 'q_bam_mile2', nom: 'Mile 2'),
          Quartier(id: 'q_bam_mile4', nom: 'Mile 4'),
          Quartier(id: 'q_bam_cow_street', nom: 'Cow Street'),
        ]),
        Ville(id: 'cm_kumbo', nom: 'Kumbo', quartiers: [
          Quartier(id: 'q_kum_centre', nom: 'Centre'),
          Quartier(id: 'q_kum_tobin', nom: 'Tobin'),
        ]),
        Ville(id: 'cm_wum', nom: 'Wum', quartiers: [
          Quartier(id: 'q_wum_centre', nom: 'Centre'),
        ]),
      ]),

      // ── Sud-Ouest ──
      Region(id: 'cm_sud_ouest', nom: 'Sud-Ouest', villes: [
        Ville(id: 'cm_buea', nom: 'Buea', quartiers: [
          Quartier(id: 'q_bue_molyko', nom: 'Molyko'),
          Quartier(id: 'q_bue_great_soppo', nom: 'Great Soppo'),
          Quartier(id: 'q_bue_mile17', nom: 'Mile 17'),
          Quartier(id: 'q_bue_bonduma', nom: 'Bonduma'),
          Quartier(id: 'q_bue_bokwango', nom: 'Bokwango'),
        ]),
        Ville(id: 'cm_limbe', nom: 'Limbé', quartiers: [
          Quartier(id: 'q_lim_down_beach', nom: 'Down Beach'),
          Quartier(id: 'q_lim_new_layout', nom: 'New Layout'),
          Quartier(id: 'q_lim_bota', nom: 'Bota'),
          Quartier(id: 'q_lim_church_street', nom: 'Church Street'),
        ]),
        Ville(id: 'cm_kumba', nom: 'Kumba', quartiers: [
          Quartier(id: 'q_kba_fiango', nom: 'Fiango'),
          Quartier(id: 'q_kba_mbonge', nom: 'Mbonge Road'),
          Quartier(id: 'q_kba_central', nom: 'Central Market'),
        ]),
        Ville(id: 'cm_mamfe', nom: 'Mamfé', quartiers: [
          Quartier(id: 'q_mam_centre', nom: 'Centre'),
        ]),
      ]),

      // ── Nord ──
      Region(id: 'cm_nord', nom: 'Nord', villes: [
        Ville(id: 'cm_garoua', nom: 'Garoua', quartiers: [
          Quartier(id: 'q_gar_marche', nom: 'Grand Marché'),
          Quartier(id: 'q_gar_yelwa', nom: 'Yelwa'),
          Quartier(id: 'q_gar_plateau', nom: 'Plateau'),
          Quartier(id: 'q_gar_roumdé', nom: 'Roumdé-Adjia'),
          Quartier(id: 'q_gar_bibemi', nom: 'Bibemi'),
        ]),
        Ville(id: 'cm_guider', nom: 'Guider', quartiers: [
          Quartier(id: 'q_gui_centre', nom: 'Centre'),
        ]),
        Ville(id: 'cm_figuil', nom: 'Figuil', quartiers: [
          Quartier(id: 'q_fig_centre', nom: 'Centre'),
        ]),
      ]),

      // ── Extrême-Nord ──
      Region(id: 'cm_extreme_nord', nom: 'Extrême-Nord', villes: [
        Ville(id: 'cm_maroua', nom: 'Maroua', quartiers: [
          Quartier(id: 'q_mar_domayo', nom: 'Domayo'),
          Quartier(id: 'q_mar_hardé', nom: 'Hardé'),
          Quartier(id: 'q_mar_dougoi', nom: 'Dougoi'),
          Quartier(id: 'q_mar_palar', nom: 'Palar'),
          Quartier(id: 'q_mar_lopere', nom: 'Lopéré'),
        ]),
        Ville(id: 'cm_kousseri', nom: 'Kousseri', quartiers: [
          Quartier(id: 'q_kou_centre', nom: 'Centre'),
          Quartier(id: 'q_kou_marche', nom: 'Marché'),
        ]),
        Ville(id: 'cm_mokolo', nom: 'Mokolo', quartiers: [
          Quartier(id: 'q_mok_centre', nom: 'Centre'),
        ]),
      ]),

      // ── Adamaoua ──
      Region(id: 'cm_adamaoua', nom: 'Adamaoua', villes: [
        Ville(id: 'cm_ngaoundere', nom: 'Ngaoundéré', quartiers: [
          Quartier(id: 'q_nga_marche', nom: 'Grand Marché'),
          Quartier(id: 'q_nga_plateau', nom: 'Plateau'),
          Quartier(id: 'q_nga_joli_soir', nom: 'Joli Soir'),
          Quartier(id: 'q_nga_bamnyanga', nom: 'Bamnyanga'),
        ]),
        Ville(id: 'cm_meiganga', nom: 'Meiganga', quartiers: [
          Quartier(id: 'q_mei_centre', nom: 'Centre'),
        ]),
        Ville(id: 'cm_tibati', nom: 'Tibati', quartiers: [
          Quartier(id: 'q_tib_centre', nom: 'Centre'),
        ]),
      ]),

      // ── Est ──
      Region(id: 'cm_est', nom: 'Est', villes: [
        Ville(id: 'cm_bertoua', nom: 'Bertoua', quartiers: [
          Quartier(id: 'q_ber_haoussa', nom: 'Haoussa'),
          Quartier(id: 'q_ber_mokolo', nom: 'Mokolo'),
          Quartier(id: 'q_ber_nkolbikon', nom: 'Nkolbikon'),
          Quartier(id: 'q_ber_camp_haut', nom: 'Camp Haut'),
        ]),
        Ville(id: 'cm_batouri', nom: 'Batouri', quartiers: [
          Quartier(id: 'q_bat_centre', nom: 'Centre'),
        ]),
        Ville(id: 'cm_abong_mbang', nom: 'Abong-Mbang', quartiers: [
          Quartier(id: 'q_abo_centre', nom: 'Centre'),
        ]),
      ]),

      // ── Sud ──
      Region(id: 'cm_sud', nom: 'Sud', villes: [
        Ville(id: 'cm_ebolowa', nom: 'Ebolowa', quartiers: [
          Quartier(id: 'q_ebo_mvog_nna', nom: 'Mvog-Nna'),
          Quartier(id: 'q_ebo_centre', nom: 'Centre administratif'),
          Quartier(id: 'q_ebo_nko_foulou', nom: 'Nko\'o Foulou'),
        ]),
        Ville(id: 'cm_kribi', nom: 'Kribi', quartiers: [
          Quartier(id: 'q_kri_cite', nom: 'Cité'),
          Quartier(id: 'q_kri_beach', nom: 'Beach'),
          Quartier(id: 'q_kri_ngoye', nom: 'Ngoye'),
        ]),
        Ville(id: 'cm_sangmelima', nom: 'Sangmélima', quartiers: [
          Quartier(id: 'q_san_centre', nom: 'Centre'),
          Quartier(id: 'q_san_mvom', nom: 'Mvom'),
        ]),
        Ville(id: 'cm_ambam', nom: 'Ambam', quartiers: [
          Quartier(id: 'q_amb_centre', nom: 'Centre'),
        ]),
      ]),
    ],
  ),

  // ═══════════════════════════════════════════════════════
  // AFRIQUE — pays avec grandes villes
  // ═══════════════════════════════════════════════════════

  Pays(id: 'ng', nom: 'Nigeria', drapeau: '🇳🇬', regions: [
    Region(id: 'ng_lagos', nom: 'Lagos', villes: [
      Ville(id: 'ng_lagos_city', nom: 'Lagos', quartiers: [
        Quartier(id: 'ng_victoria', nom: 'Victoria Island'),
        Quartier(id: 'ng_lekki', nom: 'Lekki'),
        Quartier(id: 'ng_ikeja', nom: 'Ikeja'),
        Quartier(id: 'ng_surulere', nom: 'Surulere'),
      ]),
    ]),
    Region(id: 'ng_abuja', nom: 'FCT Abuja', villes: [
      Ville(id: 'ng_abuja_city', nom: 'Abuja', quartiers: [
        Quartier(id: 'ng_wuse', nom: 'Wuse'),
        Quartier(id: 'ng_garki', nom: 'Garki'),
        Quartier(id: 'ng_maitama', nom: 'Maitama'),
      ]),
    ]),
    Region(id: 'ng_kano', nom: 'Kano', villes: [
      Ville(id: 'ng_kano_city', nom: 'Kano', quartiers: []),
    ]),
    Region(id: 'ng_ph', nom: 'Rivers', villes: [
      Ville(id: 'ng_ph_city', nom: 'Port Harcourt', quartiers: []),
    ]),
  ]),

  Pays(id: 'gh', nom: 'Ghana', drapeau: '🇬🇭', regions: [
    Region(id: 'gh_greater_accra', nom: 'Greater Accra', villes: [
      Ville(id: 'gh_accra', nom: 'Accra', quartiers: [
        Quartier(id: 'gh_osu', nom: 'Osu'),
        Quartier(id: 'gh_cantonments', nom: 'Cantonments'),
        Quartier(id: 'gh_airport', nom: 'Airport Residential'),
      ]),
    ]),
    Region(id: 'gh_ashanti', nom: 'Ashanti', villes: [
      Ville(id: 'gh_kumasi', nom: 'Kumasi', quartiers: []),
    ]),
  ]),

  Pays(id: 'ci', nom: "Côte d'Ivoire", drapeau: '🇨🇮', regions: [
    Region(id: 'ci_abidjan', nom: 'Abidjan', villes: [
      Ville(id: 'ci_abidjan_city', nom: 'Abidjan', quartiers: [
        Quartier(id: 'ci_cocody', nom: 'Cocody'),
        Quartier(id: 'ci_yopougon', nom: 'Yopougon'),
        Quartier(id: 'ci_plateau', nom: 'Plateau'),
        Quartier(id: 'ci_marcory', nom: 'Marcory'),
        Quartier(id: 'ci_treichville', nom: 'Treichville'),
      ]),
    ]),
    Region(id: 'ci_yamoussoukro', nom: 'Yamoussoukro', villes: [
      Ville(id: 'ci_yamoussoukro_city', nom: 'Yamoussoukro', quartiers: []),
    ]),
  ]),

  Pays(id: 'sn', nom: 'Sénégal', drapeau: '🇸🇳', regions: [
    Region(id: 'sn_dakar', nom: 'Dakar', villes: [
      Ville(id: 'sn_dakar_city', nom: 'Dakar', quartiers: [
        Quartier(id: 'sn_plateau', nom: 'Plateau'),
        Quartier(id: 'sn_almadies', nom: 'Les Almadies'),
        Quartier(id: 'sn_yoff', nom: 'Yoff'),
        Quartier(id: 'sn_medina', nom: 'Médina'),
      ]),
    ]),
    Region(id: 'sn_saint_louis', nom: 'Saint-Louis', villes: [
      Ville(id: 'sn_saint_louis_city', nom: 'Saint-Louis', quartiers: []),
    ]),
  ]),

  Pays(id: 'cm_gabon', nom: 'Gabon', drapeau: '🇬🇦', regions: [
    Region(id: 'ga_estuaire', nom: 'Estuaire', villes: [
      Ville(id: 'ga_libreville', nom: 'Libreville', quartiers: [
        Quartier(id: 'ga_glass', nom: 'Glass'),
        Quartier(id: 'ga_louis', nom: 'Louis'),
        Quartier(id: 'ga_owendo', nom: 'Owendo'),
      ]),
    ]),
    Region(id: 'ga_haut_ogooue', nom: 'Haut-Ogooué', villes: [
      Ville(id: 'ga_franceville', nom: 'Franceville', quartiers: []),
    ]),
  ]),

  Pays(id: 'cg', nom: 'Congo', drapeau: '🇨🇬', regions: [
    Region(id: 'cg_brazzaville', nom: 'Brazzaville', villes: [
      Ville(id: 'cg_brazzaville_city', nom: 'Brazzaville', quartiers: [
        Quartier(id: 'cg_poto', nom: 'Poto-Poto'),
        Quartier(id: 'cg_bacongo', nom: 'Bacongo'),
        Quartier(id: 'cg_centre_ville', nom: 'Centre-ville'),
      ]),
    ]),
    Region(id: 'cg_pointe_noire', nom: 'Pointe-Noire', villes: [
      Ville(id: 'cg_pointe_noire_city', nom: 'Pointe-Noire', quartiers: []),
    ]),
  ]),

  Pays(id: 'cd', nom: 'RD Congo', drapeau: '🇨🇩', regions: [
    Region(id: 'cd_kinshasa', nom: 'Kinshasa', villes: [
      Ville(id: 'cd_kinshasa_city', nom: 'Kinshasa', quartiers: [
        Quartier(id: 'cd_gombe', nom: 'Gombe'),
        Quartier(id: 'cd_lingwala', nom: 'Lingwala'),
        Quartier(id: 'cd_kasa_vubu', nom: 'Kasa-Vubu'),
      ]),
    ]),
    Region(id: 'cd_lubumbashi', nom: 'Haut-Katanga', villes: [
      Ville(id: 'cd_lubumbashi_city', nom: 'Lubumbashi', quartiers: []),
    ]),
  ]),

  Pays(id: 'ma', nom: 'Maroc', drapeau: '🇲🇦', regions: [
    Region(id: 'ma_casablanca', nom: 'Casablanca-Settat', villes: [
      Ville(id: 'ma_casablanca_city', nom: 'Casablanca', quartiers: [
        Quartier(id: 'ma_ain_diab', nom: 'Aïn Diab'),
        Quartier(id: 'ma_maarif', nom: 'Maârif'),
        Quartier(id: 'ma_anfa', nom: 'Anfa'),
      ]),
    ]),
    Region(id: 'ma_rabat', nom: 'Rabat-Salé', villes: [
      Ville(id: 'ma_rabat_city', nom: 'Rabat', quartiers: []),
    ]),
    Region(id: 'ma_marrakech', nom: 'Marrakech-Safi', villes: [
      Ville(id: 'ma_marrakech_city', nom: 'Marrakech', quartiers: [
        Quartier(id: 'ma_medina', nom: 'Médina'),
        Quartier(id: 'ma_gueliz', nom: 'Guéliz'),
        Quartier(id: 'ma_hivernage', nom: 'Hivernage'),
      ]),
    ]),
  ]),

  Pays(id: 'tn', nom: 'Tunisie', drapeau: '🇹🇳', regions: [
    Region(id: 'tn_tunis', nom: 'Tunis', villes: [
      Ville(id: 'tn_tunis_city', nom: 'Tunis', quartiers: [
        Quartier(id: 'tn_lac', nom: 'Les Berges du Lac'),
        Quartier(id: 'tn_centre', nom: 'Centre-ville'),
      ]),
    ]),
    Region(id: 'tn_sfax', nom: 'Sfax', villes: [
      Ville(id: 'tn_sfax_city', nom: 'Sfax', quartiers: []),
    ]),
  ]),

  Pays(id: 'za', nom: 'Afrique du Sud', drapeau: '🇿🇦', regions: [
    Region(id: 'za_gauteng', nom: 'Gauteng', villes: [
      Ville(id: 'za_johannesburg', nom: 'Johannesburg', quartiers: [
        Quartier(id: 'za_sandton', nom: 'Sandton'),
        Quartier(id: 'za_soweto', nom: 'Soweto'),
        Quartier(id: 'za_rosebank', nom: 'Rosebank'),
      ]),
      Ville(id: 'za_pretoria', nom: 'Pretoria', quartiers: []),
    ]),
    Region(id: 'za_western_cape', nom: 'Western Cape', villes: [
      Ville(id: 'za_cape_town', nom: 'Le Cap', quartiers: [
        Quartier(id: 'za_sea_point', nom: 'Sea Point'),
        Quartier(id: 'za_green_point', nom: 'Green Point'),
        Quartier(id: 'za_camps_bay', nom: 'Camps Bay'),
      ]),
    ]),
  ]),

  Pays(id: 'ke', nom: 'Kenya', drapeau: '🇰🇪', regions: [
    Region(id: 'ke_nairobi', nom: 'Nairobi', villes: [
      Ville(id: 'ke_nairobi_city', nom: 'Nairobi', quartiers: [
        Quartier(id: 'ke_westlands', nom: 'Westlands'),
        Quartier(id: 'ke_cbd', nom: 'CBD'),
        Quartier(id: 'ke_karen', nom: 'Karen'),
      ]),
    ]),
    Region(id: 'ke_mombasa', nom: 'Mombasa', villes: [
      Ville(id: 'ke_mombasa_city', nom: 'Mombasa', quartiers: []),
    ]),
  ]),

  Pays(id: 'et', nom: 'Éthiopie', drapeau: '🇪🇹', regions: [
    Region(id: 'et_addis', nom: 'Addis-Abeba', villes: [
      Ville(id: 'et_addis_city', nom: 'Addis-Abeba', quartiers: []),
    ]),
  ]),

  Pays(id: 'tz', nom: 'Tanzanie', drapeau: '🇹🇿', regions: [
    Region(id: 'tz_dar', nom: 'Dar es Salaam', villes: [
      Ville(id: 'tz_dar_city', nom: 'Dar es Salaam', quartiers: []),
    ]),
  ]),

  Pays(id: 'ao', nom: 'Angola', drapeau: '🇦🇴', regions: [
    Region(id: 'ao_luanda', nom: 'Luanda', villes: [
      Ville(id: 'ao_luanda_city', nom: 'Luanda', quartiers: [
        Quartier(id: 'ao_ingombota', nom: 'Ingombota'),
        Quartier(id: 'ao_maianga', nom: 'Maianga'),
      ]),
    ]),
  ]),

  Pays(id: 'cm_togo', nom: 'Togo', drapeau: '🇹🇬', regions: [
    Region(id: 'tg_maritime', nom: 'Maritime', villes: [
      Ville(id: 'tg_lome', nom: 'Lomé', quartiers: [
        Quartier(id: 'tg_baguida', nom: 'Baguida'),
        Quartier(id: 'tg_adidogome', nom: 'Adidogomé'),
      ]),
    ]),
  ]),

  Pays(id: 'bj', nom: 'Bénin', drapeau: '🇧🇯', regions: [
    Region(id: 'bj_littoral', nom: 'Littoral', villes: [
      Ville(id: 'bj_cotonou', nom: 'Cotonou', quartiers: [
        Quartier(id: 'bj_cadjehoun', nom: 'Cadjehoun'),
        Quartier(id: 'bj_jonquet', nom: 'Jonquet'),
      ]),
    ]),
    Region(id: 'bj_oueme', nom: 'Ouémé', villes: [
      Ville(id: 'bj_porto_novo', nom: 'Porto-Novo', quartiers: []),
    ]),
  ]),

  Pays(id: 'cm_burkina', nom: 'Burkina Faso', drapeau: '🇧🇫', regions: [
    Region(id: 'bf_kadiogo', nom: 'Kadiogo', villes: [
      Ville(id: 'bf_ouagadougou', nom: 'Ouagadougou', quartiers: [
        Quartier(id: 'bf_wemtenga', nom: 'Wemtenga'),
        Quartier(id: 'bf_pissy', nom: 'Pissy'),
      ]),
    ]),
    Region(id: 'bf_hauts_bassins', nom: 'Hauts-Bassins', villes: [
      Ville(id: 'bf_bobo', nom: 'Bobo-Dioulasso', quartiers: []),
    ]),
  ]),

  Pays(id: 'ml', nom: 'Mali', drapeau: '🇲🇱', regions: [
    Region(id: 'ml_bamako', nom: 'Bamako', villes: [
      Ville(id: 'ml_bamako_city', nom: 'Bamako', quartiers: [
        Quartier(id: 'ml_badalabougou', nom: 'Badalabougou'),
        Quartier(id: 'ml_aci', nom: 'ACI 2000'),
      ]),
    ]),
  ]),

  // ═══════════════════════════════════════════════════════
  // EUROPE
  // ═══════════════════════════════════════════════════════

  Pays(id: 'fr', nom: 'France', drapeau: '🇫🇷', regions: [
    Region(id: 'fr_idf', nom: 'Île-de-France', villes: [
      Ville(id: 'fr_paris', nom: 'Paris', quartiers: [
        Quartier(id: 'fr_marais', nom: 'Le Marais'),
        Quartier(id: 'fr_montmartre', nom: 'Montmartre'),
        Quartier(id: 'fr_chatelet', nom: 'Châtelet'),
        Quartier(id: 'fr_saint_germain', nom: 'Saint-Germain-des-Prés'),
        Quartier(id: 'fr_belleville', nom: 'Belleville'),
        Quartier(id: 'fr_boulogne', nom: 'Boulogne-Billancourt'),
      ]),
    ]),
    Region(id: 'fr_paca', nom: "Provence-Alpes-Côte d'Azur", villes: [
      Ville(id: 'fr_marseille', nom: 'Marseille', quartiers: [
        Quartier(id: 'fr_vieux_port', nom: 'Vieux-Port'),
        Quartier(id: 'fr_prado', nom: 'Prado'),
      ]),
      Ville(id: 'fr_nice', nom: 'Nice', quartiers: []),
    ]),
    Region(id: 'fr_aura', nom: 'Auvergne-Rhône-Alpes', villes: [
      Ville(id: 'fr_lyon', nom: 'Lyon', quartiers: [
        Quartier(id: 'fr_presquile', nom: 'Presqu\'île'),
        Quartier(id: 'fr_croix_rousse', nom: 'Croix-Rousse'),
      ]),
    ]),
    Region(id: 'fr_nouvelle_aquitaine', nom: 'Nouvelle-Aquitaine', villes: [
      Ville(id: 'fr_bordeaux', nom: 'Bordeaux', quartiers: []),
    ]),
  ]),

  Pays(id: 'be', nom: 'Belgique', drapeau: '🇧🇪', regions: [
    Region(id: 'be_bruxelles', nom: 'Bruxelles', villes: [
      Ville(id: 'be_bruxelles_city', nom: 'Bruxelles', quartiers: [
        Quartier(id: 'be_ixelles', nom: 'Ixelles'),
        Quartier(id: 'be_saint_gilles', nom: 'Saint-Gilles'),
        Quartier(id: 'be_anderlecht', nom: 'Anderlecht'),
      ]),
    ]),
    Region(id: 'be_anvers', nom: 'Anvers', villes: [
      Ville(id: 'be_anvers_city', nom: 'Anvers', quartiers: []),
    ]),
  ]),

  Pays(id: 'ch', nom: 'Suisse', drapeau: '🇨🇭', regions: [
    Region(id: 'ch_geneve', nom: 'Genève', villes: [
      Ville(id: 'ch_geneve_city', nom: 'Genève', quartiers: [
        Quartier(id: 'ch_eaux_vives', nom: 'Eaux-Vives'),
        Quartier(id: 'ch_paquis', nom: 'Pâquis'),
      ]),
    ]),
    Region(id: 'ch_zurich', nom: 'Zurich', villes: [
      Ville(id: 'ch_zurich_city', nom: 'Zurich', quartiers: []),
    ]),
  ]),

  Pays(id: 'de', nom: 'Allemagne', drapeau: '🇩🇪', regions: [
    Region(id: 'de_berlin', nom: 'Berlin', villes: [
      Ville(id: 'de_berlin_city', nom: 'Berlin', quartiers: [
        Quartier(id: 'de_mitte', nom: 'Mitte'),
        Quartier(id: 'de_kreuzberg', nom: 'Kreuzberg'),
        Quartier(id: 'de_prenzlauer', nom: 'Prenzlauer Berg'),
      ]),
    ]),
    Region(id: 'de_baviere', nom: 'Bavière', villes: [
      Ville(id: 'de_munich', nom: 'Munich', quartiers: []),
    ]),
    Region(id: 'de_hamburg', nom: 'Hambourg', villes: [
      Ville(id: 'de_hamburg_city', nom: 'Hambourg', quartiers: []),
    ]),
  ]),

  Pays(id: 'es', nom: 'Espagne', drapeau: '🇪🇸', regions: [
    Region(id: 'es_madrid', nom: 'Madrid', villes: [
      Ville(id: 'es_madrid_city', nom: 'Madrid', quartiers: [
        Quartier(id: 'es_sol', nom: 'Sol'),
        Quartier(id: 'es_salamanca', nom: 'Salamanca'),
        Quartier(id: 'es_lavapies', nom: 'Lavapiés'),
      ]),
    ]),
    Region(id: 'es_cataluna', nom: 'Catalogne', villes: [
      Ville(id: 'es_barcelona', nom: 'Barcelone', quartiers: [
        Quartier(id: 'es_gothic', nom: 'Quartier Gothique'),
        Quartier(id: 'es_gracia', nom: 'Gràcia'),
      ]),
    ]),
  ]),

  Pays(id: 'it', nom: 'Italie', drapeau: '🇮🇹', regions: [
    Region(id: 'it_lazio', nom: 'Lazio', villes: [
      Ville(id: 'it_rome', nom: 'Rome', quartiers: [
        Quartier(id: 'it_trastevere', nom: 'Trastevere'),
        Quartier(id: 'it_prati', nom: 'Prati'),
      ]),
    ]),
    Region(id: 'it_lombardia', nom: 'Lombardie', villes: [
      Ville(id: 'it_milan', nom: 'Milan', quartiers: []),
    ]),
  ]),

  Pays(id: 'gb', nom: 'Royaume-Uni', drapeau: '🇬🇧', regions: [
    Region(id: 'gb_london', nom: 'Londres', villes: [
      Ville(id: 'gb_london_city', nom: 'Londres', quartiers: [
        Quartier(id: 'gb_soho', nom: 'Soho'),
        Quartier(id: 'gb_chelsea', nom: 'Chelsea'),
        Quartier(id: 'gb_shoreditch', nom: 'Shoreditch'),
        Quartier(id: 'gb_canary_wharf', nom: 'Canary Wharf'),
      ]),
    ]),
    Region(id: 'gb_scotland', nom: 'Écosse', villes: [
      Ville(id: 'gb_edinburgh', nom: 'Édimbourg', quartiers: []),
    ]),
  ]),

  Pays(id: 'pt', nom: 'Portugal', drapeau: '🇵🇹', regions: [
    Region(id: 'pt_lisbonne', nom: 'Lisboa', villes: [
      Ville(id: 'pt_lisbonne_city', nom: 'Lisbonne', quartiers: [
        Quartier(id: 'pt_alfama', nom: 'Alfama'),
        Quartier(id: 'pt_bairro_alto', nom: 'Bairro Alto'),
      ]),
    ]),
    Region(id: 'pt_porto', nom: 'Porto', villes: [
      Ville(id: 'pt_porto_city', nom: 'Porto', quartiers: []),
    ]),
  ]),

  Pays(id: 'nl', nom: 'Pays-Bas', drapeau: '🇳🇱', regions: [
    Region(id: 'nl_amsterdam', nom: 'Noord-Holland', villes: [
      Ville(id: 'nl_amsterdam_city', nom: 'Amsterdam', quartiers: [
        Quartier(id: 'nl_jordaan', nom: 'Jordaan'),
        Quartier(id: 'nl_de_pijp', nom: 'De Pijp'),
        Quartier(id: 'nl_red_light', nom: 'Red Light District'),
      ]),
    ]),
  ]),

  // ═══════════════════════════════════════════════════════
  // AMÉRIQUE
  // ═══════════════════════════════════════════════════════

  Pays(id: 'us', nom: 'États-Unis', drapeau: '🇺🇸', regions: [
    Region(id: 'us_ny', nom: 'New York', villes: [
      Ville(id: 'us_nyc', nom: 'New York City', quartiers: [
        Quartier(id: 'us_manhattan', nom: 'Manhattan'),
        Quartier(id: 'us_brooklyn', nom: 'Brooklyn'),
        Quartier(id: 'us_bronx', nom: 'Bronx'),
        Quartier(id: 'us_queens', nom: 'Queens'),
      ]),
    ]),
    Region(id: 'us_ca', nom: 'Californie', villes: [
      Ville(id: 'us_la', nom: 'Los Angeles', quartiers: [
        Quartier(id: 'us_hollywood', nom: 'Hollywood'),
        Quartier(id: 'us_beverly_hills', nom: 'Beverly Hills'),
        Quartier(id: 'us_venice', nom: 'Venice Beach'),
      ]),
      Ville(id: 'us_sf', nom: 'San Francisco', quartiers: []),
    ]),
    Region(id: 'us_fl', nom: 'Floride', villes: [
      Ville(id: 'us_miami', nom: 'Miami', quartiers: [
        Quartier(id: 'us_south_beach', nom: 'South Beach'),
        Quartier(id: 'us_downtown_miami', nom: 'Downtown'),
      ]),
    ]),
    Region(id: 'us_tx', nom: 'Texas', villes: [
      Ville(id: 'us_houston', nom: 'Houston', quartiers: []),
      Ville(id: 'us_dallas', nom: 'Dallas', quartiers: []),
    ]),
  ]),

  Pays(id: 'ca', nom: 'Canada', drapeau: '🇨🇦', regions: [
    Region(id: 'ca_ontario', nom: 'Ontario', villes: [
      Ville(id: 'ca_toronto', nom: 'Toronto', quartiers: [
        Quartier(id: 'ca_downtown', nom: 'Downtown'),
        Quartier(id: 'ca_yorkville', nom: 'Yorkville'),
      ]),
    ]),
    Region(id: 'ca_quebec', nom: 'Québec', villes: [
      Ville(id: 'ca_montreal', nom: 'Montréal', quartiers: [
        Quartier(id: 'ca_plateau', nom: 'Plateau-Mont-Royal'),
        Quartier(id: 'ca_vieux', nom: 'Vieux-Montréal'),
      ]),
    ]),
    Region(id: 'ca_bc', nom: 'Colombie-Britannique', villes: [
      Ville(id: 'ca_vancouver', nom: 'Vancouver', quartiers: []),
    ]),
  ]),

  Pays(id: 'br', nom: 'Brésil', drapeau: '🇧🇷', regions: [
    Region(id: 'br_rio', nom: 'Rio de Janeiro', villes: [
      Ville(id: 'br_rio_city', nom: 'Rio de Janeiro', quartiers: [
        Quartier(id: 'br_copacabana', nom: 'Copacabana'),
        Quartier(id: 'br_ipanema', nom: 'Ipanema'),
        Quartier(id: 'br_leblon', nom: 'Leblon'),
      ]),
    ]),
    Region(id: 'br_sao_paulo', nom: 'São Paulo', villes: [
      Ville(id: 'br_sao_paulo_city', nom: 'São Paulo', quartiers: [
        Quartier(id: 'br_jardins', nom: 'Jardins'),
        Quartier(id: 'br_vila_madalena', nom: 'Vila Madalena'),
      ]),
    ]),
  ]),

  Pays(id: 'mx', nom: 'Mexique', drapeau: '🇲🇽', regions: [
    Region(id: 'mx_cdmx', nom: 'Mexico (CDMX)', villes: [
      Ville(id: 'mx_cdmx_city', nom: 'Mexico', quartiers: [
        Quartier(id: 'mx_condesa', nom: 'La Condesa'),
        Quartier(id: 'mx_polanco', nom: 'Polanco'),
        Quartier(id: 'mx_roma', nom: 'Roma'),
      ]),
    ]),
    Region(id: 'mx_jalisco', nom: 'Jalisco', villes: [
      Ville(id: 'mx_guadalajara', nom: 'Guadalajara', quartiers: []),
    ]),
  ]),

  Pays(id: 'co', nom: 'Colombie', drapeau: '🇨🇴', regions: [
    Region(id: 'co_bogota', nom: 'Bogotá DC', villes: [
      Ville(id: 'co_bogota_city', nom: 'Bogotá', quartiers: [
        Quartier(id: 'co_usaquen', nom: 'Usaquén'),
        Quartier(id: 'co_chapinero', nom: 'Chapinero'),
      ]),
    ]),
    Region(id: 'co_antioquia', nom: 'Antioquia', villes: [
      Ville(id: 'co_medellin', nom: 'Medellín', quartiers: []),
    ]),
  ]),

  // ═══════════════════════════════════════════════════════
  // ASIE
  // ═══════════════════════════════════════════════════════

  Pays(id: 'th', nom: 'Thaïlande', drapeau: '🇹🇭', regions: [
    Region(id: 'th_bangkok', nom: 'Bangkok', villes: [
      Ville(id: 'th_bangkok_city', nom: 'Bangkok', quartiers: [
        Quartier(id: 'th_sukhumvit', nom: 'Sukhumvit'),
        Quartier(id: 'th_silom', nom: 'Silom'),
        Quartier(id: 'th_pattaya', nom: 'Pattaya'),
      ]),
    ]),
    Region(id: 'th_chiang_mai', nom: 'Chiang Mai', villes: [
      Ville(id: 'th_chiang_mai_city', nom: 'Chiang Mai', quartiers: []),
    ]),
  ]),

  Pays(id: 'ph', nom: 'Philippines', drapeau: '🇵🇭', regions: [
    Region(id: 'ph_manila', nom: 'Metro Manila', villes: [
      Ville(id: 'ph_manila_city', nom: 'Manila', quartiers: [
        Quartier(id: 'ph_makati', nom: 'Makati'),
        Quartier(id: 'ph_bgc', nom: 'BGC'),
        Quartier(id: 'ph_malate', nom: 'Malate'),
      ]),
    ]),
    Region(id: 'ph_cebu', nom: 'Cebu', villes: [
      Ville(id: 'ph_cebu_city', nom: 'Cebu City', quartiers: []),
    ]),
  ]),

  Pays(id: 'jp', nom: 'Japon', drapeau: '🇯🇵', regions: [
    Region(id: 'jp_tokyo', nom: 'Tokyo', villes: [
      Ville(id: 'jp_tokyo_city', nom: 'Tokyo', quartiers: [
        Quartier(id: 'jp_shinjuku', nom: 'Shinjuku'),
        Quartier(id: 'jp_shibuya', nom: 'Shibuya'),
        Quartier(id: 'jp_kabukicho', nom: 'Kabukicho'),
        Quartier(id: 'jp_roppongi', nom: 'Roppongi'),
      ]),
    ]),
    Region(id: 'jp_osaka', nom: 'Osaka', villes: [
      Ville(id: 'jp_osaka_city', nom: 'Osaka', quartiers: []),
    ]),
  ]),

  Pays(id: 'cn', nom: 'Chine', drapeau: '🇨🇳', regions: [
    Region(id: 'cn_shanghai', nom: 'Shanghai', villes: [
      Ville(id: 'cn_shanghai_city', nom: 'Shanghai', quartiers: [
        Quartier(id: 'cn_the_bund', nom: 'The Bund'),
        Quartier(id: 'cn_french_concession', nom: 'Concession française'),
      ]),
    ]),
    Region(id: 'cn_beijing', nom: 'Pékin', villes: [
      Ville(id: 'cn_beijing_city', nom: 'Pékin', quartiers: []),
    ]),
  ]),

  Pays(id: 'in', nom: 'Inde', drapeau: '🇮🇳', regions: [
    Region(id: 'in_maharashtra', nom: 'Maharashtra', villes: [
      Ville(id: 'in_mumbai', nom: 'Mumbai', quartiers: [
        Quartier(id: 'in_bandra', nom: 'Bandra'),
        Quartier(id: 'in_colaba', nom: 'Colaba'),
      ]),
    ]),
    Region(id: 'in_karnataka', nom: 'Karnataka', villes: [
      Ville(id: 'in_bangalore', nom: 'Bangalore', quartiers: []),
    ]),
    Region(id: 'in_delhi', nom: 'Delhi', villes: [
      Ville(id: 'in_delhi_city', nom: 'New Delhi', quartiers: []),
    ]),
  ]),

  Pays(id: 'sg', nom: 'Singapour', drapeau: '🇸🇬', regions: [
    Region(id: 'sg_main', nom: 'Singapour', villes: [
      Ville(id: 'sg_main_city', nom: 'Singapour', quartiers: [
        Quartier(id: 'sg_orchard', nom: 'Orchard'),
        Quartier(id: 'sg_marina', nom: 'Marina Bay'),
        Quartier(id: 'sg_chinatown', nom: 'Chinatown'),
      ]),
    ]),
  ]),

  Pays(id: 'ae', nom: 'Émirats Arabes Unis', drapeau: '🇦🇪', regions: [
    Region(id: 'ae_dubai', nom: 'Dubaï', villes: [
      Ville(id: 'ae_dubai_city', nom: 'Dubaï', quartiers: [
        Quartier(id: 'ae_jbr', nom: 'JBR'),
        Quartier(id: 'ae_downtown', nom: 'Downtown'),
        Quartier(id: 'ae_deira', nom: 'Deira'),
        Quartier(id: 'ae_marina', nom: 'Dubai Marina'),
      ]),
    ]),
    Region(id: 'ae_abu_dhabi', nom: 'Abu Dhabi', villes: [
      Ville(id: 'ae_abu_dhabi_city', nom: 'Abu Dhabi', quartiers: []),
    ]),
  ]),

  // ═══════════════════════════════════════════════════════
  // OCÉANIE
  // ═══════════════════════════════════════════════════════

  Pays(id: 'au', nom: 'Australie', drapeau: '🇦🇺', regions: [
    Region(id: 'au_nsw', nom: 'Nouvelle-Galles du Sud', villes: [
      Ville(id: 'au_sydney', nom: 'Sydney', quartiers: [
        Quartier(id: 'au_cbd', nom: 'CBD'),
        Quartier(id: 'au_kings_cross', nom: 'Kings Cross'),
        Quartier(id: 'au_bondi', nom: 'Bondi'),
      ]),
    ]),
    Region(id: 'au_victoria', nom: 'Victoria', villes: [
      Ville(id: 'au_melbourne', nom: 'Melbourne', quartiers: []),
    ]),
  ]),

  Pays(id: 'nz', nom: 'Nouvelle-Zélande', drapeau: '🇳🇿', regions: [
    Region(id: 'nz_auckland', nom: 'Auckland', villes: [
      Ville(id: 'nz_auckland_city', nom: 'Auckland', quartiers: []),
    ]),
  ]),
];