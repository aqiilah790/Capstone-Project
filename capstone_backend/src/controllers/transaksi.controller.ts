import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthRequest } from '../middlewares/verifytoken';

const prisma = new PrismaClient();


export const getTransaksi = async (req: AuthRequest, res: Response) => {
    const id_user = req.user?.id;
    const { bulan, jenis } = req.query;

    try {
        const whereClause: any = { id_user };

        if (bulan && typeof bulan === 'string') {
            const startDate = new Date(`${bulan}-01T00:00:00`);
            const endDate = new Date(startDate);
            endDate.setMonth(endDate.getMonth() + 1);

            whereClause.tanggal_transaksi = {
                gte: startDate,
                lt: endDate,
            };
        }

        if (jenis && typeof jenis === 'string') {
            whereClause.kategori_relasi = { tipe: jenis };
        }

        const transaksi = await prisma.transaksi.findMany({
            where: whereClause,
            include: { kategori_relasi: true },
            orderBy: { tanggal_transaksi: 'desc' },
        });

        // Format tanggal ke 'YYYY-MM-DD'
        const formatted = transaksi.map((item) => ({
            ...item,
            tanggal_transaksi: item.tanggal_transaksi.toISOString().split('T')[0],
        }));

        res.json(formatted);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Gagal memuat transaksi' });
    }
};



export const tambahTransaksi = async (req: AuthRequest, res: Response) => {
    try {
        const { id_kategori, jumlah, tanggal_transaksi, keterangan } = req.body;
        const id_user = req.user?.id;

        // Validasi data
        if (!id_user) {
            return res.status(401).json({ message: 'User tidak terautentikasi' });
        }

        if (!id_kategori || !jumlah || !tanggal_transaksi) {
            return res.status(400).json({ message: 'Semua field wajib diisi' });
        }

        // Validasi kategori
        const kategori = await prisma.kategori.findUnique({
            where: { id_kategori: Number(id_kategori) },
        });

        if (!kategori) {
            return res.status(404).json({ message: 'Kategori tidak ditemukan' });
        }

        // Simpan transaksi
        const transaksi = await prisma.transaksi.create({
            data: {
                id_user: id_user,
                id_kategori: Number(id_kategori),
                kategori_nama: kategori.nama_kategori,
                jumlah: parseFloat(jumlah),
                tanggal_transaksi: new Date(tanggal_transaksi),
                keterangan: keterangan || null,
            },
        });

        return res.status(201).json(transaksi);
    } catch (error) {
        console.error('Gagal tambah transaksi:', error);
        return res.status(500).json({ message: 'Gagal menambahkan transaksi' });
    }
};
