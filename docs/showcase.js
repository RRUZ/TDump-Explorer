'use strict';
const scenes = {
  package: {file:'borland-debug.png',width:1467,height:951,alt:'A Delphi package with its Borland symbol tree, selected S_GDATA32 record fields, and corresponding highlighted RAW source.',caption:'Delphi package / A global symbol, its record fields, and the matching RAW report line.'},
  symbols: {file:'mach-o-symbols.png',width:1472,height:951,alt:'Mach-O dynamic imports in TDump Explorer: a dense symbol table beside architecture and loader navigation.',caption:'Dynamic imports / 1,810 symbols, named entries, and architecture-aware navigation.'},
  raw: {file:'mach-o-bindings.png',width:1470,height:939,alt:'Dark-mode RAW report panel in TDump Explorer, showing highlighted Mach-O binding opcodes, line offsets, symbol names, and Follow Selection.',caption:'RAW report / Original binding text with line offsets, highlighted opcodes, and symbol names in the dark theme.'},
  mach: {file:'mach-o-bindings.png',width:1470,height:939,alt:'Mach-O binding instructions with colored opcode and symbol data beside the navigation tree.',caption:'Mach-O bindings / Opcodes, symbols, and loader metadata in a source-backed inspection workflow.'},
  elf: {file:'elf-relocations.png',width:1489,height:963,alt:'TDump Explorer displaying ELF relocations grouped by section in the light application theme.',caption:'ELF relocations / Types, offsets, addends, and symbols grouped by source section.'},
  sections: {file:'elf-sections-raw.png',width:1472,height:950,alt:'ELF section headers in a structured table with names, types, flags, addresses, sizes, and alignment.',caption:'Section headers / Read section types, flags, addresses, sizes, and alignment in one table.'}
};
const base = './assets/screenshots/';
const sceneCrops = {
  package: {left:14,top:151,width:1280,height:565,x:'44%'},
  symbols: {left:15,top:154,width:1280,height:396,x:'35%'},
  raw: {left:8,top:558,width:1280,height:278,x:'10%'},
  mach: {left:8,top:125,width:1280,height:430,x:'30%'},
  elf: {left:20,top:159,width:1280,height:375,x:'35%'},
  sections: {left:10,top:125,width:1280,height:420,x:'38%'}
};
const sceneImage = document.querySelector('#scene-image');
const sceneFrame = document.querySelector('#scene-link');
const hero = document.querySelector('.hero');
const detailImages = document.querySelectorAll('.detail-strip img, .light-detail img');
let currentScene = 'package';

function positionNativeCrop(image, frame, width, height, crop) {
  const ratio = window.devicePixelRatio || 1;
  const cssWidth = width / ratio;
  const cssHeight = height / ratio;
  image.style.width = `${cssWidth}px`;
  image.style.height = `${cssHeight}px`;
  const bounds = frame.getBoundingClientRect();
  const originX = bounds.left + frame.clientLeft;
  const originY = bounds.top + frame.clientTop;
  const cropWidth = (crop.width || width) / ratio;
  const left = -(crop.left || 0) / ratio + Math.min(0, frame.clientWidth - cropWidth) * parseFloat(crop.x) / 100;
  const top = -crop.top / ratio;
  // Snap the bitmap's origin to a physical pixel, including fractional layout offsets.
  image.style.left = `${Math.round((originX + left) * ratio) / ratio - originX}px`;
  image.style.top = `${Math.round((originY + top) * ratio) / ratio - originY}px`;
}

