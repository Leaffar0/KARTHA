const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../..');
const ui=fs.readFileSync(path.join(root,'scripts/scr_ui/scr_ui.gml'),'utf8');
const step=fs.readFileSync(path.join(root,'objects/obj_menu/Step_0.gml'),'utf8').replace(/^#.*$/gm,'').replace(/ mod /g,' % ').replace(/exit;/g,'return;');
let click=false,escape=false;
const c={os_type:0,os_linux:1,transicao_sala_ativa:()=>false,room_width:1152,room_height:648,delta_time:16667,tempo_menu:3,menu_hover:[0,0,0,0],menu_hover_anterior:-1,
 opcoes_abertas:false,modo_jogo_aberto:false,online_aberto:false,deck_aberto:false,painel_menu_abertura:1,painel_menu_anterior:'',
 online_copiado_timer:0,deck_por_pagina:8,deck_pagina:0,deck_catalogo_menu:[()=>({nome:'Slime'})],global:{},
 min:Math.min,max:Math.max,abs:Math.abs,ceil:Math.ceil,sin:Math.sin,power:Math.pow,lerp:(a,b,t)=>a+(b-a)*t,clamp:(x,a,b)=>Math.max(a,Math.min(b,x)),dcos:a=>Math.cos(a*Math.PI/180),dsin:a=>Math.sin(a*Math.PI/180),
 noone:null,deck_ficha:null,deck_linha:0,deck_textos:[],deck_texto_pagina:0,
 floor:Math.floor,is_struct:v=>v!==null && typeof v==="object",
 menu_foco:0,modo_foco:0,menu_por_teclado:false,menu_mouse_x:0,menu_mouse_y:0,
 vk_enter:13,vk_left:37,vk_up:38,vk_right:39,vk_down:40,mb_left:1,vk_escape:27,mouse_x:0,mouse_y:0,
 mouse_check_button_pressed:()=>click,keyboard_check_pressed:k=>escape&&k===27,
 point_in_rectangle:(x,y,a,b,d,e)=>x>=a&&x<=d&&y>=b&&y<=e,
 colyseus_is_ready:()=>false,tocar_som_variado(){},array_length:a=>a.length,array_create:(n,v)=>Array(n).fill(v),
 array_copy:(dst,di,src,si,n)=>{for(let i=0;i<n;i++)dst[di+i]=src[si+i];}
};c.id=c;vm.createContext(c);
for(const n of ['carta_menu_layout','ponto_carta_menu','tipo_painel_menu','centro_painel_menu','carta_modo_menu']){const a=ui.indexOf('function '+n+'('),b=ui.indexOf('\nfunction ',a+1);vm.runInContext(ui.slice(a,b<0?undefined:b).replace(/ mod /g,' % '),c);}
vm.runInContext('function frame(){'+step+'}',c);
function select(i){const p=c.carta_menu_layout(i,false,c.tempo_menu,c.room_width,c.room_height,c.menu_hover[i]);c.mouse_x=p.x;c.mouse_y=p.y;click=true;c.frame();click=false;}
function settle(){for(let i=0;i<20;i++)c.frame();}
select(2);assert.equal(c.opcoes_abertas,true,'Opening click must not close options');settle();escape=true;c.frame();escape=false;assert.equal(c.opcoes_abertas,false);settle();
select(1);settle();assert.equal(c.deck_aberto,true);escape=true;c.frame();escape=false;assert.equal(c.deck_aberto,false);
function selectMode(i) {
  const card = c.carta_modo_menu(i, c.centro_painel_menu(c));
  c.mouse_x = card.x;
  c.mouse_y = card.y;
  click = true;
  c.frame();
  click = false;
}
for (const width of [640, 1152, 1920]) {
  c.room_width = width;
  const left = c.carta_modo_menu(0, 324);
  const right = c.carta_modo_menu(1, 324);
  assert.equal(left.x + right.x, width);
  assert(left.x - left.w/2 >= 0 && right.x + right.w/2 <= width);
  assert(left.x + left.w/2 < right.x - right.w/2);
}
c.room_width = 1152;
c.rm_jogo = 1;
let started = 0;
c.trocar_sala_suave = room => { assert.equal(room, c.rm_jogo); started++; };
c.online_nome_input = 'Teste';
settle();
select(0);
settle();
selectMode(2);
assert.equal(started, 0);
assert.equal(c.online_aberto, false);
selectMode(0);
assert.equal(c.global.modo_partida, 'ia');
assert.equal(started, 1);
selectMode(1);
assert.equal(c.online_aberto, true);
assert.equal(c.modo_jogo_aberto, false);
assert.equal(started, 1);
console.log('OK: options, deck catalog and both playable mode cards');

// Drive the actual lobby Step so a failed paste cannot leak the previous field into the room ID.
const keys = new Set();
let clipboard = '';
let connectedWith;
Object.assign(c, {
  online_ativo: () => false, online_codigo_input: 'Old_ID', online_servidor_input: 'ws://localhost:2567',
  vk_control: 17, vk_shift: 16, vk_insert: 45, vk_tab: 9, ord: ch => ch.charCodeAt(0),
  keyboard_check: key => keys.has(key), keyboard_check_pressed: key => keys.has(key),
  clipboard_get_text: () => clipboard, string_trim: s => s.trim(), string_length: s => s.length,
  string_pos: (part, s) => s.indexOf(part) + 1,
  string_replace_all: (s, from, to) => s.replaceAll(from, to), string_copy: (s, i, n) => s.slice(i-1, i-1+n),
  online_salvar_endpoint() {}, online_conectar: (...args) => { connectedWith = args; }
});
require('./helpers/load-gml.cjs')(c, 'scripts/scr_online/scr_online.gml', [
  'online_ler_area_transferencia', 'online_colar_codigo_sala',
]);
settle();
function clickLobby(dx, dy) {
  c.mouse_x = c.room_width/2 + dx;
  c.mouse_y = c.centro_painel_menu(c) + dy;
  click = true; c.frame(); click = false;
}
clickLobby(157, -37);
assert.equal(c.online_codigo_input, 'Old_ID');
assert.equal(c.keyboard_string, 'Old_ID');
clipboard = '  Sala-9_aZ\r\n';
clickLobby(157, -37);
assert.equal(c.online_codigo_input, 'Sala-9_aZ');
c.frame();
assert.equal(c.keyboard_string, 'Sala-9_aZ');
keys.add(c.vk_control); keys.add(c.ord('V'));
clipboard = 'A_b-7K';
c.keyboard_string += 'v';
c.frame(); keys.clear();
assert.equal(c.online_codigo_input, 'A_b-7K');
clickLobby(90, 80);
assert.deepEqual(connectedWith, [false, 'A_b-7K', 'Teste', 'ws://localhost:2567']);

c.online_aberto=false;
function press(key) { keys.add(key); c.frame(); keys.clear(); }
c.menu_foco=0;
press(c.vk_right);
assert.equal(c.menu_foco,1);
press(c.vk_enter);
assert.equal(c.deck_aberto,true);
settle(); press(c.vk_escape); settle();
press(c.vk_left); press(c.vk_enter); settle();
assert.equal(c.modo_jogo_aberto,true);
press(c.vk_right); press(c.vk_enter);
assert.equal(c.online_aberto,true);
assert.equal(started,1);

c.online_aberto=false;
c.deck_aberto=true;
c.deck_catalogo_menu=Array.from({length:10},(_,i)=>()=>({nome:'Carta '+i}));
Object.assign(c,{Fontenil:1,draw_get_font:()=>0,draw_set_font(){},
  aplicar_definicao_carta:(card,factory)=>Object.assign(card,factory()),
  descricao_carta_preview:card=>card.nome,paginar_detalhes_carta:s=>[s,'segunda página']});
settle(); press(c.vk_right); press(c.vk_down); press(c.vk_enter);
assert.equal(c.deck_ficha.nome,'Carta 9');
press(c.vk_right); assert.equal(c.deck_texto_pagina,1);
press(c.vk_escape); assert.equal(c.deck_aberto,true); assert.equal(c.deck_ficha,null);
press(c.vk_left);
c.mouse_x=c.room_width/2; c.mouse_y=c.centro_painel_menu(c)-115+3*31;
click=true; c.frame(); click=false;
assert.equal(c.deck_ficha.nome,'Carta 3');
press(c.vk_escape); press(c.vk_escape); assert.equal(c.deck_aberto,false);
