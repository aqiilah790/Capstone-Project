import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';
import { verifyHash } from '../utils/bcrypt';
import { AuthRequest } from '../middlewares/verifytoken';

export const prisma = new PrismaClient();
const SECRET = 'supersecret123';

export const loginUser = async (req: Request, res: Response) => {
    const { email, password } = req.body;

    try {
        const user = await prisma.user.findUnique({ where: { email } });

        if (!user) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        if (!user.password) {
            return res.status(500).json({ message: 'User tidak memiliki password yang valid' });
        }

        const isPasswordValid = await verifyHash(password, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({ message: 'Password salah' });
        }

        const token = jwt.sign({ id: user.id_user, email: user.email }, SECRET, { expiresIn: '1d' });

        return res.status(200).json({
            message: 'Login berhasil',
            token,
            data: {
                id_user: user.id_user,
                nama: user.nama,
                email: user.email,
                no_hp: user.no_hp,
                tanggal_daftar: user.tanggal_daftar,
            },
        });
    } catch (error) {
        console.error('Login error:', error);
        return res.status(500).json({ message: 'Terjadi kesalahan server' });
    }
};

export const getProfile = async (req: AuthRequest, res: Response) => {
    try {
        const id_user = req.user?.id;

        if (!id_user) {
            return res.status(401).json({ message: 'Tidak ada user dari token' });
        }

        const user = await prisma.user.findUnique({
            where: { id_user },
            select: {
                nama: true,
                email: true,
                no_hp: true,
                tanggal_daftar: true,
            },
        });

        if (!user) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        return res.json(user);
    } catch (error) {
        console.error('Gagal mengambil profil:', error);
        return res.status(500).json({ message: 'Gagal mengambil profil' });
    }
};

export const updateProfile = async (req: AuthRequest, res: Response) => {
    const id_user = req.user?.id;
    const { nama, email, no_hp } = req.body;

    if (!nama || !email || !no_hp) {
        return res.status(400).json({ message: 'Semua field wajib diisi' });
    }

    try {
        const updatedUser = await prisma.user.update({
            where: { id_user },
            data: {
                nama,
                email,
                no_hp,
            },
        });

        res.json({
            message: 'Profil berhasil diperbarui',
            user: {
                nama: updatedUser.nama,
                email: updatedUser.email,
                no_hp: updatedUser.no_hp,
            },
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Gagal memperbarui profil' });
    }
};

export const authenticateJWT = (req: Request, res: Response, next: Function) => {
    const authHeader = req.headers.authorization;
    if (!authHeader) return res.sendStatus(401);

    const token = authHeader.split(' ')[1];

    jwt.verify(token, SECRET, (err, user) => {
        if (err) return res.sendStatus(403);
        (req as any).user = user;
        next();
    });
};
