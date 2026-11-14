pulso += 0.08;

for (var _i = array_length(cartas_caindo)-1; _i >= 0; _i--) {
    cartas_caindo[_i].tempo++;
    if (cartas_caindo[_i].tempo >= 52) array_delete(cartas_caindo, _i, 1);
}

var _mostrar_legenda = point_in_rectangle(mouse_x,mouse_y,x-10, y-2, x+sprite_width+10, y+sprite_height+2);
if (instance_exists(obj_controlador)) {
    _mostrar_legenda = _mostrar_legenda && !obj_controlador.ui_modal.pausa_ativa
        && !obj_controlador.ui_modal.descarte_aberto && obj_controlador.carta_preview == noone;
}
legenda_alpha = lerp(legenda_alpha, _mostrar_legenda ? 1 : 0, 1-exp(-14*min(delta_time/1000000,0.1)));
