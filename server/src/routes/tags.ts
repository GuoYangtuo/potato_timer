import { Router, Request, Response } from 'express';
import { query } from '../database/db';
import { authMiddleware } from '../middleware/auth';

const router = Router();

// 获取所有可用标签（系统标签 + 用户自定义标签）
router.get('/', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;

    const tags = await query<any[]>(
      `SELECT DISTINCT t.id, t.name, 
        CASE WHEN t.user_id IS NULL THEN 'system' ELSE 'custom' END as type
       FROM tags t
       WHERE t.user_id IS NULL OR t.user_id = ?
       ORDER BY type DESC, t.name`,
      [userId]
    );

    res.json({
      success: true,
      data: tags,
    });
  } catch (error) {
    console.error('获取标签列表错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 获取热门标签（按使用次数排序）
router.get('/popular', async (req: Request, res: Response) => {
  try {
    const { limit = 20 } = req.query;

    const tags = await query<any[]>(
      `SELECT t.id, t.name, COUNT(mt.motivation_id) as usage_count
       FROM tags t
       LEFT JOIN motivation_tags mt ON t.id = mt.tag_id
       LEFT JOIN motivations m ON mt.motivation_id = m.id AND m.is_public = true
       GROUP BY t.id, t.name
       HAVING usage_count > 0
       ORDER BY usage_count DESC
       LIMIT ?`,
      [Number(limit)]
    );

    res.json({
      success: true,
      data: tags,
    });
  } catch (error) {
    console.error('获取热门标签错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

export default router;


