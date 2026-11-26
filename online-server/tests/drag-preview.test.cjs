// Exercise the actual local GML preview/selection functions with engine stubs.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const groups = { resource: [], troop: [], battleSlot: [], resourceSlot: [], constructionSlot: [], construction: [] };
const context = {
  groups, noone: null, obj_recurso: 'resource', obj_carta: 'troop', obj_slot_batalha: 'battleSlot',
  obj_slot_recurso: 'resourceSlot', obj_slot_construcao: 'constructionSlot', obj_construcao: 'construction',
  global: { CARTA_LARGURA: 80 }, array_length: a => a.length,
  array_push: (a, x) => a.push(x), array_get_index: (a, x) => a.indexOf(x), is_array: Array.isArray,
  instance_number: type => groups[type].length, instance_find: (type, i) => groups[type][i],
  instance_exists: Boolean, max: Math.max, min: Math.min, string: String,
  string_pos: (needle, haystack) => haystack.indexOf(needle) + 1,
  point_distance: (x, y, a, b) => Math.hypot(a - x, b - y),
  primeiro_turno_do_lado: () => false, categoria_bloqueada_primeiro_turno: () => false,
  recurso_ja_colocado_no_turno: () => false, ultima_carta_jogada: () => null,
  lado_oposto: side => side === 'jogador' ? 'inimigo' : 'jogador',
  posicao_entrada: side => side === 'jogador' ? 4 : 0, posicao_ataque: () => 2,
  slot_tem_armadilha: () => false, buscar_tropa_na_coluna: () => null,
  motivo_recusa_equipamento: (target, required) => target.nivel_inteligencia < required ? 'Inteligência insuficiente' : '',
  variable_instance_get: (obj, key) => obj[key], variable_global_exists: () => false,
  mouse_y: 100, mouse_na_faixa_da_mao: () => false,
  resumo_usos_turno: () => ({ troops: 0, items: 0, spells: 0, constructions: 0, terrain: 0, resourcePlaced: 0 }),
  obj_controlador: { turno: 'jogador', modo_partida: 'ia', rolagens_pendentes: 0, terreno_ativo: '' },
};
vm.createContext(context);
function load(file, names) {
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  for (const name of names) {
    const start = source.indexOf(`function ${name}(`), end = source.indexOf('\nfunction ', start + 1);
    assert.ok(start >= 0, name);
    let code = source.slice(start, end < 0 ? undefined : end).replace(/^#.*$/gm, '');
    code = code.replace(/with \(obj_recurso\) \{([\s\S]*?)\n    \}/,
      'for (const _instance of groups[obj_recurso]) { with (_instance) {$1\n    }}');
    vm.runInContext(code, context);
  }
}
load('scripts/scr_cartas/scr_cartas.gml', ['ajustar_custo_por_terreno', 'selecionar_recursos_para_custo', 'nome_recurso_exibicao']);
load('scripts/scr_ui/scr_ui.gml', ['motivo_bloqueio_arrasto', 'carta_arrasto_sem_alvo', 'alvos_previa_arrasto', 'estado_previa_arrasto']);
function resource(type, amount = 1) {
  const r = { tipo: type, quantidade: amount, virado: false, dono: 'jogador', bloqueado_turnos: 0 };
  r.id = r; return r;
}
const mana = resource('mana', 2), blood = resource('sangue');
groups.resource.push(mana, blood);
let result = context.selecionar_recursos_para_custo([{ tipo: 'qualquer', quantidade: 1 }, { tipo: 'mana', quantidade: 2 }], 'jogador', 'tropa');
assert.equal(result.sucesso, true, 'specific cost is reserved before neutral');
assert.equal(result.recursos.length, 2);
assert.equal(mana.virado, false, 'preview never spends resources');
blood.bloqueado_turnos = 1;
result = context.selecionar_recursos_para_custo([{ tipo: 'mana', quantidade: 2 }, { tipo: 'qualquer', quantidade: 1 }], 'jogador', 'tropa');
assert.equal(result.sucesso, false, 'cannot double-spend a resource or use blocked resources');
context.obj_controlador.terreno_ativo = 'planicies_profanas';
result = context.selecionar_recursos_para_custo({ tipo: 'mana', quantidade: 3 }, 'jogador', 'tropa');
assert.equal(result.sucesso, true, 'terrain discount is included');
const card = { id: 'drag', categoria: 'tropa', dono: 'jogador', custo: null, efeitos_declarativos: [],
  alvo_declarativo: 'nenhum', efeito_tipo: '', x: 100, y: 100, arrastar_inicio_x: 100, arrastar_inicio_y: 300 };
groups.battleSlot.push({ posicao: 4, lane: 0, ocupado: false, x: 100, y: 100 });
assert.equal(context.estado_previa_arrasto(card).pronta, true);
groups.battleSlot[0].ocupado = true;
assert.equal(context.estado_previa_arrasto(card).pronta, false);
assert.match(context.estado_previa_arrasto(card).dica, /ocupada/);
groups.battleSlot[0].ocupado = false;
context.obj_controlador.turno = 'inimigo';
assert.match(context.estado_previa_arrasto(card).dica, /seu turno/);
assert.equal(context.estado_previa_arrasto(card).pronta, false);
context.obj_controlador.turno = 'jogador';
context.mouse_na_faixa_da_mao = () => true;
assert.equal(context.estado_previa_arrasto(card).pronta, false);
context.mouse_na_faixa_da_mao = () => false;
card.categoria = 'item_equipavel'; card.requisito_inteligencia_item = 2;
groups.troop.push({ id: 'invalid', travada: true, dono: 'jogador', x: 100, y: 100, nivel_inteligencia: 0 },
  { id: 'valid', travada: true, dono: 'jogador', x: 110, y: 100, nivel_inteligencia: 2 });
assert.equal(context.estado_previa_arrasto(card).perto.x, 110, 'valid equipment targets have the same priority as placement');
card.categoria = 'item_consumivel'; card.efeito_tipo = 'comprar_cartas';
assert.equal(context.carta_arrasto_sem_alvo(card), true);
console.log('OK: resource reservation, missing/blocked resources, terrain discount, placement, turn/hand blocking and equipment targeting');

const eyeCost=[{tipo:'mana',quantidade:1},{tipo:'sangue',quantidade:1}];
groups.resource.length=0;groups.resource.push(resource('sangue'));
context.obj_controlador.terreno_ativo='';
assert.equal(context.selecionar_recursos_para_custo(eyeCost,'jogador','tropa').sucesso,false);
context.obj_controlador.terreno_ativo='planicies_profanas';
assert.equal(context.selecionar_recursos_para_custo(eyeCost,'jogador','tropa').sucesso,true);
context.obj_controlador.terreno_ativo='';groups.resource.push(resource('mana'));
assert.equal(context.selecionar_recursos_para_custo(eyeCost,'jogador','tropa').sucesso,true);
console.log('OK: Demon Eye requires mana and blood, except the active Plains mana discount');
