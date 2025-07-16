import { Request, Response } from 'express';
import { validationResult } from 'express-validator';
import { registerMahasiswa } from '../services/auth.service';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'supersecret123';

export const register = async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    try {
        const user = await registerMahasiswa(req.body);

        const token = jwt.sign(
            { id: user.id_user, email: user.email },
            JWT_SECRET,
            { expiresIn: '1d' }
        );

        res.status(200).json({
            message: 'Pendaftaran berhasil',
            user,
            token,
        });
    } catch (error: any) {
        res.status(400).json({ error: error.message });
    }
};
