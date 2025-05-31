export default interface EtablissementsResponse {
    docs: EtablissementDoc[];
  }
  
  interface EtablissementDoc {
    _version: number;
    found: boolean;
    _source: EtablissementSource;
    _type: string;
    _id: string;
  }
  
  interface EtablissementSource {
    Slug: string;
    _id: string;
    t_l_phone_text: string;
    ville_text: string;
    pays_option_os_pays: string;
    adresse_email_text: string;
    slug_text: string;
    direction_text?: string; // Optionnel car pas présent dans tous les documents
    code_text: string;
    description_courte_text: string;
    type_option_os_type_d__tablissement: string;
    ModifiedDate?: number; // Optionnel car parfois nommé "Modified Date"
    "Modified Date"?: number; // Variante avec espace
    ann_e_de_cr_ation_number: number;
    CreatedDate?: number; // Optionnel car parfois nommé "Created Date"
    "Created Date"?: number; // Variante avec espace
    adresse_text: string;
    description_d_taill_e_text: string;
    CreatedBy?: string; // Optionnel car parfois nommé "Created By"
    "Created By"?: string; // Variante avec espace
    site_web_text: string;
    id_esseyi_number: number;
    nom1_text: string;
    _version: number;
    _type: string;
    code_postal_text?: string; // Optionnel
    r_gion_text?: string; // Optionnel
    // adresse_email_text?: string; // Optionnel (déjà défini plus haut)
  }
  
  // Vous pourriez aussi définir des types pour les valeurs enumérées
  export  type TypeEtablissement = "priv_" | "public";
  // type Pays = "togo" | "b_nin" | "maroc" | "sierra_leone" | "zambie" | "kenya" | "zimbabwe" | "burundi";
  // etc. pour les autres champs qui ont des valeurs prédéfinies