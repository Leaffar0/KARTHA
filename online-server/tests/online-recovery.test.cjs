const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const load = require('./helpers/load-gml.cjs');

const file = 'scripts/scr_online/scr_online.gml';
const source = fs.readFileSync(path.resolve(__dirname, '../..', file), 'utf8');
const start = source.indexOf('    colyseus_on_message(_sala');
const end = source.indexOf('    colyseus_on_state_change', start);
const requests = [];
const state = { net_room: 4, online_assento: 1, online_sync_proxima: 0, online_sync_pendente: false };
const c = vm.createContext({
  global: state, current_time: 10, _sala: 4, obj_controlador: {}, noone: null,
  online_ativo: () => true, array_length: a => a.length, array_push: (a, x) => a.push(x),
  is_struct: v => v != null && typeof v === 'object' && !Array.isArray(v), is_array: Array.isArray,
  is_real: Number.isFinite, is_string: v => typeof v === 'string', is_bool: v => typeof v === 'boolean',
  variable_struct_exists: (v, key) => key in v, instance_exists: () => false, json_parse: JSON.parse,
  show_debug_message() {}, string: String, string_concat_ext: a => a.join(''), online_atualizar_nomes() {},
  colyseus_on_message: (_room, fn) => { c.receive = fn; },
  colyseus_send: (room, type) => { assert.equal(room, 4); requests.push(type); },
});
load(c, file, ['online_marcar_ressincronizacao', 'online_verificar_sincronizacao']);
vm.runInContext(source.slice(start, end).replace(/\[\$ /g, '['), c);
const packet = (kind, data) => c.receive(4, kind, data);
const hand = { hand: [{ instanceId: 'keep' }], deckCount: 95, revision: 4 };
const board = { players: [], cards: [], phase: 'playing', currentPlayer: 0, turnNumber: 3, revision: 4 };
packet('private_state', hand);
packet('public_state', board);
packet('private_state', '{"hand":');
packet('private_state', {});
assert.deepEqual(state.online_mao_privada, hand.hand);
c.online_verificar_sincronizacao();
c.online_verificar_sincronizacao();
assert.deepEqual(requests, ['request_private_state']);
packet('public_state', { ...board, revision: 5 });
assert.equal(state.online_estado_publico, board);
packet('private_state', hand);
packet('public_state', { ...board, revision: 5 });
assert.equal(state.online_sync_pendente, true);
packet('public_state', board);
assert.equal(state.online_sync_pendente, false);

packet('json_part', { type: 'public_state', index: 0, last: false, text: '{' });
c.current_time += 3001;
c.online_verificar_sincronizacao();
assert.equal(state.online_sync_pendente, true);
assert.equal(requests.length, 2);
c.current_time += 3001;
c.online_verificar_sincronizacao();
assert.equal(requests.length, 3);
packet('private_state', hand);
const text = JSON.stringify(board);
packet('json_part', { type: 'public_state', index: 0, last: false, text: text.slice(0, 4) });
packet('json_part', { type: 'public_state', index: 1, last: true, text: text.slice(4) });
assert.equal(state.online_sync_pendente, false);
