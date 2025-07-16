// routes/apriori.ts
import express, { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { verifyToken } from '../middlewares/verifytoken';

const router = express.Router();
const prisma = new PrismaClient();

// Terima dan simpan hasil Apriori
router.post('/simpan-hasil-apriori', async (req, res) => {
    const { id_user, rules } = req.body;

    try {
        const inserted = [];

        for (const rule of rules) {
            const existing = await prisma.hasil_apriori.findFirst({
                where: {
                    id_user: id_user,
                    rule: rule.rule,
                    rekomendasi: rule.rekomendasi
                }
            });

            if (!existing) {
                const result = await prisma.hasil_apriori.create({
                    data: {
                        id_user: id_user,
                        rule: rule.rule,
                        support: rule.support,
                        confidence: rule.confidence,
                        lift: rule.lift,
                        rekomendasi: rule.rekomendasi
                    }
                });
                inserted.push(result);
            }
        }

        res.json({ message: 'Berhasil disimpan', insertedCount: inserted.length });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Gagal menyimpan hasil apriori' });
    }
});

// routes/hasilApriori.route.ts
router.get('/hasil-apriori', verifyToken, async (req: Request, res: Response) => {
    const id_user = (req as any).user.id;

    try {
        // Hitung jumlah transaksi user
        const jumlahTransaksi = await prisma.transaksi.count({
            where: { id_user },
        });

        if (jumlahTransaksi < 10) {
            return res.status(200).json({
                message: 'Belum cukup transaksi untuk analisis Apriori',
                min_required: 10,
                current: jumlahTransaksi,
                data: [],
            });
        }

        // Jika transaksi mencukupi, ambil hasil apriori
        const results = await prisma.hasil_apriori.findMany({
            where: { id_user },
            orderBy: { waktu_dibuat: 'desc' },
            take: 50, // batasi hasil jika perlu
        });

        return res.status(200).json({
            message: 'Berhasil memuat data',
            data: results,
        });
    } catch (error) {
        console.error('[GET /hasil-apriori]', error);
        return res.status(500).json({ error: 'Gagal memuat data hasil Apriori' });
    }
});



export default router;
