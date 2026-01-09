import crypto from 'crypto';
import https from 'https';
import querystring from 'querystring';

/**
 * 生成阿里云API签名
 */
function generateSignature(
  params: Record<string, string>,
  accessKeySecret: string,
  method: string = 'POST'
): string {
  // 按参数名排序
  const sortedParams = Object.keys(params)
    .sort()
    .map((key) => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`)
    .join('&');

  // 构造待签名字符串
  const stringToSign = `${method}&${encodeURIComponent('/')}&${encodeURIComponent(sortedParams)}`;

  // 使用HMAC-SHA1算法签名
  const signature = crypto
    .createHmac('sha1', accessKeySecret + '&')
    .update(stringToSign)
    .digest('base64');

  return signature;
}

/**
 * 调用阿里云GetMobile接口获取手机号
 * @param accessToken 客户端传来的token
 * @param accessKeyId 阿里云AccessKey ID
 * @param accessKeySecret 阿里云AccessKey Secret
 * @returns 手机号
 */
export async function getMobileByToken(
  accessToken: string,
  accessKeyId: string,
  accessKeySecret: string
): Promise<string> {
  return new Promise((resolve, reject) => {
    try {
      // 公共参数
      const commonParams: Record<string, string> = {
        Format: 'JSON',
        Version: '2017-05-25',
        AccessKeyId: accessKeyId,
        SignatureMethod: 'HMAC-SHA1',
        Timestamp: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'),
        SignatureVersion: '1.0',
        SignatureNonce: Math.random().toString(36).substring(2, 15),
        Action: 'GetMobile',
        AccessToken: accessToken,
      };

      // 生成签名
      const signature = generateSignature(commonParams, accessKeySecret);
      commonParams.Signature = signature;

      // 构造请求体
      const postData = querystring.stringify(commonParams);

      // 请求选项
      const options = {
        hostname: 'dypnsapi.aliyuncs.com',
        port: 443,
        path: '/',
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': Buffer.byteLength(postData),
        },
      };

      // 发送HTTPS请求
      const req = https.request(options, (res) => {
        let data = '';

        res.on('data', (chunk) => {
          data += chunk;
        });

        res.on('end', () => {
          try {
            const result = JSON.parse(data);

            // 检查响应
            if (result.Code === 'OK' && result.GetMobileResultDTO?.Mobile) {
              resolve(result.GetMobileResultDTO.Mobile);
            } else {
              reject(
                new Error(
                  `获取手机号失败: ${result.Message || result.Code || '未知错误'}`
                )
              );
            }
          } catch (error) {
            reject(new Error(`解析响应失败: ${error instanceof Error ? error.message : '未知错误'}`));
          }
        });
      });

      req.on('error', (error) => {
        reject(new Error(`请求失败: ${error.message}`));
      });

      req.write(postData);
      req.end();
    } catch (error) {
      reject(error);
    }
  });
}
