import http from 'node:http';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync, renameSync, writeFileSync, existsSync, unlinkSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const port = Number(process.env.PORT || 8787);
const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const privateConfigPath = path.join(projectRoot, 'dulieucanhan.env');
const privateConfig = existsSync(privateConfigPath)
  ? JSON.parse(readFileSync(privateConfigPath, 'utf8'))
  : {};
const configuredUrl = (key) => {
  const value = process.env[key] || privateConfig[key];
  if (typeof value !== 'string' || value.trim() === '') {
    throw new Error(`Missing ${key} in dulieucanhan.env or process environment.`);
  }
  return value.trim();
};
const databasePath = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  'data',
  'places.sqlite',
);
const schemaPath = path.join(path.dirname(fileURLToPath(import.meta.url)), 'data', 'places.sql');
const dataDirectory = path.dirname(schemaPath);
const currentMapPath = path.join(dataDirectory, 'dia_diem_cao_lanh.json');
const currentSqlPath = path.join(dataDirectory, 'dia_diem_cao_lanh.sql');
const backupMapPath = path.join(dataDirectory, 'backup_dia_diem_cao_lanh.json');
const activeMapPath = path.join(dataDirectory, 'active_map_source.json');
const backupSqlPath = path.join(dataDirectory, 'backup_dia_diem_cao_lanh.sql');
const isCloudRuntime = Boolean(process.env.K_SERVICE || process.env.FUNCTION_TARGET);
const runtimeDatabasePath = process.env.SQLITE_DATABASE_PATH
  || (isCloudRuntime ? path.join(tmpdir(), 'places.sqlite') : databasePath);
const database = new DatabaseSync(runtimeDatabasePath);
database.exec(readFileSync(schemaPath, 'utf8'));
const seededPlaceCount = database.prepare('SELECT COUNT(*) AS count FROM places').get().count;
if (seededPlaceCount === 0 && existsSync(currentSqlPath)) {
  database.exec(readFileSync(currentSqlPath, 'utf8'));
}

function migrateLegacyPlaceCategories() {
  const migrationVersion = 1;
  database.exec(`
    CREATE TABLE IF NOT EXISTS app_migrations (
      version INTEGER PRIMARY KEY,
      applied_at TEXT NOT NULL
    )
  `);
  if (database.prepare('SELECT 1 FROM app_migrations WHERE version = ?')
    .get(migrationVersion)) {
    return;
  }

  database.exec('BEGIN');
  try {
    database.exec(`
      UPDATE places
      SET category = CASE lower(trim(category))
        WHEN 'park' THEN 'vui_choi'
        WHEN 'playground' THEN 'vui_choi'
        WHEN 'amusement_arcade' THEN 'vui_choi'
        WHEN 'water_park' THEN 'vui_choi'
        WHEN 'sports_centre' THEN 'vui_choi'
        WHEN 'stadium' THEN 'vui_choi'
        WHEN 'pitch' THEN 'vui_choi'
        WHEN 'fitness_centre' THEN 'vui_choi'
        WHEN 'swimming_pool' THEN 'vui_choi'
        WHEN 'cinema' THEN 'vui_choi'
        WHEN 'bar' THEN 'vui_choi'
        WHEN 'pub' THEN 'vui_choi'
        WHEN 'museum' THEN 'vui_choi'
        WHEN 'theme_park' THEN 'vui_choi'
        WHEN 'zoo' THEN 'vui_choi'
        WHEN 'attraction' THEN 'vui_choi'
        WHEN 'cafe' THEN 'cafe'
        WHEN 'restaurant' THEN 'quan_an'
        WHEN 'fast_food' THEN 'quan_an'
        WHEN 'school' THEN 'truong_hoc'
        WHEN 'college' THEN 'truong_hoc'
        WHEN 'university' THEN 'truong_hoc'
        WHEN 'kindergarten' THEN 'truong_hoc'
        WHEN 'guest_house' THEN 'tro'
        WHEN 'hostel' THEN 'tro'
        WHEN 'hotel' THEN 'tro'
        WHEN 'motel' THEN 'tro'
        WHEN 'apartment' THEN 'tro'
        WHEN 'chalet' THEN 'tro'
        WHEN 'alpine_hut' THEN 'tro'
        WHEN 'dormitory' THEN 'tro'
        WHEN 'bus_station' THEN 'ben_xe'
        WHEN 'bus_stop' THEN 'ben_xe'
        WHEN 'bus station' THEN 'ben_xe'
        WHEN 'supermarket' THEN 'mua_sam'
        WHEN 'convenience' THEN 'mua_sam'
        WHEN 'marketplace' THEN 'mua_sam'
        WHEN 'clothes' THEN 'mua_sam'
        WHEN 'mobile_phone' THEN 'mua_sam'
        WHEN 'variety_store' THEN 'mua_sam'
        WHEN 'jewelry' THEN 'mua_sam'
        WHEN 'optician' THEN 'mua_sam'
        WHEN 'furniture' THEN 'mua_sam'
        WHEN 'computer' THEN 'mua_sam'
        WHEN 'copyshop' THEN 'mua_sam'
        ELSE category
      END
      WHERE lower(trim(category)) IN (
        'park', 'playground', 'amusement_arcade', 'water_park',
        'sports_centre', 'stadium', 'pitch', 'fitness_centre',
        'swimming_pool', 'cinema', 'bar', 'pub', 'museum', 'theme_park',
        'zoo', 'attraction', 'cafe', 'restaurant', 'fast_food', 'school',
        'college', 'university', 'kindergarten', 'guest_house', 'hostel',
        'hotel', 'motel', 'apartment', 'chalet', 'alpine_hut', 'dormitory',
        'bus_station', 'bus_stop', 'bus station', 'supermarket',
        'convenience', 'marketplace', 'clothes', 'mobile_phone',
        'variety_store', 'jewelry', 'optician', 'furniture', 'computer',
        'copyshop'
      )
    `);
    database.prepare(`
      INSERT INTO app_migrations (version, applied_at)
      VALUES (?, datetime('now'))
    `).run(migrationVersion);
    database.exec('COMMIT');
  } catch (error) {
    database.exec('ROLLBACK');
    throw error;
  }
}

