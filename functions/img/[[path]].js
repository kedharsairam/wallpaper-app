// Cloudflare Pages Function — proxies image requests to wallhaven's CDNs.
// The app requests images from /img/th.wallhaven.cc/... or /img/w.wallhaven.cc/...
// and this function fetches them from the real CDN with CORS headers.
// This solves CORS issues with th.wallhaven.cc (which doesn't set CORS headers).

export async function onRequest(context) {
  const { request } = context;
  const url = new URL(request.url);

  // Extract the path after /img/ (e.g. /img/th.wallhaven.cc/small/xx/xx.jpg)
  const imgPath = url.pathname.replace(/^\/img\//, '');

  // Reconstruct the original URL
  const targetUrl = `https://${imgPath}`;

  try {
    const response = await fetch(targetUrl, {
      method: request.method,
      headers: {
        'User-Agent': 'Wallhaven-Client/1.0 (Cloudflare Pages)',
      },
    });

    // Copy the response body and add CORS headers
    // This allows the canvaskit/skwasm renderer to read image pixels
    const newHeaders = new Headers(response.headers);
    newHeaders.set('Access-Control-Allow-Origin', '*');
    newHeaders.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
    newHeaders.set('Access-Control-Max-Age', '86400');

    // Strip content-encoding to avoid double-decompression issues
    newHeaders.delete('content-encoding');

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: newHeaders,
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: 'Image proxy error', detail: err.message }), {
      status: 502,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
