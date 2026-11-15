const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../..'),read=p=>fs.readFileSync(path.join(root,p),'utf8');
const convert=s=>s.replace(/\bmod\b/g,'%').replace(/\bexit;/g,'throw Error("Unexpected early exit");');
const draw=[],received=[];
const ctx={game_get_speed:()=>60,gamespeed_fps:0,round:Math.round,transicao_sala_ativa:()=>false,floor:Math.floor,abs:Math.abs,min:Math.min,max:Math.max,sin:Math.sin,pi:Math.PI,sqr:x=>x*x,lerp:(a,b,t)=>a+(b-a)*t,clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),
 dsin:x=>Math.sin(x*Math.PI/180),dcos:x=>Math.cos(x*Math.PI/180),string:String,
 noone:null,c_white:0xffffff,Fontenil:1,spr_d20_corpo:2,fa_center:1,fa_middle:1,
 draw_get_font:()=>0,draw_get_halign:()=>0,draw_get_valign:()=>0,draw_get_color:()=>0,draw_get_alpha:()=>1,
 draw_set_font(){},draw_set_halign(){},draw_set_valign(){},draw_set_color(){},draw_set_alpha(){},draw_line(){},draw_sprite_ext(){},
 draw_text_transformed:(x,y,s)=>draw.push(s),string_width:s=>s.length*14,string_height:()=>33,make_color_rgb:()=>0,
 sprite_get_width:()=>256,sprite_get_height:()=>256,sprite_get_number:()=>6,
 irandom_range(){throw Error('Visual D20 must not roll again');},tocar_som_variado(){},
 is_struct:x=>x!==null&&typeof x==='object',instance_exists:()=>false,show_debug_message(){},instance_destroy(){},obj_controlador:null,id:1};
vm.createContext(ctx);vm.runInContext(convert(read('scripts/scr_d20_visual/scr_d20_visual.gml')),ctx);
for(let result=1;result<=20;result++){
 Object.assign(ctx,{devolver_mao:false,recolhendo:false,interativo_iniciativa:false,girando:true,atraso_inicio:0,tempo_girando:0,tempo_total_giro:1,
 tamanho_dado:20,valor_final:result,altura_maxima_dado:85,pos_inicial_x:10,pos_inicial_y:10,destino_x:100,destino_y:100,desvio_lateral:5,
 image_angle:0,escala_base_dado:3.25,sprite_index:0,grupo_soma:null,duracao_pouso:12,alarm:[],callback:v=>received.push(v)});
 vm.runInContext(convert(read('objects/obj_dado/Step_0.gml')),ctx);
 assert.equal(ctx.alarm[0],192);assert.equal(ctx.girando,false);assert.equal(ctx.valor_final,result);
 const face=ctx.d20_face_visual(ctx.valor_final,ctx.girando,ctx.tempo_girando);
 ctx.desenhar_d20_visual(0,0,3.25,3.25,0,face,1);assert.equal(draw.at(-1),String(result));
 vm.runInContext(read('objects/obj_dado/Alarm_0.gml'),ctx);assert.equal(received.at(-1),face);
}
assert.equal(ctx.d20_face_visual(-1,false,0),0);
const seen=new Set();for(let t=0;t<80;t++)seen.add(ctx.d20_face_visual(20,true,t));assert.equal(seen.size,20);
console.log('OK: all 20 landing faces match rendered digits and actual callback; no extra RNG; blank unrolled face');

ctx.spr_d4_corpo=3;
for(let result=1;result<=4;result++) {
 Object.assign(ctx,{devolver_mao:false,recolhendo:false,interativo_iniciativa:false,girando:true,
 atraso_inicio:0,tempo_girando:0,tempo_total_giro:30,tamanho_dado:4,valor_final:result,
 grupo_soma:null,alarm:[],callback:v=>received.push(v)});
 for(let frame=0;frame<30;frame++) vm.runInContext(convert(read('objects/obj_dado/Step_0.gml')),ctx);
 assert.equal(ctx.girando,false);assert.equal(ctx.image_angle,0);assert.equal(ctx.alarm[0],192);
 const face=ctx.d4_face_visual(ctx.valor_final,ctx.girando,ctx.tempo_girando);
 ctx.desenhar_d4_visual(0,0,3.25,3.25,0,face,1);
 assert.equal(draw.at(-1),String(result));
 vm.runInContext(read('objects/obj_dado/Alarm_0.gml'),ctx);
 assert.equal(received.at(-1),face);
}
const d4Faces=new Set();for(let t=0;t<80;t++) d4Faces.add(ctx.d4_face_visual(4,true,t));
assert.deepEqual([...d4Faces].sort(),[1,2,3,4]);
assert.equal(ctx.d4_face_visual(5,false,0),0);
console.log('OK: D4 four landing values match face and callback; animated faces stay 1–4 without new rolls');

