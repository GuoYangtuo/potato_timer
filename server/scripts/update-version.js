/**
 * 版本配置更新工具
 * 使用方法：node scripts/update-version.js <版本号> <下载URL> <更新日志>
 * 
 * 示例：
 * node scripts/update-version.js 2 "http://localhost:3000/updates/potato_timer_v2.apk" "1. 新增功能A\n2. 修复bug B"
 */

const fs = require('fs');
const path = require('path');
const http = require('http');

const VERSION_CONFIG_PATH = path.join(__dirname, '../version-config.json');

// 解析命令行参数
const args = process.argv.slice(2);

if (args.length < 2) {
  console.error('❌ 参数不足');
  console.log('\n使用方法:');
  console.log('  node scripts/update-version.js <版本号> <下载URL> [更新日志]');
  console.log('\n示例:');
  console.log('  node scripts/update-version.js 2 "http://localhost:3000/updates/potato_timer_v2.apk" "1. 新增功能\\n2. 修复bug"');
  process.exit(1);
}

const version = parseInt(args[0]);
const downloadUrl = args[1];
const updateLog = args[2] || '新版本更新';

if (isNaN(version) || version < 1) {
  console.error('❌ 版本号必须是大于0的整数');
  process.exit(1);
}

// 读取当前配置
let currentConfig = {
  version: 1,
  downloadUrl: '',
  updateLog: '当前为最新版本'
};

if (fs.existsSync(VERSION_CONFIG_PATH)) {
  try {
    const content = fs.readFileSync(VERSION_CONFIG_PATH, 'utf-8');
    currentConfig = JSON.parse(content);
  } catch (error) {
    console.warn('⚠️  读取当前配置失败，将创建新配置');
  }
}

// 创建新配置
const newConfig = {
  version,
  downloadUrl,
  updateLog
};

// 保存配置
try {
  fs.writeFileSync(VERSION_CONFIG_PATH, JSON.stringify(newConfig, null, 2), 'utf-8');
  console.log('✅ 版本配置更新成功！');
  console.log('\n当前配置:');
  console.log(`  版本号: ${newConfig.version}`);
  console.log(`  下载地址: ${newConfig.downloadUrl}`);
  console.log(`  更新日志: ${newConfig.updateLog}`);
  
  // 如果服务器正在运行，尝试通过API更新
  console.log('\n💡 提示: 如果服务器正在运行，配置已自动生效');
  console.log('   客户端下次启动时会自动检测到新版本\n');
} catch (error) {
  console.error('❌ 保存配置失败:', error.message);
  process.exit(1);
}

