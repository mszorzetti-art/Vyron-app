import test from 'node:test';
import assert from 'node:assert/strict';
import { ptBR } from './ptBR';
import { enUS } from './enUS';
import { translate, validateDictionaryParity } from './translate';
import {
  formatCompactNumberForLang,
  formatCurrencyForLang,
  formatDateForLang,
  formatNumberForLang,
} from './formatters';
import {
  labelCommissionStage,
  labelContentStatus,
  labelRiskStatus,
} from './domainLabels';

test('PT-BR and EN-US dictionaries have 100% key parity, matching placeholders, and no empty strings', () => {
  const parity = validateDictionaryParity();
  assert.deepEqual(parity.missingInEn, []);
  assert.deepEqual(parity.extraInEn, []);
  assert.deepEqual(parity.placeholderMismatches, []);
  assert.deepEqual(parity.emptyValues, []);
});

test('everyday UI dictionaries do not leak raw internal technical identifiers', () => {
  const forbidden = [
    'system_controls',
    'job_runs',
    'audit_log',
    'PUBLISHING_ENABLED',
    'RISK_REGISTER',
    'score-6.1',
    'source_commit',
    'is_test',
  ];

  for (const [langName, dict] of [
    ['PT-BR', ptBR],
    ['EN-US', enUS],
  ] as const) {
    for (const [key, value] of Object.entries(dict)) {
      for (const token of forbidden) {
        assert.equal(
          value.includes(token),
          false,
          `Forbidden identifier "${token}" leaked in ${langName} key "${key}": ${value}`
        );
      }
    }
  }
});

test('domain status labels follow required PT-BR and EN-US terminology', () => {
  assert.equal(labelContentStatus('Brief', 'PT-BR'), 'Planejamento de conteúdo');
  assert.equal(labelContentStatus('Draft', 'PT-BR'), 'Rascunho');
  assert.equal(labelContentStatus('In Review', 'PT-BR'), 'Em revisão');
  assert.equal(labelContentStatus('Approved', 'PT-BR'), 'Aprovado');
  assert.equal(labelContentStatus('Published', 'PT-BR'), 'Publicado');
  assert.equal(labelContentStatus('Rejected', 'PT-BR'), 'Rejeitado');

  assert.equal(labelContentStatus('Brief', 'EN-US'), 'Content Plan');
  assert.equal(labelContentStatus('Draft', 'EN-US'), 'Draft');
  assert.equal(labelContentStatus('In Review', 'EN-US'), 'In Review');

  assert.equal(labelCommissionStage('Pending', 'PT-BR'), 'Pendente');
  assert.equal(labelCommissionStage('Confirmed', 'PT-BR'), 'Confirmado');
  assert.equal(labelCommissionStage('Received', 'PT-BR'), 'Recebido');

  assert.equal(labelRiskStatus('Mitigado (Demo)', 'PT-BR'), 'Mitigado no protótipo');
  assert.equal(labelRiskStatus('Pendente Infra', 'PT-BR'), 'Infraestrutura pendente');
});

test('regional date and number formatting follows UI language independently from currency', () => {
  assert.equal(formatDateForLang('2026-11-18', 'PT-BR'), '18/11/2026');
  assert.equal(formatDateForLang('2026-11-18', 'EN-US'), '11/18/2026');

  assert.equal(formatNumberForLang(1234.5, 'PT-BR', 1), '1.234,5');
  assert.equal(formatNumberForLang(1234.5, 'EN-US', 1), '1,234.5');

  assert.equal(formatCompactNumberForLang(1500, 'PT-BR'), '1,5K');
  assert.equal(formatCompactNumberForLang(1500, 'EN-US'), '1.5K');

  // Currency symbol and value remain BRL even when UI language is EN-US (no FX conversion on language toggle)
  const brlInPt = formatCurrencyForLang(1234.5, 'BRL', 'PT-BR').replace(/\u00a0/g, ' ');
  const brlInEn = formatCurrencyForLang(1234.5, 'BRL', 'EN-US').replace(/\u00a0/g, ' ');
  assert.equal(brlInPt, 'R$ 1.234,50');
  assert.equal(brlInEn, 'R$1,234.50');

  assert.equal(translate('EN-US', 'controls.stopAll'), 'STOP ALL');
  assert.equal(translate('PT-BR', 'controls.title'), 'CONTROLES DO SISTEMA');
});
