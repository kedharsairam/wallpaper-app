// Cloudflare Pages Function — proxies /api/* requests to wallhaven.cc
// This lets the Flutter web app call the API without CORS issues
// since everything is served from the same origin.

export async function onRequest(context) {
  const { request } = context;
  const url = new URL(request.url);

  // Extract the path after /api/ (e.g. /api/v1/search?... -> v1/search?...)
  const apiPath = url.pathname.replace(/^\/api\//, '');

  // Reconstruct the target URL on wallhaven.cc
  const targetUrl = `https://wallhaven.cc/api/${apiPath}${url.search}`;

  try {
    const response = await fetch(targetUrl, {
      method: request.method,
      headers: {
        Accept: 'application/json',
        'User-Agent': 'Wallhaven-Client/1.0 (Cloudflare Pages)',
      },
    });

    // Read the body as text and rewrite image URLs so thumbnails and
    // full images go through our image proxy (solves CORS for canvaskit).
    // We parse the JSON to handle escaped chars (\/ -> /), rewrite URLs,
    // then re-serialize.
    const body = JSON.parse(await response.text());

    // Walk all values recursively and rewrite image CDN URLs to proxy URLs
    function rewrite(obj) {
      if (typeof obj === 'string') {
        return obj
          .replace(/^https:\/\/th\.wallhaven\.cc\//, '/img/th.wallhaven.cc/')
          .replace(/^https:\/\/w\.wallhaven\.cc\//, '/img/w.wallhaven.cc/');
      }
      if (obj && typeof obj === 'object') {
        for (const key of Object.keys(obj)) {
          obj[key] = rewrite(obj[key]);
        }
      }
      return obj;
    }

    const proxied = JSON.stringify(rewrite(body));
    return new Response(proxied, {
      status: response.status,
      statusText: response.statusText,
      headers: { 'Content-Type': 'application/json; charset=utf-8' },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: 'Proxy error', detail: err.message }), {
      status: 502,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
