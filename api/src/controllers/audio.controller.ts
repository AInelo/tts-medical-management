import { Request, Response } from 'express';
import path from 'path';
import fs from 'fs';
import multer from 'multer';

// Configuration de multer (stockage en mémoire ou temporaire, selon le besoin)
const storage = multer.memoryStorage();
export const uploadMiddleware = multer({ storage }).single('file'); // 'file' doit correspondre au nom du champ FormData

// Type de la requête avec fichier + champ texte
interface AudioUploadFormFields {
  corpus_id: string;
}

export const uploadAudio = async (req: Request<{}, {}, AudioUploadFormFields> & { file?: Express.Multer.File }, res: Response) => {
  try {
    const { corpus_id } = req.body;
    const file = req.file;

    if (!corpus_id || !file) {
      return res.status(400).json({
        success: false,
        error: 'Champs manquants (corpus_id ou fichier).',
      });
    }

    const uploadDir = path.join(__dirname, '..', '..', 'all-audio', String(corpus_id));
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

    const extension = path.extname(file.originalname) || '.wav';
    const safeFileName = `${Date.now()}-${Math.random().toString(36).substring(2, 10)}${extension}`;
    const filePath = path.join(uploadDir, safeFileName);

    fs.writeFileSync(filePath, file.buffer);

    return res.status(200).json({
      success: true,
      message: '✅ Audio reçu et sauvegardé avec succès.',
      path: filePath,
    });
  } catch (error) {
    console.error('Erreur upload FormData :', error);
    return res.status(500).json({
      success: false,
      error: 'Erreur interne du serveur',
    });
  }
};
