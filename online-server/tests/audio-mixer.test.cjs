const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../..');
const source=fs.readFileSync(path.join(root,'scripts/scr_ui/scr_ui.gml'),'utf8');
const presentation=fs.readFileSync(path.join(root,'scripts/scr_apresentacao/scr_apresentacao.gml'),'utf8');
const settings={},gains={},ctx={global:{},
 clamp:(n,a,b)=>Math.max(a,Math.min(b,n)),round:Math.round,
 ini_open(){},ini_close(){},ini_read_real:(s,k,d)=>settings[s+'.'+k]??d,
 ini_write_real:(s,k,v)=>settings[s+'.'+k]=v,
 window_get_fullscreen:()=>false,window_set_fullscreen(){},tocar_som_variado(){},
 audio_get_name:n=>n,audio_sound_gain:(s,v)=>gains[s]=v,
 string_pos:(a,b)=>b.indexOf(a)+1,
 variable_struct_get_names:Object.keys,variable_struct_get:(s,k)=>s[k],
 array_length:a=>a.length,array_get_index:(a,v)=>a.indexOf(v),array_push:(a,v)=>a.push(v)
};
ctx.variable_global_exists=k=>Object.hasOwn(ctx.global,k);
ctx.variable_global_get=k=>ctx.global[k];ctx.variable_global_set=(k,v)=>ctx.global[k]=v;
for(const n of new Set((source+presentation).match(/snd_\w+/g)))ctx[n]=n;
vm.createContext(ctx);
function load(src,name){let a=src.indexOf('function '+name+'('),b=src.indexOf('\nfunction ',a+1);assert.ok(a>=0);vm.runInContext(src.slice(a,b<0?undefined:b).replace('static _grupos','var _grupos'),ctx);}
load(presentation,'catalogo_sons_jogo');
for(const n of ['carregar_configuracoes','salvar_configuracoes','definir_tamanho_interface','aplicar_config_audio','chave_canal_audio','ajustar_canal_audio','multiplicador_audio_asset'])load(source,n);
ctx.carregar_configuracoes();
assert.equal(ctx.global.volume_interface,1);assert.equal(ctx.global.volume_combate,1);assert.equal(ctx.global.volume_magias,1);
ctx.global.canal_audio_opcoes=1;ctx.ajustar_canal_audio(-1);ctx.aplicar_config_audio();
assert.equal(gains.snd_ui_clique_1,0);assert.equal(gains.snd_slime_dano,.8);assert.equal(gains.snd_magia_raio_1,.8);
ctx.global.canal_audio_opcoes=3;ctx.ajustar_canal_audio(-.5);ctx.aplicar_config_audio();
assert.equal(gains.snd_magia_raio_1,.4);assert.equal(gains.snd_bola_fogo_impacto,.4);
assert.equal(gains.snd_slime_dano,.8);assert.equal(gains.snd_menu,.8);
ctx.salvar_configuracoes();ctx.global={};ctx.carregar_configuracoes();
assert.equal(ctx.global.volume_interface,0);assert.equal(ctx.global.volume_magias,.5);
ctx.global.canal_audio_opcoes=2;ctx.ajustar_canal_audio(5);assert.equal(ctx.global.volume_combate,1);
ctx.ajustar_canal_audio(-5);assert.equal(ctx.global.volume_combate,0);
console.log('OK: independent channel gains, music unchanged, mute, limits and config round-trip');