function sizeBannerCrops() {
  const ratio = window.devicePixelRatio || 1;
  const scene = scenes[currentScene];
  const crop = sceneCrops[currentScene];
  hero.style.setProperty('--capture-width', `${crop.width / ratio}px`);
  sceneFrame.style.height = `${Math.min(460,crop.height / ratio)}px`;
  positionNativeCrop(sceneImage, sceneFrame, scene.width, scene.height, crop);
  detailImages.forEach(image => {
    if (!image.naturalWidth) return;
    const frame = image.parentElement;
    frame.parentElement.style.maxWidth = `${image.naturalWidth / ratio}px`;
    frame.style.height = `${Math.min(260,image.naturalHeight / ratio)}px`;
    positionNativeCrop(image, frame, image.naturalWidth, image.naturalHeight, {x:'50%',top:0});
  });
}
detailImages.forEach(image => image.addEventListener('load', sizeBannerCrops));
sceneImage.addEventListener('load', sizeBannerCrops);
window.addEventListener('resize', sizeBannerCrops);
if (typeof ResizeObserver !== 'undefined') new ResizeObserver(sizeBannerCrops).observe(hero);
sizeBannerCrops();
document.querySelectorAll('[data-scene]').forEach(button => button.addEventListener('click', () => {
  currentScene = button.dataset.scene;
  const scene = scenes[button.dataset.scene];
  document.querySelectorAll('[data-scene]').forEach(item => item.setAttribute('aria-pressed', String(item === button)));
  sceneImage.src = base + scene.file;
  sceneImage.width = scene.width; sceneImage.height = scene.height; sceneImage.alt = scene.alt;
  sizeBannerCrops();
  document.querySelector('#scene-caption').textContent = scene.caption;
  const link = document.querySelector('#scene-link');
  link.href = base + scene.file; link.setAttribute('aria-label','Enlarge the complete ' + button.textContent.trim() + ' screenshot');
  document.querySelector('#scene-original').href = base + scene.file;
}));
const formats = {
  pe: ['PE / PORTABLE EXECUTABLE','What does this package import—and what does it expose?','Inspect Windows executables, DLLs, and Delphi packages through their headers, directories, and structured tables.',['DOS & PE headers','Data directories','Sections','Imports & delayed imports','Exports','Resources','Base relocations']],
  debug: ['BORLAND / DEBUG INFORMATION','Which modules, symbols, and types are in this package?','Navigate Borland debug subsections and inspect the records behind source modules, files, and symbols. Very large reports can use a compact subsection-only representation.',['Subsection directories','Source modules & files','Aligned symbols','Global symbols','Global types','Names']],
  elf: ['ELF / EXECUTABLE AND LINKABLE FORMAT','Which symbols and sections do these relocations refer to?','Browse ELF metadata and relocation tables grouped by their source section. Keep the original report available while inspecting the structured projection.',['ELF headers','Sections','Program headers','Symbols','Dynamic entries','Relocations by section']],
  mach: ['MACH-O / APPLE BINARY FORMAT','What architectures and dynamic bindings does this binary contain?','Explore FAT architectures, load commands, symbol information, and the binding data emitted by TDUMP.',['FAT architectures','Headers & load commands','Sections','Symbol tables','Dynamic imports','Indirect symbols','Binding information']],
  omf: ['OMF / AR ARCHIVES','What records and members are inside this object or library?','Inspect object records and archive structure. Record-specific details may remain generic or source-backed depending on the report.',['OMF records','Library members & index','AR members','Archive symbols']]
};
document.querySelectorAll('[data-format]').forEach(button => button.addEventListener('click', () => {
  const [label, question, description, views] = formats[button.dataset.format];
  document.querySelectorAll('[data-format]').forEach(item => item.setAttribute('aria-pressed',String(item === button)));
  document.querySelector('#format-label').textContent = label;
  document.querySelector('#format-question').textContent = question;
  document.querySelector('#format-description').textContent = description;
  document.querySelector('#format-views').replaceChildren(...views.map(value => {const li = document.createElement('li'); li.textContent = value; return li;}));
}));
// Five consecutive globals from ELF.Object.Win64.tdump, Symbol Table .symtab.
// Value and Size remain hexadecimal strings exactly as reported by TDUMP.
const exportRows = [
  {Name:'zError',Value:'20',Size:'29',Type:'FUNC',Binding:'GLOBAL'},
  {Name:'z_errmsg',Value:'0',Size:'50',Type:'OBJECT',Binding:'GLOBAL'},
  {Name:'zcalloc',Value:'50',Size:'11',Type:'FUNC',Binding:'GLOBAL'},
  {Name:'zcfree',Value:'70',Size:'D',Type:'FUNC',Binding:'GLOBAL'},
  {Name:'zlibCompileFlags',Value:'10',Size:'B',Type:'FUNC',Binding:'GLOBAL'}
];
const exportHeaders = Object.keys(exportRows[0]);
const quoteCSV = value => '"' + String(value).replaceAll('"','""') + '"';
const markdownRow = values => '| ' + values.map(value => String(value).replaceAll('\\','\\\\').replaceAll('|','\\|')).join(' | ') + ' |';
const examples = {
  json: JSON.stringify(exportRows, null, 2),
  csv: [exportHeaders,...exportRows.map(row => exportHeaders.map(key => row[key]))].map(row => row.map(quoteCSV).join(',')).join('\n'),
  markdown: [markdownRow(exportHeaders),markdownRow(exportHeaders.map(() => '---')),...exportRows.map(row => markdownRow(exportHeaders.map(key => row[key])))].join('\n')
};
// Render the Markdown table syntax emitted by this export example.
// Cells become text nodes: report content is never interpreted as HTML.
function parseMarkdownTable(source) {
  const splitRow = line => {
    let text = line.trim();
    if (text.startsWith('|')) text = text.slice(1);
    if (text.endsWith('|')) text = text.slice(0,-1);
    const cells = [];
    let cell = '';
    for (let index = 0; index < text.length; index++) {
      const char = text[index];
      if (char === '\\' && ['|','\\'].includes(text[index+1])) cell += text[++index];
      else if (char === '|') {cells.push(cell.trim()); cell = '';}
      else cell += char;
    }
    cells.push(cell.trim());
    return cells;
  };
  const lines = source.trim().split(/\r?\n/).filter(line => line.trim());
  if (lines.length < 2) throw new Error('A table needs a header and separator row.');
  const headers = splitRow(lines[0]);
  const separators = splitRow(lines[1]);
  if (headers.length !== separators.length || !separators.every(cell => /^:?-{3,}:?$/.test(cell))) {
    throw new Error('Invalid Markdown table separator.');
  }
  const rows = lines.slice(2).map(splitRow);
  if (rows.some(row => row.length !== headers.length)) throw new Error('Inconsistent table columns.');
  const alignments = separators.map(cell => cell.startsWith(':') && cell.endsWith(':') ? 'center' : cell.endsWith(':') ? 'right' : 'left');
  return {headers,rows,alignments};
}

