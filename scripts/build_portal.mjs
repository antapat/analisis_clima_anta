import { readFile, writeFile, copyFile, mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';

const rawUrl = process.env.SHINY_APP_URL;
if (!rawUrl) {
  throw new Error('Falta SHINY_APP_URL. Configure la URL pública HTTPS de la aplicación Shiny en Netlify.');
}

let shinyUrl;
try {
  shinyUrl = new URL(rawUrl);
} catch {
  throw new Error('SHINY_APP_URL debe ser una URL HTTPS válida.');
}
if (shinyUrl.protocol !== 'https:' || shinyUrl.username || shinyUrl.password || shinyUrl.search || shinyUrl.hash) {
  throw new Error('SHINY_APP_URL debe ser HTTPS y no incluir credenciales, parámetros ni fragmentos.');
}

const escapeAttribute = (value) => value.replaceAll('&', '&amp;').replaceAll('"', '&quot;')
  .replaceAll('<', '&lt;').replaceAll('>', '&gt;');
const template = await readFile(resolve('portal/index.html'), 'utf8');
const html = template.replaceAll('__SHINY_APP_URL__', escapeAttribute(shinyUrl.href));
if (html.includes('__SHINY_APP_URL__')) throw new Error('No se pudo insertar la URL de Shiny.');

await mkdir(resolve('dist'), { recursive: true });
await writeFile(resolve('dist/index.html'), html, 'utf8');
await copyFile(resolve('portal/styles.css'), resolve('dist/styles.css'));
await copyFile(resolve('portal/datos.html'), resolve('dist/datos.html'));
await mkdir(resolve('dist/datos'), { recursive: true });
for (const name of [
  'series_anuales_2001_2025_anta.csv',
  'resumen_hidroclimatico_distrital_anta.csv',
  'validacion_red_estaciones.csv',
  'distritos_anta.geojson',
]) {
  await copyFile(resolve('public_data', name), resolve('dist/datos', name));
}
console.log(`Portal Netlify preparado para ${shinyUrl.origin}`);
