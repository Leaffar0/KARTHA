const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const source = fs.readFileSync(path.join(root, 'scripts/scr_nevoa_cemiterio/scr_nevoa_cemiterio.gml'), 'utf8');
const c = { obj_controlador: {}, instance_exists: Boolean,
  variable_instance_exists: (o, k) => k in o,
  lado_oposto: x => x === 'jogador' ? 'inimigo' : 'jogador' };
vm.createContext(c);
vm.runInContext(source.slice(0, source.indexOf('function nevoa_atualizar_consulta')), c);
for (const roll of [1, 20, 21, 100]) {
  let calls = 0;
  c.irandom_range = () => { calls++; return roll; };
  c.obj_controlador = { modo_partida: 'ia', turno: 'jogador', terreno_ativo: 'cemiterio', partida_iniciada: true, nevoa_turno_sorteado: '', nevoa_dono: '' };
  c.nevoa_iniciar_turno('jogador');
  assert.equal(c.obj_controlador.nevoa_dono, roll <= 20 ? 'inimigo' : '');
  c.nevoa_iniciar_turno('jogador');
  assert.equal(calls, 1, 'announcing again must not reroll');
  c.nevoa_iniciar_turno('inimigo');
  assert.equal(calls, 2);
  c.obj_controlador.terreno_ativo = '';
  c.nevoa_iniciar_turno('jogador');
  assert.equal(c.obj_controlador.nevoa_dono, '');
  assert.equal(calls, 2);
}
Object.assign(c.obj_controlador, { terreno_ativo: 'cemiterio', nevoa_dono: 'inimigo', turno: 'jogador' });
const troop = { categoria: 'tropa', travada: true, esta_na_mao: false, dono: 'inimigo' };
assert.equal(c.tropa_oculta_nevoa(troop), true);
troop.esta_na_mao = true;
assert.equal(c.tropa_oculta_nevoa(troop), false);
troop.esta_na_mao = false;
c.obj_controlador.turno = 'inimigo';
assert.equal(c.tropa_oculta_nevoa(troop), true, 'bot turn preserves player perspective');
c.obj_controlador.modo_partida = 'online';
assert.equal(c.tropa_oculta_nevoa(troop), true, 'online observer is local jogador');
c.irandom_range = () => { throw Error('client cannot roll online fog'); };
c.nevoa_iniciar_turno('inimigo');
c.obj_controlador.terreno_ativo = '';
assert.equal(c.tropa_oculta_nevoa(troop), false);
console.log('OK: Cemetery chance boundaries, one roll per turn, expiry and observer visibility');
