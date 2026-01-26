import { Router, Request, Response } from 'express';
import { query, insert, update } from '../database/db';
import { authMiddleware, optionalAuthMiddleware } from '../middleware/auth';

const router = Router();

interface Goal {
  id: number;
  user_id: number;
  title: string;
  description: string | null;
  type: 'habit' | 'main_task';
  is_public: boolean;
  enable_timer: boolean;
  duration_minutes: number;
  reminder_time: string | null;
  total_hours: number;
  completed_hours: number;
  morning_reminder_time: string;
  afternoon_reminder_time: string;
  session_duration_minutes: number;
  streak_days: number;
  total_completed_days: number;
  last_completed_date: string | null;
  status: string;
  created_at: Date;
}

// 获取用户的所有目标
router.get('/my', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { type, status = 'active' } = req.query;

    let sql = 'SELECT * FROM goals WHERE user_id = ?';
    const params: any[] = [userId];

    if (type) {
      sql += ' AND type = ?';
      params.push(type);
    }
    if (status) {
      sql += ' AND status = ?';
      params.push(status);
    }

    sql += ' ORDER BY CASE WHEN type = "main_task" THEN 0 ELSE 1 END, created_at DESC';

    const goals = await query<Goal[]>(sql, params);

    const result = await Promise.all(
      goals.map(async (g) => {
        // 获取关联的激励内容
        const motivations = await query<any[]>(
          `SELECT m.id, m.title, m.type FROM motivations m
           JOIN goal_motivations gm ON m.id = gm.motivation_id
           WHERE gm.goal_id = ?
           ORDER BY gm.sort_order`,
          [g.id]
        );

        return {
          id: g.id,
          title: g.title,
          description: g.description,
          type: g.type,
          isPublic: Boolean(g.is_public),
          enableTimer: Boolean(g.enable_timer),
          durationMinutes: g.duration_minutes,
          reminderTime: g.reminder_time,
          totalHours: g.total_hours,
          completedHours: Number(g.completed_hours),
          morningReminderTime: g.morning_reminder_time,
          afternoonReminderTime: g.afternoon_reminder_time,
          sessionDurationMinutes: g.session_duration_minutes,
          streakDays: g.streak_days,
          totalCompletedDays: g.total_completed_days,
          lastCompletedDate: g.last_completed_date,
          status: g.status,
          createdAt: g.created_at,
          motivations: motivations.map((m) => ({
            id: m.id,
            title: m.title,
            type: m.type,
          })),
        };
      })
    );

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('获取目标列表错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 获取公开的目标列表
router.get('/public', optionalAuthMiddleware, async (req: Request, res: Response) => {
  try {
    const { type, page = '1', limit = '20' } = req.query;
    const pageNum = Math.max(1, parseInt(page as string, 10) || 1);
    const limitNum = Math.max(1, Math.min(100, parseInt(limit as string, 10) || 20));
    const offset = (pageNum - 1) * limitNum;

    let sql = `
      SELECT g.*, u.nickname as author_name, u.avatar_url as author_avatar
      FROM goals g
      JOIN users u ON g.user_id = u.id
      WHERE g.is_public = true AND g.status = 'active'
    `;
    const params: any[] = [];

    if (type) {
      sql += ' AND g.type = ?';
      params.push(type);
    }

    sql += ' ORDER BY g.streak_days DESC, g.created_at DESC LIMIT ? OFFSET ?';
    params.push(limitNum, offset);

    const goals = await query<any[]>(sql, params);

    const result = goals.map((g) => ({
      id: g.id,
      title: g.title,
      description: g.description,
      type: g.type,
      streakDays: g.streak_days,
      totalCompletedDays: g.total_completed_days,
      completedHours: Number(g.completed_hours),
      totalHours: g.total_hours,
      author: {
        id: g.user_id,
        nickname: g.author_name,
        avatarUrl: g.author_avatar,
      },
      createdAt: g.created_at,
    }));

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('获取公开目标错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 获取目标详情
router.get('/:id', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { id } = req.params;

    const goals = await query<Goal[]>(
      'SELECT * FROM goals WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (goals.length === 0) {
      return res.status(404).json({
        success: false,
        message: '目标不存在',
      });
    }

    const g = goals[0];

    // 获取关联的激励内容（完整信息）
    const motivations = await query<any[]>(
      `SELECT m.*, mm.url as first_media_url, mm.media_type as first_media_type
       FROM motivations m
       JOIN goal_motivations gm ON m.id = gm.motivation_id
       LEFT JOIN (
         SELECT motivation_id, url, media_type 
         FROM motivation_media 
         WHERE sort_order = 0
       ) mm ON m.id = mm.motivation_id
       WHERE gm.goal_id = ?
       ORDER BY gm.sort_order`,
      [id]
    );

    // 获取完成记录
    const completions = await query<any[]>(
      `SELECT * FROM goal_completions 
       WHERE goal_id = ? 
       ORDER BY completed_at DESC 
       LIMIT 30`,
      [id]
    );

    res.json({
      success: true,
      data: {
        id: g.id,
        title: g.title,
        description: g.description,
        type: g.type,
        isPublic: Boolean(g.is_public),
        enableTimer: Boolean(g.enable_timer),
        durationMinutes: g.duration_minutes,
        reminderTime: g.reminder_time,
        totalHours: g.total_hours,
        completedHours: Number(g.completed_hours),
        morningReminderTime: g.morning_reminder_time,
        afternoonReminderTime: g.afternoon_reminder_time,
        sessionDurationMinutes: g.session_duration_minutes,
        streakDays: g.streak_days,
        totalCompletedDays: g.total_completed_days,
        lastCompletedDate: g.last_completed_date,
        status: g.status,
        createdAt: g.created_at,
        motivations: motivations.map((m) => ({
          id: m.id,
          title: m.title,
          content: m.content,
          type: m.type,
          firstMediaUrl: m.first_media_url,
          firstMediaType: m.first_media_type,
        })),
        recentCompletions: completions.map((c) => ({
          id: c.id,
          completedAt: c.completed_at,
          durationMinutes: c.duration_minutes,
          notes: c.notes,
        })),
      },
    });
  } catch (error) {
    console.error('获取目标详情错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 创建目标
router.post('/', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const {
      title,
      description,
      type,
      isPublic,
      enableTimer,
      durationMinutes,
      reminderTime,
      totalHours,
      morningReminderTime,
      afternoonReminderTime,
      sessionDurationMinutes,
      motivationIds,
    } = req.body;

    if (!title || !type) {
      return res.status(400).json({
        success: false,
        message: '请填写目标标题和类型',
      });
    }

    if (!['habit', 'main_task'].includes(type)) {
      return res.status(400).json({
        success: false,
        message: '无效的目标类型',
      });
    }

    // 检查主线任务限制（只能有一个active的主线任务）
    if (type === 'main_task') {
      const existingMainTask = await query<Goal[]>(
        'SELECT id FROM goals WHERE user_id = ? AND type = "main_task" AND status = "active"',
        [userId]
      );
      if (existingMainTask.length > 0) {
        return res.status(400).json({
          success: false,
          message: '已存在一个进行中的主线任务，请先完成或归档后再创建新的',
        });
      }
    }

    const goalId = await insert(
      `INSERT INTO goals (
        user_id, title, description, type, is_public,
        enable_timer, duration_minutes, reminder_time,
        total_hours, morning_reminder_time, afternoon_reminder_time, session_duration_minutes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        title,
        description || null,
        type,
        isPublic || false,
        type === 'habit' ? (enableTimer || false) : true,
        durationMinutes || 10,
        reminderTime || null,
        totalHours || 0,
        morningReminderTime || '09:00:00',
        afternoonReminderTime || '14:00:00',
        sessionDurationMinutes || 240,
      ]
    );

    // 关联激励内容
    if (motivationIds && Array.isArray(motivationIds)) {
      for (let i = 0; i < motivationIds.length; i++) {
        await insert(
          'INSERT INTO goal_motivations (goal_id, motivation_id, sort_order) VALUES (?, ?, ?)',
          [goalId, motivationIds[i], i]
        );
      }
    }

    res.json({
      success: true,
      message: '创建成功',
      data: { id: goalId },
    });
  } catch (error) {
    console.error('创建目标错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 更新目标
router.put('/:id', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { id } = req.params;
    const {
      title,
      description,
      isPublic,
      enableTimer,
      durationMinutes,
      reminderTime,
      totalHours,
      morningReminderTime,
      afternoonReminderTime,
      sessionDurationMinutes,
      status,
      motivationIds,
    } = req.body;

    const goals = await query<Goal[]>(
      'SELECT * FROM goals WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (goals.length === 0) {
      return res.status(404).json({
        success: false,
        message: '目标不存在或无权修改',
      });
    }

    const updates: string[] = [];
    const params: any[] = [];

    if (title !== undefined) {
      updates.push('title = ?');
      params.push(title);
    }
    if (description !== undefined) {
      updates.push('description = ?');
      params.push(description);
    }
    if (isPublic !== undefined) {
      updates.push('is_public = ?');
      params.push(isPublic);
    }
    if (enableTimer !== undefined) {
      updates.push('enable_timer = ?');
      params.push(enableTimer);
    }
    if (durationMinutes !== undefined) {
      updates.push('duration_minutes = ?');
      params.push(durationMinutes);
    }
    if (reminderTime !== undefined) {
      updates.push('reminder_time = ?');
      params.push(reminderTime);
    }
    if (totalHours !== undefined) {
      updates.push('total_hours = ?');
      params.push(totalHours);
    }
    if (morningReminderTime !== undefined) {
      updates.push('morning_reminder_time = ?');
      params.push(morningReminderTime);
    }
    if (afternoonReminderTime !== undefined) {
      updates.push('afternoon_reminder_time = ?');
      params.push(afternoonReminderTime);
    }
    if (sessionDurationMinutes !== undefined) {
      updates.push('session_duration_minutes = ?');
      params.push(sessionDurationMinutes);
    }
    if (status !== undefined) {
      updates.push('status = ?');
      params.push(status);
    }

    if (updates.length > 0) {
      params.push(id);
      await update(`UPDATE goals SET ${updates.join(', ')} WHERE id = ?`, params);
    }

    // 更新激励内容关联
    if (motivationIds !== undefined) {
      await update('DELETE FROM goal_motivations WHERE goal_id = ?', [id]);
      if (Array.isArray(motivationIds)) {
        for (let i = 0; i < motivationIds.length; i++) {
          await insert(
            'INSERT INTO goal_motivations (goal_id, motivation_id, sort_order) VALUES (?, ?, ?)',
            [id, motivationIds[i], i]
          );
        }
      }
    }

    res.json({
      success: true,
      message: '更新成功',
    });
  } catch (error) {
    console.error('更新目标错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 删除目标
router.delete('/:id', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { id } = req.params;

    const affected = await update(
      'DELETE FROM goals WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (affected === 0) {
      return res.status(404).json({
        success: false,
        message: '目标不存在或无权删除',
      });
    }

    res.json({
      success: true,
      message: '删除成功',
    });
  } catch (error) {
    console.error('删除目标错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 完成目标（记录一次完成）
router.post('/:id/complete', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { id } = req.params;
    const { durationMinutes, notes } = req.body;

    const goals = await query<Goal[]>(
      'SELECT * FROM goals WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (goals.length === 0) {
      return res.status(404).json({
        success: false,
        message: '目标不存在',
      });
    }

    const goal = goals[0];
    const today = new Date().toISOString().split('T')[0];
    const lastDate = goal.last_completed_date;

    // 计算连续天数
    let newStreakDays = goal.streak_days;
    if (lastDate !== today) {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = yesterday.toISOString().split('T')[0];

      if (lastDate === yesterdayStr) {
        newStreakDays += 1;
      } else {
        newStreakDays = 1;
      }
    }

    // 记录完成
    await insert(
      'INSERT INTO goal_completions (goal_id, duration_minutes, notes) VALUES (?, ?, ?)',
      [id, durationMinutes || 0, notes || null]
    );

    // 更新目标统计
    const completedHoursIncrement = (durationMinutes || 0) / 60;
    await update(
      `UPDATE goals SET 
        streak_days = ?,
        total_completed_days = total_completed_days + ?,
        completed_hours = completed_hours + ?,
        last_completed_date = ?
       WHERE id = ?`,
      [
        newStreakDays,
        lastDate !== today ? 1 : 0,
        completedHoursIncrement,
        today,
        id,
      ]
    );

    res.json({
      success: true,
      message: '完成记录已保存',
      data: {
        streakDays: newStreakDays,
        completedHours: Number(goal.completed_hours) + completedHoursIncrement,
      },
    });
  } catch (error) {
    console.error('记录完成错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

// 获取目标的激励内容（用于激励页面）
router.get('/:id/motivations', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { id } = req.params;

    // 验证目标属于当前用户
    const goals = await query<Goal[]>(
      'SELECT * FROM goals WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (goals.length === 0) {
      return res.status(404).json({
        success: false,
        message: '目标不存在',
      });
    }

    // 获取关联的激励内容
    const motivations = await query<any[]>(
      `SELECT m.* FROM motivations m
       JOIN goal_motivations gm ON m.id = gm.motivation_id
       WHERE gm.goal_id = ?
       ORDER BY gm.sort_order`,
      [id]
    );

    const result = await Promise.all(
      motivations.map(async (m) => {
        const media = await query<any[]>(
          'SELECT * FROM motivation_media WHERE motivation_id = ? ORDER BY sort_order',
          [m.id]
        );

        return {
          id: m.id,
          title: m.title,
          content: m.content,
          type: m.type,
          media: media.map((item) => ({
            id: item.id,
            type: item.media_type,
            url: item.url,
            thumbnailUrl: item.thumbnail_url,
          })),
        };
      })
    );

    res.json({
      success: true,
      data: {
        goal: {
          id: goals[0].id,
          title: goals[0].title,
          type: goals[0].type,
          enableTimer: Boolean(goals[0].enable_timer),
          durationMinutes: goals[0].duration_minutes,
          sessionDurationMinutes: goals[0].session_duration_minutes,
        },
        motivations: result,
      },
    });
  } catch (error) {
    console.error('获取目标激励内容错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
    });
  }
});

export default router;


