const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { stripTypeScriptTypes } = require('node:module');
const { test } = require('node:test');
const loadGml = require('./helpers/load-gml.cjs');

function localRules() {
  const local = vm.createContext({
    noone: null, spr_bola_de_fogo: 1, spr_carta_mago_da_sombra: 2,
    obj_controlador: { modo_partida: 'ia', terreno_ativo: 'planicies_profanas' },
    obj_recurso: 'resources', groups: { resources: [] }, instance_exists: Boolean,
    array_length: list => list.length, array_push: (list, value) => list.push(value),
    array_get_index: (list, value) => list.indexOf(value), is_array: Array.isArray,
    max: Math.max, min: Math.min, registrar_rastro_pagamento() {}, string: String,
    is_struct: v => v !== null && typeof v === 'object', variable_struct_exists: (v, k) => k in v,
  });
  loadGml(local, 'scripts/scr_cartas/scr_cartas.gml', [
    'criar_dados_mago_da_sombra', 'criar_dados_magica_bola_fogo', 'pagar_custo', 'ajustar_custo_por_terreno',
    'selecionar_recursos_para_custo', 'nome_recurso_exibicao', 'recalcular_itens_tropa', 'bonus_sinergia_item',
    'criar_dados_item_espada', 'criar_dados_item_equipado', 'criar_dados_lobo', 'criar_dados_lobo_evoluido',
  ]);
  return local;
}

const read = name => fs.readFileSync(path.join(__dirname, '../src', name), 'utf8');
const catalog = read('game/cards.ts').replace(/^export /gm, '');
const room = read('rooms/UnoRoom.ts').replace(/^import [\s\S]*?from "[^"]+";/gm, '').replace('export class', 'class');
const { RoomType, CARD_ORDER, CARD_DEFINITIONS } = vm.runInNewContext(
  stripTypeScriptTypes(catalog + '\n' + room) + '\n({ RoomType: KarthaRoom, CARD_ORDER, CARD_DEFINITIONS })',
  { Room: class {}, PublicCardSchema: class {}, Buffer },
);

test('GameMaker receives complete UTF-8 JSON for private messages and broadcasts', () => {
  const r = new RoomType();
  const messages = [];
  const send = (type, data) => messages.push({ type, data });
  const small = { text: 'x'.repeat(4084) };
  assert.equal(Buffer.byteLength(JSON.stringify(small)), 4095);
  r.sendJson({ send }, 'public_state', small);
  assert.deepEqual(messages.splice(0), [{ type: 'public_state', data: JSON.stringify(small) }]);

  // The first boundary falls inside a four-byte character.
  const large = { text: 'x'.repeat(4085) + '🎲', cards: Array(900).fill('Bênção') };
  r.broadcast = send;
  for (const [type, deliver] of [
    ['private_state', () => r.sendJson({ send }, 'private_state', large)],
    ['action_confirmed', () => r.broadcastJson('action_confirmed', large)],
  ]) {
    deliver();
    assert.ok(messages.length >= 3);
    for (const [index, frame] of messages.entries()) {
      assert.equal(frame.type, 'json_part');
      assert.equal(frame.data.type, type);
      assert.equal(frame.data.index, index);
      assert.equal(frame.data.last, index === messages.length - 1);
      assert.ok(Buffer.byteLength(frame.data.text) <= 4095);
    }
    assert.deepEqual(JSON.parse(messages.splice(0).map(m => m.data.text).join('')), large);
  }
});

test('both opening hands keep two of every starting card across deals', () => {
  const r = new RoomType();
  r.nextCardId = 1;
  for (let deal = 0; deal < 50; deal++) {
    for (const seat of [0, 1]) {
      const deck = r.buildStartingDeck(seat);
      assert.equal(deck.length, CARD_ORDER.length * 2);
      assert.equal(new Set(deck.map(card => card.instanceId)).size, deck.length);
      const counts = new Map();
      for (const card of deck) counts.set(card.definitionId, (counts.get(card.definitionId) ?? 0) + 1);
      assert.equal(counts.get('nulo'), 2);
      for (const id of CARD_ORDER) assert.equal(counts.get(id), 2);
      const opening = deck.slice(0, 7).map(card => CARD_DEFINITIONS[card.definitionId].category);
      assert.ok(opening.includes('tropa'));
      assert.ok(opening.filter(category => category === 'recurso').length >= 2);
    }
  }
});

