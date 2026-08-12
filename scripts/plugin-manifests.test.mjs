import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

test('marketplace.json declares the helm-framework plugin at the expected relative source', () => {
  const marketplace = JSON.parse(
    readFileSync(join(REPO_ROOT, '.claude-plugin/marketplace.json'), 'utf8'),
  );
  assert.equal(marketplace.name, 'helm-framework');
  assert.ok(marketplace.owner && marketplace.owner.name);
  assert.equal(marketplace.plugins.length, 1);
  assert.equal(marketplace.plugins[0].name, 'helm-framework');
  assert.equal(marketplace.plugins[0].source, './plugins/helm-framework');
});

test('plugin.json declares the helm-framework plugin name and a non-empty description', () => {
  const plugin = JSON.parse(
    readFileSync(
      join(REPO_ROOT, 'plugins/helm-framework/.claude-plugin/plugin.json'),
      'utf8',
    ),
  );
  assert.equal(plugin.name, 'helm-framework');
  assert.ok(plugin.description.length > 0);
  assert.ok(typeof plugin.version === 'string');
});
