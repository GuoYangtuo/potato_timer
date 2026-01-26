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

// 配置 multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const type = file.mimetype.startsWith('image/') ? 'images' : 'videos';
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
  const allowedImageTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
  const allowedVideoTypes = ['video/mp4', 'video/quicktime', 'video/webm'];
  
  if (allowedImageTypes.includes(file.mimetype) || allowedVideoTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('不支持的文件类型'));
  }
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
    const isImage = file.mimetype.startsWith('image/');
    const type = isImage ? 'images' : 'videos';
    const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
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

    const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
    
    const uploadedFiles = files.map((file) => {
      const isImage = file.mimetype.startsWith('image/');
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


