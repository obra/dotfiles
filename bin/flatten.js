const fs = require('fs');
const path = require('path');

// Folders and files to include
const TO_INCLUDE = [
  'src',
  'docs',
  '.private_journal',
  'package.json'
];

function* walk(dir) {
  if (fs.statSync(dir).isFile()) {
    yield dir;
    return;
  }
  for (const entry of fs.readdirSync(dir)) {
    const full = path.join(dir, entry);
    if (fs.statSync(full).isDirectory()) {
      yield* walk(full);
    } else {
      yield full;
    }
  }
}

function readAndFormat(filename) {
  const rel = path.relative(process.cwd(), filename);
  const content = fs.readFileSync(filename, 'utf8');
  return `\n\n===== FILE: ${rel} =====\n${content}\n`;
}

for (const entry of TO_INCLUDE) {
  if (fs.existsSync(entry)) {
    if (fs.statSync(entry).isFile()) {
      process.stdout.write(readAndFormat(entry));
    } else {
      for (const file of walk(entry)) {
        process.stdout.write(readAndFormat(file));
      }
    }
  }
}