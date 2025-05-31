import express from 'express';
import audioRoutes from './routes/audio.routes';
import etablissementRoutes from './routes/etablissement.routes';
import cors from 'cors';

const app = express();

// Autorise la détection du proxy
app.set('trust proxy', true); // 1 = 1er niveau de proxy, souvent suffisant sur un mutualisé

// Utilisation du port provenant de l'environnement sinon 3000 par défaut
const PORT = process.env.PORT || 5100;

// CORS avec toutes les origines autorisées (pour dev uniquement, à adapter en prod)
app.use(cors({
  origin: "*",
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type']
}));

// app.use((req, res, next) => {
//   if (!req.secure) {
//     return res.redirect('https://' + req.headers.host + req.url);
//   }
//   next();
// });


app.use(express.json());

// Routes
app.use('/api', audioRoutes);
app.use('/api', etablissementRoutes);
// Démarre le serveur
app.listen(PORT, () => {
  console.log(`Serveur en écoute sur le port ${PORT}`);
});
