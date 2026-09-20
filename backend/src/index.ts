import express from 'express';
import cors from 'cors';
import path from 'path';
import { env } from './config/env';
import { errorHandler } from './middleware/errorHandler';
import { generalLimiter } from './middleware/rateLimiter';

// Route imports
import authRoutes from './routes/auth';
import foodRoutes from './routes/food';
import dashboardRoutes from './routes/dashboard';
import userRoutes from './routes/user';

const app = express();

// ─── Global Middleware ──────────────────────────────────────────────────

// CORS — allow Flutter app to connect
app.use(
  cors({
    origin: '*', // In production, restrict to your domain
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    maxAge: 86400,
  })
);

// Parse JSON and URL-encoded bodies
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// General rate limiter
app.use(generalLimiter);

// Serve uploaded images as static files
app.use('/uploads', express.static(path.resolve(env.UPLOAD_DIR)));

// ─── Health Check ───────────────────────────────────────────────────────

app.get('/api/health', (_req, res) => {
  res.json({
    success: true,
    message: 'NutriTrack API is running',
    timestamp: new Date().toISOString(),
  });
});

// ─── API Routes ─────────────────────────────────────────────────────────

app.use('/api/auth', authRoutes);
app.use('/api/food', foodRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/user', userRoutes);

// ─── 404 Handler ────────────────────────────────────────────────────────

app.use((_req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found.',
  });
});

// ─── Global Error Handler ───────────────────────────────────────────────

app.use(errorHandler);

// ─── Start Server ───────────────────────────────────────────────────────

const PORT = parseInt(env.PORT, 10);

app.listen(PORT, () => {
  console.log(`\n🚀 NutriTrack API server running on http://localhost:${PORT}`);
  console.log(`📋 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🔧 Environment: ${env.NODE_ENV}\n`);
});

export default app;
