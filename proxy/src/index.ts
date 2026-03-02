const ALLOWED_ORIGINS = [
  'https://brothware.github.io',
];

const USER_AGENT = 'Andreg 12345';
const ALLOWED_METHODS = ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'];

const UPSTREAM_REWRITES: [RegExp, string][] = [
  [/^https?:\/\/poczta\.mobireg\.pl(\/.*)?$/, '/poczta$1'],
  [/^https?:\/\/rodzic\.mobireg\.pl(\/.*)?$/, '/portal$1'],
];

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
    'Access-Control-Allow-Methods': ALLOWED_METHODS.join(', '),
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
    pattern: /^\/poczta\/?$/,
    buildUrl: () => `https://poczta.mobireg.pl/`,
    addUserAgent: false,
  },
  {
    pattern: /^\/login\/([^/]+)\/(.+)$/,
    buildUrl: (m) => `https://mobireg.pl/${m[1]}/${m[2]}`,
    addUserAgent: false,
  },
];

function rewriteLocationHeader(
  headers: Headers,
  proxyOrigin: string,
): void {
  const location = headers.get('location');
  if (!location) return;

  for (const [pattern, replacement] of UPSTREAM_REWRITES) {
    const rewritten = location.replace(pattern, `${proxyOrigin}${replacement}`);
    if (rewritten !== location) {
      headers.set('location', rewritten);
      return;
    }
  }
}

function buildResponse(
  upstream: Response,
  origin: string,
  proxyOrigin: string,
): Response {
  const headers = new Headers(upstream.headers);

  for (const [key, value] of Object.entries(corsHeaders(origin))) {
    headers.set(key, value);
  }

  rewriteLocationHeader(headers, proxyOrigin);

  return new Response(upstream.body, {
    status: upstream.status,
    statusText: upstream.statusText,
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

    if (!ALLOWED_METHODS.includes(request.method)) {
      return new Response('Method not allowed', { status: 405 });
    }

    const url = new URL(request.url);
    const proxyOrigin = url.origin;
    const path = url.pathname;

    for (const route of routes) {
      const match = path.match(route.pattern);
      if (!match) continue;

      let targetUrl = route.buildUrl(match);
      if (url.search) {
        targetUrl += url.search;
      }

      const headers = new Headers(request.headers);
      headers.delete('host');
      if (route.addUserAgent) {
        headers.set('User-Agent', USER_AGENT);
      }

      const hasBody = request.method !== 'GET' && request.method !== 'DELETE';

      const upstream = await fetch(targetUrl, {
        method: request.method,
        headers,
        body: hasBody ? request.body : null,
        redirect: 'manual',
      });

      return buildResponse(upstream, origin, proxyOrigin);
    }

    return buildResponse(
      new Response('Not found', { status: 404 }),
      origin,
      proxyOrigin,
    );
  },
};
