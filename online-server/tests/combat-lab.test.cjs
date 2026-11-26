const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../..');
const step=fs.readFileSync(path.join(root,'objects/obj_laboratorio/Step_0.gml'),'utf8').replace(/ mod /g,' % ');
const keys=new Set(),hits=[],paused=[],stopped=[];
const ctx={global:{},modo:0,tempo:0,som_contato:false,pausado:false,repetir:false,som_previa:-1,sons_combate:[],
 combatentes:[{nome:'Lobo'},{nome:'Slime'}],atacante_previa:0,alvo_previa:1,bloqueio_previa:false,critico_previa:false,magia_previa:false,
 noone:-1,mb_left:1,id:0,magia:0,
 keyboard_check_pressed:k=>keys.has(k),mouse_check_button_pressed:()=>false,
 display_get_gui_width:()=>1280,display_get_gui_height:()=>720,device_mouse_x_to_gui:()=>0,device_mouse_y_to_gui:()=>0,
 point_in_rectangle:()=>false,ord:s=>s.charCodeAt(0),floor:Math.floor,
 array_length:a=>a.length,array_concat:(a,b)=>a.concat(b),array_push:(a,v)=>a.push(v),
 tocar_som_impacto_criatura:d=>{hits.push(d);return [71,72];},tocar_som_variado:()=>73,
 audio_pause_sound:v=>paused.push(v),audio_resume_sound(){},audio_is_playing:()=>false,audio_stop_sound:v=>stopped.push(v),
 laboratorio_reiniciar(){throw Error('Unexpected automatic replay');}
};
for(const [i,k] of ['escape','f7','space','left','right','up','down'].entries())ctx['vk_'+k]=1000+i;
Object.assign(ctx,{clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),exp:Math.exp,
 lerp:(a,b,t)=>a+(b-a)*t,delta_time:1000000/60,terreno_previa:0});
vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(root,'scripts/scr_mesa_ambiente/scr_mesa_ambiente.gml'),'utf8').replace(/\bmod\b/g,'%').replace(/\bstatic (?=_)/g,'let '),ctx);
ctx.ambiente_mesa=ctx.mesa_ambiente_criar();
for(let i=0;i<31;i++)vm.runInContext(step,ctx);
assert.equal(hits.length,0);vm.runInContext(step,ctx);assert.equal(hits.length,1);
assert.equal(hits[0].nome_atacante,'Lobo');assert.equal(hits[0].nome_alvo,'Slime');
for(let i=0;i<20;i++)vm.runInContext(step,ctx);assert.equal(hits.length,1);
keys.add('P'.charCodeAt(0));vm.runInContext(step,ctx);keys.clear();assert.deepEqual(paused,[71,72]);
const t=ctx.tempo;for(let i=0;i<40;i++)vm.runInContext(step,ctx);assert.equal(ctx.tempo,t);
vm.runInContext(fs.readFileSync(path.join(root,'objects/obj_laboratorio/CleanUp_0.gml'),'utf8'),ctx);
assert.deepEqual(stopped,[71,72]);
keys.add('T'.charCodeAt(0));vm.runInContext(step,ctx);keys.clear();
assert.equal(ctx.terreno_previa,1);assert.equal(ctx.ambiente_mesa.pesos[1],0);
ctx.pausado=false;vm.runInContext(step,ctx);assert.ok(ctx.ambiente_mesa.pesos[1]>0);
console.log('OK: combat preview triggers audio once at contact, pauses timeline and voices, cleans up on exit');
