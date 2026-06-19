import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const srcDir = path.join(__dirname, '../src');

function walk(dir, ext, files = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, ext, files);
    else if (entry.name.endsWith(ext)) files.push(full);
  }
  return files;
}

function toModulePath(cssPath) {
  if (cssPath.endsWith('.modules.css')) return cssPath.replace('.modules.css', '.module.css');
  return cssPath.replace(/\.css$/, '.module.css');
}

function wrapIndexCss(content) {
  return `:global(:root) {\n${content
    .replace(/^:root\s*\{/, '')
    .replace(/\}$/, '')
    .split('\n')
    .map((l) => (l ? `  ${l}` : l))
    .join('\n')}\n}\n`.replace(/:global\(:root\) \{\s*\n\}/, '');
}

// Rename all .css files (except already .module.css)
const cssFiles = walk(srcDir, '.css').filter((f) => !f.endsWith('.module.css'));
for (const file of cssFiles) {
  if (file.endsWith('home.modules.css')) {
    continue; // handled separately
  }
  const target = toModulePath(file);
  if (file === path.join(srcDir, 'index.css')) {
    const content = fs.readFileSync(file, 'utf8');
    const moduleContent = content
      .replace(/^:root\s*\{/m, ':global(:root) {')
      .replace(/^body\s*\{/m, ':global(body) {')
      .replace(/^#root\s*\{/m, ':global(#root) {')
      .replace(/^h1,\s*\n\s*h2\s*\{/m, ':global(h1),\n:global(h2) {')
      .replace(/^h1\s*\{/m, ':global(h1) {')
      .replace(/^h2\s*\{/m, ':global(h2) {')
      .replace(/^p\s*\{/m, ':global(p) {')
      .replace(/^code,\s*\n\.counter\s*\{/m, ':global(code),\n:global(.counter) {')
      .replace(/^code\s*\{/m, ':global(code) {')
      .replace(/@media \(prefers-color-scheme: dark\) \{\s*\n\s*:root\s*\{/m, '@media (prefers-color-scheme: dark) {\n  :global(:root) {');
    fs.writeFileSync(target, moduleContent);
    fs.unlinkSync(file);
    console.log(`Converted ${path.relative(srcDir, file)} -> ${path.basename(target)}`);
    continue;
  }
  fs.renameSync(file, target);
  console.log(`Renamed ${path.relative(srcDir, file)} -> ${path.basename(target)}`);
}

// Remove duplicate home.css if exists
const homeCss = path.join(srcDir, 'paginas/home/home.css');
if (fs.existsSync(homeCss)) fs.unlinkSync(homeCss);
