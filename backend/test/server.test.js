import assert from 'node:assert/strict';
import {after, before, test} from 'node:test';
import {mkdtempSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';

const temporaryDirectory = mkdtempSync(path.join(tmpdir(), 'nearby-api-test-'));
process.env.K_SERVICE = 'nearby-api-test';
process.env.SQLITE_DATABASE_PATH = path.join(temporaryDirectory, 'places.sqlite');

const {categoryForTags, database, isPlace, server} = await import('../server.js');

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
  for (const element of body.elements) {
    const latitudeDelta = (element.lat - 10.46) * Math.PI / 180;
    const longitudeDelta = (element.lon - 105.63) * Math.PI / 180;
    const a = Math.sin(latitudeDelta / 2) ** 2
      + Math.cos(10.46 * Math.PI / 180)
      * Math.cos(element.lat * Math.PI / 180)
      * Math.sin(longitudeDelta / 2) ** 2;
    const distance = 6371000 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    assert.ok(distance <= 5000);
  }
});

test('legacy OSM activity categories are migrated to application categories', () => {
  const places = database.prepare(`
    SELECT name, category FROM places
    WHERE id IN ('osm-way-169406235', 'osm-node-14256264925', 'osm-way-169958985')
  `).all();
  assert.equal(places.length, 3);
  for (const place of places) {
    assert.equal(place.category, 'vui_choi', place.name);
  }
});

test('map category aliases normalize lodging and transit variants', () => {
  for (const category of [
    'nha_tro',
    'nhà trọ',
    'khach_san',
    'khách sạn',
    'hotel',
    'guest_house',
    'bus_stop',
    'bus_station',
  ]) {
    const expected = category.includes('bus') ? 'ben_xe' : 'tro';
    assert.equal(categoryForTags({'app:category': category}), expected, category);
  }
});

test('explicit OSM categories override name heuristics; unknown categories stay unknown', () => {
  assert.equal(
    categoryForTags({
      name: 'Công viên cà phê',
      amenity: 'cafe',
      'app:category': 'khac',
    }),
    'cafe',
  );
  assert.equal(
    categoryForTags({name: 'Quán ăn', 'app:category': 'not_a_known_category'}),
    'khac',
  );
});

test('map import keeps named places and transit stops but skips road segments', () => {
  assert.equal(isPlace({name: 'Bến xe', amenity: 'bus_station'}), true);
  assert.equal(isPlace({name: 'Trạm xe buýt', highway: 'bus_stop'}), true);
  assert.equal(isPlace({name: 'Địa điểm chưa phân loại', amenity: 'unknown'}), true);
  assert.equal(isPlace({name: 'Đường Lê Lợi', highway: 'residential'}), false);
  assert.equal(
    isPlace({name: 'Quán cà phê trên đường', highway: 'service', amenity: 'cafe'}),
    true,
  );
  assert.equal(isPlace({highway: 'bus_stop'}), false);
});

test('nearby endpoint rejects malformed JSON instead of returning unfiltered places', async () => {
  const response = await fetch(`${baseUrl()}/api/nearby`, {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: '{',
  });
  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), {
    error: 'Invalid JSON request body',
  });
});

test('nearby coordinate lookup uses the spatial prefilter index', () => {
  const plan = database.prepare(`
    EXPLAIN QUERY PLAN
    SELECT id FROM places
    WHERE latitude BETWEEN ? AND ?
      AND longitude BETWEEN ? AND ?
  `).all(10.4, 10.5, 105.5, 105.7);

  assert.ok(
    plan.some((step) => step.detail.includes('idx_places_coordinates')),
    `Expected coordinate index in query plan, got: ${plan.map((step) => step.detail).join('; ')}`,
  );
});

test('cloud runtime serves the offline places endpoint', async () => {
  const response = await fetch(`${baseUrl()}/api/offline-places`);
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.ok(body.elements.length > 0);
  const museum = body.elements.find(
    (element) => element.tags.name === 'Bảo tàng Đồng Tháp',
  );
  assert.equal(museum.tags['app:category'], 'vui_choi');
});

test('cloud runtime does not expose local map mutation endpoints', async () => {
  const response = await fetch(`${baseUrl()}/api/admin/update-map`, {
    method: 'POST',
  });
  assert.equal(response.status, 501);
});