function match() {
  const r = new RoomType();
  const players = new Map(['a', 'b'].map((sessionId, seatIndex) =>
    [sessionId, { sessionId, seatIndex, life: 20, connected: true }]));
  r.state = { players, cards: new Map(), phase: 'playing', revision: 4, winner: -1 };
  r.privatePlayers = [0, 1].map(() => ({ hand: [], effects: [], effectCards: [] }));
  r.clients = [...players.values()].map(({ sessionId }) => ({ sessionId }));
  r.sendPublicState = () => {};
  return r;
}

test('a drop reserves a seat and reconnect restores the outstanding choice to its owner', () => {
  const r = match();
  const client = r.clients[1], received = [];
  r.allowReconnection = (c, seconds) => { assert.equal(c, client); assert.equal(seconds, 20); };
  r.sendJson = (c, type, payload) => { assert.equal(c, client); received.push([type, payload]); };
  r.sendPrivateState = seat => assert.equal(seat, 1);
  r.onDrop(client);
  assert.equal(r.state.players.get('b').connected, false);
  assert.equal(r.state.phase, 'playing');
  r.pendingCritical = { seat: 1, cardId: 'troop', targetId: 'enemy', dice: 2, die: 6 };
  r.onReconnect(client);
  assert.equal(r.state.players.get('b').connected, true);
  assert.deepEqual(received.map(([type]) => type), ['seat', 'critical_choice']);
  assert.equal(received[1][1].cardId, 'troop');
});

test('a definitive departure ends a live match and cannot overwrite a finished result', () => {
  const r = match();
  let notified = 0;
  r.sendPublicState = () => notified++;
  r.onLeave(r.clients[1]);
  assert.equal(r.state.winner, 0);
  assert.equal(r.state.phase, 'finished');
  assert.equal(r.state.lastAction, 'disconnect');
  assert.equal(r.state.players.get('a').life, 20);
  const revision = r.state.revision;
  r.onLeave(r.clients[0]);
  assert.equal(r.state.winner, 0);
  assert.equal(r.state.revision, revision);
  assert.equal(notified, 2);
});

test('a side can hold two blessings and two curses independently', () => {
  const r = match();
  r.payCost = () => true;
  r.discardPlayedCard = () => {};
  const play = (seat, definitionId) => {
    const instanceId = String(r.privatePlayers[seat].hand.length);
    r.privatePlayers[seat].hand.push({ instanceId, definitionId });
    return r.playEffect(seat, { cardId: instanceId });
  };
  for (const id of ['bencao_vida', 'bencao_decomposicao']) assert.equal(play(0, id).ok, true);
  for (const id of ['maldicao_perda', 'sangue_por_sangue']) assert.equal(play(1, id).ok, true);
  assert.equal(play(0, 'bencao_vida').reason, 'limite_efeitos_ativos');
  assert.equal(play(1, 'sangue_por_sangue').reason, 'limite_efeitos_ativos');
  assert.equal(r.privatePlayers[0].effectCards.length, 4);
});

