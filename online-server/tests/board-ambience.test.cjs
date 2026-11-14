const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const calls = [];
const controller = {terreno_ativo: ''};
let slot = null;
const context = vm.createContext({
  clamp: (n,a,b)=>Math.max(a,Math.min(b,n)), floor:Math.floor, exp:Math.exp,
  lerp:(a,b,t)=>a+(b-a)*t, noone:null, c_white:0xffffff, spr_mesa_madeira:1,
  obj_controlador:controller, obj_slot_terreno:'slot',
  shd_mesa_cinza:2, shader_is_compiled:()=>true, shader_set(){}, shader_reset(){},
  instance_exists:x=>x!==null, instance_find:()=>slot,
  is_struct:x=>x!==null && typeof x==='object',
  variable_struct_exists:(x,k)=>Object.hasOwn(x,k),
  draw_sprite_stretched_ext:(...args)=>calls.push(args),
});
vm.runInContext(fs.readFileSync(path.join(root,'scripts/scr_mesa_ambiente/scr_mesa_ambiente.gml'),'utf8').replace(/\bmod\b/g,'%'),context);
assert.equal(context.mesa_ambiente_terreno(),0);
slot={ocupado:true,terreno_atual:{dados_carta:{nome:'Pântano Sombrio'}}};
assert.equal(context.mesa_ambiente_terreno(),1);
slot.ocupado=false; assert.equal(context.mesa_ambiente_terreno(),0);
controller.terreno_ativo='cemiterio'; assert.equal(context.mesa_ambiente_terreno(),2);
controller.terreno_ativo='planicies_profanas'; assert.equal(context.mesa_ambiente_terreno(),3);
const state=context.mesa_ambiente_criar();
// A second terrain can arrive midway through the first fade without a reset.
for(const target of [1,3,2,0]) {
  const before=[...state.pesos];
  context.mesa_ambiente_atualizar(state,target,1/60);
  assert.ok(Math.max(...state.pesos.map((p,i)=>Math.abs(p-before[i])))<0.05);
  for(let i=0;i<20;i++) context.mesa_ambiente_atualizar(state,target,1/60);
  assert.ok(Math.abs(state.pesos.reduce((a,b)=>a+b,0)-1)<1e-10);
  calls.length=0;context.mesa_ambiente_desenhar(state,0,0,1152,648);
  assert.equal(calls[0].at(-1),1); // Full opaque coverage on the first layer.
  const rendered=[0,0,0,0];
  for(const args of calls){const alpha=args.at(-1);for(let i=0;i<4;i++)rendered[i]*=1-alpha;rendered[args[1]]+=alpha;}
  rendered.forEach((p,i)=>assert.ok(Math.abs(p-state.pesos[i])<1e-10));
}
for(let i=0;i<200;i++)context.mesa_ambiente_atualizar(state,0,1/60);
assert.deepEqual([...state.pesos],[1,0,0,0]);
const a=context.mesa_ambiente_criar(),b=context.mesa_ambiente_criar();
for(let i=0;i<30;i++)context.mesa_ambiente_atualizar(a,1,1/30);
for(let i=0;i<120;i++)context.mesa_ambiente_atualizar(b,1,1/120);
assert.ok(Math.abs(a.pesos[1]-b.pesos[1])<1e-10);
console.log('OK: terrain detection, interrupted fades, constant opacity, FPS independence and return to neutral wood');

// Atmospheric effects are bounded, terrain-specific, and don't invoke random().
let vertices=0,lines=0,rings=0;
Object.assign(context,{fator_efeitos_visuais:()=>1,draw_get_alpha:()=>1,draw_get_color:()=>0,
 draw_set_alpha(){},draw_set_color(){},draw_primitive_begin(){},draw_primitive_end(){},pr_trianglestrip:1,
 draw_vertex_color:(x,y,c,a)=>{assert.ok(Number.isFinite(x)&&Number.isFinite(y));assert.ok(a>=-1e-12&&a<=1);vertices++;},
 draw_line:()=>lines++,draw_ellipse:()=>rings++,make_color_rgb:()=>0,
 sin:Math.sin,power:Math.pow,abs:Math.abs,frac:x=>x-Math.floor(x),sqr:x=>x*x,min:Math.min,pi:Math.PI});
context.mesa_ambiente_atmosfera({pesos:[1,0,0,0],tempo:1},0,0,1152,648);
assert.equal(vertices+lines+rings,0);
context.mesa_ambiente_atmosfera({pesos:[0,0,1,0],tempo:2},0,0,1152,648);
assert.equal(vertices,1392);assert.equal(lines+rings,0);
vertices=0;
for(let t=0;t<8;t+=0.1)context.mesa_ambiente_atmosfera({pesos:[0,1,0,0],tempo:t},0,0,1152,648);
assert.equal(vertices,0);assert.ok(lines>0&&rings>0);
console.log('OK: cemetery mist, intermittent swamp drops and ripples, no effects on neutral terrain');
