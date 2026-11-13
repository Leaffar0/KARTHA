const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const source = fs.readFileSync(path.join(root, 'scripts/scr_apresentacao/scr_apresentacao.gml'), 'utf8');
const played = [];
const ctx = {
  array_push: (a,v) => a.push(v),
  string_lower: s => s.toLowerCase(), string_pos: (s, text) => text.indexOf(s) + 1,
  instance_exists: c => c != null, variable_instance_exists: (c, k) => Object.hasOwn(c, k),
  variable_struct_exists: (c, k) => Object.hasOwn(c, k),
  tocar_som_variado: g => played.push(g)
};
vm.createContext(ctx);
function extract(name) {
  const start = source.indexOf('function ' + name + '(');
  assert.ok(start >= 0);
  const end = source.indexOf('\nfunction ', start + 1);
  return source.slice(start, end < 0 ? undefined : end);
}
for (const name of ['grupo_som_criatura', 'nome_tropa_sonora', 'tocar_som_impacto_criatura'])
  vm.runInContext(extract(name), ctx);
function impact(attacker, target, extra = {}) {
  played.length = 0;
  const data = {atacante: null, alvo: null, nome_atacante: attacker, nome_alvo: target,
    dano: 3, defesa: 0, critico: false, ...extra};
  const before = JSON.stringify(data);
  ctx.tocar_som_impacto_criatura(data);
  assert.equal(JSON.stringify(data), before, 'Audio must not modify combat state');
  return [...played];
}
assert.deepEqual(impact('Lobo Alfa', 'Slime'), ['mordida', 'slime_dano']);
assert.deepEqual(impact('Urso', 'Esqueleto'), ['mordida', 'esqueleto']);
assert.deepEqual(impact('Slime Digestão', 'Goblin'), ['slime_ataque']);
assert.deepEqual(impact('Slimet', 'Esqueleto'), ['slime_ataque', 'esqueleto']);
assert.deepEqual(impact('Esqueleto', 'Esqueleto'), ['esqueleto']);
assert.deepEqual(impact('Lobo', 'Slime', {dano: 0, defesa: 4}), []);
assert.deepEqual(impact('Lobo', 'Goblin', {magica: true}), ['magia_impacto']);
assert.deepEqual(impact('Goblin', 'Slime', {critico: true}), ['slime_dano']);
assert.deepEqual(impact('', ''), ['ataque_corpo']);
assert.deepEqual(impact('Mimic', ''), ['mordida']);
const catalogCode = extract('catalogo_sons_jogo');
for (const n of new Set(catalogCode.match(/snd_\w+/g))) ctx[n] = n;
vm.runInContext(catalogCode.replace('static _grupos', 'var _grupos'), ctx);
const catalog = ctx.catalogo_sons_jogo();
assert.deepEqual(Array.from(catalog.imitacao), ['snd_mimic_bau_1', 'snd_mimic_bau_2']);
const all = Object.values(catalog).flat();
const project = fs.readFileSync(path.join(root, 'KARTHA.yyp'), 'utf8');
for (const entry of JSON.parse(fs.readFileSync(path.join(root, 'audio_importar/preparacao/catalogo_criaturas.json'), 'utf8'))) {
  assert.ok(all.includes(entry.name), entry.name + ' must be available in F7');
  const rel = `sounds/${entry.name}/${entry.name}.yy`;
  assert.ok(project.includes(rel));
  const meta = JSON.parse(fs.readFileSync(path.join(root, rel), 'utf8'));
  assert.ok(fs.statSync(path.join(root, 'sounds', entry.name, meta.soundFile)).size > 44);
}
console.log('OK: creature audio, blocked/magical/lethal impacts, Mimic chest variations and F7 resources');
