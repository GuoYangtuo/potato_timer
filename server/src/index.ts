import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { testConnection } from './database/db';

// 路由
import authRouter from './routes/auth';
import motivationsRouter from './routes/motivations';
import goalsRouter from './routes/goals';
import tagsRouter from './routes/tags';
import uploadRouter from './routes/upload';
import versionRouter from './routes/version';

// 加载环境变量
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 静态文件服务（上传的文件）
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// 静态文件服务（应用更新包）
app.use('/updates', express.static(path.join(__dirname, '../updates')));

// 健康检查接口
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// API 路由
app.use('/api/auth', authRouter);
app.use('/api/motivations', motivationsRouter);
app.use('/api/goals', goalsRouter);
app.use('/api/tags', tagsRouter);
app.use('/api/upload', uploadRouter);
app.use('/api/version', versionRouter);

// 错误处理
app.use((err: any, req: Request, res: Response, next: any) => {
  console.error('服务器错误:', err);
  res.status(500).json({
    success: false,
    message: '服务器内部错误',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// 启动服务器
async function start() {
  // 测试数据库连接
  const dbConnected = await testConnection();
  if (!dbConnected) {
    console.error('❌ 数据库连接失败，请检查配置');
    process.exit(1);
  }

  app.listen(PORT, () => {
    console.log(`🚀 服务器运行在 http://localhost:${PORT}`);
    console.log(`📝 API 路由:`);
    console.log(`   POST /api/auth/login - 一键登录`);
    console.log(`   GET  /api/auth/me - 获取当前用户信息`);
    console.log(`   PUT  /api/auth/profile - 更新用户信息`);
    console.log(`   GET  /api/motivations/public - 获取公开激励内容`);
    console.log(`   GET  /api/motivations/my - 获取我的激励内容`);
    console.log(`   POST /api/motivations - 创建激励内容`);
    console.log(`   GET  /api/goals/my - 获取我的目标`);
    console.log(`   GET  /api/goals/public - 获取公开目标`);
    console.log(`   POST /api/goals - 创建目标`);
    console.log(`   POST /api/goals/:id/complete - 完成目标`);
    console.log(`   GET  /api/tags - 获取标签列表`);
    console.log(`   POST /api/upload/file - 上传文件`);
    console.log(`   GET  /api/version/check - 检查版本更新`);
    console.log(`   POST /api/version/update - 更新版本配置（管理员）`);
    console.log(`   GET  /health - 健康检查`);
  });
}

start();
