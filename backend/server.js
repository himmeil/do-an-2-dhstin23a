import http from 'node:http';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync, renameSync, writeFileSync, existsSync, unlinkSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const port = Number(process.env.PORT || 8787);
const databasePath = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  'data',
  'places.sqlite',
);
const database = new DatabaseSync(databasePath);
const schemaPath = path.join(path.dirname(fileURLToPath(import.meta.url)), 'data', 'places.sql');
const dataDirectory = path.dirname(schemaPath);
const currentMapPath = path.join(dataDirectory, 'dia_diem_cao_lanh.json');
const backupMapPath = path.join(dataDirectory, 'backup_dia_diem_cao_lanh.json');
const currentSqlPath = path.join(dataDirectory, 'dia_diem_cao_lanh.sql');
const backupSqlPath = path.join(dataDirectory, 'backup_dia_diem_cao_lanh.sql');
database.exec(readFileSync(schemaPath, 'utf8'));
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
  process.env.OVERPASS_URL,
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
].filter(Boolean);

function sendJson(response, status, body) {
  response.writeHead(status, {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json; charset=utf-8',
  });
  response.end(JSON.stringify(body));
}

function queryFor({latitude, longitude, radiusMeters}) {
  return `[out:json][timeout:${overpassQueryTimeoutSeconds}];(`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["amenity"~"^(cafe|restaurant|fast_food|bar|pub|cinema|school|college|university)$"];`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["leisure"~"^(park|playground|amusement_arcade|water_park|sports_centre|stadium)$"];`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["shop"];`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["tourism"~"^(theme_park|zoo|museum|attraction)$"];`
    + `);out center tags;`;
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
    database.prepare("DELETE FROM places WHERE source IN ('overpass', 'osm-api')").run();
    for (const element of elements) {
      const tags = element.tags || {};
      const latitude = element.lat ?? element.center?.lat;
      const longitude = element.lon ?? element.center?.lon;
      if (!tags.name || latitude == null || longitude == null) continue;
      statement.run(
        `osm-${element.type}-${element.id}`,
        tags.name,
        tags['app:category'] || tags.amenity || tags.leisure || tags.shop
          || tags.tourism || tags.place || tags.highway || tags.building || 'khac',
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

function writeMapSnapshot(elements, source = 'overpass') {
  const snapshot = `${JSON.stringify({
    source,
    updatedAt: new Date().toISOString(),
    elements,
  }, null, 2)}\n`;
  const sql = [
    '-- Generated from OpenStreetMap data. Do not edit manually.',
    'BEGIN TRANSACTION;',
    "DELETE FROM places WHERE source IN ('overpass', 'osm-api');",
    ...elements.flatMap((element) => {
      const tags = element.tags || {};
      const latitude = element.lat ?? element.center?.lat;
      const longitude = element.lon ?? element.center?.lon;
      if (!tags.name || latitude == null || longitude == null) return [];
      const category = tags['app:category'] || tags.amenity || tags.leisure || tags.shop
        || tags.tourism || tags.place || tags.highway || tags.building || 'khac';
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
            sqlValue(new Date().toISOString()),
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

function loadMapSnapshot() {
  if (!existsSync(currentMapPath)) return;
  const snapshot = JSON.parse(readFileSync(currentMapPath, 'utf8'));
  if (!snapshot || !Array.isArray(snapshot.elements)) {
    throw new Error('dia_diem_cao_lanh.json has no elements array');
  }
  saveMapElements(snapshot.elements, 'overpass');
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

  const elements = [...elementsById.values()];
  saveMapElements(elements, 'overpass');
  writeMapSnapshot(elements, 'overpass');
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
  return Boolean(tags.name);
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
    const url = `https://api.openstreetmap.org/api/0.6/map?bbox=${
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

function sendLocalFallback(response, failure) {
  const elements = localDatabaseElements();
  console.warn(`Using local map database after Overpass failure: ${failure}`);
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
    sendJson(response, 200, {
      source: existsSync(currentMapPath)
        ? 'dia_diem_cao_lanh.json'
        : 'local-cao-lanh-sql',
      elements: localDatabaseElements(),
    });
    return;
  }
  if (request.method === 'POST' && request.url === '/api/admin/update-map') {
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

  try {
    const chunks = [];
    for await (const chunk of request) chunks.push(chunk);
    const input = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    if (!validRequest(input)) {
      sendJson(response, 400, {error: 'Invalid location or radius'});
      return;
    }

    sendJson(response, 200, {
      elements: nearbyDatabaseElements(input),
      source: 'dia_diem_cao_lanh-sql',
    });
  } catch (error) {
    console.error('Nearby proxy request failed:', error);
    try {
      sendLocalFallback(response, error instanceof Error ? error.message : 'Overpass unavailable');
    } catch (fallbackError) {
      console.error('Local map database failed:', fallbackError);
      sendJson(response, 502, {error: 'Overpass and local map database unavailable'});
    }
  }
});

server.listen(port, '127.0.0.1', () => {
  console.log(`Nearby proxy listening on http://localhost:${port}`);
});
