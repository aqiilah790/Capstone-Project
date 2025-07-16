import { PrismaClient } from '@prisma/client';
import { hashing } from '../utils/bcrypt';

const prisma = new PrismaClient();

export const registerMahasiswa = async (data: {
    nama: string;
    email: string;
    password: string;
    no_hp: string;
}) => {
    const existing = await prisma.user.findUnique({
        where: { email: data.email },
    });

    if (existing) {
        throw new Error('Email sudah digunakan');
    }

    const hashedPassword = await hashing(data.password);

    const mahasiswa = await prisma.user.create({
        data: {
            nama: data.nama,
            email: data.email,
            password: hashedPassword,
            no_hp: data.no_hp,
        },
    });

    return mahasiswa;
};
