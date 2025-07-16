import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getPengeluaranBulanan = async (req: Request, res: Response) => {
    try {
        const user = (req as any).user;
        const id_user = user?.id_user || user?.id;

        if (!id_user) {
            return res.status(401).json({ message: 'User tidak valid' });
        }

        const now = new Date();
        const bulanAwal = new Date(now.getFullYear(), now.getMonth(), 1);
        const bulanAkhir = new Date(now.getFullYear(), now.getMonth() + 1, 0);

        const hasil = await prisma.transaksi.groupBy({
            by: ['kategori_nama'],
            where: {
                id_user,
                kategori_nama: {
                    not: null, // pastikan kolom tidak null
                },
                tanggal_transaksi: {
                    gte: bulanAwal,
                    lte: bulanAkhir,
                },
            },
            _sum: {
                jumlah: true,
            },
        });

        const result = hasil.map((item) => ({
            kategori: item.kategori_nama,
            jumlah: Number(item._sum.jumlah ?? 0),
        }));

        return res.json(result);
    } catch (error) {
        console.error('Error getPengeluaranBulanan:', error);
        return res.status(500).json({ error: 'Gagal mengambil pengeluaran bulanan' });
    }
};
