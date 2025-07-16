// routes/saldo.ts
// import express from 'express';
import express, { Request, Response } from 'express';
import { authenticateJWT } from '../controllers/auth.controller';
import { PrismaClient } from '@prisma/client';
import { verifyToken, AuthRequest } from '../middlewares/verifytoken';

const router = express.Router();
const prisma = new PrismaClient();

// Ambil saldo berdasarkan anggaran dan pengeluaran
router.get('/saldo', verifyToken, async (req: Request, res: Response) => {
    const id_user = (req as any).user.id;

    try {
        // 1. Total semua anggaran user
        const totalAnggaranResult = await prisma.anggaran.aggregate({
            _sum: { total_anggaran: true },
            where: { id_user },
        });

        const totalAnggaran = Number(totalAnggaranResult._sum.total_anggaran ?? 0);

        // 2. Total semua pengeluaran user
        const pengeluaranResult = await prisma.transaksi.aggregate({
            _sum: { jumlah: true },
            where: {
                id_user,
                kategori_relasi: {
                    tipe: 'pengeluaran'
                },
            },
        });

        const totalPengeluaran = Number(pengeluaranResult._sum.jumlah ?? 0);

        // 3. Hitung saldo
        const saldo = totalAnggaran - totalPengeluaran;

        res.json({
            total_anggaran: totalAnggaran,
            total_pengeluaran: totalPengeluaran,
            saldo,
            status: saldo < 0 ? 'Defisit' : 'Aman',
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Gagal mengambil data saldo' });
    }
});


router.post('/anggaran', verifyToken, async (req: AuthRequest, res: Response) => {
    const { total_anggaran, periode_mulai, periode_selesai } = req.body;

    if (!total_anggaran || !periode_mulai || !periode_selesai) {
        return res.status(400).json({ message: 'Semua field wajib diisi' });
    }

    try {
        const anggaran = await prisma.anggaran.create({
            data: {
                id_user: req.user!.id, // ✅ dari token
                total_anggaran: parseFloat(total_anggaran),
                periode_mulai: new Date(periode_mulai),
                periode_selesai: new Date(periode_selesai),
            },
        });

        res.status(201).json(anggaran);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Gagal menyimpan anggaran' });
    }
});


export default router;
