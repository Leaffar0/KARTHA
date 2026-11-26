const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { stripTypeScriptTypes } = require('node:module');
const { test } = require('node:test');
const read = name => fs.readFileSync(path.join(__dirname, '../src', name), 'utf8');
const catalog = read('game/cards.ts').replace(/^export /gm, '');
const room = read('rooms/UnoRoom.ts').replace(/^import [\s\S]*?from "[^"]+";/gm, '').replace('export class', 'class');
const { RoomType, CARD_ORDER, CARD_DEFINITIONS } = vm.runInNewContext(
  stripTypeScriptTypes(catalog + '\n' + room) + '\n({ RoomType: KarthaRoom, CARD_ORDER, CARD_DEFINITIONS })',
  { Room: class {}, PublicCardSchema: class {} },
);

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
    r.state.terrainDefinitionId = 'planicies_profanas';
    assert.equal(r.playTroop(seat, { cardId: 'mage', lane: 1 }).ok, true);
    assert.equal(player.mana - player.manaUsed, 1);
    // Replacing the terrain restores the spell's printed cost without spending the remaining mana.
    r.state.terrainDefinitionId = 'cemiterio';
    const cast = () => r.playSpell(seat, { cardId: 'fire', targetType: 'castle' });
    assert.equal(cast().reason, 'recursos_insuficientes');
    assert.equal(player.mana - player.manaUsed, 1);
    r.state.terrainDefinitionId = 'planicies_profanas';
    assert.equal(cast().ok, true);
    assert.equal(player.mana - player.manaUsed, 0);
    assert.equal(data.hand.length, 0);
    assert.ok(r.playerBySeat(1 - seat).life < 20);
  }
});
