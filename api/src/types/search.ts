export default interface SearchResponse {
    hits: {
      hits: Hit[];
      total?: {
        value: number;
        relation: string;
      };
    };
    extras: string[];
    at_end: boolean;
    search_version: number;
  }
  
export  interface Hit {
    _version?: number;
    found?: boolean;
    _source: CursusSource;
    _type: string;
    _id: string;
  }
  
export  interface CursusSource {
  id_esseyi_number: number;
  slug_text: string;
  Slug: string;
  nom1_text: string;
  pays_option_os_pays: string;
  "Modified Date": number;
  type_option_os_type_d__tablissement: string;
  "Created By": string;
  "Created Date": number;
  t_l_phone_text: string;
  ville_text: string;
  _id: string;
  description_d_taill_e_text: string;
  code_text: string;
  adresse_text: string;
  site_web_text: string;
  r_gion_text: string;
  description_courte_text: string;
  _version: number;
  _type: string;

    // favori_par_list_user: string[];
    // cat_gorie_option_os_cat_gorie: string;
    // langue_option_os_langue: string;
    // crit_res_d_admission_text: string;
    // description_courte_text: string;
    // "Created By": string;
    // programme_text: string;
    // email_text: string;
    // site_web_text: string;
    // dipl_me_option_os_diplome: string;
    // Slug: string;
    // cat_gorie_e_text: string;
    // mode_option_os_mode: string;
    // pays_option_os_pays: string;
    // etablissement1_custom_etablissements: string;
    // "Modified Date": number;
    // etablissement_text: string;
    // identifiant_number: number;
    // id_esseyi_number: number;
    // "Created Date": number;
    // slug1_text: string;
    // t_l_phone_text: string;
    // _id: string;
    // cursus_text: string;
    // dur_e__mois__number: number;
    // _version: number;
    // _type: string;
    // // Champs optionnels qui peuvent apparaître dans d'autres hits
    // niveau_de_sortie_option_os_admission0?: string;
    // type_cursus_option_os_type_de_cursus?: string;
    // frais_de_scolarit__par_ann_e_number?: number;
    // frais_de_dossier_number?: number;
    // admission_option_os_admission?: string;
    // statut_option_os_statut_de_candidature?: string;
  }
  
  // Vous pourriez aussi définir des types pour les valeurs enumérées
export  type DiplomeType = "licence" | "baccalaur_at" | "master" | "doctorat";
export  type ModeEnseignement = "pr_sentiel" | "en_ligne" | "hybride";
export  type Langue = "fran_ais" | "anglais" | "bilingue";
  // etc. pour les autres champs qui ont des valeurs prédéfinies

