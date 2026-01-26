import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'potato_timer_secret_key';

export interface AuthRequest extends Request {
  userId?: number;
}

export function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: '未授权，请先登录',
    });
  }

  const token = authHeader.substring(7);

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as { userId: number };
    (req as any).userId = decoded.userId;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Token无效或已过期',
    });
  }
}

// 可选认证中间件（不强制要求登录）
export function optionalAuthMiddleware(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    try {
      const decoded = jwt.verify(token, JWT_SECRET) as { userId: number };
      (req as any).userId = decoded.userId;
    } catch (error) {
      // Token无效，但不阻止请求
    }
  }
  next();
}