ctx.spr_d6_corpo=4;
for(let result=1;result<=6;result++) {
 Object.assign(ctx,{devolver_mao:false,recolhendo:false,interativo_iniciativa:false,girando:true,
 atraso_inicio:0,tempo_girando:0,tempo_total_giro:30,tamanho_dado:6,valor_final:result,
 grupo_soma:null,alarm:[],callback:v=>received.push(v)});
 for(let frame=0;frame<30;frame++) vm.runInContext(convert(read('objects/obj_dado/Step_0.gml')),ctx);
 assert.equal(ctx.girando,false);assert.equal(ctx.image_angle,0);assert.equal(ctx.alarm[0],192);
 const face=ctx.d6_face_visual(ctx.valor_final,ctx.girando,ctx.tempo_girando);
 ctx.desenhar_d6_visual(0,0,3.25,3.25,0,face,1);
 assert.equal(draw.at(-1),String(result));
 vm.runInContext(read('objects/obj_dado/Alarm_0.gml'),ctx);
 assert.equal(received.at(-1),face);
}
const d6Faces=new Set();for(let t=0;t<80;t++) d6Faces.add(ctx.d6_face_visual(6,true,t));
assert.deepEqual([...d6Faces].sort(),[1,2,3,4,5,6]);
assert.equal(ctx.d6_face_visual(7,false,0),0);
console.log('OK: D6 six landing values match face and callback; animated faces stay 1–6 without new rolls');

ctx.spr_d8_corpo=5;
for(let result=1;result<=8;result++) {
 Object.assign(ctx,{devolver_mao:false,recolhendo:false,interativo_iniciativa:false,girando:true,
 atraso_inicio:0,tempo_girando:0,tempo_total_giro:30,tamanho_dado:8,valor_final:result,
 grupo_soma:null,alarm:[],callback:v=>received.push(v)});
 for(let frame=0;frame<30;frame++) vm.runInContext(convert(read('objects/obj_dado/Step_0.gml')),ctx);
 assert.equal(ctx.girando,false);assert.equal(ctx.image_angle,0);assert.equal(ctx.alarm[0],192);
 const face=ctx.d8_face_visual(ctx.valor_final,ctx.girando,ctx.tempo_girando);
 ctx.desenhar_d8_visual(0,0,3.25,3.25,0,face,1);
 assert.equal(draw.at(-1),String(result));
 vm.runInContext(read('objects/obj_dado/Alarm_0.gml'),ctx);
 assert.equal(received.at(-1),face);
}
const d8Faces=new Set();for(let t=0;t<80;t++) d8Faces.add(ctx.d8_face_visual(8,true,t));
assert.deepEqual([...d8Faces].sort(),[1,2,3,4,5,6,7,8]);
assert.equal(ctx.d8_face_visual(9,false,0),0);
console.log('OK: D8 eight landing values match face and callback; animated faces stay 1–8 without new rolls');

ctx.spr_d10_corpo=6;
for(let result=1;result<=10;result++) {
 Object.assign(ctx,{devolver_mao:false,recolhendo:false,interativo_iniciativa:false,girando:true,
 atraso_inicio:0,tempo_girando:0,tempo_total_giro:30,tamanho_dado:10,valor_final:result,
 grupo_soma:null,alarm:[],callback:v=>received.push(v)});
 for(let frame=0;frame<30;frame++) vm.runInContext(convert(read('objects/obj_dado/Step_0.gml')),ctx);
 assert.equal(ctx.girando,false);assert.equal(ctx.image_angle,0);assert.equal(ctx.alarm[0],192);
 const face=ctx.d10_face_visual(ctx.valor_final,ctx.girando,ctx.tempo_girando);
 ctx.desenhar_d10_visual(0,0,3.25,3.25,0,face,1);
 assert.equal(draw.at(-1),String(result));
 vm.runInContext(read('objects/obj_dado/Alarm_0.gml'),ctx);
 assert.equal(received.at(-1),face);
}
const d10Faces=new Set();for(let t=0;t<80;t++) d10Faces.add(ctx.d10_face_visual(10,true,t));
assert.deepEqual([...d10Faces].sort((a,b)=>a-b),[1,2,3,4,5,6,7,8,9,10]);
assert.equal(ctx.d10_face_visual(11,false,0),0);
console.log('OK: D10 ten landing values match face and callback; animated faces stay 1–10 without new rolls');

ctx.spr_d12_corpo=7;
for(let result=1;result<=12;result++) {
 Object.assign(ctx,{devolver_mao:false,recolhendo:false,interativo_iniciativa:false,girando:true,
 atraso_inicio:0,tempo_girando:0,tempo_total_giro:30,tamanho_dado:12,valor_final:result,
 grupo_soma:null,alarm:[],callback:v=>received.push(v)});
 for(let frame=0;frame<30;frame++) vm.runInContext(convert(read('objects/obj_dado/Step_0.gml')),ctx);
 assert.equal(ctx.girando,false);assert.equal(ctx.image_angle,0);assert.equal(ctx.alarm[0],192);
 const face=ctx.d12_face_visual(ctx.valor_final,ctx.girando,ctx.tempo_girando);
 ctx.desenhar_d12_visual(0,0,3.25,3.25,0,face,1);
 assert.equal(draw.at(-1),String(result));
 vm.runInContext(read('objects/obj_dado/Alarm_0.gml'),ctx);
 assert.equal(received.at(-1),face);
}
const d12Faces=new Set();for(let t=0;t<80;t++) d12Faces.add(ctx.d12_face_visual(12,true,t));
assert.deepEqual([...d12Faces].sort((a,b)=>a-b),[1,2,3,4,5,6,7,8,9,10,11,12]);
assert.equal(ctx.d12_face_visual(13,false,0),0);
console.log('OK: D12 twelve landing values match face and callback; animated faces stay 1–12 without new rolls');
