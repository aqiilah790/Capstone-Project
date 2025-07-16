import { compare, hash } from 'bcryptjs';

const saltRounds = 10;

export async function hashing(password: string): Promise<string | null> {
    try {
        const hashed = await hash(password, saltRounds); // ✅ pakai await
        return hashed;
    } catch (error: any) {
        console.log(`Gagal hashing password: ${error.message}`);
        return null;
    }
}

export async function verifyHash(inputPassword: string, storedPassword: string): Promise<boolean> {
    try {
        return await compare(inputPassword, storedPassword);
    } catch (error: any) {
        console.log(`Gagal verifikasi password: ${error.message}`);
        return false;
    }
}
