import express from 'express';
import audioRoutes from './routes/audio.routes';
import etablissementRoutes from './routes/etablissement.routes';
import cors from 'cors';

const app = express();

// Autorise la détection du proxy
app.set('trust proxy', true);

// Utilisation du port provenant de l'environnement sinon 5100 par défaut
const PORT = process.env.PORT || 5100;

// Configuration CORS appropriée
const corsOptions = {
  origin: function (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) {
    // Autoriser les requêtes sans origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    
    // Liste des origines autorisées
    const allowedOrigins = [
      'http://localhost:3000',
      'http://localhost:5173',
      'http://localhost:5174',
      'https://localhost:3000',
      'https://localhost:5173',
      'https://localhost:5174',
      // Ajoutez ici vos domaines de production
      'https://collection.urmaphalab.com',
      'http://collection.urmaphalab.com'
    ];
    
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      // En développement, on peut être plus permissif
      if (process.env.NODE_ENV === 'development') {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type', 
    'Authorization', 
    'X-Requested-With',
    'Accept',
    'Origin'
  ],
  credentials: true, // Si vous avez besoin de cookies/auth
  optionsSuccessStatus: 200 // Pour supporter les anciens navigateurs
};

app.use(cors(corsOptions));

// Middleware pour parser le JSON
app.use(express.json({ limit: '10mb' })); // Augmenté pour les fichiers audio
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Routes de test et de santé
app.get('/', (req, res) => {
  res.json({
    message: '🚀 TTS Medical API is running!',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    port: PORT
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    version: process.version
  });
});

app.get('/api/test', (req, res) => {
  res.json({
    message: '✅ API endpoints are working!',
    routes: [
      'GET /',
      'GET /health',
      'GET /api/test',
      'GET /api/audio/* (your audio routes)',
      'GET /api/etablissement/* (your etablissement routes)'
    ],
    timestamp: new Date().toISOString(),
    cors: 'Configured properly'
  });
});

// Routes principales
app.use('/api', audioRoutes);
app.use('/api', etablissementRoutes);

// Route catch-all pour les 404
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl,
    method: req.method,
    timestamp: new Date().toISOString()
  });
});

// Error handler
app.use((error: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Error:', error);
  res.status(500).json({
    error: 'Internal server error',
    message: error.message,
    timestamp: new Date().toISOString()
  });
});

// Démarre le serveur
app.listen(PORT, () => {
  console.log(`🚀 Serveur TTS Medical API en écoute sur le port ${PORT}`);
  console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  console.log(`🧪 Test route: http://localhost:${PORT}/api/test`);
});