migrateLegacyPlaceCategories();

const overpassQueryTimeoutSeconds = Number(process.env.OVERPASS_QUERY_TIMEOUT_SECONDS || 25);
const upstreamTimeoutMs = Number(
  process.env.OVERPASS_TIMEOUT_MS || (overpassQueryTimeoutSeconds + 5) * 1000,
);
const osmApiTimeoutMs = Number(process.env.OSM_API_TIMEOUT_MS || 60000);
const mapBounds = {
  minLatitude: 10.4086,
  maxLatitude: 10.4848,
  minLongitude: 105.5707,
  maxLongitude: 105.6919,
};
const overpassUrls = [
  process.env.OVERPASS_URL || configuredUrl('OVERPASS_API_URL'),
  ...(process.env.OVERPASS_FALLBACK_URLS
    || configuredUrl('OVERPASS_FALLBACK_URLS')).split(','),
].map((url) => url.trim()).filter(Boolean);
const osmMapApiUrl = configuredUrl('OSM_MAP_API_URL');

function sendJson(response, status, body) {
  response.writeHead(status, {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json; charset=utf-8',
  });
  response.end(JSON.stringify(body));
}

async function requestJson(request) {
  if (request.body !== undefined) return request.body;
  const chunks = [];
  for await (const chunk of request) chunks.push(chunk);
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

function queryFor({latitude, longitude, radiusMeters}) {
  return `[out:json][timeout:${overpassQueryTimeoutSeconds}];(`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["amenity"~"^(cafe|restaurant|fast_food|bar|pub|cinema|school|college|university|dormitory|bus_station)$"];`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["leisure"~"^(park|playground|amusement_arcade|water_park|sports_centre|stadium|pitch|fitness_centre|swimming_pool)$"];`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["shop"];`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["tourism"~"^(theme_park|zoo|museum|attraction|guest_house|hostel|hotel|motel|apartment|chalet|alpine_hut)$"];`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["building"="dormitory"];`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["public_transport"="station"]["bus"="yes"];`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["highway"="bus_stop"];`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["public_transport"~"^(platform|stop_position)$"]["bus"="yes"];`
    + `);out center tags;`;
}

const appCategoryAliases = new Map([
  ['quan an', 'quan_an'],
  ['an uong', 'quan_an'],
  ['nha hang', 'quan_an'],
  ['food', 'quan_an'],
  ['restaurant', 'quan_an'],
  ['fast food', 'quan_an'],
  ['ca phe', 'cafe'],
  ['coffee', 'cafe'],
  ['tra sua', 'cafe'],
  ['truong hoc', 'truong_hoc'],
  ['school', 'truong_hoc'],
  ['college', 'truong_hoc'],
  ['university', 'truong_hoc'],
  ['kindergarten', 'truong_hoc'],
  ['tro', 'tro'],
  ['nha tro', 'tro'],
  ['phong tro', 'tro'],
  ['ky tuc xa', 'tro'],
  ['nha khach', 'tro'],
  ['nha nghi', 'tro'],
  ['khach san', 'tro'],
  ['luu tru', 'tro'],
  ['guest house', 'tro'],
  ['guesthouse', 'tro'],
  ['serviced apartment', 'tro'],
  ['homestay', 'tro'],
  ['hostel', 'tro'],
  ['dormitory', 'tro'],
  ['hotel', 'tro'],
  ['motel', 'tro'],
  ['apartment', 'tro'],
  ['chalet', 'tro'],
  ['alpine hut', 'tro'],
  ['ben xe', 'ben_xe'],
  ['bus station', 'ben_xe'],
  ['bus terminal', 'ben_xe'],
  ['bus stop', 'ben_xe'],
  ['transit stop', 'ben_xe'],
  ['diem dung', 'ben_xe'],
  ['diem dung xe buyt', 'ben_xe'],
  ['tram dung', 'ben_xe'],
  ['tram xe buyt', 'ben_xe'],
  ['vui choi', 'vui_choi'],
  ['giai tri', 'vui_choi'],
  ['cong vien', 'vui_choi'],
  ['rap phim', 'vui_choi'],
  ['park', 'vui_choi'],
  ['playground', 'vui_choi'],
  ['amusement arcade', 'vui_choi'],
  ['water park', 'vui_choi'],
  ['sports centre', 'vui_choi'],
  ['stadium', 'vui_choi'],
  ['pitch', 'vui_choi'],
  ['fitness centre', 'vui_choi'],
  ['swimming pool', 'vui_choi'],
  ['cinema', 'vui_choi'],
  ['bar', 'vui_choi'],
  ['pub', 'vui_choi'],
  ['museum', 'vui_choi'],
  ['theme park', 'vui_choi'],
  ['zoo', 'vui_choi'],
  ['attraction', 'vui_choi'],
  ['mua sam', 'mua_sam'],
  ['cua hang', 'mua_sam'],
  ['shop', 'mua_sam'],
  ['sieu thi', 'mua_sam'],
  ['cho', 'mua_sam'],
  ['supermarket', 'mua_sam'],
  ['convenience', 'mua_sam'],
  ['marketplace', 'mua_sam'],
  ['clothes', 'mua_sam'],
  ['mobile phone', 'mua_sam'],
  ['variety store', 'mua_sam'],
  ['jewelry', 'mua_sam'],
  ['optician', 'mua_sam'],
  ['furniture', 'mua_sam'],
  ['computer', 'mua_sam'],
  ['copyshop', 'mua_sam'],
]);

function normalizeCategoryKey(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replaceAll('đ', 'd')
    .replace(/[_-]+/g, ' ')
    .trim()
    .replace(/\s+/g, ' ');
}

function categoryForTags(tags) {
  const appCategory = normalizeCategoryKey(tags['app:category']);
  const mappedAppCategory = appCategoryAliases.get(appCategory)
    || (['quan_an', 'cafe', 'truong_hoc', 'tro', 'ben_xe', 'vui_choi', 'mua_sam', 'khac']
      .includes(appCategory)
      ? appCategory
      : null);
  const lodging = ['guest_house', 'hostel', 'hotel', 'motel', 'apartment', 'chalet', 'alpine_hut'];
  const leisure = [
    'park', 'playground', 'amusement_arcade', 'water_park', 'sports_centre',
    'stadium', 'pitch', 'fitness_centre', 'swimming_pool',
  ];
  const attractions = ['theme_park', 'zoo', 'museum', 'attraction'];
  if (tags.amenity === 'bus_station'
    || tags.highway === 'bus_stop'
    || (['platform', 'stop_position', 'station'].includes(tags.public_transport)
      && tags.bus === 'yes')) return 'ben_xe';
  if (lodging.includes(tags.tourism)
    || ['hotel', 'hostel', 'guest_house'].includes(tags.amenity)
    || tags.amenity === 'dormitory'
    || tags.building === 'dormitory') return 'tro';
  if (['school', 'college', 'university', 'kindergarten'].includes(tags.amenity)) {
    return 'truong_hoc';
  }
  if (tags.amenity === 'cafe') return 'cafe';
  if (['restaurant', 'fast_food'].includes(tags.amenity)) return 'quan_an';
  if (['bar', 'pub', 'cinema'].includes(tags.amenity)
    || leisure.includes(tags.leisure)
    || attractions.includes(tags.tourism)) return 'vui_choi';
  if (tags.shop) return 'mua_sam';

  if (mappedAppCategory && mappedAppCategory !== 'khac') return mappedAppCategory;

  const name = normalizeCategoryKey(tags.name || tags['name:vi']);
  if (/nha\s*(khach|tro|nghi)|ky\s*tuc\s*xa|khach\s*san|hostel|guest\s*house/.test(name)) {
    return 'tro';
  }
  if (/ben\s*xe|tram\s*xe\s*buyt|diem\s*dung\s*xe\s*buyt/.test(name)) return 'ben_xe';
  if (/giao\s*duc|truong\s*hoc|hoc\s*tap/.test(name)) return 'truong_hoc';
  if (/cong\s*vien|\bpark\b/.test(name)) return 'vui_choi';
  return mappedAppCategory || 'khac';
}

function updateCenters() {
  const minLatitude = 10.4086;
  const maxLatitude = 10.4848;
  const minLongitude = 105.5707;
  const maxLongitude = 105.6919;
  const latitudeStep = 0.012;
  const longitudeStep = 0.012 / Math.cos(10.45 * Math.PI / 180);
  const centers = [];
  for (let latitude = minLatitude; latitude <= maxLatitude; latitude += latitudeStep) {
    for (let longitude = minLongitude; longitude <= maxLongitude; longitude += longitudeStep) {
      centers.push({latitude, longitude});
    }
  }
  return centers;
}

function validRequest(value) {
  return value && Number.isFinite(value.latitude)
    && Number.isFinite(value.longitude)
    && Number.isFinite(value.radiusMeters)
    && value.radiusMeters > 0 && value.radiusMeters <= 10000
    && value.latitude >= -90 && value.latitude <= 90
    && value.longitude >= -180 && value.longitude <= 180;
}

function localDatabaseElements() {
  return database.prepare(`
    SELECT id, name, category, latitude, longitude, address, phone, hours
    FROM places ORDER BY name
  `).all().map((row) => ({
    type: 'node',
    id: row.id,
    lat: row.latitude,
    lon: row.longitude,
    tags: {
      name: row.name,
      'app:category': row.category,
      'addr:full': row.address,
      phone: row.phone,
      opening_hours: row.hours,
      source: 'local-cao-lanh-sql',
    },
  }));
}

function nearbyDatabaseElements({latitude, longitude, radiusMeters}) {
  const latitudeRadius = radiusMeters / 111320;
  const longitudeRadius = latitudeRadius / Math.max(Math.cos(latitude * Math.PI / 180), 0.1);
  const rows = database.prepare(`
    SELECT id, name, category, latitude, longitude, address, phone, hours
    FROM places
    WHERE latitude BETWEEN ? AND ?
      AND longitude BETWEEN ? AND ?
  `).all(
    latitude - latitudeRadius,
    latitude + latitudeRadius,
    longitude - longitudeRadius,
    longitude + longitudeRadius,
  );
  return rows
    .map((row) => ({
      ...row,
      distance: distanceMeters(latitude, longitude, row.latitude, row.longitude),
    }))
    .filter((row) => row.distance <= radiusMeters)
    .sort((a, b) => a.distance - b.distance)
    .map((row) => ({
      type: 'node',
      id: row.id,
      lat: row.latitude,
      lon: row.longitude,
      tags: {
        name: row.name,
        'app:category': row.category,
        'addr:full': row.address,
        phone: row.phone,
        opening_hours: row.hours,
        source: 'dia_diem_cao_lanh-sql',
      },
    }));
}

function distanceMeters(latitudeA, longitudeA, latitudeB, longitudeB) {
  const radians = Math.PI / 180;
  const latitudeDelta = (latitudeB - latitudeA) * radians;
  const longitudeDelta = (longitudeB - longitudeA) * radians;
  const a = Math.sin(latitudeDelta / 2) ** 2
    + Math.cos(latitudeA * radians)
    * Math.cos(latitudeB * radians)
    * Math.sin(longitudeDelta / 2) ** 2;
  return 6371000 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function saveMapElements(elements, source = 'overpass') {
  const statement = database.prepare(`
    INSERT OR REPLACE INTO places
      (id, name, category, latitude, longitude, address, phone, hours, source, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
  `);
  database.exec('BEGIN');
  try {
    database.prepare(
      "DELETE FROM places WHERE source IN ('overpass', 'osm-api', 'admin-selected')",
    ).run();
    for (const element of elements) {
      const tags = element.tags || {};
      const latitude = element.lat ?? element.center?.lat;
      const longitude = element.lon ?? element.center?.lon;
      if (!isPlace(tags) || latitude == null || longitude == null) continue;
      statement.run(
        `osm-${element.type}-${element.id}`,
        tags.name,
        categoryForTags(tags),
        latitude,
        longitude,
        tags['addr:full'] || [tags['addr:housenumber'], tags['addr:street']]
          .filter(Boolean).join(' '),
        tags.phone || tags['contact:phone'] || '',
        tags.opening_hours || '',
        source,
      );
    }
    database.exec('COMMIT');
  } catch (error) {
    database.exec('ROLLBACK');
    throw error;
  }
}

function sqlValue(value) {
  return `'${String(value ?? '').replaceAll("'", "''")}'`;
}

function writeMapSnapshot(
  elements,
  source = 'overpass',
  updatedAt = new Date().toISOString(),
) {
  const placeElements = elements.filter((element) => isPlace(element.tags || {}));
  const snapshot = `${JSON.stringify({
    source,
    updatedAt,
    elements: placeElements,
  }, null, 2)}\n`;
  const sql = [
    '-- Generated from OpenStreetMap data. Do not edit manually.',
    'BEGIN TRANSACTION;',
    "DELETE FROM places WHERE source IN ('overpass', 'osm-api', 'admin-selected');",
    ...placeElements.flatMap((element) => {
      const tags = element.tags || {};
      const latitude = element.lat ?? element.center?.lat;
      const longitude = element.lon ?? element.center?.lon;
      if (!tags.name || latitude == null || longitude == null) return [];
      const category = categoryForTags(tags);
      const address = tags['addr:full']
        || [tags['addr:housenumber'], tags['addr:street']].filter(Boolean).join(' ');
      return [
        `INSERT OR REPLACE INTO places `
          + '(id, name, category, latitude, longitude, address, phone, hours, source, updated_at) VALUES ('
          + [
            sqlValue(`osm-${element.type}-${element.id}`),
            sqlValue(tags.name),
            sqlValue(category),
            Number(latitude),
            Number(longitude),
            sqlValue(address),
            sqlValue(tags.phone || tags['contact:phone'] || ''),
            sqlValue(tags.opening_hours || ''),
            sqlValue(source),
            sqlValue(updatedAt),
          ].join(', ') + ');',
      ];
    }),
    'COMMIT;',
    '',
  ].join('\n');
  if (existsSync(currentMapPath)) {
    if (existsSync(backupMapPath)) unlinkSync(backupMapPath);
    renameSync(currentMapPath, backupMapPath);
  }
  if (existsSync(currentSqlPath)) {
    if (existsSync(backupSqlPath)) unlinkSync(backupSqlPath);
    renameSync(currentSqlPath, backupSqlPath);
  }
  writeFileSync(currentMapPath, snapshot, 'utf8');
  writeFileSync(currentSqlPath, sql, 'utf8');
}

function mapSourcePath(source) {
  if (source === 'current') return currentMapPath;
  if (source === 'backup') return backupMapPath;
  throw new Error('Nguồn dữ liệu bản đồ không hợp lệ.');
}

function activeMapSource() {
  if (!existsSync(activeMapPath)) return 'current';
  try {
    const selection = JSON.parse(readFileSync(activeMapPath, 'utf8'));
    if (['current', 'backup'].includes(selection.source)
      && existsSync(mapSourcePath(selection.source))) {
      return selection.source;
    }
  } catch (error) {
    console.warn('Could not read active map source:', error);
  }
  return 'current';
}

function mapSourceInfo(source) {
  const file = mapSourcePath(source);
  if (!existsSync(file)) return null;
  const snapshot = JSON.parse(readFileSync(file, 'utf8'));
  if (!snapshot || !Array.isArray(snapshot.elements)) {
    throw new Error(`${path.basename(file)} không chứa danh sách địa điểm hợp lệ.`);
  }
  return {
    source,
    label: source === 'current' ? 'Địa điểm Cao Lãnh mới' : 'Địa điểm Cao Lãnh cũ',
    file: path.basename(file),
    count: snapshot.elements.length,
    updatedAt: snapshot.updatedAt || null,
    active: activeMapSource() === source,
  };
}

function availableMapSources() {
  return ['current', 'backup']
    .map(mapSourceInfo)
    .filter(Boolean);
}

function selectMapSource(source) {
  const file = mapSourcePath(source);
  if (!existsSync(file)) {
    throw new Error(`Không tìm thấy file dữ liệu ${path.basename(file)}.`);
  }
  const snapshot = JSON.parse(readFileSync(file, 'utf8'));
  if (!snapshot || !Array.isArray(snapshot.elements)) {
    throw new Error(`${path.basename(file)} không chứa danh sách địa điểm hợp lệ.`);
  }
  const elements = snapshot.elements.filter((element) => isPlace(element.tags || {}));
  saveMapElements(elements, 'admin-selected');
  writeFileSync(activeMapPath, `${JSON.stringify({source}, null, 2)}\n`, 'utf8');
  return {source, file: path.basename(file), count: elements.length};
}

function loadMapSnapshot() {
  const source = activeMapSource();
  const info = mapSourceInfo(source);
  if (!info) return;
  const file = mapSourcePath(source);
  const snapshot = JSON.parse(readFileSync(file, 'utf8'));
  saveMapElements(
    snapshot.elements.filter((element) => isPlace(element.tags || {})),
    source === 'backup' ? 'admin-selected' : snapshot.source || 'overpass',
  );
}

async function updateMapFromOverpass() {
  const elementsById = new Map();
  const centers = updateCenters();
  let nextCenterIndex = 0;

  async function loadChunk(center) {
    const attempts = overpassUrls.map(async (overpassUrl) => {
      const response = await fetch(overpassUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'vn.diadiem.quanhday-local-proxy',
        },
        body: new URLSearchParams({
          data: queryFor({...center, radiusMeters: 1000}),
        }),
        signal: AbortSignal.timeout(upstreamTimeoutMs),
      });
      if (!response.ok) {
        throw new Error(`Overpass returned ${response.status}`);
      }
      const decoded = await response.json();
      if (!Array.isArray(decoded.elements)) {
        throw new Error('Overpass response has no elements array');
      }
      return decoded.elements;
    });

    try {
      return await Promise.any(attempts);
    } catch (error) {
      const failures = error instanceof AggregateError
        ? error.errors.map((failure) => failure instanceof Error ? failure.message : String(failure))
        : ['Overpass unavailable'];
      throw new Error(
        `Không tải được ô ${center.latitude.toFixed(4)},${center.longitude.toFixed(4)}: ${failures.join('; ')}`,
      );
    }
  }

  async function worker() {
    while (nextCenterIndex < centers.length) {
      const center = centers[nextCenterIndex++];
      const elements = await loadChunk(center);
      for (const element of elements) {
        if (element.type != null && element.id != null) {
          elementsById.set(`${element.type}/${element.id}`, element);
        }
      }
    }
  }

  const workerCount = Math.min(3, centers.length);
  await Promise.all(Array.from({length: workerCount}, () => worker()));

  const elements = [...elementsById.values()].filter((element) =>
    isPlace(element.tags || {}),
  );
  saveMapElements(elements, 'overpass');
  writeMapSnapshot(elements, 'overpass');
  writeFileSync(activeMapPath, `${JSON.stringify({source: 'current'}, null, 2)}\n`, 'utf8');
  return {count: elements.length, chunks: centers.length};
}

