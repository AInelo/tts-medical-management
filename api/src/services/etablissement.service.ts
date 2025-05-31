import axios from 'axios';
import SearchResponse from "../types/search";

import { Etablissement, PostObjetDataType, UniqueResquest } from '../types/etablissement.type';

import ApiResponse from '../types/msearch.type';

import EtablissementsResponse from '../types/mget.type';

const baseURL = 'https://www.esseyi.com/elasticsearch';

type ResponseData = SearchResponse | ApiResponse | EtablissementsResponse;

const extract = (data: ResponseData): Etablissement[] => {
  
    // Cas 1 : SearchResponse (single search)
  
  if ('hits' in data && Array.isArray(data.hits.hits)) {
    return data.hits.hits.map((hit: any) => {
      const s = hit._source || {};
      return {
        name: s.nom1_text || '',
        email: s.adresse_email_text || '',
        phone: s.t_l_phone_text || '',
        country: s.pays_option_os_pays || '',
        website: s.site_web_text || ''
      };
    });
  }

  
  // // Cas 3 : EtablissementsResponse (mget)
  // if ('docs' in data && Array.isArray(data.docs)) {
  //   return data.docs.map((doc: any) => {
  //     const s = doc._source || {};
  //     return {
  //       name: s.nom1_text || '',
  //       email: s.adresse_email_text || '',
  //       phone: s.t_l_phone_text || '',
  //       country: s.pays_option_os_pays || '',
  //       website: s.site_web_text || ''
  //     };
  //   });
  // }


  // Cas 2 : ApiResponse (msearch)

  if ('responses' in data && Array.isArray(data.responses)) {
    return data.responses.flatMap(resp => {
      return resp.hits?.hits?.map(hit => {
        const source = hit._source as {
          nom1_text?: string,
          adresse_email_text?: string,
          t_l_phone_text?: string,
          pays_option_os_pays?: string,
          site_web_text?: string
        } || {}
  
        return {
          name: source.nom1_text || "",
          email: source.adresse_email_text || "",
          phone: source.t_l_phone_text || "",
          country: source.pays_option_os_pays || "",
          website: source.site_web_text || ""
        }
      }) || []
    })
  }
   
  return [];
};

export const getAllEtablissements = async (payload: PostObjetDataType[]) => {
  const all: Etablissement[] = [];

  const fetchFromEsseyi = async (request: UniqueResquest): Promise<Etablissement[]> => {
    const res = await axios.post(`${baseURL}/${request.endpoint}`, request.body_element, {
      headers: { 'Content-Type': 'application/json' }
    });
    return extract(res.data);
  };

  for (const request of payload) {
    // console.log("Payload envoyé :", JSON.stringify(request, null, 2));
    all.push(...await fetchFromEsseyi(request));
  }

  // Remove duplicates by name
  const seen = new Map<string, any>();
  for (const e of all) {
    if (!seen.has(e.name)) {
      const key = `${e.name}-${e.email}-${e.country}`;
      if (!seen.has(key)) {
        seen.set(key, e);
      }
    }
  }

  // return Array.from(seen.values());
  return Array.from(seen.values())
};
