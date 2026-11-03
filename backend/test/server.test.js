import assert from 'node:assert/strict';
import {after, before, test} from 'node:test';
import {mkdtempSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';

const temporaryDirectory = mkdtempSync(path.join(tmpdir(), 'nearby-api-test-'));
process.env.K_SERVICE = 'nearby-api-test';
process.env.SQLITE_DATABASE_PATH = path.join(temporaryDirectory, 'places.sqlite');

const {database, server} = await import('../server.js');

before(async () => {
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
});

after(async () => {
  await new Promise((resolve, reject) => {
    server.close((error) => error ? reject(error) : resolve());
  });
  database.close();
  rmSync(temporaryDirectory, {recursive: true, force: true});
});

const baseUrl = () => `http://127.0.0.1:${server.address().port}`;

test('health endpoint responds from the cloud runtime', async () => {
  const response = await fetch(`${baseUrl()}/health`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    ok: true,
    service: 'nearby-overpass-proxy',
  });
});

test('cloud runtime seeds and serves the bundled SQL places', async () => {
  const response = await fetch(`${baseUrl()}/api/nearby`, {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
      latitude: 10.46,
      longitude: 105.63,
      radiusMeters: 5000,
    }),
  });
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.source, 'dia_diem_cao_lanh-sql');
  assert.ok(body.elements.length > 0);
});

test('cloud runtime serves the offline places endpoint', async () => {
  const response = await fetch(`${baseUrl()}/api/offline-places`);
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.ok(body.elements.length > 0);
});

test('cloud runtime does not expose local map mutation endpoints', async () => {
  const response = await fetch(`${baseUrl()}/api/admin/update-map`, {
    method: 'POST',
  });
  assert.equal(response.status, 501);
});
