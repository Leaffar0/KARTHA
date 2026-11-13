const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const source=fs.readFileSync(path.resolve(__dirname,'../../scripts/scr_apresentacao/scr_apresentacao.gml'),'utf8');
const ctx={obj_controlador:{marcas_mesa:[]},instance_exists:x=>!!x,array_push:(a,v)=>a.push(v),array_length:a=>a.length,array_delete:(a,i,n)=>a.splice(i,n),sin:Math.sin,pi:Math.PI,string_lower:s=>s.toLowerCase(),string_pos:(s,v)=>v.indexOf(s)+1,mostrar_feedback(){},tocar_som_variado(){},c_yellow:1};
vm.createContext(ctx);
for(const name of ['registrar_marca_mesa','personalidade_visual','apresentar_contra_ataque']) {
 const start=source.indexOf('function '+name+'('),next=source.indexOf('\nfunction ',start+1);
 vm.runInContext(source.slice(start,next<0?undefined:next).replace(/ mod /g,' % '),ctx);
}
for(let i=0;i<40;i++)ctx.registrar_marca_mesa(i,10,i%2===0);
assert.equal(ctx.obj_controlador.marcas_mesa.length,24);assert.equal(ctx.obj_controlador.marcas_mesa[0].x,16);
for(let t=0;t<16000;t+=37){
 const s=ctx.personalidade_visual('Slime',false,t),f=ctx.personalidade_visual('Olho',true,t),m=ctx.personalidade_visual('Mimic',false,t);
 assert.ok(s.escala>=.982 && s.escala<=1.018);assert.ok(f.y>=-4 && f.y<=0);assert.ok(Math.abs(m.rotacao)<=.65);
 assert.deepEqual({...ctx.personalidade_visual('Goblin',false,t)},{escala:1,y:0,rotacao:0});
}
ctx.apresentar_contra_ataque(null);
const card={vida:7,atacou_este_turno:false};ctx.apresentar_contra_ataque(card);
assert.equal(card.vida,7);assert.equal(card.atacou_este_turno,false);assert.equal(card.contra_ataque_pendente,true);
console.log('OK: bounded visual residues, stable personality motion and counterattack presentation without rule mutation');

// The lab parks the offline room and never changes match state or opens online.
Object.assign(ctx,{global:{},room:12,room_persistent:false,view_enabled:true,obj_laboratorio:99,
 variable_global_exists:k=>Object.hasOwn(ctx.global,k),room_add:()=>44,
 room_instance_add:()=>{},room_goto:r=>{ctx.destination=r;}});
ctx.obj_controlador={modo_partida:'online',ui_modal:{pausa_ativa:false},vida_jogador:13};
const labStart=source.indexOf('function abrir_laboratorio_visual(');
vm.runInContext(source.slice(labStart,source.indexOf('\nfunction ',labStart+1)),ctx);
ctx.abrir_laboratorio_visual();assert.equal(ctx.destination,undefined);assert.equal(ctx.room_persistent,false);
ctx.obj_controlador.modo_partida='local';ctx.abrir_laboratorio_visual();
assert.equal(ctx.destination,44);assert.equal(ctx.global.laboratorio_origem,12);
assert.equal(ctx.global.laboratorio_persistencia,false);assert.equal(ctx.room_persistent,true);
assert.equal(ctx.obj_controlador.vida_jogador,13);assert.equal(ctx.obj_controlador.ui_modal.pausa_ativa,true);
console.log('OK: offline lab preserves the match and rejects online entry');

// Preview reads original/weapon dice without spending an action or rolling RNG.
Object.assign(ctx,{noone:null,obj_carta:'troop',string_delete:(s,a,n)=>s.slice(0,a-1)+s.slice(a-1+n),string_length:s=>s.length,string:String,
 tem_habilidade:(c,k)=>c.habilidades.includes(k),direcao_avanco:()=>-1,posicao_assalto:()=>1,posicao_entrada:()=>0,lado_oposto:()=> 'inimigo',
 buscar_construcao:()=>null,buscar_defensor_castelo:()=>null,calcular_defesa_fisica_total:()=>3,calcular_defesa_magica_total:()=>2});
ctx.obj_controlador={terreno_bonus_defesa:1};
const target={nome_carta:'Alvo',object_index:'troop',habilidades:[],dono:'inimigo',posicao_atual:2,sombra_ativa:false,defendendo_castelo:false,dado_dano:4};
ctx.buscar_slot=(lane,pos)=>pos===2?{ocupado:true,carta_atual:target}:null;
const previewSource=fs.readFileSync(path.resolve(__dirname,'../../scripts/scr_apresentacao/scr_apresentacao.gml'),'utf8');
ctx.is_struct=x=>x!==null&&typeof x==='object';
const ps=previewSource.indexOf('function dados_previa_ataque(');
vm.runInContext(previewSource.slice(ps,previewSource.indexOf('\nfunction ',ps+1)),ctx);
const attacker={nome_carta:'Origem',dono:'jogador',lane_atual:0,posicao_atual:3,habilidades:[],itens_equipados:[{nome:'Espada',dado:8,modificador:2}],qtd_dados_dano:2,dado_dano:4,mod_dano:1,qtd_dados_dano_magico:1,dado_dano_magico:6,mod_dano_magico:0,iludido_por_imitacao:false};
const saved=JSON.stringify(attacker);
assert.equal(ctx.dados_previa_ataque(attacker,'Atacar (Física)').alvo,target);
assert.ok(ctx.dados_previa_ataque(attacker,'Atacar com Espada').texto.includes('1D8 + 2'));
assert.equal(ctx.dados_previa_ataque(attacker,'Atacar [já usado]'),null);
assert.equal(JSON.stringify(attacker),saved);
console.log('OK: attack preview leaves combat state unchanged');
