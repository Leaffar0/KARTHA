const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const { stripTypeScriptTypes } = require('node:module');
const root = path.resolve(__dirname, '../..');
const server = fs.readFileSync(path.join(root, 'online-server/src/rooms/UnoRoom.ts'), 'utf8');
// Parse the complete server file, then exercise its actual methods in isolation.
stripTypeScriptTypes(server);
const names = ['conditions', 'setConditions', 'hasCondition', 'removeCondition', 'applyCondition',
  'tryBreakIllusion', 'processSleep', 'endTurn', 'drawCards'];
const methods = names.map(name => {
  const start = server.indexOf(`  private ${name}(`);
  assert.ok(start >= 0, name);
  const end = server.indexOf('\n  private ', start + 1);
  return server.slice(start, end);
}).join('\n');
const Room = vm.runInNewContext(stripTypeScriptTypes(`(class { ${methods} })`));
function setup() {
  const room = new Room();
  room.privatePlayers = [{ traps: [], deck: [], hand: [] }, { traps: [], deck: [], hand: [] }];
  room.state = { cards: new Map(), currentPlayer: 0, turnNumber: 1 };
  room.abilityState = card => ({ ...card.ability });
  room.setAbilityState = (card, state) => { card.ability = state; };
  room.rollForSeat = () => 1;
  const players = [{ blockedTurns: 0 }, { blockedTurns: 0 }];
  room.playerBySeat = seat => players[seat];
  room.resetPlayerTurn = () => {};
  room.processMadness = room.processArtillery = () => [];
  room.updateCounts = () => {};
  room.destroyPublicCard = card => room.state.cards.delete(card.instanceId);
  return room;
}
function troop(id = 'a', owner = 1) {
  return { instanceId: id, owner, category: 'tropa', condition: '', conditionTurns: 0,
    conditionPower: 0, ability: {}, life: 20, maxLife: 20, intelligence: 0 };
}
const room = setup(), card = troop();
room.state.cards.set('a', card);
room.applyCondition(card, 'envenenado', -1, 1);
room.applyCondition(card, 'queimado', 3, 2);
room.applyCondition(card, 'paralisado', 1, 0);
assert.equal(room.conditions(card).length, 3);
assert.equal(room.conditions(card).find(x => x.type === 'paralisado').turns, 2);
room.endTurn(0);
assert.equal(card.life, 17, 'poison and burn both deal damage');
room.endTurn(1);
assert.equal(room.conditions(card).find(x => x.type === 'paralisado').turns, 1);
room.endTurn(0);
room.endTurn(1);
assert.equal(room.hasCondition(card, 'paralisado'), false);
assert.equal(room.hasCondition(card, 'queimado'), true);
assert.equal(room.hasCondition(card, 'envenenado'), true);
room.applyCondition(card, 'sangrando', 1, 3);
room.applyCondition(card, 'sangrando', 1, 3);
assert.equal(room.conditions(card).find(x => x.type === 'sangrando').turns, 2);
room.applyCondition(card, 'adormecido', -1, 0);
room.processSleep(1);
assert.equal(room.hasCondition(card, 'adormecido'), false);
assert.equal(room.hasCondition(card, 'envenenado'), true);
room.applyCondition(card, 'queimado', 1, 2);
assert.equal(room.conditions(card).filter(x => x.type === 'queimado').length, 1);
const source = troop('source', 0);
room.state.cards.set('source', source);
card.ability.illusion = true;
card.ability.illusionSourceId = 'source';
let rolls = [1, 20]; room.rollForSeat = () => rolls.shift();
assert.equal(room.tryBreakIllusion(card), false);
assert.equal(card.ability.illusion, true);
rolls = [20, 1];
assert.equal(room.tryBreakIllusion(card), true);
assert.equal(card.ability.illusion, false);
card.ability.illusion = true;
rolls = [10, 10];
assert.equal(room.tryBreakIllusion(card), true, 'a tied test is no longer lower');
card.ability.illusion = true;
room.state.cards.delete('source');
assert.equal(room.tryBreakIllusion(card), true);
const net = setup(), combined = troop();
for (const roll of [1, 20, 21, 100]) {
  const fog = setup();
  fog.state.terrainDefinitionId = 'cemiterio';
  fog.roll = sides => { assert.equal(sides, 100); return roll; };
  fog.endTurn(0);
  assert.equal(fog.state.fogProtectedSeat, roll <= 20 ? 0 : -1);
  fog.endTurn(1);
  assert.equal(fog.state.fogProtectedSeat, roll <= 20 ? 1 : -1);
  fog.state.terrainDefinitionId = '';
  fog.endTurn(0);
  assert.equal(fog.state.fogProtectedSeat, -1, 'fog clears outside Cemetery');
}
net.state.cards.set('a', combined);
combined.life = 1;
net.applyCondition(combined, 'envenenado', -1, 1);
net.applyCondition(combined, 'regeneracao', 2, 2);
net.endTurn(0);
assert.equal(combined.life, 2, 'damage and healing resolve together');
assert.ok(net.state.cards.has('a'));
net.drawCards(0, 1);
assert.equal(net.privatePlayers[0].hand.length, 0);
net.privatePlayers[0].deck.push({ definitionId: 'returned-card' });
net.drawCards(0, 1);
assert.equal(net.privatePlayers[0].hand[0].definitionId, 'returned-card');

