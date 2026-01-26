import { Router, Request, Response } from 'express';
import { authMiddleware } from '../middleware/auth';
import multer from 'multer';
import path from 'path';
import fs from 'fs';

const router = Router();

// 确保上传目录存在
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// 辅助函数：根据文件判断是否为图片
const isImageFile = (file: Express.Multer.File): boolean => {
  if (file.mimetype.startsWith('image/')) return true;
  
  // 如果 MIME 类型不可靠，检查扩展名
  const ext = path.extname(file.originalname).toLowerCase();
  return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
};

// 配置 multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const type = isImageFile(file) ? 'images' : 'videos';
    const typeDir = path.join(uploadDir, type);
    if (!fs.existsSync(typeDir)) {
      fs.mkdirSync(typeDir, { recursive: true });
    }
    cb(null, typeDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, uniqueSuffix + ext);
  },
});

const fileFilter = (req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
  const allowedImageTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/jpg'];
  const allowedVideoTypes = ['video/mp4', 'video/quicktime', 'video/webm'];
  
  // 检查 MIME 类型
  if (allowedImageTypes.includes(file.mimetype) || allowedVideoTypes.includes(file.mimetype)) {
    cb(null, true);
    return;
  }
  
  // 如果 MIME 类型是 application/octet-stream 或未识别，检查文件扩展名
  if (file.mimetype === 'application/octet-stream' || !file.mimetype || file.mimetype === 'application/unknown') {
    const ext = path.extname(file.originalname).toLowerCase();
    const allowedImageExts = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    const allowedVideoExts = ['.mp4', '.mov', '.webm'];
    
    if (allowedImageExts.includes(ext) || allowedVideoExts.includes(ext)) {
      console.log(`文件 MIME 类型未正确识别 (${file.mimetype})，但扩展名有效: ${ext}`);
      cb(null, true);
      return;
    }
  }
  
  console.log(`不支持的文件类型 - MIME: ${file.mimetype}, 文件名: ${file.originalname}`);
  cb(new Error('不支持的文件类型'));
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB
  },
});

// 上传单个文件
router.post('/file', authMiddleware, upload.single('file'), async (req: Request, res: Response) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: '请选择要上传的文件',
      });
    }

    const file = req.file;
    const isImage = isImageFile(file);
    const type = isImage ? 'images' : 'videos';
    const baseUrl = process.env.BASE_URL || `http://192.168.124.18:${process.env.PORT || 3000}`;
    const url = `${baseUrl}/uploads/${type}/${file.filename}`;

    res.json({
      success: true,
      data: {
        url,
        type: isImage ? 'image' : 'video',
        filename: file.filename,
        size: file.size,
      },
    });
  } catch (error) {
    console.error('文件上传错误:', error);
    res.status(500).json({
      success: false,
      message: '文件上传失败',
    });
  }
});

// 上传多个文件
router.post('/files', authMiddleware, upload.array('files', 10), async (req: Request, res: Response) => {
  try {
    const files = req.files as Express.Multer.File[];
    
    if (!files || files.length === 0) {
      return res.status(400).json({
        success: false,
        message: '请选择要上传的文件',
      });
    }

    const baseUrl = process.env.BASE_URL || `http://192.168.124.18:${process.env.PORT || 3000}`;
    
    const uploadedFiles = files.map((file) => {
      const isImage = isImageFile(file);
      const type = isImage ? 'images' : 'videos';
      return {
        url: `${baseUrl}/uploads/${type}/${file.filename}`,
        type: isImage ? 'image' : 'video',
        filename: file.filename,
        size: file.size,
      };
    });

    res.json({
      success: true,
      data: uploadedFiles,
    });
  } catch (error) {
    console.error('文件上传错误:', error);
    res.status(500).json({
      success: false,
      message: '文件上传失败',
    });
  }
});

export default router;


