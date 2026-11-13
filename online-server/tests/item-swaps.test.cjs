// Exercises the room's actual methods without starting a network server.
const { readFileSync } = require('node:fs');
const { stripTypeScriptTypes } = require('node:module');
const { runInNewContext } = require('node:vm');
const assert = require('node:assert/strict');
const source = readFileSync(require('node:path').join(__dirname, '../src/rooms/UnoRoom.ts'), 'utf8');
const methods = ['removeItem', 'transferItem', 'resetPlayerTurn', 'conditions', 'hasCondition'].map(name => {
  const start = source.indexOf(`  private ${name}(`);
  assert.ok(start >= 0);
  const end = source.indexOf('\n  private ', start + 1);
  return source.slice(start, end);
}).join('\n');
const Room = runInNewContext(stripTypeScriptTypes(`(class { ${methods} })`), {
  CARD_DEFINITIONS: { troop: { itemSlots: 2 } },
});
function setup() {
  const room = new Room();
  room.privatePlayers = [{ hand: [] }, { hand: [] }];
  room.state = { cards: new Map() };
  room.abilityState = card => card.ability;
  room.setAbilityState = (card, state) => { card.ability = state; };
  room.equipmentIds = card => [...card.equipment];
  room.setEquipment = (card, equipment) => { card.equipment = equipment; };
  room.makePrivateCard = (seat, definitionId) => ({ seat, definitionId });
  room.updateCounts = () => {};
  for (const [id, owner] of [['a', 0], ['b', 0], ['c', 0], ['d', 1]]) {
    room.state.cards.set(id, { owner, category: 'tropa', definitionId: 'troop',
      condition: '', ability: {}, equipment: ['sword'] });
  }
  return room;
}
let room = setup();
assert.equal(room.removeItem(0, { cardId: 'a' }).ok, true);
assert.equal(room.removeItem(0, { cardId: 'b' }).reason, 'limite_trocas_turno');
assert.equal(room.transferItem(0, { cardId: 'b', targetId: 'c' }).reason, 'limite_trocas_turno');
assert.equal(room.removeItem(1, { cardId: 'd' }).ok, true);
assert.equal(room.privatePlayers[1].hand[0].definitionId, 'sword');
room.resetPlayerTurn({ seatIndex: 0 });
assert.equal(room.privatePlayers[1].itemSwapUsed, true);
assert.equal(room.removeItem(0, { cardId: 'b' }).ok, true);
room = setup();
assert.equal(room.transferItem(0, { cardId: 'a', targetId: 'b' }).ok, true);
assert.equal(room.state.cards.get('a').ability.itemActionUsed, true);
assert.equal(room.state.cards.get('b').ability.itemActionUsed, true);
assert.equal(room.removeItem(0, { cardId: 'c' }).reason, 'limite_trocas_turno');
room = setup();
assert.equal(room.transferItem(0, { cardId: 'a', targetId: 'd' }).ok, false);
assert.equal(room.privatePlayers[0].itemSwapUsed, undefined);
assert.equal(room.removeItem(0, { cardId: 'a' }).ok, true);
console.log('OK: swap limit, mixed actions, ownership, failed actions and turn reset');
