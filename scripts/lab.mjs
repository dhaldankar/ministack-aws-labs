#!/usr/bin/env node

import {
  constants, copyFileSync, cpSync, existsSync, lstatSync, mkdirSync, mkdtempSync,
  readFileSync, readdirSync, renameSync, rmSync, writeFileSync,
} from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = fileURLToPath(new URL('../', import.meta.url));
const source = join(root, 'labs');
const catalog = join(root, '.lab-catalog');
const inventory = join(catalog, 'catalog.json');
const workspace = process.env.LAB_WORKSPACE || '/lab';
const numberedFolder = /^(\d{2})_([a-z0-9]+(?:-[a-z0-9]+)*)$/;

function prepare() {
  const entries = readdirSync(source, { withFileTypes: true });
  const folders = entries.filter(entry => entry.isDirectory()).map(entry => entry.name).sort();
  if (!folders.length) throw new Error('No lab folders found.');
  const positions = new Set();
  const ids = new Set();
  const labs = folders.map(folderName => {
    const match = folderName.match(numberedFolder);
    if (!match || match[1] === '00') throw new Error(`Expected an NN_<id> lab folder: ${folderName}`);
    const [, position, id] = match;
    if (positions.has(position)) throw new Error(`Duplicate lab position: ${position}`);
    if (ids.has(id)) throw new Error(`Duplicate lab ID: ${id}`);
    positions.add(position);
    ids.add(id);

    const folder = join(source, folderName);
    const markdown = readFileSync(join(folder, 'lab.md'), 'utf8');
    const metadata = markdown.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/)?.[1];
    if (metadata?.match(/^id:[ \t]*(\S+)[ \t]*$/m)?.[1] !== id) {
      throw new Error(`The id in ${folderName}/lab.md must match ${id}.`);
    }
    const title = /^(title:[ \t]*['"]?)(?=\S)/m;
    if (!title.test(metadata)) throw new Error(`${folderName}/lab.md needs a title.`);
    // Labforge sorts catalog entries by title and uses the ID for the URL.
    const numberedMetadata = metadata.replace(title, (_, prefix) => `${prefix}${position} `);
    if (!lstatSync(join(folder, 'starter')).isDirectory() ||
        !readdirSync(join(folder, 'starter')).length ||
        !lstatSync(join(folder, 'check.sh')).isFile()) {
      throw new Error(`${id} needs starter files and a check.sh script.`);
    }
    const markerFile = join(folder, 'legacy-check.txt');
    const legacyMarker = existsSync(markerFile) ? readFileSync(markerFile, 'utf8').trim() : '';
    return { id, folderName, markdown: markdown.replace(metadata, () => numberedMetadata), legacyMarker };
  });

  const docs = join(catalog, 'docs');
  rmSync(docs, { recursive: true, force: true });
  mkdirSync(docs, { recursive: true });
  for (const { id, markdown } of labs) writeFileSync(join(docs, `${id}.md`), markdown);
  writeFileSync(inventory, JSON.stringify(labs.map(({ id, folderName, legacyMarker }) =>
    ({ id, folderName, legacyMarker }))));
}

function resolveWorkspace(lab, create) {
  const folder = join(workspace, lab.id);
  if (existsSync(folder)) {
    if (!lstatSync(folder).isDirectory()) throw new Error(`Expected a directory at ${folder}`);
    return folder;
  }

  const previousChecker = join(workspace, 'check.sh');
  if (lab.legacyMarker && existsSync(join(workspace, 'main.tf')) &&
      existsSync(previousChecker) && readFileSync(previousChecker, 'utf8').includes(lab.legacyMarker)) {
    return workspace;
  }

  if (!create) throw new Error(`Start this lab with: lab start ${lab.id}`);
  const temporary = mkdtempSync(join(workspace, '.lab-start-'));
  try {
    cpSync(join(source, lab.folderName, 'starter'), temporary, { recursive: true });
    try {
      renameSync(temporary, folder);
    } catch (error) {
      if (!existsSync(folder) || !lstatSync(folder).isDirectory()) throw error;
    }
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
  return folder;
}

function run([command, id, ...args]) {
  if (command === 'prepare' && !id) return prepare();
  if (command === 'sandbox' && !id) {
    console.log(join(root, 'scripts', 'sandbox.sh'));
    return;
  }
  if (command === 'welcome' && !id) {
    try {
      copyFileSync(join(root, 'scripts', 'START-HERE.md'), join(workspace, 'START-HERE.md'),
        constants.COPYFILE_EXCL);
    } catch (error) {
      if (error.code !== 'EEXIST') throw error;
    }
    return;
  }
  if ((command === 'list' && id) || !['list', 'start', 'check'].includes(command) ||
      (command === 'start' && args.length)) {
    throw new Error('Usage: lab list | lab start <id> | lab check <id> [checker arguments] | lab sandbox');
  }

  const labs = JSON.parse(readFileSync(inventory, 'utf8'));
  if (command === 'list') {
    for (const lab of labs) console.log(lab.id);
    return;
  }
  const lab = labs.find(entry => entry.id === id);
  if (!lab) throw new Error(`Unknown lab: ${id ?? '(missing ID)'}. Run lab list.`);
  const directory = resolveWorkspace(lab, command === 'start');
  if (command === 'start') {
    console.log(directory);
    return;
  }
  const labSource = join(source, lab.folderName);
  const result = spawnSync('bash', [join(labSource, 'check.sh'), ...args], {
    cwd: directory,
    env: { ...process.env, LAB_SOURCE_DIR: labSource },
    stdio: 'inherit',
  });
  if (result.error) throw result.error;
  process.exitCode = result.status ?? 1;
}

try {
  run(process.argv.slice(2));
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