// Verify the same local GML collection helpers with minimal engine primitives.
const local = fs.readFileSync(path.join(root, 'scripts/scr_combate/scr_combate.gml'), 'utf8');
const helpers = ['obter_condicao', 'tem_condicao', 'sincronizar_condicao_principal', 'remover_condicao',
  'aplicar_condicao', 'aplicar_sangramento', 'tropa_pode_agir', 'tropa_pode_usar_habilidade'];
const context = {
  noone: null, obj_carta: 'troop', instance_exists: Boolean,
  variable_instance_exists: (c, key) => key in c, array_length: a => a.length,
  array_push: (a, x) => a.push(x), array_delete: (a, i, n) => a.splice(i, n),
  max: Math.max, string_upper: s => s.toUpperCase(), mostrar_feedback() {},
  obter_config_condicao: () => ({ cor: 0 }), ativar_loucura_mutua() {}, debug_combate() {}, string: String,
};
vm.createContext(context);
for (const name of helpers) {
  const start = local.indexOf(`function ${name}(`);
  const next = local.indexOf('\nfunction ', start + 1);
  vm.runInContext(local.slice(start, next < 0 ? undefined : next).replace(/^#.*$/gm, ''), context);
}
const localCard = { condicoes: [], object_index: 'troop', imunidade_queimado_turnos: 0,
  x: 0, y: 0, sprite_height: 10 };
context.aplicar_condicao(localCard, 'envenenado', -1, 1);
context.aplicar_condicao(localCard, 'paralisado', 1, 0);
assert.equal(localCard.condicoes.length, 2);
assert.equal(context.obter_condicao(localCard, 'paralisado').turnos, 2);
assert.equal(context.tropa_pode_agir(localCard), false);
assert.equal(context.tropa_pode_usar_habilidade(localCard), false);
context.remover_condicao(localCard, 'paralisado');
assert.equal(context.tem_condicao(localCard, 'envenenado'), true);
assert.equal(context.tropa_pode_agir(localCard), true);
context.aplicar_sangramento(localCard);
context.aplicar_sangramento(localCard);
assert.equal(context.obter_condicao(localCard, 'sangrando').turnos, 2);
// GML's with iterates instances; emulate one instance to exercise the actual
// beginning/end-of-turn functions without a graphical runner.
Object.assign(context, { min: Math.min, aplicar_flash_dano() {}, mostrar_dano_tropa() {},
  destruir_tropa(card) { card.morrendo = true; }, processar_loucura() {} });
for (const name of ['processar_condicoes', 'expirar_condicoes']) {
  const start = local.indexOf(`function ${name}(`), next = local.indexOf('\nfunction ', start + 1);
  let code = local.slice(start, next).replace(/^#.*$/gm, '').trim();
  code = code.replace('with (obj_carta) {', 'for (const _current of [localTroop]) { with (_current) {');
  // Insert a matching close immediately before the function's last close.
  const close = code.lastIndexOf('}');
  code = code.slice(0, close) + '}\n' + code.slice(close);
  vm.runInContext(code, context);
}
Object.assign(localCard, { nome_carta: 'Tropa de teste', condicoes: [], dono: 'jogador', travada: true, morrendo: false,
  vida: 20, vida_maxima: 20, sombra_cooldown: 0, eletrocutado_neste_ciclo: false });
context.aplicar_condicao(localCard, 'envenenado', -1, 1);
context.aplicar_condicao(localCard, 'queimado', 3, 2);
context.aplicar_condicao(localCard, 'paralisado', 2, 0);
localCard.id = localCard;
context.localTroop = localCard;
context.processar_condicoes('jogador');
assert.equal(localCard.vida, 17);
context.expirar_condicoes('jogador');
assert.equal(context.obter_condicao(localCard, 'paralisado').turnos, 1);
context.processar_condicoes('jogador');
context.expirar_condicoes('jogador');
assert.equal(context.tem_condicao(localCard, 'paralisado'), false);
assert.equal(context.tem_condicao(localCard, 'envenenado'), true);
console.log('OK: simultaneous conditions, two-turn paralysis, independent expiry, sleep, bleeding, net healing and illusion retests; local helpers and server');

localCard.condicoes = [];
localCard.sombra_cooldown = 2;
localCard.sombra_ativa = true;
context.expirar_condicoes('jogador');
assert.equal(localCard.sombra_ativa, true, 'shadow must protect throughout the enemy turn');
assert.equal(localCard.sombra_cooldown, 2);
context.processar_condicoes('jogador');
assert.equal(localCard.sombra_ativa, false);
assert.equal(localCard.sombra_cooldown, 1);
context.expirar_condicoes('jogador');
context.processar_condicoes('jogador');
assert.equal(localCard.sombra_cooldown, 0);


// Poison ticks when control passes to the affected troop's owner.
for (const seat of [0, 1]) {
  const online = setup();
  const target = troop('poisoned', seat);
  online.state.cards.set(target.instanceId, target);
  online.applyCondition(target, 'envenenado', -1, 1);
  Object.assign(localCard, { vida: target.life, condicoes: [], dono: seat === 0 ? 'jogador' : 'inimigo' });
  assert.equal(context.aplicar_condicao(localCard, 'envenenado', -1, 1), true);
  let ending = online.state.currentPlayer;
  for (let turn = 0; turn < 4; turn++) {
    const next = 1 - ending;
    context.expirar_condicoes(ending === 0 ? 'jogador' : 'inimigo');
    context.processar_condicoes(next === 0 ? 'jogador' : 'inimigo');
    online.endTurn(ending);
    assert.equal(localCard.vida, target.life);
    ending = next;
  }
  assert.equal(target.life, 18);
}
