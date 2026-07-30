#!/usr/bin/env node
// DeepGrade: Migration guard (PreToolUse: Write|Edit) — lane N
//
// Warns when editing an ALREADY-APPLIED migration. New migrations are fine.
// Ledger row 2: Windows backslash normalization — exists ONLY in the inline
// implementation (plugin.json), never in dg-migration-guard.sh, so a naive port
// would have dropped it and the guard would miss every Windows-style path.
// Ledger row 3: the wider directory/filename coverage is the SCRIPT's, kept.
//
// Contract 3.1.6: parse the named field, fail closed on a malformed payload,
// never deny on an unparsed blob. Each hook is self-contained on purpose — F06's
// reverse sweep requires every file in scripts/ to be referenced by the hook
// config, so a shared library would fail it.
'use strict';
const fs = require('fs');
const path = require('path');

function deny(msg) { process.stderr.write(`[DeepGrade] BLOCKED: ${msg}\n`); process.exit(2); }
function allow() { process.exit(0); }

let raw = '';
try { raw = fs.readFileSync(0, 'utf8'); } catch { raw = ''; }
if (raw.trim() === '') allow();

let payload;
try { payload = JSON.parse(raw); }
catch { deny('hook payload is not valid JSON — refusing to guess at its contents.'); }

let filePath = payload && payload.tool_input && typeof payload.tool_input.file_path === 'string'
  ? payload.tool_input.file_path
  : '';
if (!filePath.trim()) allow();

// Row 2. C:\repo\db\migrations\001_init.sql must be recognized as a migration.
filePath = filePath.replace(/\\/g, '/');

const MIGRATION_DIRS = [
  '/migrations/', '/migrate/', '/Migrations/',
  '/alembic/versions/', '/drizzle/', '/changelog/',
];
// Leading-segment matches too: "migrations/001.sql" has no leading slash.
const inMigrationDir = MIGRATION_DIRS.some(
  (d) => filePath.includes(d) || filePath.startsWith(d.slice(1))
);
if (!inMigrationDir) allow();

const base = path.posix.basename(filePath);
const IS_MIGRATION = [
  /\.sql$/i,          // any SQL file in a migration directory
  /^\d{4,14}/,        // timestamp or numeric prefix
  /^V\d+/,            // Flyway V-prefix
  /^\d{4}_/,          // 4-digit underscore prefix
  /ModelSnapshot\.cs$/, // EF Core snapshot
].some((re) => re.test(base));
if (!IS_MIGRATION) allow();

// Only an EXISTING file has potentially been applied. Creating a new migration
// is the correct action and must never be blocked.
if (!fs.existsSync(filePath)) allow();

deny(`Editing an existing migration: ${filePath}. Modifying an applied migration can break databases that already ran it. Create a NEW migration instead.`);
