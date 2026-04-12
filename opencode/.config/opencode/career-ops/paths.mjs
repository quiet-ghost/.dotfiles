#!/usr/bin/env node

import { dirname, join } from 'path';
import { homedir } from 'os';
import { fileURLToPath } from 'url';

const packageRoot = dirname(fileURLToPath(import.meta.url));
const dataRoot = process.env.CAREER_OPS_DATA_DIR || join(homedir(), '.local', 'share', 'career-ops');

export const paths = {
  packageRoot,
  dataRoot,
  cv: join(dataRoot, 'cv.md'),
  articleDigest: join(dataRoot, 'article-digest.md'),
  profile: join(dataRoot, 'config', 'profile.yml'),
  profileExample: join(packageRoot, 'config', 'profile.example.yml'),
  portals: join(dataRoot, 'portals.yml'),
  portalsExample: join(packageRoot, 'templates', 'portals.example.yml'),
  applications: join(dataRoot, 'data', 'applications.md'),
  pipeline: join(dataRoot, 'data', 'pipeline.md'),
  scanHistory: join(dataRoot, 'data', 'scan-history.tsv'),
  reports: join(dataRoot, 'reports'),
  output: join(dataRoot, 'output'),
  jds: join(dataRoot, 'jds'),
  batchDir: join(dataRoot, 'batch'),
  batchInput: join(dataRoot, 'batch', 'batch-input.tsv'),
  batchState: join(dataRoot, 'batch', 'batch-state.tsv'),
  batchLogs: join(dataRoot, 'batch', 'logs'),
  trackerAdditions: join(dataRoot, 'batch', 'tracker-additions'),
  states: join(packageRoot, 'templates', 'states.yml'),
  sharedMode: join(packageRoot, 'modes', '_shared.md'),
};
