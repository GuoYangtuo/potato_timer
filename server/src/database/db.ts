import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

dotenv.config();

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'hh20061202',
};

const dbName = process.env.DB_NAME || 'potato_timer';

// 数据库连接池（延迟初始化）
let pool: mysql.Pool;

// 初始化连接池
function createPool() {
  if (!pool) {
    pool = mysql.createPool({
      ...dbConfig,
      database: dbName,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      charset: 'utf8mb4',
    });
  }
  return pool;
}

// 确保数据库存在，如果不存在则自动创建
async function ensureDatabaseExists(): Promise<void> {
  // 先创建一个不指定数据库的连接
  const connection = await mysql.createConnection(dbConfig);
  
  try {
    // 创建数据库（如果不存在）
    await connection.execute(
      `CREATE DATABASE IF NOT EXISTS \`${dbName}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
    );
    console.log(`✅ 数据库 '${dbName}' 已确认存在或已创建`);
    
    // 切换到该数据库
    await connection.changeUser({ database: dbName });
    
    // 检查是否需要初始化表结构
    const [tables] = await connection.execute('SHOW TABLES');
    console.log(tables);
    if ((tables as any[]).length === 0) {
      console.log('📦 数据库为空，正在初始化表结构...');
      await initializeSchema(connection);
    }
  } finally {
    await connection.end();
  }
}

// 执行 schema.sql 初始化表结构
async function initializeSchema(connection: mysql.Connection): Promise<void> {
  const schemaPath = path.join(__dirname, 'schema.sql');
  
  if (!fs.existsSync(schemaPath)) {
    console.warn('⚠️ schema.sql 文件不存在，跳过表结构初始化');
    return;
  }
  
  const schema = fs.readFileSync(schemaPath, 'utf8');
  
  // 移除单行注释，但保留语句内容
  const cleanedSchema = schema
    .split('\n')
    .map(line => {
      // 移除以 -- 开头的注释行
      const trimmed = line.trim();
      if (trimmed.startsWith('--')) {
        return '';
      }
      return line;
    })
    .join('\n');
  
  // 分割 SQL 语句（按分号+换行分割，更可靠）
  const statements = cleanedSchema
    .split(/;\s*\n/)
    .map(s => s.trim())
    .filter(s => {
      if (s.length === 0) return false;
      const upper = s.toUpperCase();
      // 跳过 CREATE DATABASE 和 USE 语句
      if (upper.startsWith('CREATE DATABASE')) return false;
      if (upper.startsWith('USE ')) return false;
      return true;
    });
  
  console.log(`📋 准备执行 ${statements.length} 个 SQL 语句...`);
  
  let successCount = 0;
  for (const statement of statements) {
    if (statement.trim()) {
      try {
        // 使用 query 而不是 execute，对于 DDL 语句更可靠
        await connection.query(statement);
        successCount++;
      } catch (error: any) {
        // 忽略重复键错误和表已存在错误
        if (error.code !== 'ER_DUP_ENTRY' && error.code !== 'ER_TABLE_EXISTS_ERROR') {
          console.error(`❌ 执行 SQL 失败: ${error.message}`);
          console.error(`   语句: ${statement.substring(0, 100)}...`);
        }
      }
    }
  }
  
  console.log(`✅ 表结构初始化完成 (成功执行 ${successCount}/${statements.length} 个语句)`);
}

// 测试数据库连接
export async function testConnection(): Promise<boolean> {
  try {
    // 首先确保数据库存在
    await ensureDatabaseExists();
    
    // 然后创建连接池并测试连接
    const p = createPool();
    const connection = await p.getConnection();
    console.log('✅ 数据库连接成功');
    connection.release();
    return true;
  } catch (error) {
    console.error('❌ 数据库连接失败:', error);
    return false;
  }
}

// 执行查询 - 使用 query 而非 execute 以避免 LIMIT/OFFSET 参数问题
export async function query<T>(sql: string, params?: any[]): Promise<T> {
  const p = createPool();
  const [rows] = await p.query(sql, params);
  return rows as T;
}

// 执行带返回插入ID的查询
export async function insert(sql: string, params?: any[]): Promise<number> {
  const p = createPool();
  const [result] = await p.query(sql, params);
  return (result as any).insertId;
}

// 执行更新/删除操作，返回影响的行数
export async function update(sql: string, params?: any[]): Promise<number> {
  const p = createPool();
  const [result] = await p.query(sql, params);
  return (result as any).affectedRows;
}

// 获取连接池
export function getPool(): mysql.Pool {
  return createPool();
}

export default { getPool, query, insert, update, testConnection };


