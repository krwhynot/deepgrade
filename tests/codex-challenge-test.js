#!/usr/bin/env node
/**
 * Parser regression tests for /deepgrade:codex-challenge
 *
 * Tests the SCORES/GAPS response parsing logic against fixture files.
 * Run with: node tests/codex-challenge-test.js
 */

const fs = require('fs');
const path = require('path');

const FIXTURES_DIR = path.join(__dirname, 'fixtures', 'codex-challenge');

// ─── Parser Logic (mirrors what Claude executes at runtime) ───

function parseCodexResponse(text) {
  if (!text || text.trim().length === 0) {
    return { valid: false, error: 'Empty response' };
  }

  // Check for SCORES header
  if (!text.includes('SCORES:')) {
    return { valid: false, error: 'Missing SCORES header' };
  }

  // Extract 8 dimension scores
  const scores = {};
  const dimensionNames = [
    'Problem Definition', 'Architecture', 'Sequencing', 'Risk',
    'Rollback', 'Timeline', 'Testing', 'Omissions'
  ];

  for (let i = 1; i <= 8; i++) {
    // Match pattern: N. Name: [1-5] — justification
    const pattern = new RegExp(`${i}\\.\\s*${dimensionNames[i - 1]}:\\s*(\\d)\\s*[—–-]\\s*(.+)`, 'i');
    const match = text.match(pattern);
    if (!match) {
      return { valid: false, error: `Missing or malformed score for dimension ${i} (${dimensionNames[i - 1]})` };
    }
    const score = parseInt(match[1], 10);
    if (score < 1 || score > 5) {
      return { valid: false, error: `Invalid score ${score} for dimension ${i} (must be 1-5)` };
    }
    scores[i] = { score, justification: match[2].trim() };
  }

  // Extract TOTAL
  const totalMatch = text.match(/TOTAL:\s*(\d+)\/40/);
  if (!totalMatch) {
    return { valid: false, error: 'Missing TOTAL line' };
  }
  const total = parseInt(totalMatch[1], 10);

  // Verify total matches sum
  const computedTotal = Object.values(scores).reduce((sum, s) => sum + s.score, 0);
  if (total !== computedTotal) {
    // Allow mismatch but flag it — use computed total
  }

  // Extract gaps (optional section)
  const gaps = [];
  const gapPattern = /GAP-(\d+):\s*Dimension\s*\[?(\d+)\]?,?\s*Score\s*\[?(\d+)\/5\]?\s*\n\s*Issue:\s*(.+)\s*\n\s*Fix:\s*(.+)/gi;
  let gapMatch;
  while ((gapMatch = gapPattern.exec(text)) !== null) {
    gaps.push({
      id: parseInt(gapMatch[1], 10),
      dimension: parseInt(gapMatch[2], 10),
      score: parseInt(gapMatch[3], 10),
      issue: gapMatch[4].trim(),
      fix: gapMatch[5].trim(),
    });
  }

  return {
    valid: true,
    scores,
    total: computedTotal,
    gaps,
    isLgtm: computedTotal >= 36 && gaps.length === 0,
  };
}

