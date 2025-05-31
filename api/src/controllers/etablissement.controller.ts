import { Request, Response } from 'express';
import { getAllEtablissements } from '../services/etablissement.service';

export const fetchEtablissements = async (req: Request, res: Response) => {
  try {

    console.log("Payload envoyé :", JSON.stringify(req.body, null, 2));


    const data = await getAllEtablissements(req.body);
    res.json(data);
  }  catch (error: any) {
    console.error("Erreur fetchEtablissements:", error);
    res.status(500).json({
      message: 'Erreur serveur',
      error: error?.message || 'Erreur inconnue',
      stack: error?.stack || null
    });
  }
  
};


// export const fetchEtablissements = async (req: Request, res: Response): Promise<Response> => {
//     try {
//       const { search, msearch, mget } = req.body;
  
//       if (!search || !msearch || !mget) {
//         return res.status(400).json({
//           message: 'Le body doit contenir les objets search, msearch et mget',
//           example: {
//             search: { endpoint: 'search', body: {} },
//             msearch: { endpoint: 'msearch', body: {} },
//             mget: { endpoint: 'mget', body: {} }
//           }
//         });
//       }
  
//       const data = await getAllEtablissements({ search, msearch, mget });
//       return res.json(data); // ✅ return bien un Response
  
//     } catch (error: any) {
//       console.error("Erreur fetchEtablissements:", error);
//       return res.status(500).json({
//         message: 'Erreur serveur',
//         error: error.message,
//         stack: error.stack
//       });
//     }
//   };
  