function renderMarkdownTable(source, container) {
  const {headers,rows,alignments} = parseMarkdownTable(source);
  const table = document.createElement('table');
  const caption = document.createElement('caption');
  caption.textContent = 'ELF global symbols · Value and Size are hexadecimal';
  const head = document.createElement('thead');
  const headerRow = document.createElement('tr');
  headers.forEach((header,index) => {
    const cell = document.createElement('th');
    cell.setAttribute('scope','col');
    cell.style.textAlign = alignments[index];
    cell.textContent = header;
    headerRow.append(cell);
  });
  head.append(headerRow);
  const body = document.createElement('tbody');
  rows.forEach(row => {
    const tr = document.createElement('tr');
    row.forEach((value,index) => {
      const cell = document.createElement('td');
      cell.style.textAlign = alignments[index];
      cell.textContent = value;
      tr.append(cell);
    });
    body.append(tr);
  });
  table.append(caption,head,body);
  container.replaceChildren(table);
}

let currentExport = 'json';
let markdownMode = 'preview';
const exportCode = document.querySelector('#export-code');
const markdownPreview = document.querySelector('#markdown-preview');
const markdownControls = document.querySelector('#markdown-controls');
renderMarkdownTable(examples.markdown, markdownPreview);

function updateExportView() {
  const isMarkdown = currentExport === 'markdown';
  const showPreview = isMarkdown && markdownMode === 'preview';
  markdownControls.hidden = !isMarkdown;
  exportCode.hidden = showPreview;
  markdownPreview.hidden = !showPreview;
  exportCode.textContent = examples[currentExport];
  document.querySelectorAll('[data-markdown-view]').forEach(button => {
    button.setAttribute('aria-pressed',String(button.dataset.markdownView === markdownMode));
  });
}
document.querySelectorAll('[data-markdown-view]').forEach(button => button.addEventListener('click', () => {
  markdownMode = button.dataset.markdownView;
  updateExportView();
}));
document.querySelectorAll('[data-export]').forEach(button => button.addEventListener('click', () => {
  currentExport = button.dataset.export;
  document.querySelectorAll('[data-export]').forEach(item => item.setAttribute('aria-pressed', String(item === button)));
  updateExportView();
  document.querySelector('#copy-example').textContent = 'Copy';
}));
const copyButton = document.querySelector('#copy-example');
updateExportView();
if (navigator.clipboard && window.isSecureContext) {
  copyButton.hidden = false;
  copyButton.addEventListener('click', async () => {
    try {await navigator.clipboard.writeText(examples[currentExport]); copyButton.textContent = 'Copied'; document.querySelector('#copy-status').textContent = currentExport === 'markdown' ? 'Markdown source copied to clipboard.' : 'Example copied to clipboard.';}
    catch {document.querySelector('#copy-status').textContent = 'Copy unavailable. Select and copy the example manually.'; copyButton.textContent = 'Select text to copy';}
  });
}
const viewer = document.querySelector('#image-viewer');
const viewerImage = document.querySelector('#viewer-image');
const viewerScroll = document.querySelector('.viewer-scroll');
const fitButton = document.querySelector('#viewer-fit');
const pixelsButton = document.querySelector('#viewer-pixels');
const viewerStatus = document.querySelector('#viewer-status');
let viewerMode = 'fit';
let previousOverflow = '';
let panStart = null;

