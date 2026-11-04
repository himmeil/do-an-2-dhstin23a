import {readFileSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const projectRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
);
const defaultConfigPath = path.join(
  projectRoot,
  'ca_nhan',
  'dulieucanhan.env',
);

const requiredStrings = [
  'NEARBY_API_BASE_URL',
  'OVERPASS_API_URL',
  'OVERPASS_FALLBACK_URLS',
  'OSM_MAP_API_URL',
  'NOMINATIM_SEARCH_URL',
  'STREET_TILE_URL',
  'SATELLITE_TILE_URL',
  'DIRECTIONS_URL',
  'FIREBASE_WEB_API_KEY',
  'FIREBASE_WEB_APP_ID',
  'FIREBASE_ANDROID_API_KEY',
  'FIREBASE_ANDROID_APP_ID',
  'FIREBASE_IOS_API_KEY',
  'FIREBASE_IOS_APP_ID',
  'FIREBASE_IOS_BUNDLE_ID',
  'FIREBASE_MESSAGING_SENDER_ID',
  'FIREBASE_PROJECT_ID',
  'FIREBASE_AUTH_DOMAIN',
  'FIREBASE_STORAGE_BUCKET',
];

const urlKeys = [
  'NEARBY_API_BASE_URL',
  'OVERPASS_API_URL',
  'OSM_MAP_API_URL',
  'NOMINATIM_SEARCH_URL',
  'STREET_TILE_URL',
  'SATELLITE_TILE_URL',
  'DIRECTIONS_URL',
];

function isSecretName(name) {
  return (
    /(?:SECRET|TOKEN|PASSWORD|PRIVATE_KEY|SERVICE_ACCOUNT|CLIENT_SECRET)/i.test(
      name,
    ) ||
    (/API_KEY/i.test(name) &&
      !/^FIREBASE_(?:WEB|ANDROID|IOS)_API_KEY$/i.test(name))
  );
}

function isValidHttpUrl(value) {
  try {
    const parsed = new URL(value.replace(/\{[^{}]+\}/g, 'placeholder'));
    return (
      ['http:', 'https:'].includes(parsed.protocol) &&
      parsed.hostname.length > 0 &&
      parsed.username.length === 0 &&
      parsed.password.length === 0
    );
  } catch {
    return false;
  }
}

export function validateConfig(config) {
  if (config === null || typeof config !== 'object' || Array.isArray(config)) {
    throw new Error('ca_nhan/dulieucanhan.env phải là một JSON object.');
  }

  const issues = [];
  for (const name of Object.keys(config)) {
    if (isSecretName(name)) {
      issues.push(
        `${name}: không lưu bí mật server trong file cấu hình client.`,
      );
    }
  }

  for (const name of requiredStrings) {
    const value = config[name];
    if (typeof value !== 'string' || value.trim() === '') {
      issues.push(`${name}: thiếu giá trị dạng chuỗi.`);
    } else if (value !== value.trim()) {
      issues.push(`${name}: bỏ khoảng trắng ở đầu/cuối giá trị.`);
    } else if (/^(YOUR_|CHANGEME|REPLACE_ME)/i.test(value.trim())) {
      issues.push(`${name}: vẫn đang dùng giá trị mẫu.`);
    }
  }

  for (const name of urlKeys) {
    const value = config[name];
    if (
      typeof value === 'string' &&
      value.trim() !== '' &&
      !isValidHttpUrl(value.trim())
    ) {
      issues.push(`${name}: cần là URL HTTP(S) hợp lệ.`);
    }
  }

  if (typeof config.OVERPASS_FALLBACK_URLS === 'string') {
    const fallbackUrls = config.OVERPASS_FALLBACK_URLS
      .split(',')
      .map((url) => url.trim());
    if (
      fallbackUrls.some((url) => url === '' || !isValidHttpUrl(url))
    ) {
      issues.push(
        'OVERPASS_FALLBACK_URLS: mỗi URL phân tách bằng dấu phẩy phải hợp lệ.',
      );
    }
  }

  if (
    config.FIREBASE_MEASUREMENT_ID !== undefined &&
    typeof config.FIREBASE_MEASUREMENT_ID !== 'string'
  ) {
    issues.push('FIREBASE_MEASUREMENT_ID: cần là chuỗi nếu được khai báo.');
  }

  if (issues.length > 0) {
    throw new Error(
      `Cấu hình ca_nhan/dulieucanhan.env không hợp lệ:\n- ${issues.join('\n- ')}`,
    );
  }
}

export function validateConfigFile(configPath = defaultConfigPath) {
  let config;
  try {
    config = JSON.parse(readFileSync(configPath, 'utf8'));
  } catch (error) {
    if (error instanceof SyntaxError) {
      throw new Error(
        'JSON không đúng định dạng. Kiểm tra ca_nhan/dulieucanhan.env.',
      );
    }
    throw new Error(
      `Không đọc được ca_nhan/dulieucanhan.env (${error.code ?? 'lỗi không xác định'}).`,
    );
  }
  validateConfig(config);
  return config;
}

if (
  process.argv[1] &&
  path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
) {
  const configPath = process.argv[2] ?? defaultConfigPath;
  try {
    validateConfigFile(configPath);
    console.log('dulieucanhan.env hợp lệ.');
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
