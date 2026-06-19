import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const srcDir = path.join(__dirname, '../src');

const files = [
  'paginas/login/login.jsx',
  'components/header/HeaderCal.jsx',
  'components/footer/FooterCal.jsx',
  'paginas/cadastro/cadastroSelecao.jsx',
  'paginas/cadastro/cadastroPessoal.jsx',
  'paginas/cadastro/cadastroBanda.jsx',
  'paginas/cadastro/cadastroComunidade.jsx',
  'paginas/criar_evento/criar_evento.jsx',
  'paginas/evento/evento.jsx',
  'paginas/eventos/eventoDetalhes.jsx',
  'paginas/calendario/calendario.jsx',
  'paginas/vitrine_comunidade/vitrine_comunidade.jsx',
  'components/layout/Header.jsx',
  'components/layout/Footer.jsx',
];

function cls(name) {
  return `styles['${name}']`;
}

function convertStaticClass(match, classes) {
  const parts = classes.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 1) return `className={${cls(parts[0])}}`;
  return `className={cn(${parts.map(cls).join(', ')})}`;
}

for (const rel of files) {
  const file = path.join(srcDir, rel);
  let content = fs.readFileSync(file, 'utf8');

  content = content.replace(/import\s+['"]\.\/([^'"]+)\.css['"];?/g, "import styles from './$1.module.css';");

  if (!content.includes("from '../../utils/cn'") && !content.includes("from '../utils/cn'")) {
    const depth = rel.split('/').length - 1;
    const cnPath = '../'.repeat(depth) + 'utils/cn';
    const firstImport = content.indexOf('import ');
    const lineEnd = content.indexOf('\n', firstImport);
    content = content.slice(0, lineEnd + 1) + `import { cn } from '${cnPath}';\n` + content.slice(lineEnd + 1);
  }

  content = content.replace(/className="([^"]+)"/g, convertStaticClass);

  // layout Header needs same treatment as header Header - copy from updated file
  if (rel === 'components/layout/Header.jsx') {
    const headerContent = fs.readFileSync(path.join(srcDir, 'components/header/Header.jsx'), 'utf8');
    content = headerContent.replace(
      "import { getNavConfig } from '../layout/layoutHelpers';",
      "import { getNavConfig } from './layoutHelpers';"
    ).replace(
      /isSolidPage && styles\['navbar--solid'\],\s*\n\s*!isSolidPage && scrolled && styles\['navbar--scrolled'\],/,
      "scrolled && styles['navbar--scrolled'],"
    ).replace(
      /const isEventDetail[\s\S]*?const isSolidPage[\s\S]*?\n\n/,
      '\n'
    );
  }

  if (rel === 'components/layout/Footer.jsx') {
    const footerContent = fs.readFileSync(path.join(srcDir, 'components/footer/Footer.jsx'), 'utf8');
    content = footerContent.replace(
      "import { getNavConfig } from '../layout/layoutHelpers';",
      "import { getNavConfig } from './layoutHelpers';"
    );
  }

  fs.writeFileSync(file, content);
  console.log('Updated', rel);
}
