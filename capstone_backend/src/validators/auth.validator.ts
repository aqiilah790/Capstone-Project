import { body } from 'express-validator';

export const registerValidator = [
    body('nama').notEmpty().withMessage('Nama wajib diisi'),
    body('email').isEmail().withMessage('Email tidak valid'),
    body('password').isLength({ min: 6 }).withMessage('Password minimal 6 karakter'),
    body('no_hp').notEmpty().withMessage('Nomor HP wajib diisi'),
];
