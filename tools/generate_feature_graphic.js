// Generate a 1024x500 feature graphic for Google Play Store
// Uses only Node.js built-in modules

const zlib = require('zlib');
const fs = require('fs');

const W = 1024;
const H = 500;
const CX = W / 2;
const CY = H / 2;

const pixels = Buffer.alloc(W * H * 4, 0);

function setPixel(x, y, r, g, b, a = 255) {
  if (x < 0 || x >= W || y < 0 || y >= H) return;
  const i = (y * W + x) * 4;
  pixels[i] = r;
  pixels[i + 1] = g;
  pixels[i + 2] = b;
  pixels[i + 3] = a;
}

function lerp(a, b, t) { return a + (b - a) * t; }
function clamp(v, min, max) { return Math.max(min, Math.min(max, v)); }

function drawCircle(cx, cy, radius, r, g, b, a = 255) {
  const minX = Math.max(0, Math.floor(cx - radius - 1));
  const maxX = Math.min(W - 1, Math.ceil(cx + radius + 1));
  const minY = Math.max(0, Math.floor(cy - radius - 1));
  const maxY = Math.min(H - 1, Math.ceil(cy + radius + 1));

  for (let y = minY; y <= maxY; y++) {
    for (let x = minX; x <= maxX; x++) {
      const dx = x - cx;
      const dy = y - cy;
      const dist = Math.sqrt(dx * dx + dy * dy);
      const alpha = clamp(1 - (dist - radius + 0.5), 0, 1) * (a / 255);
      if (alpha > 0) {
        const i = (y * W + x) * 4;
        const srcAlpha = alpha;
        const dstAlpha = pixels[i + 3] / 255;
        const outAlpha = srcAlpha + dstAlpha * (1 - srcAlpha);
        if (outAlpha > 0) {
          pixels[i] = Math.round((r * srcAlpha + pixels[i] * dstAlpha * (1 - srcAlpha)) / outAlpha);
          pixels[i + 1] = Math.round((g * srcAlpha + pixels[i + 1] * dstAlpha * (1 - srcAlpha)) / outAlpha);
          pixels[i + 2] = Math.round((b * srcAlpha + pixels[i + 2] * dstAlpha * (1 - srcAlpha)) / outAlpha);
          pixels[i + 3] = Math.round(outAlpha * 255);
        }
      }
    }
  }
}

function fillPolygon(points, r, g, b, a = 255) {
  if (points.length < 3) return;
  let minX = W, maxX = 0, minY = H, maxY = 0;
  for (const [px, py] of points) {
    minX = Math.min(minX, px);
    maxX = Math.max(maxX, px);
    minY = Math.min(minY, py);
    maxY = Math.max(maxY, py);
  }
  minX = Math.max(0, Math.floor(minX - 1));
  maxX = Math.min(W - 1, Math.ceil(maxX + 1));
  minY = Math.max(0, Math.floor(minY - 1));
  maxY = Math.min(H - 1, Math.ceil(maxY + 1));

  const edges = [];
  for (let i = 0; i < points.length; i++) {
    const j = (i + 1) % points.length;
    const [x1, y1] = points[i];
    const [x2, y2] = points[j];
    edges.push({ x1, y1, x2, y2 });
  }

  for (let y = minY; y <= maxY; y++) {
    for (let x = minX; x <= maxX; x++) {
      let minDist = Infinity;
      let inside = true;
      for (const e of edges) {
        const val = (x - e.x1) * (e.y2 - e.y1) - (y - e.y1) * (e.x2 - e.x1);
        if (val < -1) { inside = false; break; }
        const dist = val / Math.sqrt((e.y2 - e.y1) ** 2 + (e.x2 - e.x1) ** 2);
        if (dist < minDist) minDist = dist;
      }
      if (inside) {
        const alpha = clamp(1 - (-minDist + 0.5), 0, 1) * (a / 255);
        if (alpha > 0) {
          const i = (y * W + x) * 4;
          const srcAlpha = alpha;
          const dstAlpha = pixels[i + 3] / 255;
          const outAlpha = srcAlpha + dstAlpha * (1 - srcAlpha);
          if (outAlpha > 0) {
            pixels[i] = Math.round((r * srcAlpha + pixels[i] * dstAlpha * (1 - srcAlpha)) / outAlpha);
            pixels[i + 1] = Math.round((g * srcAlpha + pixels[i + 1] * dstAlpha * (1 - srcAlpha)) / outAlpha);
            pixels[i + 2] = Math.round((b * srcAlpha + pixels[i + 2] * dstAlpha * (1 - srcAlpha)) / outAlpha);
            pixels[i + 3] = Math.round(outAlpha * 255);
          }
        }
      }
    }
  }
}

// --- DRAW THE FEATURE GRAPHIC ---

