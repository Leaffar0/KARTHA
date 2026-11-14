const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const src=fs.readFileSync(path.resolve(__dirname,'../../scripts/scr_fluxo_partida/scr_fluxo_partida.gml'),'utf8');
const a=src.indexOf('    var _clicou_continuar ='),b=src.indexOf('    return true;',a);
function click(x,y,online=false){
 const calls=[];const c={_tutorial_gui_x:x,_tutorial_gui_y:y,_pausa_cx:640,_pausa_cy:360,
 ui_modal:{pausa_ativa:true,opcoes_pausa_ativa:false},modo_partida:online?'online':'local',global:{net_room:1},rm_menu:2,mb_left:1,vk_escape:27,vk_f1:112,
 mouse_check_button_pressed:()=>true,keyboard_check_pressed:()=>false,ord:s=>s.charCodeAt(0),
 point_in_rectangle:(x,y,a,b,d,e)=>x>=a&&x<=d&&y>=b&&y<=e,
 online_ativo:()=>online,colyseus_send:()=>calls.push('concede'),online_desconectar:()=>calls.push('disconnect'),trocar_sala_suave:r=>calls.push(r)};
 vm.createContext(c);vm.runInContext(src.slice(a,b),c);return {c,calls};
}
for(const y of [506,525,544])for(const x of [516,640,764])assert.deepEqual(click(x,y).calls,[2]);
assert.deepEqual(click(640,525,true).calls,['concede','disconnect',2]);
for(const y of [451,470,489])assert.equal(click(640,y).c.ui_modal.opcoes_pausa_ativa,true);
assert.equal(click(640,415).c.ui_modal.pausa_ativa,false);
assert.deepEqual(click(640,550).calls,[]);
console.log('OK: entire pause button areas, local return, online concede/disconnect, options and continue');