function decodeXml(value) {
  return value
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>');
}

function xmlAttributes(value) {
  const attributes = {};
  for (const match of value.matchAll(/([A-Za-z_:][\w:.-]*)="([^"]*)"/g)) {
    attributes[match[1]] = decodeXml(match[2]);
  }
  return attributes;
}

function xmlTags(value) {
  const tags = {};
  for (const match of value.matchAll(/<tag\b([^>]*)\/>/g)) {
    const attributes = xmlAttributes(match[1]);
    if (attributes.k && attributes.v) tags[attributes.k] = attributes.v;
  }
  return tags;
}

function isPlace(tags) {
  if (!String(tags.name || tags['name:vi'] || '').trim()) return false;
  const highway = String(tags.highway || '').trim();
  if (!highway || highway === 'bus_stop' || highway === 'platform') return true;
  return [
    'amenity',
    'shop',
    'leisure',
    'tourism',
    'public_transport',
    'historic',
    'building',
    'place',
  ].some((key) => Boolean(tags[key]));
}

function parseOsmMapXml(xml) {
  const nodes = new Map();
  const elements = [];
  const nodePattern = /<node\b([^>]*?)(?:\/>|>([\s\S]*?)<\/node>)/g;
  for (const match of xml.matchAll(nodePattern)) {
    const attributes = xmlAttributes(match[1]);
    const latitude = Number(attributes.lat);
    const longitude = Number(attributes.lon);
    if (!attributes.id || !Number.isFinite(latitude) || !Number.isFinite(longitude)) continue;
    const tags = xmlTags(match[2] || '');
    nodes.set(attributes.id, {lat: latitude, lon: longitude});
    if (isPlace(tags)) elements.push({type: 'node', id: Number(attributes.id), lat: latitude, lon: longitude, tags});
  }

  const wayPattern = /<way\b([^>]*?)>([\s\S]*?)<\/way>/g;
  for (const match of xml.matchAll(wayPattern)) {
    const attributes = xmlAttributes(match[1]);
    const tags = xmlTags(match[2]);
    if (!attributes.id || !isPlace(tags)) continue;
    const coordinates = [...match[2].matchAll(/<nd\b([^>]*)\/>/g)]
      .map((ref) => nodes.get(xmlAttributes(ref[1]).ref))
      .filter(Boolean);
    if (coordinates.length === 0) continue;
    const center = coordinates.reduce(
      (sum, point) => ({lat: sum.lat + point.lat, lon: sum.lon + point.lon}),
      {lat: 0, lon: 0},
    );
    elements.push({
      type: 'way',
      id: Number(attributes.id),
      center: {
        lat: center.lat / coordinates.length,
        lon: center.lon / coordinates.length,
      },
      tags,
    });
  }
  return elements;
}