// Background gradient: dark navy to deep purple (matches icon)
for (let y = 0; y < H; y++) {
  const t = y / H;
  const r = Math.floor(lerp(13, 30, t));
  const g = Math.floor(lerp(13, 13, t));
  const b = Math.floor(lerp(26, 50, t));
  for (let x = 0; x < W; x++) {
    setPixel(x, y, r, g, b);
  }
}

// Subtle decorative circles in the background
drawCircle(150, 80, 200, 40, 30, 80, 30);
drawCircle(900, 400, 180, 60, 20, 90, 25);
drawCircle(500, 450, 150, 30, 40, 70, 20);

// "W" Monogram (left side, smaller than icon)
const scale = 0.12;
const s = H * scale;
const iconCX = 180;
const iconCY = CY;

const leftPeak = [
  [iconCX - s * 1.1, iconCY + s * 0.8],
  [iconCX - s * 0.5, iconCY - s * 0.8],
  [iconCX - s * 0.1, iconCY - s * 0.2],
  [iconCX + s * 0.1, iconCY - s * 0.2],
  [iconCX - s * 0.3, iconCY + s * 0.8],
];

const rightPeak = [
  [iconCX + s * 0.3, iconCY + s * 0.8],
  [iconCX + s * 0.1, iconCY - s * 0.2],
  [iconCX + s * 0.5, iconCY - s * 0.8],
  [iconCX + s * 1.1, iconCY + s * 0.8],
  [iconCX + s * 0.7, iconCY + s * 0.8],
  [iconCX + s * 0.5, iconCY - s * 0.4],
  [iconCX + s * 0.3, iconCY - s * 0.1],
  [iconCX + s * 0.1, iconCY + s * 0.8],
];

fillPolygon(leftPeak.map(([x, y]) => [Math.round(x), Math.round(y)]), 255, 183, 77);
fillPolygon(rightPeak.map(([x, y]) => [Math.round(x), Math.round(y)]), 255, 183, 77);

// --- Text rendering using simple pixel patterns ---
// Since we can't load fonts, we'll create a simple implied text area
// with an underline accent bar

// App name area - a subtle background pill
const pillX = 360;
const pillY = CY - 40;
const pillW = 600;
const pillH = 80;
const pill = [
  [pillX, pillY],
  [pillX + pillW, pillY],
  [pillX + pillW, pillY + pillH],
  [pillX, pillY + pillH],
];
fillPolygon(pill.map(([x, y]) => [Math.round(x), Math.round(y)]), 255, 255, 255, 20);

// Accent bar under the app name area
const bar = [
  [CX - 150, CY + 55],
  [CX + 150, CY + 55],
  [CX + 150, CY + 60],
  [CX - 150, CY + 60],
];
fillPolygon(bar.map(([x, y]) => [Math.round(x), Math.round(y)]), 255, 183, 77);

// Tagline dots (decorative elements suggesting text)
const dotPositions = [
  [CX - 200, CY + 90],
  [CX - 120, CY + 90],
  [CX - 40, CY + 90],
  [CX + 40, CY + 90],
  [CX + 120, CY + 90],
  [CX + 200, CY + 90],
];

for (const [dx, dy] of dotPositions) {
  drawCircle(dx, dy, 3, 255, 255, 255, 120);
}

// --- ENCODE PNG ---

function createChunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const typeB = Buffer.from(type, 'ascii');
  const crcData = Buffer.concat([typeB, data]);
  const crc = crc32(crcData);
  const crcB = Buffer.alloc(4);
  crcB.writeUInt32BE(crc);
  return Buffer.concat([length, typeB, data, crcB]);
}

function crc32(buf) {
  let crc = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) {
    crc ^= buf[i];
    for (let j = 0; j < 8; j++) {
      crc = (crc >>> 1) ^ (crc & 1 ? 0xEDB88320 : 0);
    }
  }
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

const rawData = Buffer.alloc(H * (1 + W * 4));
for (let y = 0; y < H; y++) {
  const offset = y * (1 + W * 4);
  rawData[offset] = 0;
  pixels.copy(rawData, offset + 1, y * W * 4, (y + 1) * W * 4);
}

const compressed = zlib.deflateSync(rawData);

const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(W, 0);
ihdr.writeUInt32BE(H, 4);
ihdr[8] = 8;
ihdr[9] = 6;
ihdr[10] = 0;
ihdr[11] = 0;
ihdr[12] = 0;

const png = Buffer.concat([
  signature,
  createChunk('IHDR', ihdr),
  createChunk('IDAT', compressed),
  createChunk('IEND', Buffer.alloc(0)),
]);

const outPath = 'C:\\Users\\kedhar\\OpenCode\\projects\\wallhaven_client\\assets\\feature_graphic.png';
fs.mkdirSync('C:\\Users\\kedhar\\OpenCode\\projects\\wallhaven_client\\assets', { recursive: true });
fs.writeFileSync(outPath, png);
console.log(`Feature graphic written to ${outPath} (${png.length} bytes)`);
