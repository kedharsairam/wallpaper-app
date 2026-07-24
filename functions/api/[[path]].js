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

    // Return the proxied response as-is (same-origin, so no CORS needed)
    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: response.headers,
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: 'Proxy error', detail: err.message }), {
      status: 502,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
