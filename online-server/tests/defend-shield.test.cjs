const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../..'),read=p=>fs.readFileSync(path.join(root,p),'utf8');
const step=read('objects/obj_carta/Step_0.gml');
const update=step.slice(step.indexOf('var _dt_defesa'),step.indexOf('if (travada && categoria'));
for(const fps of [30,60,144]) {
 const c={delta_time:1e6/fps,min:Math.min,max:Math.max,defendendo_castelo:false,travada:true,morrendo:false,defesa_formacao:0,defesa_presenca:0};
 vm.createContext(c);vm.runInContext(update,c);assert.equal(c.defesa_presenca,0);
 c.defendendo_castelo=true;
 vm.runInContext(update,c);assert.ok(c.defesa_formacao>0&&c.defesa_formacao<1,'stance starts formation without impact');
 for(let i=0;i<fps;i++)vm.runInContext(update,c);
 assert.equal(c.defesa_presenca,1);assert.equal(c.defesa_formacao,1);
 c.defendendo_castelo=false;vm.runInContext(update,c);
 assert.ok(c.defesa_presenca>0&&c.defesa_presenca<1,'removal fades');
 for(let i=0;i<fps;i++)vm.runInContext(update,c);
 assert.equal(c.defesa_presenca,0);assert.equal(c.defesa_formacao,0);
}
const source=read('scripts/scr_apresentacao/scr_apresentacao.gml');
const body=source.slice(source.indexOf('function desenhar_escudo_defesa_formacao'),source.indexOf('function desenhar_escudo_bloqueio'));
let alpha=0.8,color=42,lines=0,filledAlpha=0;
const c={min:Math.min,max:Math.max,clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),sin:Math.sin,pi:Math.PI,lerp:(a,b,t)=>a+(b-a)*t,
 draw_get_alpha:()=>alpha,draw_get_color:()=>color,draw_set_alpha:a=>{assert.ok(a>=0&&a<=1);alpha=a;},draw_set_color:v=>color=v,
 make_color_rgb:(r,g,b)=>[r,g,b],c_white:0xffffff,pr_trianglefan:1,draw_primitive_begin:()=>filledAlpha=alpha,
 draw_vertex:(x,y)=>{assert.ok(Number.isFinite(x)&&Number.isFinite(y));},draw_primitive_end(){},draw_line_width:()=>lines++,draw_line(){}};
vm.createContext(c);vm.runInContext(body.replace(/\bmod\b/g,'%'),c);
c.desenhar_escudo_defesa_formacao(100,100,70,0.1,1);const early=lines;
lines=0;c.desenhar_escudo_defesa_formacao(100,100,70,1,1);
assert.ok(lines>early,'outline forms progressively');assert.ok(filledAlpha<=0.25,'fill stays translucent');assert.equal(alpha,0.8);assert.equal(color,42);
assert.ok(!read('objects/obj_carta/Draw_0.gml').includes('draw_text(_x_desenho, _tag_y, "DEF")'));
console.log('OK: Defend stance forms shield without attack; fade and timing at 30/60/144 FPS; transparent fill and progressive contour');
