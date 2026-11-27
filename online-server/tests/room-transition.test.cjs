const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const path = require('node:path');
const read = p => fs.readFileSync(path.resolve(__dirname, '../..', p), 'utf8');
for(const fps of [30,60,144]) {
 let switched=0,dead=false,lastAlpha=0;
 const c={room:1,min:Math.min,clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),delta_time:1e6/fps,
 room_goto:r=>{assert.equal(r,2);assert.equal(lastAlpha,1,'black frame before room switch');switched++;},instance_destroy:()=>dead=true};
 vm.createContext(c);vm.runInContext(read('objects/obj_transicao_sala/Create_0.gml'),c);c.destino=2;
 assert.ok(c.depth > -16000 && c.depth < 16000, 'transition must be within GameMaker drawable depth');
 let frames=0;
 for(;frames<fps*3&&!dead;frames++){vm.runInContext(read('objects/obj_transicao_sala/Step_0.gml'),c);assert.ok(c.opacidade>=0&&c.opacidade<=1);lastAlpha=c.opacidade;}
 assert.ok(frames/fps >= 1.9 && frames/fps < 2.1, 'cinematic duration stays consistent');
 assert.equal(switched,1);assert.equal(dead,true);assert.equal(c.opacidade,0);
}
console.log('OK: one room switch under full black; fade completes at 30, 60 and 144 FPS');
