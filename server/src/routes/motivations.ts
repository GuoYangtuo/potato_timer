import { Router, Request, Response } from 'express';
import { query, insert, update } from '../database/db';
import { authMiddleware, optionalAuthMiddleware } from '../middleware/auth';

const router = Router();

interface Motivation {
  id: number;
  user_id: number;
  title: string | null;
  content: string | null;
  type: 'positive' | 'negative';
  is_public: boolean;
  view_count: number;
  like_count: number;
  created_at: Date;
}

interface Media {
  id: number;
  motivation_id: number;
  media_type: 'image' | 'video';
  url: string;
  thumbnail_url: string | null;
  sort_order: number;
}

interface Tag {
  id: number;
  name: string;
}

// 获取激励内容列表（公开的）
router.get('/public', optionalAuthMiddleware, async (req: Request, res: Response) => {
  try {
    const { type, tag, page = '1', limit = '20' } = req.query;
    const pageNum = Math.max(1, parseInt(page as string, 10) || 1);
    const limitNum = Math.max(1, Math.min(100, parseInt(limit as string, 10) || 20));
    const offset = (pageNum - 1) * limitNum;
    const userId = (req as any).userId;

    let sql = `
      SELECT m.*, u.nickname as author_name, u.avatar_url as author_avatar
      FROM motivations m
      JOIN users u ON m.user_id = u.id
      WHERE m.is_public = true
    `;
    const params: any[] = [];

    if (type) {
      sql += ' AND m.type = ?';
      params.push(type);
    }

    if (tag) {
      sql += ` AND m.id IN (
        SELECT mt.motivation_id FROM motivation_tags mt
        JOIN tags t ON mt.tag_id = t.id
        WHERE t.name = ?
      )`;
      params.push(tag);
    }

    sql += ' ORDER BY m.created_at DESC LIMIT ? OFFSET ?';
    params.push(limitNum, offset);

    const motivations = await query<any[]>(sql, params);

    // 获取每个激励内容的媒体和标签
    const result = await Promise.all(
      motivations.map(async (m) => {
        const media = await query<Media[]>(
          'SELECT * FROM motivation_media WHERE motivation_id = ? ORDER BY sort_order',
          [m.id]
        );
        const tags = await query<Tag[]>(
          `SELECT t.* FROM tags t
           JOIN motivation_tags mt ON t.id = mt.tag_id
           WHERE mt.motivation_id = ?`,
          [m.id]
        );
        
        let isLiked = false;
        let isFavorited = false;
        if (userId) {
          const likes = await query<any[]>(
            'SELECT 1 FROM likes WHERE user_id = ? AND motivation_id = ?',
            [userId, m.id]
          );
          isLiked = likes.length > 0;
          
          const favorites = await query<any[]>(
            'SELECT 1 FROM favorites WHERE user_id = ? AND motivation_id = ?',
            [userId, m.id]
          );
          isFavorited = favorites.length > 0;
        }

        return {
          id: m.id,
          title: m.title,
          content: m.content,
          type: m.type,
          viewCount: m.view_count,
          likeCount: m.like_count,
          createdAt: m.created_at,
          author: {
            id: m.user_id,
            nickname: m.author_name,
            avatarUrl: m.author_avatar,
          },
          media: media.map((item) => ({
            id: item.id,
            type: item.media_type,
            url: item.url,
            thumbnailUrl: item.thumbnail_url,
          })),
          tags: tags.map((t) => t.name),
          isLiked,
          isFavorited,
        };
      })
    );

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('获取公开激励内容错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 获取用户自己的激励内容
router.get('/my', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { type, page = '1', limit = '20' } = req.query;
    const pageNum = Math.max(1, parseInt(page as string, 10) || 1);
    const limitNum = Math.max(1, Math.min(100, parseInt(limit as string, 10) || 20));
    const offset = (pageNum - 1) * limitNum;

    let sql = 'SELECT * FROM motivations WHERE user_id = ?';
    const params: any[] = [userId];

    if (type) {
      sql += ' AND type = ?';
      params.push(type);
    }

    sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(limitNum, offset);

    const motivations = await query<Motivation[]>(sql, params);

    const result = await Promise.all(
      motivations.map(async (m) => {
        const media = await query<Media[]>(
          'SELECT * FROM motivation_media WHERE motivation_id = ? ORDER BY sort_order',
          [m.id]
        );
        const tags = await query<Tag[]>(
          `SELECT t.* FROM tags t
           JOIN motivation_tags mt ON t.id = mt.tag_id
           WHERE mt.motivation_id = ?`,
          [m.id]
        );

        return {
          id: m.id,
          title: m.title,
          content: m.content,
          type: m.type,
          isPublic: Boolean(m.is_public),
          viewCount: m.view_count,
          likeCount: m.like_count,
          createdAt: m.created_at,
          media: media.map((item) => ({
            id: item.id,
            type: item.media_type,
            url: item.url,
            thumbnailUrl: item.thumbnail_url,
          })),
          tags: tags.map((t) => t.name),
        };
      })
    );

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('获取我的激励内容错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 获取单个激励内容详情
router.get('/:id', optionalAuthMiddleware, async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const userId = (req as any).userId;

    const motivations = await query<any[]>(
      `SELECT m.*, u.nickname as author_name, u.avatar_url as author_avatar
       FROM motivations m
       JOIN users u ON m.user_id = u.id
       WHERE m.id = ?`,
      [id]
    );

    if (motivations.length === 0) {
      return res.status(404).json({
        success: false,
        message: '激励内容不存在',
      });
    }

    const m = motivations[0];

    // 检查权限
    if (!m.is_public && m.user_id !== userId) {
      return res.status(403).json({
        success: false,
        message: '无权访问该内容',
      });
    }

    // 增加浏览量
    await update('UPDATE motivations SET view_count = view_count + 1 WHERE id = ?', [id]);

    const media = await query<Media[]>(
      'SELECT * FROM motivation_media WHERE motivation_id = ? ORDER BY sort_order',
      [id]
    );
    const tags = await query<Tag[]>(
      `SELECT t.* FROM tags t
       JOIN motivation_tags mt ON t.id = mt.tag_id
       WHERE mt.motivation_id = ?`,
      [id]
    );

    let isLiked = false;
    let isFavorited = false;
    if (userId) {
      const likes = await query<any[]>(
        'SELECT 1 FROM likes WHERE user_id = ? AND motivation_id = ?',
        [userId, id]
      );
      isLiked = likes.length > 0;
      
      const favorites = await query<any[]>(
        'SELECT 1 FROM favorites WHERE user_id = ? AND motivation_id = ?',
        [userId, id]
      );
      isFavorited = favorites.length > 0;
    }

    res.json({
      success: true,
      data: {
        id: m.id,
        title: m.title,
        content: m.content,
        type: m.type,
        isPublic: Boolean(m.is_public),
        viewCount: m.view_count + 1,
        likeCount: m.like_count,
        createdAt: m.created_at,
        author: {
          id: m.user_id,
          nickname: m.author_name,
          avatarUrl: m.author_avatar,
        },
        media: media.map((item) => ({
          id: item.id,
          type: item.media_type,
          url: item.url,
          thumbnailUrl: item.thumbnail_url,
        })),
        tags: tags.map((t) => t.name),
        isLiked: Boolean(isLiked),
        isFavorited: Boolean(isFavorited),
      },
    });
  } catch (error) {
    console.error('获取激励内容详情错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 创建激励内容
router.post('/', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { title, content, type, isPublic, media, tags } = req.body;

    if (!type || !['positive', 'negative'].includes(type)) {
      return res.status(400).json({
        success: false,
        message: '请选择激励类型（positive/negative）',
      });
    }

    // 创建激励内容
    const motivationId = await insert(
      'INSERT INTO motivations (user_id, title, content, type, is_public) VALUES (?, ?, ?, ?, ?)',
      [userId, title || null, content || null, type, isPublic || false]
    );

    // 添加媒体
    if (media && Array.isArray(media)) {
      for (let i = 0; i < media.length; i++) {
        const m = media[i];
        await insert(
          'INSERT INTO motivation_media (motivation_id, media_type, url, thumbnail_url, sort_order) VALUES (?, ?, ?, ?, ?)',
          [motivationId, m.type, m.url, m.thumbnailUrl || null, i]
        );
      }
    }

    // 添加标签
    if (tags && Array.isArray(tags)) {
      for (const tagName of tags) {
        // 查找或创建标签
        let tagRows = await query<Tag[]>(
          'SELECT id FROM tags WHERE name = ? AND (user_id IS NULL OR user_id = ?)',
          [tagName, userId]
        );

        let tagId: number;
        if (tagRows.length > 0) {
          tagId = tagRows[0].id;
        } else {
          tagId = await insert(
            'INSERT INTO tags (name, user_id) VALUES (?, ?)',
            [tagName, userId]
          );
        }

        await insert(
          'INSERT INTO motivation_tags (motivation_id, tag_id) VALUES (?, ?)',
          [motivationId, tagId]
        );
      }
    }

    res.json({
      success: true,
      message: '创建成功',
      data: { id: motivationId },
    });
  } catch (error) {
    console.error('创建激励内容错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 更新激励内容
router.put('/:id', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { id } = req.params;
    const { title, content, type, isPublic, media, tags } = req.body;

    // 检查是否是自己的内容
    const motivations = await query<Motivation[]>(
      'SELECT * FROM motivations WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (motivations.length === 0) {
      return res.status(404).json({
        success: false,
        message: '激励内容不存在或无权修改',
      });
    }

    // 更新基本信息
    const updates: string[] = [];
    const params: any[] = [];

    if (title !== undefined) {
      updates.push('title = ?');
      params.push(title);
    }
    if (content !== undefined) {
      updates.push('content = ?');
      params.push(content);
    }
    if (type !== undefined) {
      updates.push('type = ?');
      params.push(type);
    }
    if (isPublic !== undefined) {
      updates.push('is_public = ?');
      params.push(isPublic);
    }

    if (updates.length > 0) {
      params.push(id);
      await update(`UPDATE motivations SET ${updates.join(', ')} WHERE id = ?`, params);
    }

    // 更新媒体
    if (media !== undefined) {
      await update('DELETE FROM motivation_media WHERE motivation_id = ?', [id]);
      if (Array.isArray(media)) {
        for (let i = 0; i < media.length; i++) {
          const m = media[i];
          await insert(
            'INSERT INTO motivation_media (motivation_id, media_type, url, thumbnail_url, sort_order) VALUES (?, ?, ?, ?, ?)',
            [id, m.type, m.url, m.thumbnailUrl || null, i]
          );
        }
      }
    }

    // 更新标签
    if (tags !== undefined) {
      await update('DELETE FROM motivation_tags WHERE motivation_id = ?', [id]);
      if (Array.isArray(tags)) {
        for (const tagName of tags) {
          let tagRows = await query<Tag[]>(
            'SELECT id FROM tags WHERE name = ? AND (user_id IS NULL OR user_id = ?)',
            [tagName, userId]
          );

          let tagId: number;
          if (tagRows.length > 0) {
            tagId = tagRows[0].id;
          } else {
            tagId = await insert('INSERT INTO tags (name, user_id) VALUES (?, ?)', [tagName, userId]);
          }

          await insert('INSERT INTO motivation_tags (motivation_id, tag_id) VALUES (?, ?)', [id, tagId]);
        }
      }
    }

    res.json({
      success: true,
      message: '更新成功',
    });
  } catch (error) {
    console.error('更新激励内容错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 删除激励内容
router.delete('/:id', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { id } = req.params;

    const affected = await update(
      'DELETE FROM motivations WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (affected === 0) {
      return res.status(404).json({
        success: false,
        message: '激励内容不存在或无权删除',
      });
    }

    res.json({
      success: true,
      message: '删除成功',
    });
  } catch (error) {
    console.error('删除激励内容错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 点赞
router.post('/:id/like', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { id } = req.params;

    try {
      await insert('INSERT INTO likes (user_id, motivation_id) VALUES (?, ?)', [userId, id]);
      await update('UPDATE motivations SET like_count = like_count + 1 WHERE id = ?', [id]);
    } catch (err: any) {
      if (err.code === 'ER_DUP_ENTRY') {
        return res.status(400).json({
          success: false,
          message: '已点赞',
        });
      }
      throw err;
    }

    res.json({
      success: true,
      message: '点赞成功',
    });
  } catch (error) {
    console.error('点赞错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 取消点赞
router.delete('/:id/like', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { id } = req.params;

    const affected = await update(
      'DELETE FROM likes WHERE user_id = ? AND motivation_id = ?',
      [userId, id]
    );

    if (affected > 0) {
      await update('UPDATE motivations SET like_count = like_count - 1 WHERE id = ? AND like_count > 0', [id]);
    }

    res.json({
      success: true,
      message: '取消点赞成功',
    });
  } catch (error) {
    console.error('取消点赞错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 收藏
router.post('/:id/favorite', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { id } = req.params;

    try {
      await insert('INSERT INTO favorites (user_id, motivation_id) VALUES (?, ?)', [userId, id]);
    } catch (err: any) {
      if (err.code === 'ER_DUP_ENTRY') {
        return res.status(400).json({
          success: false,
          message: '已收藏',
        });
      }
      throw err;
    }

    res.json({
      success: true,
      message: '收藏成功',
    });
  } catch (error) {
    console.error('收藏错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 取消收藏
router.delete('/:id/favorite', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { id } = req.params;

    await update('DELETE FROM favorites WHERE user_id = ? AND motivation_id = ?', [userId, id]);

    res.json({
      success: true,
      message: '取消收藏成功',
    });
  } catch (error) {
    console.error('取消收藏错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 获取收藏列表
router.get('/favorites/list', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { page = '1', limit = '20' } = req.query;
    const pageNum = Math.max(1, parseInt(page as string, 10) || 1);
    const limitNum = Math.max(1, Math.min(100, parseInt(limit as string, 10) || 20));
    const offset = (pageNum - 1) * limitNum;

    const motivations = await query<any[]>(
      `SELECT m.*, u.nickname as author_name, u.avatar_url as author_avatar
       FROM motivations m
       JOIN users u ON m.user_id = u.id
       JOIN favorites f ON m.id = f.motivation_id
       WHERE f.user_id = ?
       ORDER BY f.created_at DESC
       LIMIT ? OFFSET ?`,
      [userId, limitNum, offset]
    );

    const result = await Promise.all(
      motivations.map(async (m) => {
        const media = await query<Media[]>(
          'SELECT * FROM motivation_media WHERE motivation_id = ? ORDER BY sort_order',
          [m.id]
        );
        const tags = await query<Tag[]>(
          `SELECT t.* FROM tags t
           JOIN motivation_tags mt ON t.id = mt.tag_id
           WHERE mt.motivation_id = ?`,
          [m.id]
        );

        return {
          id: m.id,
          title: m.title,
          content: m.content,
          type: m.type,
          viewCount: m.view_count,
          likeCount: m.like_count,
          createdAt: m.created_at,
          author: {
            id: m.user_id,
            nickname: m.author_name,
            avatarUrl: m.author_avatar,
          },
          media: media.map((item) => ({
            id: item.id,
            type: item.media_type,
            url: item.url,
            thumbnailUrl: item.thumbnail_url,
          })),
          tags: tags.map((t) => t.name),
          isLiked: true,
          isFavorited: true,
        };
      })
    );

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('获取收藏列表错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

export default router;


