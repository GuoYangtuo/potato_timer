import { Router, Request, Response } from 'express';
import { query, insert } from '../database/db';
import { getMobileByToken } from '../aliyun';
import jwt from 'jsonwebtoken';

const router = Router();

const ALIYUN_ACCESS_KEY_ID = process.env.ALIYUN_ACCESS_KEY_ID || '';
const ALIYUN_ACCESS_KEY_SECRET = process.env.ALIYUN_ACCESS_KEY_SECRET || '';
const JWT_SECRET = process.env.JWT_SECRET || 'potato_timer_secret_key';

interface User {
  id: number;
  phone_number: string;
  nickname: string | null;
  avatar_url: string | null;
}

// 一键登录
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: '缺少必要的参数：token',
      });
    }

    if (!ALIYUN_ACCESS_KEY_ID || !ALIYUN_ACCESS_KEY_SECRET) {
      return res.status(500).json({
        success: false,
        message: '服务器配置错误：未配置阿里云AccessKey',
      });
    }

    // 获取手机号
    let phoneNumber: string;
    try {
      phoneNumber = await getMobileByToken(
        token,
        ALIYUN_ACCESS_KEY_ID,
        ALIYUN_ACCESS_KEY_SECRET
      );
    } catch (error) {
      console.error('调用阿里云GetMobile接口失败:', error);
      return res.status(500).json({
        success: false,
        message: '获取手机号失败',
        error: error instanceof Error ? error.message : '未知错误',
      });
    }

    // 查找或创建用户
    const existingUsers = await query<User[]>(
      'SELECT * FROM users WHERE phone_number = ?',
      [phoneNumber]
    );

    let userId: number;
    let user: User;

    if (existingUsers.length > 0) {
      // 用户已存在
      user = existingUsers[0];
      userId = user.id;
    } else {
      // 创建新用户
      const defaultNickname = `用户${phoneNumber.slice(-4)}`;
      userId = await insert(
        'INSERT INTO users (phone_number, nickname) VALUES (?, ?)',
        [phoneNumber, defaultNickname]
      );
      user = {
        id: userId,
        phone_number: phoneNumber,
        nickname: defaultNickname,
        avatar_url: null,
      };
    }

    // 生成JWT token
    const jwtToken = jwt.sign(
      { userId, phoneNumber },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      message: '登录成功',
      data: {
        token: jwtToken,
        user: {
          id: user.id,
          phoneNumber: user.phone_number,
          nickname: user.nickname,
          avatarUrl: user.avatar_url,
        },
      },
    });
  } catch (error) {
    console.error('登录处理错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
      error: error instanceof Error ? error.message : '未知错误',
    });
  }
});

// 手机号直接登录（仅用于开发/测试环境）
router.post('/login-phone', async (req: Request, res: Response) => {
  try {
    const { phoneNumber } = req.body;

    if (!phoneNumber) {
      return res.status(400).json({
        success: false,
        message: '缺少必要的参数：phoneNumber',
      });
    }

    // 简单的手机号格式验证
    if (!/^1[3-9]\d{9}$/.test(phoneNumber)) {
      return res.status(400).json({
        success: false,
        message: '手机号格式不正确',
      });
    }

    // 查找或创建用户
    const existingUsers = await query<User[]>(
      'SELECT * FROM users WHERE phone_number = ?',
      [phoneNumber]
    );

    let userId: number;
    let user: User;

    if (existingUsers.length > 0) {
      // 用户已存在
      user = existingUsers[0];
      userId = user.id;
    } else {
      // 创建新用户
      const defaultNickname = `用户${phoneNumber.slice(-4)}`;
      userId = await insert(
        'INSERT INTO users (phone_number, nickname) VALUES (?, ?)',
        [phoneNumber, defaultNickname]
      );
      user = {
        id: userId,
        phone_number: phoneNumber,
        nickname: defaultNickname,
        avatar_url: null,
      };
    }

    // 生成JWT token
    const jwtToken = jwt.sign(
      { userId, phoneNumber },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      message: '登录成功',
      data: {
        token: jwtToken,
        user: {
          id: user.id,
          phoneNumber: user.phone_number,
          nickname: user.nickname,
          avatarUrl: user.avatar_url,
        },
      },
    });
  } catch (error) {
    console.error('手机号登录处理错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
      error: error instanceof Error ? error.message : '未知错误',
    });
  }
});

// 获取当前用户信息
router.get('/me', async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    
    const users = await query<User[]>(
      'SELECT * FROM users WHERE id = ?',
      [userId]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: '用户不存在',
      });
    }

    const user = users[0];
    res.json({
      success: true,
      data: {
        id: user.id,
        phoneNumber: user.phone_number,
        nickname: user.nickname,
        avatarUrl: user.avatar_url,
      },
    });
  } catch (error) {
    console.error('获取用户信息错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 更新用户信息
router.put('/profile', async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { nickname, avatarUrl } = req.body;

    const updates: string[] = [];
    const params: any[] = [];

    if (nickname !== undefined) {
      updates.push('nickname = ?');
      params.push(nickname);
    }
    if (avatarUrl !== undefined) {
      updates.push('avatar_url = ?');
      params.push(avatarUrl);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: '没有要更新的内容',
      });
    }

    params.push(userId);
    await query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = ?`,
      params
    );

    res.json({
      success: true,
      message: '更新成功',
    });
  } catch (error) {
    console.error('更新用户信息错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

export default router;