function sizeViewerImage() {
  if (!viewer.open || !viewerImage.complete || !viewerImage.naturalWidth) return;
  const ratio = window.devicePixelRatio || 1;
  const originalWidth = viewerImage.naturalWidth / ratio;
  const originalHeight = viewerImage.naturalHeight / ratio;
  const availableWidth = Math.max(1, viewerScroll.clientWidth - 32);
  const availableHeight = Math.max(1, viewerScroll.clientHeight - 32);
  const scale = viewerMode === 'fit'
    ? Math.min(1, availableWidth / originalWidth, availableHeight / originalHeight)
    : 1;
  viewerImage.style.width = `${originalWidth * scale}px`;
  viewerImage.style.height = `${originalHeight * scale}px`;
  viewerImage.style.visibility = 'visible';
  viewerScroll.dataset.mode = viewerMode;
  fitButton.setAttribute('aria-pressed', String(viewerMode === 'fit'));
  pixelsButton.setAttribute('aria-pressed', String(viewerMode === 'pixels'));
  viewerStatus.textContent = viewerMode === 'fit'
    ? 'Complete image · fit without upscaling'
    : '1 image pixel = 1 display pixel · drag or scroll to pan';
}

function setViewerMode(mode) {
  viewerMode = mode;
  sizeViewerImage();
  viewerScroll.scrollTo(0,0);
}
fitButton.addEventListener('click', () => setViewerMode('fit'));
pixelsButton.addEventListener('click', () => setViewerMode('pixels'));
viewerImage.addEventListener('load', sizeViewerImage);
viewerImage.addEventListener('error', () => {
  viewerStatus.textContent = 'Unable to load this capture. Try the Open PNG link.';
});
window.addEventListener('resize', sizeViewerImage);
if (typeof ResizeObserver !== 'undefined') new ResizeObserver(sizeViewerImage).observe(viewerScroll);

// Touch and keyboard scrolling remain native; mouse users can also drag to pan.
viewerScroll.addEventListener('pointerdown', event => {
  if (viewerMode !== 'pixels' || event.pointerType !== 'mouse' || event.button !== 0) return;
  panStart = {x:event.clientX,y:event.clientY,left:viewerScroll.scrollLeft,top:viewerScroll.scrollTop};
  viewerScroll.setPointerCapture(event.pointerId);
  viewerScroll.dataset.panning = 'true';
  event.preventDefault();
});
viewerScroll.addEventListener('pointermove', event => {
  if (!panStart) return;
  viewerScroll.scrollLeft = panStart.left - (event.clientX - panStart.x);
  viewerScroll.scrollTop = panStart.top - (event.clientY - panStart.y);
});
function stopPanning() {
  panStart = null;
  delete viewerScroll.dataset.panning;
}
viewerScroll.addEventListener('pointerup', stopPanning);
viewerScroll.addEventListener('pointercancel', stopPanning);
viewerScroll.addEventListener('lostpointercapture', stopPanning);
let previousFocus;
document.querySelectorAll('[data-viewer]').forEach(link => link.addEventListener('click', event => {
  if (!viewer.showModal || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
  event.preventDefault(); previousFocus = link;
  viewerMode = 'fit';
  viewerImage.style.visibility = 'hidden';
  viewerStatus.textContent = 'Loading complete capture…';
  viewerImage.src = link.href;
  viewerImage.alt = Object.values(scenes).find(scene => link.href.endsWith(scene.file))?.alt || 'Complete TDump Explorer application screenshot';
  document.querySelector('#viewer-file').href = link.href;
  previousOverflow = document.body.style.overflow;
  document.body.style.overflow = 'hidden';
  viewer.showModal();
  sizeViewerImage();
  viewerScroll.scrollTo(0,0);
  document.querySelector('#viewer-close').focus();
}));
document.querySelector('#viewer-close').addEventListener('click', () => viewer.close());
viewer.addEventListener('close', () => {
  stopPanning();
  document.body.style.overflow = previousOverflow;
  previousFocus?.focus();
});
