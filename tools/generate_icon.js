// Generate a 1024x1024 app icon for WallKraft
// Uses only Node.js built-in modules (zlib for PNG compression)
// Creates a dark gradient background with a stylized mountain/sun motif

const zlib = require('zlib');
const fs = require('fs');

const SIZE = 1024;
const CX = SIZE / 2;
const CY = SIZE / 2;

// Canvas: RGBA pixels stored as [r, g, b, a, r, g, b, a, ...]
const pixels = Buffer.alloc(SIZE * SIZE * 4, 0);

function setPixel(x, y, r, g, b, a = 255) {
  if (x < 0 || x >= SIZE || y < 0 || y >= SIZE) return;
  const i = (y * SIZE + x) * 4;
  pixels[i] = r;
  pixels[i + 1] = g;
  pixels[i + 2] = b;
  pixels[i + 3] = a;
}

function fillCircle(cx, cy, radius, r, g, b, a = 255) {
  const r2 = radius * radius;
  for (let y = cy - radius; y <= cy + radius; y++) {
    for (let x = cx - radius; x <= cx + radius; x++) {
      const dx = x - cx;
      const dy = y - cy;
      if (dx * dx + dy * dy <= r2) {
        setPixel(x, y, r, g, b, a);
      }
    }
  }
}

function fillTriangle(x1, y1, x2, y2, x3, y3, r, g, b, a = 255) {
  // Bounding box
  const minX = Math.max(0, Math.floor(Math.min(x1, x2, x3)));
  const maxX = Math.min(SIZE - 1, Math.ceil(Math.max(x1, x2, x3)));
  const minY = Math.max(0, Math.floor(Math.min(y1, y2, y3)));
  const maxY = Math.min(SIZE - 1, Math.ceil(Math.max(y1, y2, y3)));

  function edge(x, y, x1, y1, x2, y2) {
    return (x - x1) * (y2 - y1) - (y - y1) * (x2 - x1);
  }

  const w0 = 0;
  for (let y = minY; y <= maxY; y++) {
    for (let x = minX; x <= maxX; x++) {
      const e0 = edge(x, y, x1, y1, x2, y2);
      const e1 = edge(x, y, x2, y2, x3, y3);
      const e2 = edge(x, y, x3, y3, x1, y1);
      if ((e0 >= w0 && e1 >= w0 && e2 >= w0) || (e0 <= w0 && e1 <= w0 && e2 <= w0)) {
        setPixel(x, y, r, g, b, a);
      }
    }
  }
}

function lerp(a, b, t) { return a + (b - a) * t; }

// --- DRAW THE ICON ---

// Background gradient: dark navy to deep purple
for (let y = 0; y < SIZE; y++) {
  const t = y / SIZE;
  const r = Math.floor(lerp(26, 60, t));   // #1A -> #3C
  const g = Math.floor(lerp(26, 20, t));   // #1A -> #14
  const b = Math.floor(lerp(46, 70, t));   // #2E -> #46
  for (let x = 0; x < SIZE; x++) {
    setPixel(x, y, r, g, b);
  }
}

// Sun glow (soft circle, top center)
fillCircle(CX, Math.floor(SIZE * 0.3), Math.floor(SIZE * 0.2),
  255, 183, 77, 40);  // warm orange, semi-transparent

// Sun core
fillCircle(CX, Math.floor(SIZE * 0.3), Math.floor(SIZE * 0.08),
  255, 200, 100);

// Mountain back layer (distant, lighter teal)
const mt1 = [
  [0, SIZE * 0.65],
  [SIZE * 0.15, SIZE * 0.38],
  [SIZE * 0.35, SIZE * 0.52],
  [SIZE * 0.55, SIZE * 0.35],
  [SIZE * 0.75, SIZE * 0.48],
  [SIZE * 0.9, SIZE * 0.40],
  [SIZE, SIZE * 0.60],
  [SIZE, SIZE],
  [0, SIZE],
].map(([x, y]) => [Math.round(x), Math.round(y)]);

// Draw back mountain as filled polygon using triangle fan
for (let i = 1; i < mt1.length - 1; i++) {
  fillTriangle(
    mt1[0][0], mt1[0][1],
    mt1[i][0], mt1[i][1],
    mt1[i + 1][0], mt1[i + 1][1],
    79, 195, 247, 200  // Light blue, semi-transparent
  );
}

// Mountain front layer (darker, more saturated)
const mt2 = [
  [0, SIZE * 0.75],
  [SIZE * 0.12, SIZE * 0.52],
  [SIZE * 0.30, SIZE * 0.62],
  [SIZE * 0.50, SIZE * 0.45],
  [SIZE * 0.65, SIZE * 0.58],
  [SIZE * 0.82, SIZE * 0.48],
  [SIZE, SIZE * 0.70],
  [SIZE, SIZE],
  [0, SIZE],
].map(([x, y]) => [Math.round(x), Math.round(y)]);

for (let i = 1; i < mt2.length - 1; i++) {
  fillTriangle(
    mt2[0][0], mt2[0][1],
    mt2[i][0], mt2[i][1],
    mt2[i + 1][0], mt2[i + 1][1],
    41, 182, 246  // Stronger blue
  );
}

// Snow caps on front mountain peaks
fillCircle(mt2[1][0], mt2[1][1] - 8, 10, 255, 255, 255, 180);
fillCircle(mt2[3][0], mt2[3][1] - 10, 12, 255, 255, 255, 180);
fillCircle(mt2[5][0], mt2[5][1] - 8, 10, 255, 255, 255, 180);

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

// Build raw scanlines (each starts with filter byte 0)
const rawData = Buffer.alloc(SIZE * (1 + SIZE * 4));
for (let y = 0; y < SIZE; y++) {
  const offset = y * (1 + SIZE * 4);
  rawData[offset] = 0; // No filter
  pixels.copy(rawData, offset + 1, y * SIZE * 4, (y + 1) * SIZE * 4);
}

// Compress
const compressed = zlib.deflateSync(rawData);

// Build PNG
const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(SIZE, 0);  // width
ihdr.writeUInt32BE(SIZE, 4);  // height
ihdr[8] = 8;   // bit depth
ihdr[9] = 6;   // color type: RGBA
ihdr[10] = 0;  // compression
ihdr[11] = 0;  // filter
ihdr[12] = 0;  // interlace

const png = Buffer.concat([
  signature,
  createChunk('IHDR', ihdr),
  createChunk('IDAT', compressed),
  createChunk('IEND', Buffer.alloc(0)),
]);

const outPath = 'C:\\Users\\kedhar\\OpenCode\\projects\\wallhaven_client\\assets\\icon_source.png';
fs.mkdirSync('C:\\Users\\kedhar\\OpenCode\\projects\\wallhaven_client\\assets', { recursive: true });
fs.writeFileSync(outPath, png);
console.log(`Icon written to ${outPath} (${png.length} bytes)`);
