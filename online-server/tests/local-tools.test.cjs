const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const source = fs.readFileSync(path.join(root, 'scripts/scr_ui/scr_ui.gml'), 'utf8');
const control = { modo_partida: 'local', turno: 'jogador', rolagens_pendentes: 0, mao_y: 600,
  monte: ['a', 'b'], monte_inimigo: ['enemy'], debug_montes_guardados: { jogador: null, inimigo: null } };
let added = 0, created = 0, resources = 0, failures = 0;
const slots = [];
const context = {
  global: { DEBUG_COMBATE: true }, obj_controlador: control, noone: null,
  obj_slot_batalha: 'slot', room_width: 1152, room_height: 648, c_aqua: 0,
  array_length: a => a.length, array_push: (a, v) => a.push(v),
  variable_struct_get: (s, k) => s[k], variable_struct_set: (s, k, v) => { s[k] = v; },
  lado_controlado_localmente: () => true, controlador_modal_atual: () => '',
  instance_number: () => slots.length, instance_find: (_, i) => slots[i],
  posicao_entrada: () => 4, buscar_tropa_na_coluna: () => null,
  comprar_carta_do_deck_por_funcao: () => { added++; }, debug_encher_recursos: () => { resources++; },
  organizar_mao() {}, debug_combate() {}, mostrar_feedback() {}, mostrar_aviso_regra() { failures++; },
  string: String, nome_jogador_lado: side => side,
  criar_dados_esquilo() {}, criar_dados_item_espada: () => ({ nome: 'Espada', sprite_carta: null, bonus_mod_dano: 2, bonus_defesa: 0 }),
  criar_dados_item_escudo: () => ({ nome: 'Escudo', sprite_carta: 'shield', bonus_mod_dano: 0, bonus_defesa: 2 }),
  criar_dados_item_pocao() {}, criar_dados_magica_bola_fogo() {}, criar_dados_magica_veneno() {},
  criar_dados_lobo: () => ({ vida: 10 }), spr_carta_placeholder: 'placeholder',
  criar_tropa_no_slot: (data, slot, side) => { created++; slot.ocupado = true; return { data, dono: side }; },
  aplicar_condicao() {}, criar_dados_item_equipado: (...args) => args, equipar_item_dados() {},
  motivo_bloqueio_arrasto: () => '', selecionar_recursos_para_custo: () => ({ sucesso: true, faltas: [] }),
};
vm.createContext(context);
for (const name of ['debug_preparar_cenario', 'disponibilidade_carta_mao', 'sigla_condicao']) {
  const a = source.indexOf(`function ${name}(`), b = source.indexOf('\nfunction ', a + 1);
  assert.ok(a >= 0);
  vm.runInContext(source.slice(a, b < 0 ? undefined : b), context);
}
assert.equal(context.debug_preparar_cenario(4), true);
assert.equal(control.monte.length, 0);
assert.equal(control.debug_montes_guardados.jogador.join(','), 'a,b');
assert.equal(context.debug_preparar_cenario(4), false, 'cannot overwrite backup');
control.monte.push('returned');
assert.equal(context.debug_preparar_cenario(5), true);
assert.equal(control.monte.join(','), 'returned,a,b', 'restoration preserves cards returned during test');
assert.equal(control.monte_inimigo.join(','), 'enemy');
assert.equal(context.debug_preparar_cenario(5), false, 'cannot restore twice');
control.modo_partida = 'online';
assert.equal(context.debug_preparar_cenario(1), false);
assert.equal(added, 0);
control.modo_partida = 'local';
context.global.DEBUG_COMBATE = false;
assert.equal(context.debug_preparar_cenario(1), false);
context.global.DEBUG_COMBATE = true;
assert.equal(context.debug_preparar_cenario(1), true);
assert.equal(added, 6); assert.equal(resources, 1);
slots.push({ posicao: 4, lane: 0, ocupado: false });
assert.equal(context.debug_preparar_cenario(3), false);
assert.equal(created, 0, 'insufficient space must not create half a scenario');
slots.push({ posicao: 4, lane: 1, ocupado: false });
assert.equal(context.debug_preparar_cenario(3), true);
assert.equal(created, 2);
const card = { custo: null, dono: 'jogador', categoria: 'tropa' };
assert.equal(context.disponibilidade_carta_mao(card).texto, 'CUSTO OK');
context.motivo_bloqueio_arrasto = () => 'Primeiro turno';
assert.equal(context.disponibilidade_carta_mao(card).motivo, 'Primeiro turno');
context.motivo_bloqueio_arrasto = () => '';
context.selecionar_recursos_para_custo = () => ({ sucesso: false, faltas: ['2 Mana', '1 Osso'] });
assert.equal(context.disponibilidade_carta_mao(card).motivo, 'Falta: 2 Mana, 1 Osso');
const types = ['queimado', 'envenenado', 'paralisado', 'congelado', 'confusao', 'adormecido',
  'berserker', 'loucura', 'sangrando', 'corrosao', 'apodrecer', 'regeneracao', 'eletrocutado'];
assert.equal(new Set(types.map(context.sigla_condicao)).size, types.length);
assert.ok(failures >= 3);
console.log('OK: offline/debug guards, additive scenarios, deck backup/restore, atomic setup, hand status and condition labels');
