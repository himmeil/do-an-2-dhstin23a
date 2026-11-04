import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {test} from 'node:test';
import {validateConfig} from '../../scripts/validate_dulieucanhan_env.mjs';

const exampleConfig = JSON.parse(
  readFileSync(new URL('../../dulieucanhan.env.example', import.meta.url), 'utf8'),
);

function validConfig() {
  return Object.fromEntries(
    Object.entries(exampleConfig).map(([name, value]) => [
      name,
      typeof value === 'string' && value.startsWith('YOUR_')
        ? `configured-${name.toLowerCase()}`
        : value,
    ]),
  );
}

test('accepts configured service URLs, Firebase client settings, and tile templates', () => {
  assert.doesNotThrow(() => validateConfig(validConfig()));
});

test('rejects missing and placeholder values without printing their contents', () => {
  const config = validConfig();
  config.FIREBASE_PROJECT_ID = 'YOUR_FIREBASE_PROJECT_ID';
  delete config.STREET_TILE_URL;

  assert.throws(
    () => validateConfig(config),
    (error) =>
      error.message.includes('FIREBASE_PROJECT_ID') &&
      error.message.includes('STREET_TILE_URL') &&
      !error.message.includes('YOUR_FIREBASE_PROJECT_ID'),
  );
});

test('rejects malformed or credential-bearing URLs', () => {
  const config = validConfig();
  config.NOMINATIM_SEARCH_URL = 'not-a-url';
  config.STREET_TILE_URL = 'https://user:password@example.com/{z}/{x}/{y}.png';

  assert.throws(
    () => validateConfig(config),
    (error) =>
      error.message.includes('NOMINATIM_SEARCH_URL') &&
      error.message.includes('STREET_TILE_URL') &&
      !error.message.includes('password'),
  );
});

test('rejects values with accidental surrounding whitespace', () => {
  const config = validConfig();
  config.NEARBY_API_BASE_URL = ` ${config.NEARBY_API_BASE_URL} `;

  assert.throws(
    () => validateConfig(config),
    (error) => error.message.includes('NEARBY_API_BASE_URL'),
  );
});

test('rejects server secrets from the client build config', () => {
  const config = {
    ...validConfig(),
    FIREBASE_SERVICE_ACCOUNT: 'do-not-print',
    THIRD_PARTY_API_KEY: 'also-do-not-print',
  };

  assert.throws(
    () => validateConfig(config),
    (error) =>
      error.message.includes('FIREBASE_SERVICE_ACCOUNT') &&
      error.message.includes('THIRD_PARTY_API_KEY') &&
      !error.message.includes('do-not-print'),
  );
});
