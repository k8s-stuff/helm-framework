import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  buildValuesContractMarkdown,
  buildMigrationSkillMarkdown,
  buildMigrationPlaybookMarkdown,
} from './generate-migration-skill.mjs';

// --- generated migration markdown ------------------------------------------

const READ_SET = ['image', 'replicaCount', 'service'];
const VALUE_TREE = ['image', 'image.repository', 'replicaCount', 'service', 'service.port'];

test('buildValuesContractMarkdown lists every contract key and warns about nested paths', () => {
  const md = buildValuesContractMarkdown({
    chartName: 'helm-framework',
    version: '1.4.0',
    readSet: READ_SET,
    valueTree: VALUE_TREE,
  });
  for (const key of READ_SET) {
    assert.match(md, new RegExp(`\`${key}\``));
  }
  for (const path of VALUE_TREE) {
    assert.match(md, new RegExp(`\`${path.replace('.', '\\.')}\``));
  }
  assert.match(md, /authoritative/i);
  assert.match(md, /not.*grep-verified|declared-surface only/i);
  assert.match(md, /helper indirection/i);
});

test('buildMigrationSkillMarkdown embeds the version pin and a scoped description', () => {
  const md = buildMigrationSkillMarkdown({ chartName: 'helm-framework', version: '1.4.0' });
  assert.match(md, /1\.4\.0/);
  assert.match(md, /^---\nname: "helm-framework-migration"/);
  assert.match(md, /migrat/i);
});

test('buildMigrationPlaybookMarkdown embeds the version pin and all five phase names', () => {
  const md = buildMigrationPlaybookMarkdown({ chartName: 'helm-framework', version: '1.4.0' });
  assert.match(md, /1\.4\.0/);
  assert.match(md, /Phase 0 — Preflight/);
  assert.match(md, /Phase 1 — Baseline capture/);
  assert.match(md, /Phase 2 — Migration/);
  assert.match(md, /Phase 3 — Regression check/);
  assert.match(md, /Phase 4 — Orphan classification/);
  assert.match(md, /kind and role/);
  assert.match(md, /byte-identical/);
});

test('buildMigrationPlaybookMarkdown states leaf-segment matching, not top-level-only', () => {
  const md = buildMigrationPlaybookMarkdown({ chartName: 'helm-framework', version: '1.4.0' });
  assert.match(md, /leaf segment/i);
  assert.match(md, /top-level-only matching is a defect/i);
});

test('buildMigrationPlaybookMarkdown alias table includes the broadened probe and metadata aliases', () => {
  const md = buildMigrationPlaybookMarkdown({ chartName: 'helm-framework', version: '1.4.0' });
  assert.match(md, /`livenessProbe`\s*\|\s*`healthChecks\.livenessProbe`/);
  assert.match(md, /`readinessProbe`\s*\|\s*`healthChecks\.readinessProbe`/);
  assert.match(md, /`startupProbe`\s*\|\s*`healthChecks\.startupProbe`/);
  assert.match(md, /`annotations`\s*\|\s*`podAnnotations`/);
  assert.match(md, /`labels`\s*\|\s*`podLabels`/);
});

test('buildMigrationPlaybookMarkdown states the phase-3/phase-4 contradiction rule', () => {
  const md = buildMigrationPlaybookMarkdown({ chartName: 'helm-framework', version: '1.4.0' });
  assert.match(md, /Phase-3\/phase-4 cross-check/i);
  assert.match(md, /contradiction/i);
  assert.match(md, /second, independent net/i);
});

test('buildMigrationPlaybookMarkdown adds affinity to the critical-field checklist', () => {
  const md = buildMigrationPlaybookMarkdown({ chartName: 'helm-framework', version: '1.4.0' });
  assert.match(md, /- affinity/);
  assert.match(md, /podAntiAffinity/);
});

test('buildMigrationPlaybookMarkdown states the composite-row verdict convention', () => {
  const md = buildMigrationPlaybookMarkdown({ chartName: 'helm-framework', version: '1.4.0' });
  assert.match(md, /Verdict granularity/i);
  assert.match(md, /one verdict per checklist row/i);
});

test('buildMigrationPlaybookMarkdown walks the livenessProbe worked example to LIKELY MISS', () => {
  const md = buildMigrationPlaybookMarkdown({ chartName: 'helm-framework', version: '1.4.0' });
  assert.match(md, /Worked example/i);
  const exampleIndex = md.search(/Worked example/i);
  assert.ok(exampleIndex >= 0, 'expected a worked example section');
  const exampleSection = md.slice(exampleIndex);
  assert.match(exampleSection, /livenessProbe/);
  assert.match(exampleSection, /byte-identical/);
  assert.match(exampleSection, /LIKELY MISS/);
  assert.match(exampleSection, /not[\s\S]*?removed/i);
});

// --- idempotence -----------------------------------------------------------

test('buildValuesContractMarkdown is idempotent', () => {
  const input = { chartName: 'helm-framework', version: '1.4.0', readSet: READ_SET, valueTree: VALUE_TREE };
  assert.equal(buildValuesContractMarkdown(input), buildValuesContractMarkdown(input));
});

test('buildMigrationSkillMarkdown is idempotent', () => {
  const input = { chartName: 'helm-framework', version: '1.4.0' };
  assert.equal(buildMigrationSkillMarkdown(input), buildMigrationSkillMarkdown(input));
});

test('buildMigrationPlaybookMarkdown is idempotent', () => {
  const input = { chartName: 'helm-framework', version: '1.4.0' };
  assert.equal(buildMigrationPlaybookMarkdown(input), buildMigrationPlaybookMarkdown(input));
});
