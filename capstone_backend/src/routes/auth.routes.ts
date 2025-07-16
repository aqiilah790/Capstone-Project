import { Router } from 'express';
import { loginUser } from '../controllers/auth.controller';
import { getProfile } from '../controllers/auth.controller';
import { updateProfile } from '../controllers/auth.controller';
import { verifyToken } from '../middlewares/verifytoken';

export const authRouter = Router();

authRouter.post('/login', loginUser);
authRouter.get('/profile', verifyToken, getProfile);
authRouter.put('/profile', verifyToken, updateProfile);

