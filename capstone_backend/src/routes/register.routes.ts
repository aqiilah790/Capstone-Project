import { Router } from 'express';
import { register } from '../controllers/register.controller';
import { registerValidator } from '../validators/auth.validator';

export const router = Router();

router.post('/register', registerValidator, register);

export default router;
