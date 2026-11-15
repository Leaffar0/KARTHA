const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),path=require('node:path');
const root=path.resolve(__dirname,'../..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
for(const top of [false,true])for(const fps of [30,60,144]) {
 let delivered=0,destroyed=0;
 const c={devolver_mao:true,devolver_topo:top,recolhendo:false,x:240,y:180,
 view_camera:[0],camera_get_view_x:()=>50,camera_get_view_y:()=>20,camera_get_view_width:()=>900,camera_get_view_height:()=>550,
 delta_time:1e6/fps,min:Math.min,max:Math.max,sin:Math.sin,pi:Math.PI,lerp:(a,b,t)=>a+(b-a)*t,
 escala_base_dado:3.25,valor_final:17,id:1,callback:v=>{assert.equal(v,17);delivered++;},
 noone:null,obj_controlador:{rolagens_pendentes:1},instance_exists:()=>true,string:String,show_debug_message(){},instance_destroy:()=>destroyed++,
 transicao_sala_ativa:()=>false,ev_alarm:2};
 vm.createContext(c);
 vm.runInContext('function finish(){'+read('objects/obj_dado/Alarm_0.gml').replace(/\bexit;/g,'return;')+'}',c);
 // Exercise the actual retrieval branch; normal rolling has its own D20 tests.
 const step=read('objects/obj_dado/Step_0.gml').split('// D20 físico')[0].replace(/\bexit;/g,'return;');
 vm.runInContext('function frame(){'+step+'}',c);
 c.event_perform=()=>c.finish();c.finish();
 assert.equal(delivered,0);assert.equal(destroyed,0);
 assert.equal(c.obj_controlador.rolagens_pendentes,1);
 for(let i=0;i<fps&&!destroyed;i++)c.frame();
 assert.equal(delivered,1);assert.equal(destroyed,1);
 assert.equal(c.obj_controlador.rolagens_pendentes,0);
 assert.equal(c.x,500);assert.equal(c.y,top?-80:670);
 assert.equal(c.valor_final,17);
}
console.log('OK: initiative dice leave toward their owner before callback; single result and pending count at 30/60/144 FPS');