async function updateMapFromOsmApi() {
  const latitudeStep = 0.025;
  const longitudeStep = 0.04;
  const bounds = [];
  for (let minLatitude = mapBounds.minLatitude; minLatitude < mapBounds.maxLatitude; minLatitude += latitudeStep) {
    for (let minLongitude = mapBounds.minLongitude; minLongitude < mapBounds.maxLongitude; minLongitude += longitudeStep) {
      bounds.push({
        minLatitude,
        minLongitude,
        maxLatitude: Math.min(minLatitude + latitudeStep, mapBounds.maxLatitude),
        maxLongitude: Math.min(minLongitude + longitudeStep, mapBounds.maxLongitude),
      });
    }
  }
  const elementsById = new Map();
  let nextBoundsIndex = 0;
  async function loadBounds(bound) {
    const url = `${osmMapApiUrl}?bbox=${
      bound.minLongitude},${bound.minLatitude},${bound.maxLongitude},${bound.maxLatitude}`;
    const response = await fetch(url, {
      headers: {'User-Agent': 'vn.diadiem.quanhday-local-proxy/1.0'},
      signal: AbortSignal.timeout(osmApiTimeoutMs),
    });
    if (!response.ok) throw new Error(`OpenStreetMap API returned ${response.status}`);
    return parseOsmMapXml(await response.text());
  }
  async function worker() {
    while (nextBoundsIndex < bounds.length) {
      const bound = bounds[nextBoundsIndex++];
      const chunk = await loadBounds(bound);
      for (const element of chunk) {
        elementsById.set(`${element.type}/${element.id}`, element);
      }
    }
  }
  await Promise.all(Array.from({length: 2}, () => worker()));
  const elements = [...elementsById.values()];
  if (elements.length === 0) throw new Error('OpenStreetMap API returned no named places');
  saveMapElements(elements, 'osm-api');
  writeMapSnapshot(elements, 'osm-api');
  writeFileSync(activeMapPath, `${JSON.stringify({source: 'current'}, null, 2)}\n`, 'utf8');
  return {count: elements.length, chunks: bounds.length, source: 'osm-api'};
}

