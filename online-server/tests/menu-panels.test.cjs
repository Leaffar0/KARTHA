const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../..');
const ui=fs.readFileSync(path.join(root,'scripts/scr_ui/scr_ui.gml'),'utf8');
const step=fs.readFileSync(path.join(root,'objects/obj_menu/Step_0.gml'),'utf8').replace(/^#.*$/gm,'').replace(/ mod /g,' % ').replace(/exit;/g,'return;');
let click=false,escape=false;
const c={room_width:1152,room_height:648,delta_time:16667,tempo_menu:3,menu_hover:[0,0,0,0],menu_hover_anterior:-1,
 opcoes_abertas:false,modo_jogo_aberto:false,online_aberto:false,deck_aberto:false,painel_menu_abertura:1,painel_menu_anterior:'',
 online_copiado_timer:0,deck_aviso_timer:0,deck_por_pagina:8,deck_pagina:0,deck_catalogo_menu:[()=>({nome:'Slime'})],deck_backup_menu:[],global:{deck_contagens:[50]},
 min:Math.min,max:Math.max,abs:Math.abs,ceil:Math.ceil,sin:Math.sin,power:Math.pow,lerp:(a,b,t)=>a+(b-a)*t,clamp:(x,a,b)=>Math.max(a,Math.min(b,x)),dcos:a=>Math.cos(a*Math.PI/180),dsin:a=>Math.sin(a*Math.PI/180),
 mb_left:1,vk_escape:27,mouse_x:0,mouse_y:0,
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
select(1);settle();assert.deepEqual(Array.from(c.deck_backup_menu),[50]);c.global.deck_contagens[0]=2;escape=true;c.frame();escape=false;assert.equal(c.deck_aberto,false);assert.deepEqual(Array.from(c.global.deck_contagens),[50]);
for(const w of [640,1152,1920]){c.room_width=w;for(let i=0;i<3;i++){const p=c.carta_modo_menu(i,324);assert(p.x-p.w/2>=0&&p.x+p.w/2<=w);assert(c.ponto_carta_menu(p,p.x,p.y));}}
console.log('OK: panel click isolation, Escape, deck cancellation restoring backup and mode card hit areas');
