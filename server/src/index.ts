import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { getMobileByToken } from './aliyun';

// 加载环境变量
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 存储用户信息的接口（实际项目中应该使用数据库）
interface UserInfo {
  token: string;
  phoneNumber: string;
  loginTime: string;
}

// 临时存储用户信息（实际项目中应使用数据库）
const users: UserInfo[] = [];

// 从环境变量获取阿里云配置
const ALIYUN_ACCESS_KEY_ID = process.env.ALIYUN_ACCESS_KEY_ID || '';
const ALIYUN_ACCESS_KEY_SECRET = process.env.ALIYUN_ACCESS_KEY_SECRET || '';

if (!ALIYUN_ACCESS_KEY_ID || !ALIYUN_ACCESS_KEY_SECRET) {
  console.warn('⚠️  警告: 未配置阿里云AccessKey，请设置环境变量 ALIYUN_ACCESS_KEY_ID 和 ALIYUN_ACCESS_KEY_SECRET');
}

// 健康检查接口
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// 一键登录接口
app.post('/api/auth/login', async (req: Request, res: Response) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: '缺少必要的参数：token',
      });
    }

    // 检查阿里云配置
    if (!ALIYUN_ACCESS_KEY_ID || !ALIYUN_ACCESS_KEY_SECRET) {
      return res.status(500).json({
        success: false,
        message: '服务器配置错误：未配置阿里云AccessKey',
      });
    }

    // 通过阿里云GetMobile接口获取手机号
    let phoneNumber: string;
    try {
      phoneNumber = await getMobileByToken(
        token,
        ALIYUN_ACCESS_KEY_ID,
        ALIYUN_ACCESS_KEY_SECRET
      );
      console.log('成功获取手机号:', phoneNumber);
    } catch (error) {
      console.error('调用阿里云GetMobile接口失败:', error);
      return res.status(500).json({
        success: false,
        message: '获取手机号失败',
        error: error instanceof Error ? error.message : '未知错误',
      });
    }

    // 记录用户登录信息
    const userInfo: UserInfo = {
      token,
      phoneNumber,
      loginTime: new Date().toISOString(),
    };

    // 保存用户信息（实际项目中应保存到数据库）
    users.push(userInfo);

    console.log('用户登录成功:', {
      phoneNumber: userInfo.phoneNumber,
      loginTime: userInfo.loginTime,
      token: userInfo.token.substring(0, 20) + '...',
    });

    // 返回成功响应
    res.json({
      success: true,
      message: '登录成功',
      data: {
        userId: users.length, // 临时ID，实际应使用数据库生成的ID
        phoneNumber: userInfo.phoneNumber,
        loginTime: userInfo.loginTime,
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

// 获取用户信息接口
app.get('/api/user/:userId', (req: Request, res: Response) => {
  try {
    const userId = parseInt(req.params.userId);
    const user = users[userId - 1];

    if (!user) {
      return res.status(404).json({
        success: false,
        message: '用户不存在',
      });
    }

    res.json({
      success: true,
      data: {
        userId,
        phoneNumber: user.phoneNumber,
        loginTime: user.loginTime,
      },
    });
  } catch (error) {
    console.error('获取用户信息错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
      error: error instanceof Error ? error.message : '未知错误',
    });
  }
});

// 获取所有用户列表（仅用于开发测试）
app.get('/api/users', (req: Request, res: Response) => {
  try {
    const userList = users.map((user, index) => ({
      userId: index + 1,
      phoneNumber: user.phoneNumber,
      loginTime: user.loginTime,
    }));

    res.json({
      success: true,
      count: userList.length,
      data: userList,
    });
  } catch (error) {
    console.error('获取用户列表错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
      error: error instanceof Error ? error.message : '未知错误',
    });
  }
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`🚀 服务器运行在 http://localhost:${PORT}`);
  console.log(`📝 API 文档:`);
  console.log(`   POST /api/auth/login - 一键登录`);
  console.log(`   GET  /api/user/:userId - 获取用户信息`);
  console.log(`   GET  /api/users - 获取所有用户列表`);
  console.log(`   GET  /health - 健康检查`);
  if (!ALIYUN_ACCESS_KEY_ID || !ALIYUN_ACCESS_KEY_SECRET) {
    console.log(`⚠️  警告: 请配置阿里云AccessKey环境变量`);
  }
});
