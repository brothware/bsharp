const ALLOWED_ORIGINS = [
  'https://brothware.github.io',
];

const USER_AGENT = 'Andreg 12345';

function isAllowedOrigin(origin: string | null): boolean {
  if (!origin) return false;
  if (ALLOWED_ORIGINS.includes(origin)) return true;
  try {
    const url = new URL(origin);
    return url.hostname === 'localhost' || url.hostname === '127.0.0.1';
  } catch {
    return false;
  }
}

function corsHeaders(origin: string): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-Requested-With, X-CSRF-TOKEN',
    'Access-Control-Allow-Credentials': 'true',
  };
}

interface Route {
  pattern: RegExp;
  buildUrl: (match: RegExpMatchArray) => string;
  addUserAgent: boolean;
}

const routes: Route[] = [
  {
    pattern: /^\/sync\/([^/]+)\/(.+)$/,
    buildUrl: (m) => `https://mobireg.pl/${m[1]}/modules/api/${m[2]}`,
    addUserAgent: true,
  },
  {
    pattern: /^\/portal\/(.+)$/,
    buildUrl: (m) => `https://rodzic.mobireg.pl/${m[1]}`,
    addUserAgent: false,
  },
  {
    pattern: /^\/poczta\/(.+)$/,
    buildUrl: (m) => `https://poczta.mobireg.pl/${m[1]}`,
    addUserAgent: false,
  },
  {
    pattern: /^\/login\/([^/]+)\/(.+)$/,
    buildUrl: (m) => `https://mobireg.pl/${m[1]}/${m[2]}`,
    addUserAgent: false,
  },
];

function addCorsHeaders(response: Response, origin: string): Response {
  const headers = new Headers(response.headers);
  for (const [key, value] of Object.entries(corsHeaders(origin))) {
    headers.set(key, value);
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

export default {
  async fetch(request: Request): Promise<Response> {
    const origin = request.headers.get('Origin') ?? ALLOWED_ORIGINS[0];

    if (!isAllowedOrigin(origin)) {
      return new Response('Forbidden', { status: 403 });
    }

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(origin) });
    }

    if (request.method !== 'POST') {
      return addCorsHeaders(new Response('Method not allowed', { status: 405 }), origin);
    }

    const url = new URL(request.url);
    const path = url.pathname;

    for (const route of routes) {
      const match = path.match(route.pattern);
      if (!match) continue;

      const targetUrl = route.buildUrl(match);
      const headers = new Headers(request.headers);
      headers.delete('host');
      if (route.addUserAgent) {
        headers.set('User-Agent', USER_AGENT);
      }

      const upstream = await fetch(targetUrl, {
        method: 'POST',
        headers,
        body: request.body,
        redirect: 'manual',
      });

      return addCorsHeaders(upstream, origin);
    }

    return addCorsHeaders(new Response('Not found', { status: 404 }), origin);
  },
};
