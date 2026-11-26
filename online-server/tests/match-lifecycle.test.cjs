const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { stripTypeScriptTypes } = require('node:module');
const { test } = require('node:test');
const read = name => fs.readFileSync(path.join(__dirname, '../src', name), 'utf8');
const catalog = read('game/cards.ts').replace(/^export /gm, '');
const room = read('rooms/UnoRoom.ts').replace(/^import [\s\S]*?from "[^"]+";/gm, '').replace('export class', 'class');
const { RoomType, validateDeck, defaultDeck } = vm.runInNewContext(
  stripTypeScriptTypes(catalog + '\n' + room) + '\n({ RoomType: KarthaRoom, validateDeck, defaultDeck })',
  { Room: class {} },
);

test('starting decks accept the editor catalog and reserve evolved forms for evolution', () => {
  assert.equal(validateDeck(defaultDeck()).length, 50);
  assert.equal(validateDeck(Array(50).fill('esquilo_gigante')), undefined);
  assert.equal(validateDeck(Array(50).fill('esquilo')).length, 50);
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
