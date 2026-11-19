import test from 'node:test';
import assert from 'node:assert/strict';
import {
  DEFAULT_DEMO_ACCESS_HASH,
  buildAuthenticatedSession,
  createInitialAccessSession,
  evaluatePersistedSession,
  hashAccessCredential,
  shouldAutoLock,
  verifyAccessCredential,
} from './vyronAccess';
import { OWNER_PROFILE, normalizeOwnerName } from '../data/ownerProfile';

test('verifyAccessCredential validates via salted SHA-256 without plaintext comparison', () => {
  assert.equal(verifyAccessCredential('', DEFAULT_DEMO_ACCESS_HASH), false);
  assert.equal(verifyAccessCredential('wrong-pass', DEFAULT_DEMO_ACCESS_HASH), false);
  assert.equal(verifyAccessCredential('vyron2026', DEFAULT_DEMO_ACCESS_HASH), true);

  const customHash = hashAccessCredential('minha-chave-privada');
  assert.notEqual(customHash, 'minha-chave-privada');
  assert.equal(verifyAccessCredential('minha-chave-privada', customHash), true);
  assert.equal(verifyAccessCredential('vyron2026', customHash), false);
});

test('shouldAutoLock triggers strictly after configured inactivity window', () => {
  const t0 = 1_700_000_000_000;
  assert.equal(shouldAutoLock(t0, t0 + 14 * 60_000, 15), false);
  assert.equal(shouldAutoLock(t0, t0 + 15 * 60_000, 15), true);
  assert.equal(shouldAutoLock(t0, t0 + 120 * 60_000, 0), false);
});

test('evaluatePersistedSession keeps active session across reload, locks on inactivity, and expires after max age', () => {
  const t0 = 1_700_000_000_000;
  const active = buildAuthenticatedSession(createInitialAccessSession(), t0);

  const reloadedSoon = evaluatePersistedSession(active, t0 + 5 * 60_000);
  assert.equal(reloadedSoon.authenticated, true);
  assert.equal(reloadedSoon.locked, false);

  const reloadedIdle = evaluatePersistedSession(active, t0 + 20 * 60_000);
  assert.equal(reloadedIdle.authenticated, true);
  assert.equal(reloadedIdle.locked, true);
  assert.equal(reloadedIdle.lockReason, 'inactivity');

  const expired = evaluatePersistedSession(active, t0 + 13 * 3_600_000);
  assert.equal(expired.authenticated, false);
  assert.equal(expired.locked, false);
  assert.equal(expired.lockReason, 'expired');
});

test('normalizeOwnerName enforces centralized Marcus Zorzetti identity', () => {
  assert.equal(OWNER_PROFILE.name, 'Marcus Zorzetti');
  assert.equal(normalizeOwnerName('Mateus Zorzetti'), 'Marcus Zorzetti');
  assert.equal(normalizeOwnerName(''), 'Marcus Zorzetti');
  assert.equal(normalizeOwnerName('Marcus Zorzetti'), 'Marcus Zorzetti');
});
