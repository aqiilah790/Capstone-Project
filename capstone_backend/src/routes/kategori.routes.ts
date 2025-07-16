// src/routes/kategori.routes.ts
import express from 'express';
import { getKategori } from '../controllers/kategori.controller';
import { verifyToken } from '../middlewares/verifytoken';

const router = express.Router();

// Mendapatkan semua kategori (dengan autentikasi)
router.get('/kategori', verifyToken, getKategori);

export default router;
