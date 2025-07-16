import jwt from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';

export interface AuthRequest extends Request {
    user?: {
        id: number;
        email: string;
        // tambahkan lainnya jika perlu
    };
}

export const verifyToken = (
    req: AuthRequest,
    res: Response,
    next: NextFunction
) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) return res.status(401).json({ message: 'Token tidak ditemukan' });

    jwt.verify(token, process.env.JWT_SECRET as string, (err, decoded) => {
        if (err) return res.status(403).json({ message: 'Token tidak valid' });

        req.user = decoded as { id: number; email: string };
        next();
    });
};
