import http from 'node:http';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
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
database.exec(readFileSync(schemaPath, 'utf8'));
const upstreamTimeoutMs = Number(process.env.OVERPASS_TIMEOUT_MS || 4000);
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
  return `[out:json][timeout:15];(`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["amenity"~"^(cafe|restaurant|fast_food|bar|pub|cinema|school|college|university)$"];`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["leisure"~"^(park|playground|amusement_arcade|water_park|sports_centre|stadium)$"];`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["shop"];`
    + `nwr(around:${radiusMeters},${latitude},${longitude})["name"]["tourism"~"^(theme_park|zoo|museum|attraction)$"];`
    + `);out center tags;`;
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

function saveOverpassElements(elements) {
  const statement = database.prepare(`
    INSERT OR REPLACE INTO places
      (id, name, category, latitude, longitude, address, phone, hours, source, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'overpass', datetime('now'))
  `);
  database.exec('BEGIN');
  try {
    database.prepare('DELETE FROM places WHERE source = ?').run('overpass');
    for (const element of elements) {
      const tags = element.tags || {};
      const latitude = element.lat ?? element.center?.lat;
      const longitude = element.lon ?? element.center?.lon;
      if (!tags.name || latitude == null || longitude == null) continue;
      statement.run(
        `osm-${element.type}-${element.id}`,
        tags.name,
        tags['app:category'] || tags.amenity || tags.leisure || tags.shop || 'khac',
        latitude,
        longitude,
        tags['addr:full'] || '',
        tags.phone || tags['contact:phone'] || '',
        tags.opening_hours || '',
      );
    }
    database.exec('COMMIT');
  } catch (error) {
    database.exec('ROLLBACK');
    throw error;
  }
}

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
      source: 'local-cao-lanh-sql',
      elements: localDatabaseElements(),
    });
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

    let lastFailure = 'Overpass unavailable';
    for (const overpassUrl of overpassUrls) {
      try {
        const overpassResponse = await fetch(overpassUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'vn.diadiem.quanhday-local-proxy',
          },
          body: new URLSearchParams({data: queryFor(input)}),
          signal: AbortSignal.timeout(upstreamTimeoutMs),
        });
        const body = await overpassResponse.text();
        if (overpassResponse.ok) {
          const decoded = JSON.parse(body);
          if (Array.isArray(decoded.elements)) saveOverpassElements(decoded.elements);
          response.writeHead(200, {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json; charset=utf-8',
          });
          response.end(body);
          return;
        }
        lastFailure = `Overpass returned ${overpassResponse.status}`;
      } catch (error) {
        lastFailure = error instanceof Error ? error.message : 'Overpass unavailable';
      }
    }
    sendLocalFallback(response, lastFailure);
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
