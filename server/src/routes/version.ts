import { Router, Request, Response } from 'express';
import fs from 'fs';
import path from 'path';

const router = Router();

// 版本配置文件路径
const VERSION_CONFIG_PATH = path.join(__dirname, '../../version-config.json');

// 默认版本配置
const DEFAULT_VERSION_CONFIG = {
  version: 1,
  downloadUrl: '',
  updateLog: '当前为最新版本'
};

/**
 * 读取版本配置
 */
function getVersionConfig() {
  try {
    if (fs.existsSync(VERSION_CONFIG_PATH)) {
      const content = fs.readFileSync(VERSION_CONFIG_PATH, 'utf-8');
      return JSON.parse(content);
    }
    return DEFAULT_VERSION_CONFIG;
  } catch (error) {
    console.error('读取版本配置失败:', error);
    return DEFAULT_VERSION_CONFIG;
  }
}

/**
 * 保存版本配置
 */
function saveVersionConfig(config: any) {
  try {
    fs.writeFileSync(VERSION_CONFIG_PATH, JSON.stringify(config, null, 2), 'utf-8');
    return true;
  } catch (error) {
    console.error('保存版本配置失败:', error);
    return false;
  }
}

/**
 * GET /api/version/check
 * 检查版本更新
 */
router.get('/check', (req: Request, res: Response) => {
  try {
    const versionConfig = getVersionConfig();
    
    res.json({
      code: 200,
      message: 'success',
      data: versionConfig
    });
  } catch (error: any) {
    console.error('检查版本失败:', error);
    res.status(500).json({
      code: 500,
      message: '检查版本失败',
      error: error.message
    });
  }
});

/**
 * POST /api/version/update
 * 更新版本配置（管理员接口）
 * 
 * Body:
 * {
 *   "version": 2,
 *   "downloadUrl": "http://localhost:3000/updates/potato_timer_v2.apk",
 *   "updateLog": "1. 新增功能\n2. 修复bug"
 * }
 */
router.post('/update', (req: Request, res: Response) => {
  try {
    const { version, downloadUrl, updateLog } = req.body;
    
    if (!version || !downloadUrl) {
      return res.status(400).json({
        code: 400,
        message: '缺少必要参数: version 和 downloadUrl'
      });
    }
    
    const config = {
      version: parseInt(version),
      downloadUrl,
      updateLog: updateLog || '新版本更新'
    };
    
    const success = saveVersionConfig(config);
    
    if (success) {
      res.json({
        code: 200,
        message: '版本配置更新成功',
        data: config
      });
    } else {
      res.status(500).json({
        code: 500,
        message: '保存版本配置失败'
      });
    }
  } catch (error: any) {
    console.error('更新版本配置失败:', error);
    res.status(500).json({
      code: 500,
      message: '更新版本配置失败',
      error: error.message
    });
  }
});

/**
 * GET /api/version/current
 * 获取当前版本配置
 */
router.get('/current', (req: Request, res: Response) => {
  try {
    const versionConfig = getVersionConfig();
    
    res.json({
      code: 200,
      message: 'success',
      data: versionConfig
    });
  } catch (error: any) {
    console.error('获取版本配置失败:', error);
    res.status(500).json({
      code: 500,
      message: '获取版本配置失败',
      error: error.message
    });
  }
});

export default router;

