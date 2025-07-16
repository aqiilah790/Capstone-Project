// src/controllers/kategori.controller.ts
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getKategori = async (req: Request, res: Response) => {
    try {
        const kategoriList = await prisma.kategori.findMany({
            orderBy: { id_kategori: 'asc' },
        });

        res.status(200).json(kategoriList);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Gagal mengambil data kategori' });
    }
};
