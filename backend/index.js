import {onRequest} from 'firebase-functions/v2/https';

import {server} from './server.js';

export const nearbyApi = onRequest(
  {
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  (request, response) => {
    server.emit('request', request, response);
  },
);
