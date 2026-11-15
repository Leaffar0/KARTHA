if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_f7)) {
    global.laboratorio_voltando=true;
    room_goto(global.laboratorio_origem); exit;
}
var _w=display_get_gui_width(), _h=display_get_gui_height();
var _bw=(_w-40)/4, _mx=device_mouse_x_to_gui(0), _my=device_mouse_y_to_gui(0);
for(var i=0;i<8;i++) {
    var _x=20+(i mod 4)*_bw, _y=80+floor(i/4)*42;
    if (keyboard_check_pressed(ord("1")+i) || (mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_mx,_my,_x,_y,_x+_bw-6,_y+34))) {
        modo=i; laboratorio_reiniciar(id);
    }
}
if(keyboard_check_pressed(ord("D"))) { modo=8; laboratorio_reiniciar(id); }
if(modo==8 && (keyboard_check_pressed(vk_left)||keyboard_check_pressed(vk_right))) {
    dado_previa_deslocamento += keyboard_check_pressed(vk_right)?1:-1;
    laboratorio_reiniciar(id);
}
if(keyboard_check_pressed(vk_space)) laboratorio_reiniciar(id);
if(keyboard_check_pressed(ord("P"))) {
    pausado=!pausado;
    var _vozes=array_concat(sons_combate,[som_previa]);
    for(var _v=0;_v<array_length(_vozes);_v++) if(_vozes[_v]!=noone) {
        if(pausado) audio_pause_sound(_vozes[_v]); else audio_resume_sound(_vozes[_v]);
    }
}
if(modo==0) {
    var _alterou=false;
    if(keyboard_check_pressed(vk_left)||keyboard_check_pressed(vk_right)) {
        atacante_previa=(atacante_previa+array_length(combatentes)+(keyboard_check_pressed(vk_right)?1:-1)) mod array_length(combatentes); _alterou=true;
    }
    if(keyboard_check_pressed(vk_up)||keyboard_check_pressed(vk_down)) {
        alvo_previa=(alvo_previa+array_length(combatentes)+(keyboard_check_pressed(vk_down)?1:-1)) mod array_length(combatentes); _alterou=true;
    }
    if(keyboard_check_pressed(ord("B"))) {bloqueio_previa=!bloqueio_previa;_alterou=true;}
    if(keyboard_check_pressed(ord("C"))) {critico_previa=!critico_previa;_alterou=true;}
    if(keyboard_check_pressed(ord("M"))) {magia_previa=!magia_previa;_alterou=true;}
    if(_alterou) laboratorio_reiniciar(id);
}
if(keyboard_check_pressed(ord("R"))) repetir=!repetir;
if(modo==7 && (keyboard_check_pressed(vk_left)||keyboard_check_pressed(vk_right))) {
    grupo=(grupo+array_length(grupos)+(keyboard_check_pressed(vk_right)?1:-1)) mod array_length(grupos);
    variacao_som=0;
    laboratorio_reiniciar(id);
}
if(modo==6 && (keyboard_check_pressed(vk_left)||keyboard_check_pressed(vk_right))) {
    habilidade=(habilidade+array_length(habilidades)+(keyboard_check_pressed(vk_right)?1:-1)) mod array_length(habilidades);
    laboratorio_reiniciar(id);
}
if(modo==1 && (keyboard_check_pressed(vk_left)||keyboard_check_pressed(vk_right))) {
    magia=(magia+array_length(magias)+(keyboard_check_pressed(vk_right)?1:-1)) mod array_length(magias);
    laboratorio_reiniciar(id);
}
if(modo==7 && (keyboard_check_pressed(vk_up)||keyboard_check_pressed(vk_down))) {
    var _sons=variable_struct_get(catalogo_sons_jogo(),grupos[grupo]);
    variacao_som=(variacao_som+array_length(_sons)+(keyboard_check_pressed(vk_down)?1:-1)) mod array_length(_sons);
    laboratorio_reiniciar(id);
}
if(!pausado) tempo++;
if(!pausado && !som_contato && tempo>=((modo==4)?12:((modo==1 && magia==1)?70:32))) {
    som_contato=true;
    if(modo==0) {
        sons_combate=tocar_som_impacto_criatura({atacante:noone,alvo:noone,
            nome_atacante:combatentes[atacante_previa].nome,nome_alvo:combatentes[alvo_previa].nome,
            dano:bloqueio_previa?0:3,defesa:bloqueio_previa?4:0,critico:critico_previa,magica:magia_previa});
        if(bloqueio_previa) array_push(sons_combate,tocar_som_variado(magia_previa?"magia_escudo":"defesa_escudo",0.25));
        else if(critico_previa) array_push(sons_combate,tocar_som_variado("critico",0.40,0.90));
    }
    if(modo==1 && magia==1) {
        if(som_previa!=noone) audio_stop_sound(som_previa);
        som_previa=audio_play_sound(snd_bola_fogo_impacto,1,false,0.6);
    }
    if(modo==3) array_push(sons_combate,tocar_som_variado("empurrao",0.30));
    if(modo==4) array_push(sons_combate,tocar_som_variado("metal",0.48,0.8));
    if(modo==5) array_push(sons_combate,tocar_som_variado("encaixe",0.40));
}
// Sons longos terminam antes da próxima repetição automática.
if(!pausado && repetir && tempo>(modo==8?300:180) && (som_previa==noone || !audio_is_playing(som_previa))) laboratorio_reiniciar(id);

if (keyboard_check_pressed(ord("T"))) terreno_previa = (terreno_previa+1) mod 4;
if (!pausado) mesa_ambiente_atualizar(ambiente_mesa, terreno_previa, delta_time/1000000);
