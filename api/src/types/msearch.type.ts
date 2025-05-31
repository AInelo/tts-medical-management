export default interface ApiResponse {
    responses: ResponseItem[];
  }
  
  interface ResponseItem {
    hits: Hits;
    extras: string[];
    at_end: boolean;
    search_version: number;
  }
  
  interface Hits {
    hits: HitItem[];
    total?: number; // Optionnel car présent seulement dans le premier objet
  }
  
  interface HitItem {
    _version?: number;
    found?: boolean;
    _source?: Source;
    _type?: string;
    _id?: string;
  }
  
  interface Source {

    statut_inscription_ecole_option_os_statut_inscription_ecole: string;
    nom1_text: string;
    adresse_email_text: string;
    t_l_phone_text: string;
    "Created By": string;
    "Created Date": number;
    "Modified Date": number;
    pays_option_os_pays: string;
    _id: string;
    _version: number;
    _type: string;


    // niveau_de_sortie_option_os_admission0: string;
    // site_web_text: string;
    // type_cursus_option_os_type_de_cursus: string;
    // "Created By": string;
    // frais_de_scolarit__par_ann_e_number: number;
    // etablissement_text: string;
    // favori_par_list_user: string[];
    // cat_gorie_e_text: string;
    // etablissement1_custom_etablissements: string;
    // crit_res_d_admission_text: string;
    // programme_text: string;
    // email_text: string;
    // statut_option_os_statut_de_candidature: string;
    // mode_option_os_mode: string;
    // "Created Date": number;
    // slug1_text: string;
    // cursus_text: string;
    // frais_de_dossier_number: number;
    // cat_gorie_option_os_cat_gorie: string;
    // _id: string;
    // dipl_me_option_os_diplome: string;
    // t_l_phone_text: string;
    // identifiant_number: number;
    // dur_e__mois__number: number;
    // admission_option_os_admission: string;
    // id_esseyi_number: number;
    // pays_option_os_pays: string;
    // Slug: string;
    // "Modified Date": number;
    // description_courte_text: string;
    // langue_option_os_langue: string;
    // _version: number;
    // _type: string;
  }
