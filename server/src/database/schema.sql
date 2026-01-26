-- 土豆时钟数据库结构
-- 创建数据库
CREATE DATABASE IF NOT EXISTS potato_timer DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE potato_timer;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    phone_number VARCHAR(20) UNIQUE NOT NULL COMMENT '手机号',
    nickname VARCHAR(100) COMMENT '昵称',
    avatar_url VARCHAR(500) COMMENT '头像URL',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 标签表
CREATE TABLE IF NOT EXISTS tags (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL COMMENT '标签名称',
    user_id INT COMMENT '创建者ID，NULL表示系统标签',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_name_user (name, user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='标签表';

-- 激励内容表
CREATE TABLE IF NOT EXISTS motivations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL COMMENT '创建者ID',
    title VARCHAR(200) COMMENT '标题',
    content TEXT COMMENT '文案内容',
    type ENUM('positive', 'negative') NOT NULL COMMENT '类型：positive-正向激励，negative-反向激励',
    is_public BOOLEAN DEFAULT FALSE COMMENT '是否公开',
    view_count INT DEFAULT 0 COMMENT '浏览次数',
    like_count INT DEFAULT 0 COMMENT '点赞次数',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_public_type (is_public, type),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='激励内容表';

-- 激励内容媒体表（图片/视频）
CREATE TABLE IF NOT EXISTS motivation_media (
    id INT PRIMARY KEY AUTO_INCREMENT,
    motivation_id INT NOT NULL COMMENT '激励内容ID',
    media_type ENUM('image', 'video') NOT NULL COMMENT '媒体类型',
    url VARCHAR(500) NOT NULL COMMENT '媒体URL',
    thumbnail_url VARCHAR(500) COMMENT '缩略图URL（视频用）',
    sort_order INT DEFAULT 0 COMMENT '排序顺序',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (motivation_id) REFERENCES motivations(id) ON DELETE CASCADE,
    INDEX idx_motivation (motivation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='激励内容媒体表';

-- 激励内容-标签关联表
CREATE TABLE IF NOT EXISTS motivation_tags (
    motivation_id INT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (motivation_id, tag_id),
    FOREIGN KEY (motivation_id) REFERENCES motivations(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='激励内容-标签关联表';

-- 目标表
CREATE TABLE IF NOT EXISTS goals (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL COMMENT '用户ID',
    title VARCHAR(200) NOT NULL COMMENT '目标标题',
    description TEXT COMMENT '目标描述',
    type ENUM('habit', 'main_task') NOT NULL COMMENT '类型：habit-微习惯，main_task-主线任务',
    is_public BOOLEAN DEFAULT FALSE COMMENT '是否公开',
    
    -- 微习惯相关字段
    enable_timer BOOLEAN DEFAULT FALSE COMMENT '是否启用计时器（微习惯用）',
    duration_minutes INT DEFAULT 10 COMMENT '计时时长（分钟）',
    reminder_time TIME COMMENT '提醒时间（微习惯用）',
    
    -- 主线任务相关字段
    total_hours INT DEFAULT 0 COMMENT '预计总时长（小时，主线任务用）',
    completed_hours DECIMAL(10,2) DEFAULT 0 COMMENT '已完成时长（小时）',
    morning_reminder_time TIME DEFAULT '09:00:00' COMMENT '上午提醒时间',
    afternoon_reminder_time TIME DEFAULT '14:00:00' COMMENT '下午提醒时间',
    session_duration_minutes INT DEFAULT 240 COMMENT '每次计时时长（分钟，默认4小时）',
    
    -- 通用字段
    streak_days INT DEFAULT 0 COMMENT '连续坚持天数',
    total_completed_days INT DEFAULT 0 COMMENT '总完成天数',
    last_completed_date DATE COMMENT '上次完成日期',
    status ENUM('active', 'paused', 'completed', 'archived') DEFAULT 'active' COMMENT '状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_type (user_id, type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='目标表';

-- 目标-激励内容关联表
CREATE TABLE IF NOT EXISTS goal_motivations (
    goal_id INT NOT NULL,
    motivation_id INT NOT NULL,
    sort_order INT DEFAULT 0 COMMENT '排序顺序',
    PRIMARY KEY (goal_id, motivation_id),
    FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE,
    FOREIGN KEY (motivation_id) REFERENCES motivations(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='目标-激励内容关联表';

-- 目标完成记录表
CREATE TABLE IF NOT EXISTS goal_completions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    goal_id INT NOT NULL COMMENT '目标ID',
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '完成时间',
    duration_minutes INT DEFAULT 0 COMMENT '实际花费时间（分钟）',
    notes TEXT COMMENT '备注',
    FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE,
    INDEX idx_goal_date (goal_id, completed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='目标完成记录表';

-- 点赞表
CREATE TABLE IF NOT EXISTS likes (
    user_id INT NOT NULL,
    motivation_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, motivation_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (motivation_id) REFERENCES motivations(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='点赞表';

-- 收藏表
CREATE TABLE IF NOT EXISTS favorites (
    user_id INT NOT NULL,
    motivation_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, motivation_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (motivation_id) REFERENCES motivations(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='收藏表';

-- 插入一些默认标签
INSERT INTO tags (name, user_id) VALUES 
('学习', NULL),
('健身', NULL),
('阅读', NULL),
('工作', NULL),
('编程', NULL),
('健康', NULL),
('理财', NULL),
('社交', NULL),
('创作', NULL),
('冥想', NULL)
ON DUPLICATE KEY UPDATE name=name;