test('Shadow Mage then Fireball use one mana each on Profane Plains for either seat', () => {
  for (const seat of [0, 1]) {
    const r = match();
    const player = r.playerBySeat(seat);
    Object.assign(player, { hasTakenTurn: true, troopsPlayed: 0, spellsUsed: 0 });
    const data = r.privatePlayers[seat];
    Object.assign(data, {
      hand: [{ instanceId: 'mage', definitionId: 'mago_sombra' }, { instanceId: 'fire', definitionId: 'bola_fogo' }],
      deck: [], discard: [],
      resources: ['m1', 'm2'].map(instanceId => ({ instanceId, type: 'mana', amount: 1, used: false })),
    });
    const local = localRules();
    const side = seat === 0 ? 'jogador' : 'inimigo';
    for (const resource of data.resources) {
      const instance = { tipo: resource.type, quantidade: resource.amount, dono: side, bloqueado_turnos: 0, virado: false };
      instance.id = instance;
      local.groups.resources.push(instance);
    }
    const comparePayment = (card, onlineAccepted) => {
      local.obj_controlador.terreno_ativo = r.state.terrainDefinitionId;
      assert.equal(local.pagar_custo(card.custo, side, card.categoria), onlineAccepted);
      assert.equal(local.groups.resources.filter(item => !item.virado).length, player.mana - player.manaUsed);
    };
    r.state.terrainDefinitionId = 'planicies_profanas';
    assert.equal(r.playTroop(seat, { cardId: 'mage', lane: 1 }).ok, true);
    assert.equal(player.mana - player.manaUsed, 1);
    comparePayment(local.criar_dados_mago_da_sombra(), true);
    // Replacing the terrain restores the spell's printed cost without spending the remaining mana.
    r.state.terrainDefinitionId = 'cemiterio';
    const cast = () => r.playSpell(seat, { cardId: 'fire', targetType: 'castle' });
    assert.equal(cast().reason, 'recursos_insuficientes');
    comparePayment(local.criar_dados_magica_bola_fogo(), false);
    assert.equal(player.mana - player.manaUsed, 1);
    r.state.terrainDefinitionId = 'planicies_profanas';
    assert.equal(cast().ok, true);
    comparePayment(local.criar_dados_magica_bola_fogo(), true);
    assert.equal(player.mana - player.manaUsed, 0);
    assert.equal(data.hand.length, 0);
    assert.ok(r.playerBySeat(1 - seat).life < 20);
  }
});

test('Rusty Sword changes the damage of a successful physical hit equally in both modes', () => {
  const local = localRules();
  const wolf = local.criar_dados_lobo();
  Object.assign(wolf, { dado_dano_base: wolf.dado_dano, mod_dano_base: wolf.mod_dano,
    defesa_fisica_base: wolf.defesa_fisica, mochila_maxima: wolf.mochila, itens_equipados: [], qtd_dados_dano: 1 });
  const sword = local.criar_dados_item_espada();
  loadGml(local, 'scripts/scr_combate/scr_combate.gml', ['rolar_dano_direto_visual']);
  Object.assign(local, {
    tem_condicao: () => false, direcao_avanco: () => -1,
    method: (fields, fn) => value => { Object.assign(local, fields); return fn(value); },
    rolar_varios_dados_visuais: (_x, _y, _tx, _ty, count, die, callback) => {
      assert.equal(die, 8);
      callback(count * 4);
    },
  });
  const r = match();
  r.playerBySeat(0).hasTakenTurn = true;
  r.rollForSeat = () => 4;
  const attacker = { instanceId: 'wolf', definitionId: 'lobo', name: wolf.nome, category: 'tropa', owner: 0, lane: 1, position: 1 };
  r.state.cards.set(attacker.instanceId, attacker);
  for (const equipped of [false, true]) {
    if (equipped) wolf.itens_equipados.push(local.criar_dados_item_equipado(sword.nome, null, null, sword.bonus_mod_dano, sword.bonus_defesa, 0, 0));
    local.recalcular_itens_tropa(wolf);
    let damage;
    local.rolar_dano_direto_visual(wolf, 'fisica', value => { damage = value; });
    r.setEquipment(attacker, equipped ? ['espada_enferrujada'] : []);
    attacker.attacked = false;
    const result = r.attack(0, { cardId: 'wolf', attackType: 'fisica' });
    assert.equal(result.ok, true);
    assert.equal(damage, equipped ? 7 : 5);
    assert.equal(result.details.damage, damage);
  }
});