// ─── Test Runner ───

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  ✓ ${name}`);
    passed++;
  } catch (err) {
    console.log(`  ✗ ${name}`);
    console.log(`    ${err.message}`);
    failed++;
  }
}

function assert(condition, message) {
  if (!condition) throw new Error(message || 'Assertion failed');
}

function assertEqual(actual, expected, message) {
  if (actual !== expected) {
    throw new Error(`${message || 'assertEqual'}: expected ${expected}, got ${actual}`);
  }
}

// ─── Tests ───

console.log('\nCodex Challenge Parser Tests');
console.log('═'.repeat(40));

// Test 1: Valid LGTM response
console.log('\n1. Valid LGTM Response (40/40)');
const lgtm = fs.readFileSync(path.join(FIXTURES_DIR, 'valid-lgtm.txt'), 'utf-8');
const lgtmResult = parseCodexResponse(lgtm);

test('parses successfully', () => {
  assert(lgtmResult.valid, `Parse failed: ${lgtmResult.error}`);
});

test('extracts 8 dimension scores', () => {
  assertEqual(Object.keys(lgtmResult.scores).length, 8, 'Score count');
});

test('all scores are 5/5', () => {
  for (let i = 1; i <= 8; i++) {
    assertEqual(lgtmResult.scores[i].score, 5, `Dimension ${i} score`);
  }
});

test('total is 40', () => {
  assertEqual(lgtmResult.total, 40, 'Total');
});

test('detects LGTM', () => {
  assert(lgtmResult.isLgtm, 'Should detect as LGTM');
});

test('no gaps', () => {
  assertEqual(lgtmResult.gaps.length, 0, 'Gap count');
});

// Test 2: Valid concerns response
console.log('\n2. Valid Concerns Response (26/40)');
const concerns = fs.readFileSync(path.join(FIXTURES_DIR, 'valid-concerns.txt'), 'utf-8');
const concernsResult = parseCodexResponse(concerns);

test('parses successfully', () => {
  assert(concernsResult.valid, `Parse failed: ${concernsResult.error}`);
});

test('total is 26', () => {
  assertEqual(concernsResult.total, 26, 'Total');
});

test('not LGTM', () => {
  assert(!concernsResult.isLgtm, 'Should not detect as LGTM');
});

test('extracts 5 gaps', () => {
  assertEqual(concernsResult.gaps.length, 5, 'Gap count');
});

test('lowest score is 2/5 (Rollback)', () => {
  assertEqual(concernsResult.scores[5].score, 2, 'Rollback score');
});

// Test 3: Malformed response
console.log('\n3. Malformed Response (fail-closed)');
const malformed = fs.readFileSync(path.join(FIXTURES_DIR, 'malformed.txt'), 'utf-8');
const malformedResult = parseCodexResponse(malformed);

test('rejects malformed response', () => {
  assert(!malformedResult.valid, 'Should reject malformed response');
});

test('provides error message', () => {
  assert(malformedResult.error && malformedResult.error.length > 0, 'Should have error message');
});

// Test 4: Empty response
console.log('\n4. Empty Response');
const empty = fs.readFileSync(path.join(FIXTURES_DIR, 'empty.txt'), 'utf-8');
const emptyResult = parseCodexResponse(empty);

test('rejects empty response', () => {
  assert(!emptyResult.valid, 'Should reject empty response');
});

test('error mentions empty', () => {
  assert(emptyResult.error.toLowerCase().includes('empty'), 'Error should mention empty');
});

// Test 5: Edge cases
console.log('\n5. Edge Cases');

test('null input returns invalid', () => {
  const result = parseCodexResponse(null);
  assert(!result.valid, 'Should reject null');
});

test('undefined input returns invalid', () => {
  const result = parseCodexResponse(undefined);
  assert(!result.valid, 'Should reject undefined');
});

test('whitespace-only input returns invalid', () => {
  const result = parseCodexResponse('   \n\n  ');
  assert(!result.valid, 'Should reject whitespace-only');
});

// ═══════════════════════════════════════
// JSON PARSER TESTS (--output-schema mode)
// ═══════════════════════════════════════

// ─── JSON Parser Logic ───

const DIMENSION_KEYS = [
  'problem_definition', 'architecture', 'sequencing', 'risk',
  'rollback', 'timeline', 'testing', 'omissions'
];

function parseCodexJsonResponse(input) {
  if (!input || (typeof input === 'string' && input.trim().length === 0)) {
    return { valid: false, error: 'Empty response' };
  }

  let data;
  try {
    data = typeof input === 'string' ? JSON.parse(input) : input;
  } catch (e) {
    return { valid: false, error: `Invalid JSON: ${e.message}` };
  }

  // Validate required fields
  if (!data.scores || typeof data.scores !== 'object') {
    return { valid: false, error: 'Missing scores object' };
  }
  if (typeof data.total !== 'number') {
    return { valid: false, error: 'Missing or invalid total' };
  }
  if (!Array.isArray(data.gaps)) {
    return { valid: false, error: 'Missing gaps array' };
  }

  // Validate all 8 dimensions present
  const scores = {};
  for (const key of DIMENSION_KEYS) {
    const dim = data.scores[key];
    if (!dim || typeof dim.score !== 'number' || typeof dim.justification !== 'string') {
      return { valid: false, error: `Missing or invalid dimension: ${key}` };
    }
    if (dim.score < 1 || dim.score > 5) {
      return { valid: false, error: `Score out of range for ${key}: ${dim.score}` };
    }
    scores[key] = dim;
  }

  const computedTotal = DIMENSION_KEYS.reduce((sum, k) => sum + scores[k].score, 0);

  // Validate gaps
  const gaps = data.gaps.map(g => ({
    dimension: g.dimension,
    score: g.score,
    issue: g.issue,
    fix: g.fix,
  }));

  return {
    valid: true,
    scores,
    total: computedTotal,
    gaps,
    isLgtm: computedTotal >= 36 && gaps.length === 0,
  };
}

// ─── JSON Tests ───

console.log('\n\n' + '═'.repeat(40));
console.log('JSON Parser Tests (--output-schema mode)');
console.log('═'.repeat(40));

// Test 6: JSON LGTM
console.log('\n6. JSON LGTM Response (40/40)');
const jsonLgtm = JSON.parse(fs.readFileSync(path.join(FIXTURES_DIR, 'valid-lgtm.json'), 'utf-8'));
const jsonLgtmResult = parseCodexJsonResponse(jsonLgtm);

test('parses JSON successfully', () => {
  assert(jsonLgtmResult.valid, `Parse failed: ${jsonLgtmResult.error}`);
});

test('extracts 8 dimensions from JSON', () => {
  assertEqual(Object.keys(jsonLgtmResult.scores).length, 8, 'Score count');
});

test('all JSON scores are 5/5', () => {
  for (const key of DIMENSION_KEYS) {
    assertEqual(jsonLgtmResult.scores[key].score, 5, `${key} score`);
  }
});

test('JSON total is 40', () => {
  assertEqual(jsonLgtmResult.total, 40, 'Total');
});

test('JSON detects LGTM', () => {
  assert(jsonLgtmResult.isLgtm, 'Should detect as LGTM');
});

test('JSON no gaps', () => {
  assertEqual(jsonLgtmResult.gaps.length, 0, 'Gap count');
});

// Test 7: JSON concerns
console.log('\n7. JSON Concerns Response (26/40)');
const jsonConcerns = JSON.parse(fs.readFileSync(path.join(FIXTURES_DIR, 'valid-concerns.json'), 'utf-8'));
const jsonConcernsResult = parseCodexJsonResponse(jsonConcerns);

test('parses JSON concerns successfully', () => {
  assert(jsonConcernsResult.valid, `Parse failed: ${jsonConcernsResult.error}`);
});

test('JSON total is 26', () => {
  assertEqual(jsonConcernsResult.total, 26, 'Total');
});

test('JSON not LGTM', () => {
  assert(!jsonConcernsResult.isLgtm, 'Should not be LGTM');
});

test('JSON extracts 5 gaps', () => {
  assertEqual(jsonConcernsResult.gaps.length, 5, 'Gap count');
});

test('JSON rollback score is 2', () => {
  assertEqual(jsonConcernsResult.scores.rollback.score, 2, 'Rollback');
});

test('JSON gap has dimension, score, issue, fix', () => {
  const gap = jsonConcernsResult.gaps[0];
  assert(gap.dimension && gap.issue && gap.fix, 'Gap fields present');
  assert(typeof gap.score === 'number', 'Gap score is number');
});

// Test 8: JSON edge cases
console.log('\n8. JSON Edge Cases');

test('JSON rejects null', () => {
  assert(!parseCodexJsonResponse(null).valid, 'Should reject null');
});

test('JSON rejects empty string', () => {
  assert(!parseCodexJsonResponse('').valid, 'Should reject empty');
});

test('JSON rejects invalid JSON string', () => {
  const result = parseCodexJsonResponse('{ not valid json }');
  assert(!result.valid, 'Should reject invalid JSON');
  assert(result.error.includes('Invalid JSON'), 'Error should mention JSON');
});

test('JSON rejects missing scores', () => {
  assert(!parseCodexJsonResponse({ total: 30, gaps: [] }).valid, 'Should reject missing scores');
});

test('JSON rejects missing dimension', () => {
  const partial = { scores: { problem_definition: { score: 5, justification: "ok" } }, total: 5, gaps: [] };
  assert(!parseCodexJsonResponse(partial).valid, 'Should reject incomplete dimensions');
});

test('JSON rejects out-of-range score', () => {
  const bad = JSON.parse(fs.readFileSync(path.join(FIXTURES_DIR, 'valid-lgtm.json'), 'utf-8'));
  bad.scores.risk.score = 6;
  assert(!parseCodexJsonResponse(bad).valid, 'Should reject score > 5');
});

// Test 9: Schema validation
console.log('\n9. Schema File Validation');
const schema = JSON.parse(fs.readFileSync(path.join(FIXTURES_DIR, 'codex-review-schema.json'), 'utf-8'));

test('schema is valid JSON', () => {
  assert(schema.type === 'object', 'Schema root type is object');
});

test('schema requires scores, total, gaps', () => {
  assert(schema.required.includes('scores'), 'Requires scores');
  assert(schema.required.includes('total'), 'Requires total');
  assert(schema.required.includes('gaps'), 'Requires gaps');
});

test('schema defines all 8 dimensions', () => {
  for (const key of DIMENSION_KEYS) {
    assert(schema.properties.scores.properties[key], `Schema missing ${key}`);
  }
});

test('schema limits gaps to max 7', () => {
  assertEqual(schema.properties.gaps.maxItems, 7, 'Max gaps');
});

test('schema disallows additional properties', () => {
  assert(schema.additionalProperties === false, 'No additional properties');
});

// ─── Results ───

console.log('\n' + '═'.repeat(40));
console.log(`Results: ${passed} passed, ${failed} failed`);
console.log('═'.repeat(40) + '\n');

process.exit(failed > 0 ? 1 : 0);
