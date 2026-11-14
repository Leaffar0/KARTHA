const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const src=fs.readFileSync(path.resolve(__dirname,'../../scripts/scr_online/scr_online.gml'),'utf8');
const a=src.indexOf('function online_sincronizar_terreno_visual(');
const slot={x:400,y:300,terreno_atual:null,ocupado:false};let creates=0;
const ctx={noone:null,obj_slot_terreno:1,obj_terreno_ativo:2,spr_carta_placeholder:9,global:{TERRENO_LARGURA_ALVO:70},
 instance_find:()=>slot,instance_exists:i=>!!i&&!i.dead,variable_instance_exists:(i,k)=>Object.hasOwn(i,k),
 online_funcao_carta_por_id:id=>()=>({nome:id,categoria:'terreno',sprite_carta:null}),
 instance_destroy:i=>i.dead=true,instance_create_layer:()=>{creates++;return {};},sprite_exists:s=>s!=null,sprite_get_height:()=>100};
vm.createContext(ctx);vm.runInContext(src.slice(a),ctx);
ctx.online_sincronizar_terreno_visual('planicies_profanas');assert(slot.ocupado);assert.equal(slot.terreno_atual.sprite_index,9);assert.equal(creates,1);
const first=slot.terreno_atual;ctx.online_sincronizar_terreno_visual('planicies_profanas');assert.equal(creates,1);
ctx.online_sincronizar_terreno_visual('cemiterio');assert(first.dead);assert.equal(creates,2);
const second=slot.terreno_atual;ctx.online_sincronizar_terreno_visual('');assert(second.dead);assert.equal(slot.terreno_atual,null);assert.equal(slot.ocupado,false);
console.log('OK: online terrain visual creation, repeated snapshots, replacement and removal');
