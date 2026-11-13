const fs=require('fs'),cp=require('child_process');
const ff='C:/ProgramData/GameMakerStudio2-LTS2026/Cache/runtimes/runtime-2026.0.0.23/bin/ffmpeg/windows/ffmpeg.exe';
const entries=[
  {
    "name": "snd_mimic_bau_1",
    "source": "audio_importar/Audio/floraphonic-wooden-trunk-latch-1-183944.mp3",
    "use": "Imitação: fecho de baú"
  },
  {
    "name": "snd_mimic_bau_2",
    "source": "audio_importar/Audio/floraphonic-wooden-trunk-latch-2-183945.mp3",
    "use": "Imitação: fecho de baú"
  },
  {
    "name": "snd_monstro_mordida",
    "source": "audio_importar/Audio/freesound_community-monster-bite-44538.mp3",
    "use": "Mordida de lobo, urso e mímico"
  },
  {
    "name": "snd_esqueleto_osso_1",
    "source": "audio_importar/Audio/universfield-bone-break-2-140224.mp3",
    "use": "Impacto em esqueleto"
  },
  {
    "name": "snd_esqueleto_osso_2",
    "source": "audio_importar/Audio/freeeverythingxx-bone-break-sound-269658.mp3",
    "use": "Impacto em esqueleto"
  },
  {
    "name": "snd_slime_dano",
    "source": "audio_importar/Audio/floraphonic-slime-splatter-4-220263.mp3",
    "use": "Slime recebendo dano"
  },
  {
    "name": "snd_slime_ataque",
    "source": "audio_importar/Audio/freesound_community-slimejump-6913.mp3",
    "use": "Slime atacando"
  },
  {
    "name": "snd_magia_raio_1",
    "source": "audio_importar/Audio/yodguard-lightning-magic-3-378649.mp3",
    "use": "Raio"
  },
  {
    "name": "snd_magia_raio_2",
    "source": "audio_importar/Audio/yodguard-lightning-magic-4-378647.mp3",
    "use": "Raio"
  },
  {
    "name": "snd_magia_gelo_1",
    "source": "audio_importar/Audio/yodguard-iced-magic-5-378605.mp3",
    "use": "Gelo"
  },
  {
    "name": "snd_magia_gelo_2",
    "source": "audio_importar/Audio/yodguard-iced-magic-6-378606.mp3",
    "use": "Gelo"
  },
  {
    "name": "snd_magia_sombria",
    "source": "audio_importar/Audio/yodguard-dark-magic-6-378652.mp3",
    "use": "Magia sombria"
  }
];
let project=fs.readFileSync('KARTHA.yyp','utf8'),order=fs.readFileSync('KARTHA.resource_order','utf8');const template=JSON.parse(fs.readFileSync('sounds/snd_papel_deslize/snd_papel_deslize.yy','utf8'));
for(const e of entries){const dir='sounds/'+e.name;fs.mkdirSync(dir,{recursive:true});const out=dir+'/'+e.name+'.wav';const r=cp.spawnSync(ff,['-y','-hide_banner','-loglevel','error','-i',e.source,'-ac','1','-ar','44100','-c:a','pcm_s16le',out],{encoding:'utf8'});if(r.status!==0){ const info=cp.spawnSync(ff,['-hide_banner','-i',e.source],{encoding:'utf8'}).stderr;const m=info.match(/Duration: (\d+):(\d+):([\d.]+)/);if(!m)throw Error(r.stderr);e.duration=+m[1]*3600+ +m[2]*60+ +m[3];e.originalOgg=true;fs.copyFileSync(e.source,dir+'/'+e.name+'.ogg');fs.writeFileSync(dir+'/'+e.name+'.yy',JSON.stringify({...template,'%Name':e.name,name:e.name,soundFile:e.name+'.ogg',duration:e.duration},null,2));if(fs.statSync(out).size<100)fs.unlinkSync(out); } else {
const b=fs.readFileSync(out);let at=12;while(at+8<b.length&&b.toString('ascii',at,at+4)!=='data')at+=8+b.readUInt32LE(at+4)+(b.readUInt32LE(at+4)%2);const n=b.readUInt32LE(at+4)/2;at+=8;let values=Array.from({length:n},(_,i)=>b.readInt16LE(at+2*i)),pk=values.reduce((m,v)=>Math.max(m,Math.abs(v)),0);if(!pk)throw Error('Silent '+e.name);
let first=values.findIndex(v=>Math.abs(v)>pk*.015),last=n-1;while(last>first&&Math.abs(values[last])<pk*.015)last--;values=values.slice(Math.max(0,first-353),Math.min(n,last+6615));const active=values.filter(v=>Math.abs(v)>pk*.02),rms=Math.sqrt(active.reduce((t,v)=>t+v*v,0)/active.length),gain=Math.min(4,23592/pk,2600/rms);
const w=Buffer.alloc(44+values.length*2);w.write('RIFF');w.writeUInt32LE(w.length-8,4);w.write('WAVEfmt ',8);w.writeUInt32LE(16,16);w.writeUInt16LE(1,20);w.writeUInt16LE(1,22);w.writeUInt32LE(44100,24);w.writeUInt32LE(88200,28);w.writeUInt16LE(2,32);w.writeUInt16LE(16,34);w.write('data',36);w.writeUInt32LE(values.length*2,40);values.forEach((v,i)=>w.writeInt16LE(Math.round(v*gain*Math.min(1,i/220,(values.length-1-i)/1323)),44+i*2));fs.writeFileSync(out,w);
e.duration=values.length/44100;e.gain=gain;const meta={...template,'%Name':e.name,name:e.name,soundFile:e.name+'.wav',duration:e.duration,volume:0.7};fs.writeFileSync(dir+'/'+e.name+'.yy',JSON.stringify(meta,null,2)+'\n');
}
if(!project.includes('"name":"'+e.name+'"'))project=project.replace('  "resources":[','  "resources":[\n    {"id":{"name":"'+e.name+'","path":"'+dir+'/'+e.name+'.yy",},},');if(!order.includes('"name":"'+e.name+'"'))order=order.replace('    {"name":"snd_colocar"','    {"name":"'+e.name+'","order":'+(120+entries.indexOf(e))+',"path":"'+dir+'/'+e.name+'.yy",},\n    {"name":"snd_colocar"');console.log(e.name,e.duration.toFixed(2)+'s');}
fs.writeFileSync('KARTHA.yyp',project);fs.writeFileSync('KARTHA.resource_order',order);fs.writeFileSync('audio_importar/preparacao/catalogo_criaturas.json',JSON.stringify(entries,null,2));