async function updateMapFromSources() {
  try {
    return await updateMapFromOverpass();
  } catch (overpassError) {
    console.warn(`Overpass failed, trying OpenStreetMap API: ${
      overpassError instanceof Error ? overpassError.message : String(overpassError)
    }`);
    try {
      return await updateMapFromOsmApi();
    } catch (osmError) {
      throw new Error(
        `Overpass và OpenStreetMap API đều thất bại: ${
          osmError instanceof Error ? osmError.message : String(osmError)
        }`,
      );
    }
  }
}

loadMapSnapshot();

function sendLocalFallback(response, failure, input) {
  const elements = localDatabaseElements().filter((element) =>
    distanceMeters(
      input.latitude,
      input.longitude,
      element.lat,
      element.lon,
    ) <= input.radiusMeters,
  );
  console.warn(`Using local map database after nearby query failure: ${failure}`);
  sendJson(response, 200, {
    elements,
    source: 'local-cao-lanh-database',
  });
}

const server = http.createServer(async (request, response) => {
  if (request.method === 'OPTIONS') {
    sendJson(response, 204, {});
    return;
  }
  if (request.method === 'GET' && request.url === '/health') {
    sendJson(response, 200, {ok: true, service: 'nearby-overpass-proxy'});
    return;
  }
  if (request.method === 'GET' && request.url === '/api/offline-places') {
    const activeSource = activeMapSource();
    sendJson(response, 200, {
      source: existsSync(mapSourcePath(activeSource))
        ? path.basename(mapSourcePath(activeSource))
        : 'local-cao-lanh-sql',
      elements: localDatabaseElements(),
    });
    return;
  }
  if (request.method === 'GET' && request.url === '/api/admin/map-sources') {
    if (isCloudRuntime) {
      sendJson(response, 501, {
        error: 'Quản lý snapshot bản đồ hiện chỉ được hỗ trợ trên backend local.',
      });
      return;
    }
    try {
      sendJson(response, 200, {sources: availableMapSources()});
    } catch (error) {
      console.error('Could not list map snapshots:', error);
      sendJson(response, 500, {
        error: error instanceof Error ? error.message : 'Could not list map snapshots',
      });
    }
    return;
  }
  if (request.method === 'POST' && request.url === '/api/admin/select-map') {
    if (isCloudRuntime) {
      sendJson(response, 501, {
        error: 'Chọn snapshot bản đồ hiện chỉ được hỗ trợ trên backend local.',
      });
      return;
    }
    try {
      const input = await requestJson(request);
      if (!input || !['current', 'backup'].includes(input.source)) {
        sendJson(response, 400, {error: 'Nguồn dữ liệu bản đồ không hợp lệ.'});
        return;
      }
      sendJson(response, 200, selectMapSource(input.source));
    } catch (error) {
      console.error('Admin map selection failed:', error);
      sendJson(response, 400, {
        error: error instanceof Error ? error.message : 'Could not select map data',
      });
    }
    return;
  }
  if (request.method === 'POST' && request.url === '/api/admin/update-map') {
    if (isCloudRuntime) {
      sendJson(response, 501, {
        error: 'Cập nhật dữ liệu bản đồ hiện chỉ được hỗ trợ trên backend local.',
      });
      return;
    }
    try {
      const result = await updateMapFromSources();
      sendJson(response, 200, {
        source: result.source || 'overpass',
        count: result.count,
        chunks: result.chunks,
        file: 'dia_diem_cao_lanh.json',
        backup: 'backup_dia_diem_cao_lanh.json',
      });
    } catch (error) {
      console.error('Admin map update failed:', error);
      sendJson(response, 502, {
        error: error instanceof Error ? error.message : 'Map update failed',
      });
    }
    return;
  }
  if (request.method !== 'POST' || request.url !== '/api/nearby') {
    sendJson(response, 404, {error: 'Not found'});
    return;
  }

  let input;
  try {
    input = await requestJson(request);
  } catch {
    sendJson(response, 400, {error: 'Invalid JSON request body'});
    return;
  }
  if (!validRequest(input)) {
    sendJson(response, 400, {error: 'Invalid location or radius'});
    return;
  }

  try {
    sendJson(response, 200, {
      elements: nearbyDatabaseElements(input),
      source: 'dia_diem_cao_lanh-sql',
    });
  } catch (error) {
    console.error('Nearby proxy request failed:', error);
    try {
      sendLocalFallback(
        response,
        error instanceof Error ? error.message : 'Nearby query failed',
        input,
      );
    } catch (fallbackError) {
      console.error('Local map database failed:', fallbackError);
      sendJson(response, 502, {error: 'Overpass and local map database unavailable'});
    }
  }
});

export {categoryForTags, database, isPlace, server, writeMapSnapshot};

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  server.listen(port, process.env.HOST || '127.0.0.1', () => {
    console.log(`Nearby proxy listening on port ${port}`);
  });
}
