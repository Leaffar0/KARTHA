const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const {stripTypeScriptTypes}=require('node:module');
const root=path.resolve(__dirname,'../..'),read=p=>fs.readFileSync(path.join(root,p),'utf8');
const src=read('online-server/src/rooms/UnoRoom.ts');
const methods=['startMatch','startInitiativeWhenReady','finishInitiativeIfReady','buildStartingDeck','makePrivateCard','updateCounts','drawCards'].map(name=>{const i=src.indexOf('  private '+name+'(');return src.slice(i,src.indexOf('\n  private ',i+1));}).join('\n');
const cards=read('online-server/src/game/cards.ts').replace(/^export /gm, '');
const {Room, deckSize, openingSize}=vm.runInNewContext(stripTypeScriptTypes(cards+'\n({Room: class {'+methods+'}, deckSize: STARTING_DECK_SIZE, openingSize: OPENING_HAND_SIZE})'));
const r=new Room(),players=[0,1].map(seatIndex=>({seatIndex,ready:true,initiative:0})),messages=[];
Object.assign(r,{state:{phase:'waiting',players:new Map(players.map(p=>[String(p.seatIndex),p])),cards:new Map()},clients:[{},{}],privatePlayers:[0,1].map(()=>({})),rematchVotes:new Set(),pendingMagnet:[],pendingMitosis:[],shuffle:a=>a,playerBySeat:s=>players[s],resetPlayerTurn(){},bump(){},sendPrivateState(){},sendPublicState(){},broadcastJson:(t,p)=>messages.push(t),findPlayer:id=>players[Number(id)]});
const handlers={};

r.onMessage=(name,fn)=>handlers[name]=fn;
for(const name of ['draw_initial','choose_first']){const i=src.indexOf('    this.onMessage("'+name+'"');const j=src.indexOf('\n    });',i)+8;vm.runInNewContext(stripTypeScriptTypes('(function(){'+src.slice(i,j)+'})'), { OPENING_HAND_SIZE: openingSize }).call(r);}
r.lock=()=>{r.locked=true;};
r.startInitiativeWhenReady();assert.equal(r.locked,true);assert.equal(r.state.phase,'drawing');assert.equal(messages.at(-1),'match_started');
handlers.choose_first({sessionId:'0'},{seat:1});assert.equal(r.state.phase,'drawing');
handlers.draw_initial({sessionId:'0'});assert.equal(r.state.phase,'drawing');assert.equal(r.privatePlayers[0].hand.length,7);
handlers.draw_initial({sessionId:'0'});assert.equal(r.privatePlayers[0].hand.length,7);
handlers.draw_initial({sessionId:'1'});assert.equal(r.state.phase,'initiative');assert.equal(messages.at(-1),'initiative_started');
players.forEach(p=>p.initiative=10);r.finishInitiativeIfReady();assert.equal(r.state.phase,'initiative');assert.equal(players[0].initiative,0);
players[0].initiative=18;players[1].initiative=4;r.finishInitiativeIfReady();assert.equal(r.state.phase,'choose_first');
handlers.choose_first({sessionId:'1'},{seat:1});assert.equal(r.state.phase,'choose_first');
const hands=r.privatePlayers.map(p=>p.hand);
handlers.choose_first({sessionId:'0'},{seat:1});assert.equal(r.state.phase,'playing');assert.equal(r.state.currentPlayer,1);assert.equal(messages.at(-1),'match_ready');
for(let seat=0;seat<2;seat++){assert.equal(r.privatePlayers[seat].hand,hands[seat]);assert.equal(hands[seat].length,7);assert.equal(r.privatePlayers[seat].deck.length,deckSize-openingSize);}
assert.match(read('objects/obj_controlador/Create_0.gml'),/disputa_inicial_estado = "aguardando_deck"/);
const flow=read('scripts/scr_fluxo_partida/scr_fluxo_partida.gml');
const deal=flow.slice(flow.indexOf('} else if (disputa_inicial_estado == "distribuindo")'),flow.indexOf('    return true;', flow.indexOf('} else if (disputa_inicial_estado == "distribuindo")')));
assert.match(deal,/disputa_inicial_estado = "preparando_dado"/);assert.doesNotMatch(deal,/finalizar_disputa_inicial/);
console.log('Startup order: hands before initiative, duplicate draws, ties, winner choice and hand preservation passed.');
