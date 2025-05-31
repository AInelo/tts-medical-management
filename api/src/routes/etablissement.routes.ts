import { Router } from 'express';
import { fetchEtablissements } from '../controllers/etablissement.controller';
import { wrapController } from '../middlewares/wrapController';

const router = Router();
router.post('/etablissements',fetchEtablissements );

export default router;
