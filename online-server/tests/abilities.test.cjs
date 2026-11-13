const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const { stripTypeScriptTypes } = require('node:module');
const root = path.resolve(__dirname, '../..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const source = read('online-server/src/rooms/UnoRoom.ts');
const definitions = vm.runInNewContext(stripTypeScriptTypes(
  read('online-server/src/game/cards.ts').replace(/^export /gm, '')) + '\nCARD_DEFINITIONS;');
const names = ['useAbility', 'tryBreakIllusion', 'conditions', 'setConditions', 'hasCondition',
  'applyCondition', 'removeCondition', 'processSleep', 'endTurn', 'drawCards', 'performMitosis', 'chooseMitosis', 'checkGazeEncounters', 'attack', 'firstEnemyAhead', 'moveTroop', 'counterAttack', 'effectiveAttackDie'];
const methods = names.map(name => {
  const start = source.indexOf('  private ' + name + '(');
  assert.ok(start >= 0, name);
  return source.slice(start, source.indexOf('\n  private ', start + 1));
}).join('\n');
const Room = vm.runInNewContext(stripTypeScriptTypes('(class {' + methods + '})'),
  { CARD_DEFINITIONS: definitions, numberInRange: (x, min, max) => Number.isInteger(x) && x >= min && x <= max ? x : undefined });
function setup() {
  const room = new Room();
  const players = [0, 1].map(() => ({hasTakenTurn: true, life: 20, mana: 6, manaUsed: 0, sangue: 6, sangueUsed: 0, blockedTurns: 0}));
  Object.assign(room, {
    state: { cards: new Map(), currentPlayer: 0, turnNumber: 1 },
    privatePlayers: [0, 1].map(() => ({hand: [], deck: [], traps: []})),
    pendingMitosis: [], abilityState: card => ({...card.ability}),
    setAbilityState: (card, state) => {card.ability = state;},
    playerBySeat: seat => players[seat],
    findPublic: predicate => [...room.state.cards.values()].find(predicate),
    hasAbility: (card, ability) => definitions[card.definitionId].abilities?.includes(ability),
    rollForSeat: () => 1, spendResourceUnits: () => true,
    equipmentIds: c => c.equipment ?? [], setEquipment: (c, equipment) => {c.equipment=equipment;},
    equipmentAttackBonus: () => 0, equipmentDefenseBonus: () => 0, cemeteryBonus: () => 0,
    terrainDefenseModifier: () => 0, synergyBonus: () => 0, updateTrapReadiness() {}, roll: () => 1,
    resetPlayerTurn() {}, processMadness: () => [], processArtillery: () => [], updateCounts() {},
    destroyPublicCard: card => room.state.cards.delete(card.instanceId),
    clientBySeat: () => undefined, publicCardPayload: card => card,
    createPublicCard: (source, def, owner, lane, position) => ({...source, definitionId:def.id, category:'tropa', owner,lane,position,ability:{}}),
  });
  return room;
}
function card(room, id, definitionId, owner, position) {
  const def = definitions[definitionId];
  const c = {instanceId:id, definitionId, owner, position, lane:0, category:'tropa',
    intelligence:def.intelligence, life:def.life, maxLife:def.life, ability:{}, condition:''};
  room.state.cards.set(id,c);
  return c;
}
// Sombra protects through the enemy turn, then spends a full own turn recharging.
{
  const r=setup(), c=card(r,'m','mago_sombra',0,3);
  assert.equal(r.useAbility(0,{cardId:'m',ability:'sombra_translucida'}).ok,true);
  r.endTurn(0); assert.equal(c.ability.shadowTurns,1);
  r.endTurn(1); assert.equal(c.ability.shadowTurns,0); assert.equal(c.ability.shadowCooldown,1);
  r.endTurn(0); r.endTurn(1); assert.equal(c.ability.shadowCooldown,0);
}
// Ferida uses all three original dice; tails do no damage.
{
  const r=setup(), c=card(r,'c','carnica_ambulante',0,3), target=card(r,'t','urso',1,2);
  let rolls=[1,2,3,4]; r.rollForSeat=()=>rolls.shift();
  const result=r.useAbility(0,{cardId:'c',ability:'ferida_exposta'});
  assert.equal(result.details.damage,9); assert.equal(c.attacked,true);
  assert.equal(r.hasCondition(target,'sangrando'),true);
  assert.equal(r.useAbility(0,{cardId:'c',ability:'ferida_exposta'}).reason,'habilidade_ja_usada');
}
// Imitação remains once per turn even against intelligence zero and causes no initial attack.
{
  const r=setup(), c=card(r,'m','mimic',0,3), target=card(r,'s','slime',1,2);
  let rolls=[20,1]; r.rollForSeat=()=>rolls.shift();
  assert.equal(r.useAbility(0,{cardId:'m',ability:'imitacao'}).details.success,true);
  assert.equal(c.attacked,undefined);
  assert.equal(r.useAbility(0,{cardId:'m',ability:'imitacao'}).reason,'habilidade_ja_usada');
  rolls=[11,10]; assert.equal(r.tryBreakIllusion(target),true);
}
// Mitose allows the second child in the same lane.
{
  const r=setup(), parent=card(r,'parent','slime',0,2);
  r.state.cards.delete('parent');
  const pool=[{instanceId:'one',definitionId:'slimet'},{instanceId:'two',definitionId:'slimet'}];
  r.takeDefinitionFromHandOrDeck=()=>pool.shift();
  r.performMitosis(parent);
  assert.ok(r.pendingMitosis[0].candidates.some(([lane,pos])=>lane===0 && pos===3));
  assert.equal(r.chooseMitosis(0,{lane:0,position:3}).ok,true);
  assert.equal(r.state.cards.size,2);
}
// Olhar Vazio tests the stationary enemy once, including fresh placements.
{
  const r=setup(), enemy=card(r,'e','esquilo',0,4); card(r,'h','hollow_jack',1,3);
  let rolls=0; r.rollForSeat=()=>{rolls++;return 1;};
  r.checkGazeEncounters(); r.checkGazeEncounters();
  assert.equal(rolls,1); assert.equal(r.hasCondition(enemy,'paralisado'),true);
}
// Digestão raises maximum life without healing current life; Visão is once per match.
{
  const r=setup(), c=card(r,'s','slime_digestao',0,3), target=card(r,'t','esquilo',1,2);
  c.life=10;target.life=3;
  assert.equal(r.useAbility(0,{cardId:'s',ability:'digestao',targetId:'t'}).ok,true);
  assert.equal(c.maxLife,23);assert.equal(c.life,10);assert.equal(r.hasCondition(c,'regeneracao'),true);
  const viewer=card(r,'v','gato_mago',0,4);
  assert.equal(r.useAbility(0,{cardId:'v',ability:'visao_do_veu',choice:'protect'}).ok,true);
  viewer.ability.used=false;
  assert.equal(r.useAbility(0,{cardId:'v',ability:'visao_do_veu',choice:'protect'}).reason,'visao_ja_usada');
}
console.log('OK: shadow lifetime, original wound dice, imitation limit, same-lane mitosis, gaze encounters, digestion and veil');

// The long range belongs to the matching original attack, never an equipped weapon.
{
  const r=setup(), eye=card(r,'e','olho_demonio',0,3), target=card(r,'t','urso',1,1);
  r.rollForSeat=(_,die)=>die===20?11:1;
  assert.equal(r.attack(0,{cardId:'e',attackType:'fisica'}).ok,false);
  assert.equal(r.attack(0,{cardId:'e',attackType:'magica'}).ok,true);
  eye.attacked=false;eye.equipment=['espada_quebrada'];
  assert.equal(r.attack(0,{cardId:'e',itemDefinitionId:'espada_quebrada'}).ok,false);
}
// Flying can pass over a ground ally, but may not enter the enemy base.
{
  const r=setup(), eye=card(r,'e','olho_demonio',0,4);
  eye.turnsInPlay=1;card(r,'a','esquilo',0,3);
  assert.equal(r.moveTroop(0,{cardId:'e'}).ok,true);assert.equal(eye.position,2);
  eye.moved=false;eye.position=1;
  assert.equal(r.moveTroop(0,{cardId:'e'}).ok,false);
}
// Roubo on a natural ten transfers the attacking weapon once, subject to capacity.
{
  const r=setup(), a=card(r,'a','esquilo',0,3), thief=card(r,'s','slime_digestao',1,2);
  a.equipment=['espada_quebrada'];
  r.rollForSeat=(_,die)=>die===10?10:die===20?11:1;
  assert.equal(r.attack(0,{cardId:'a',itemDefinitionId:'espada_quebrada'}).details.stolenItem,'espada_quebrada');
  assert.equal(a.equipment.length,0);assert.equal(thief.equipment[0],'espada_quebrada');
}
// Tiro Burro redirects a critical to a randomly selected troop, including its owner.
{
  const r=setup(), a=card(r,'a','shroomilin',0,3);card(r,'t','urso',1,2);
  r.rollForSeat=()=>20;r.roll=()=>1;
  const result=r.attack(0,{cardId:'a'});
  assert.equal(result.details.criticalChoice,true);assert.equal(result.details.targetId,'a');
}
// Carniça spends two blood and consumes its prepared bonus on the next attack.
{
  const r=setup(), a=card(r,'a','carnica_ambulante',0,3);card(r,'t','urso',1,2);
  let paid=0;r.spendResourceUnits=(_,type,n)=>{assert.equal(type,'sangue');paid+=n;return true;};
  r.rollForSeat=(_,die)=>die===20?11:1;
  assert.equal(r.useAbility(0,{cardId:'a',ability:'carnica_frenetica'}).ok,true);assert.equal(paid,2);
  const result=r.attack(0,{cardId:'a'});
  assert.equal(result.details.defense,0);assert.equal(result.details.frenzyBonus,1);assert.equal(a.ability.frenzy,undefined);
}
// Golpe Duplo dispatches two original attacks and consumes the attack action.
{
  const r=setup(), a=card(r,'a','goblin',0,3);card(r,'t','urso',1,2);
  a.equipment=['espada_quebrada','espada_quebrada'];
  let attacks=0;r.attack=(_,payload)=>{attacks++;assert.equal(payload.itemDefinitionId,undefined);return {ok:true,details:{damage:1}};};
  assert.equal(r.useAbility(0,{cardId:'a',ability:'golpe_duplo'}).ok,true);
  assert.equal(attacks,2);assert.equal(a.attacked,true);assert.equal(a.ability.used,true);
}
console.log('OK: typed range, flight, theft, random critical target, frenzy payment and double attack');

const combat = read('scripts/scr_combate/scr_combate.gml');
let chosen = '';
const context = { noone:null, instance_exists:Boolean, array_length:a=>a.length,
  array_get_index:(a,v)=>a.indexOf(v), array_push:(a,v)=>a.push(v), tropa_pode_usar_habilidade:()=>true,
  habilidade_carnica_frenetica:()=>{chosen='carnica_frenetica';},
  habilidade_ferida_exposta:()=>{chosen='ferida_exposta';}
};
vm.createContext(context);
for (const name of ['habilidades_ativas','tem_habilidade_ativa','usar_habilidade']) {
  const start = combat.indexOf('function ' + name + '(');
  const end = combat.indexOf('\nfunction ', start + 1);
  vm.runInContext(combat.slice(start,end).replace(/^#.*$/gm,''),context);
}
const both = {habilidades:['carnica_frenetica','ferida_exposta'],travada:true,morrendo:false,habilidade_usada_este_turno:false};
assert.equal(context.habilidades_ativas(both).length,2);
context.usar_habilidade(both,'ferida_exposta');assert.equal(chosen,'ferida_exposta');
both.habilidade_usada_este_turno=true;chosen='';
context.usar_habilidade(both,'carnica_frenetica');assert.equal(chosen,'');
console.log('OK: local multi-ability selection and repeated-use guard');

// Digestion accepts either owner in each orthogonal direction, never diagonals or dead troops.
for (const owner of [0,1]) for (const [lane,position] of [[0,3],[2,3],[1,2],[1,4]]) {
  const r=setup(), c=card(r,'s','slime_digestao',0,3), t=card(r,'t','esquilo',owner,position);
  c.lane=1;t.lane=lane;t.life=3;
  let enemyKill;
  r.destroyPublicCard=(target,byEnemy)=>{enemyKill=byEnemy;r.state.cards.delete(target.instanceId);};
  assert.equal(r.useAbility(0,{cardId:'s',ability:'digestao',targetId:'t'}).ok,true);
  assert.equal(enemyKill,owner!==c.owner);assert.equal(r.state.cards.has('t'),false);
}
for (const changes of [{life:4},{life:0},{category:'construcao'},{lane:1},{position:1}]) {
  const r=setup(), c=card(r,'s','slime_digestao',0,3), t=card(r,'t','esquilo',0,2);
  t.life=3;Object.assign(t,changes);
  const before=c.maxLife;
  assert.equal(r.useAbility(0,{cardId:'s',ability:'digestao',targetId:'t'}).reason,'digestao_alvo_invalido');
  assert.equal(c.maxLife,before);assert.equal(c.ability.used,undefined);assert.equal(r.state.cards.has('t'),true);
}
context.abs=Math.abs;
{
  const start=combat.indexOf('function alvo_valido_digestao(');
  vm.runInContext(combat.slice(start,combat.indexOf('\nfunction ',start+1)),context);
  const origin={dono:0,lane_atual:1,posicao_atual:3};
  const target={dono:0,lane_atual:1,posicao_atual:2,vida:3,categoria:'tropa',travada:true,morrendo:false};
  for(const dono of [0,1]) for(const [lane_atual,posicao_atual] of [[0,3],[2,3],[1,2],[1,4]])
    assert.equal(context.alvo_valido_digestao(origin,{...target,dono,lane_atual,posicao_atual}),true);
  for(const changes of [{vida:4},{vida:0},{categoria:'construcao'},{morrendo:true},{travada:false},{lane_atual:0},{posicao_atual:1},{posicao_atual:3}])
    assert.equal(context.alvo_valido_digestao(origin,{...target,...changes}),false);
}
console.log('OK: allied and enemy digestion, orthogonal adjacency, invalid targets and allied death attribution');
