import express from 'express';
import { getPengeluaranBulanan } from '../controllers/anggaran.controller';
import { tambahTransaksi } from '../controllers/transaksi.controller';
import { getTransaksi } from '../controllers/transaksi.controller';
import {verifyToken} from '../middlewares/verifytoken';

const router = express.Router();

router.get('/pengeluaran-bulanan', verifyToken, getPengeluaranBulanan);
router.post('/transaksi', verifyToken, tambahTransaksi);
router.get('/get-transaksi', verifyToken, getTransaksi);

export default router;
