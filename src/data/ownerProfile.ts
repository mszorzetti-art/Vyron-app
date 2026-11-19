export const OWNER_PROFILE = {
  name: 'Marcus Zorzetti',
  email: 'mszorzetti@gmail.com',
  roleLabel: 'Proprietário & Operador Único',
} as const;

const LEGACY_OWNER_ALIASES = new Set(['mateus zorzetti', 'proprietário', '']);

export function normalizeOwnerName(value?: string | null): string {
  const trimmed = (value ?? '').trim();
  if (!trimmed || LEGACY_OWNER_ALIASES.has(trimmed.toLowerCase())) {
    return OWNER_PROFILE.name;
  }
  return trimmed;
}