test('Null Resource and printed wildcard costs select the same cards locally and online', () => {
  const scenarios = [
    ['slimet', ['ossos'], true, [0]],
    ['slime', ['mana', 'ossos', 'sucata'], true, [0, 1, 2]],
    ['slime', ['nulo', 'sangue'], false, []],
    ['mago_sombra', ['nulo', 'mana', 'mana'], true, [1, 2]],
    ['mago_sombra', ['nulo', 'mana'], true, [0, 1]],
    ['olho_demonio', ['nulo'], false, []],
    ['olho_demonio', ['nulo', 'sangue'], true, [0, 1]],
  ];
  for (const [card, types, payable, used] of scenarios) {
    const local = localRules();
    Object.assign(local, { spr_carta_slime: 1, spr_carta_slimet: 2, spr_carta_olho_demonio: 3, criar_dados_slime_digestao() {} });
    loadGml(local, 'scripts/scr_cartas/scr_cartas.gml', ['criar_dados_slime', 'criar_dados_slimet', 'criar_dados_olho_demonio']);
    const definition = { slime: local.criar_dados_slime, slimet: local.criar_dados_slimet, olho_demonio: local.criar_dados_olho_demonio,
      mago_sombra: local.criar_dados_mago_da_sombra }[card]();
    local.obj_controlador.terreno_ativo = '';
    const r = match();
    const resources = r.privatePlayers[0].resources = types.map((type, i) => ({ type, instanceId: String(i), amount: 1, used: false }));
    for (const type of types) {
      const res = { tipo: type, quantidade: 1, dono: 'jogador', bloqueado_turnos: 0, virado: false };
      res.id = res;
      local.groups.resources.push(res);
    }
    assert.equal(local.pagar_custo(definition.custo, 'jogador', definition.categoria), payable, card);
    assert.equal(r.payCost(r.playerBySeat(0), CARD_DEFINITIONS[card]), payable, card);
    assert.deepEqual(resources.flatMap((res, i) => res.used ? [i] : []), used);
    assert.deepEqual(local.groups.resources.flatMap((res, i) => res.virado ? [i] : []), used);
  }
});

test('a Null Resource keeps its identity on placement, activation and return to hand', () => {
  const r = match(), player = r.playerBySeat(0), data = r.privatePlayers[0];
  const card = { instanceId: 'wild', definitionId: 'nulo' };
  Object.assign(data, { hand: [card], resources: [], deck: [], discard: [] });
  assert.equal(r.placeResource(0, { cardId: 'wild' }).ok, true);
  assert.equal(player.nulo, 1);
  assert.equal(data.resources[0].type, 'nulo');
  for (const type of ['mana', 'sangue', 'ossos', 'sucata']) {
    r.resetPlayerTurn(player);
    player.blockedResource = 'nulo';
    player.blockedTurns = 1;
    assert.equal(r.spendResourceUnits(0, type, 1), false);
    player.blockedTurns = 0;
    assert.equal(r.spendResourceUnits(0, type, 1), true);
    assert.equal(player.nuloUsed, 1);
    assert.equal(r.spendResourceUnits(0, type, 1), false);
  }
  assert.equal(r.removeResource(0, { resourceId: 'wild' }).ok, true);
  assert.equal(player.nulo, 0);
  assert.equal(data.hand[0].definitionId, 'nulo');
});

test('public choice notices identify only the chooser and the kind of decision', () => {
  const r = match();
  assert.equal(r.publicChoice(), null);
  r.pendingMitosis[0] = { candidates: [[0, 1]] };
  r.pendingMagnet[1].push({ equipment: ['elmo_ferro'] });
  assert.equal(JSON.stringify(r.publicChoice()), '{"seat":0,"kind":"mitosis"}');
  r.pendingMagnet[0].push({ equipment: ['elmo_ferro'] });
  assert.equal(JSON.stringify(r.publicChoice()), '{"seat":0,"kind":"magnet"}');
  r.pendingMagnet[0] = [];
  r.pendingMitosis[0] = undefined;
  assert.equal(r.publicChoice().kind, 'magnet');
  r.pendingCritical = { seat: 0, dice: 2 };
  assert.equal(r.publicChoice().kind, 'critical');
  r.pendingManipulated = { waiting: { seat: 1, natural: 1, fixed: 3 } };
  assert.equal(JSON.stringify(r.publicChoice()), '{"seat":1,"kind":"dice"}');
  r.pendingManipulated = undefined;
  r.pendingCritical = undefined;
  r.pendingMagnet[1] = [];
  r.veilChoice = { seat: 0, cardId: 'private' };
  assert.equal(JSON.stringify(r.publicChoice()), '{"seat":0,"kind":"veil"}');
  r.state.phase = 'finished';
  assert.equal(r.publicChoice(), null);
});
