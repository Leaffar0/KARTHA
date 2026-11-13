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
if(keyboard_check_pressed(vk_space)) laboratorio_reiniciar(id);
if(keyboard_check_pressed(ord("P"))) pausado=!pausado;
if(keyboard_check_pressed(ord("R"))) repetir=!repetir;
if(modo==7 && (keyboard_check_pressed(vk_left)||keyboard_check_pressed(vk_right))) {
    grupo=(grupo+array_length(grupos)+(keyboard_check_pressed(vk_right)?1:-1)) mod array_length(grupos);
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
if(!pausado) tempo++;
if(!som_contato && tempo>=((modo==4)?12:((modo==1 && magia==1)?70:32))) {
    som_contato=true;
    if(modo==1 && magia==1) {
        if(som_previa!=noone) audio_stop_sound(som_previa);
        som_previa=audio_play_sound(snd_bola_fogo_impacto,1,false,0.6);
    }
    if(modo==3) tocar_som_variado("empurrao",0.30);
    if(modo==4) tocar_som_variado("metal",0.48,0.8);
    if(modo==5) tocar_som_variado("encaixe",0.40);
}
if(repetir && tempo>180) laboratorio_reiniciar(id);
