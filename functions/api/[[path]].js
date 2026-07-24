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

    // Read the body as text and pass it through explicitly.
    // Using response.body (stream) can cause type coercion issues with
    // Cloudflare's internal handling (e.g. "per_page":24 becomes "per_page":"24").
    const bodyText = await response.text();
    return new Response(bodyText, {
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
