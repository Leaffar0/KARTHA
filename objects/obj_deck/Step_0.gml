// Sincroniza a quantidade visual com o monte real e detecta quando uma carta foi comprada.
if (instance_exists(obj_controlador)) {
    var _quantidade_real = (obj_controlador.modo_partida == "online") ? global.online_deck_count : array_length(obj_controlador.monte);

    if (_quantidade_real < quantidade_cartas) {
        // Uma ou mais cartas saíram do monte: dispara o "solavanco" de compra.
        pulso_timer = pulso_duracao;
        criar_poeira(x, y - sprite_height / 4, sprite_width * 0.6);
        tocar_som_variado("deslize", 0.32, 1.08);
    }

    quantidade_cartas = _quantidade_real;
}

// Pulso de compra: achata e estica rapidamente, como se reagisse à carta saindo.
if (pulso_timer > 0) {
    var _progresso = pulso_timer / pulso_duracao;
    var _onda = sin(_progresso * pi);
    escala_deck_x = 1 + _onda * 0.025;
    escala_deck_y = 1 - _onda * 0.018;
    offset_y_pulso = -_onda * 0.8;
    pulso_timer--;
} else {
    escala_deck_x += (1 - escala_deck_x) * 0.3;
    escala_deck_y += (1 - escala_deck_y) * 0.3;
    offset_y_pulso += (0 - offset_y_pulso) * 0.3;
}

offset_y_bob = offset_y_pulso;
var _mostrar_legenda = point_in_rectangle(mouse_x,mouse_y,x-sprite_width/2-4, y-sprite_height/2-5, x+sprite_width/2+4, y+sprite_height/2+4);
if (instance_exists(obj_controlador)) {
    _mostrar_legenda = _mostrar_legenda && !obj_controlador.ui_modal.pausa_ativa
        && !obj_controlador.ui_modal.descarte_aberto && obj_controlador.carta_preview == noone;
}
legenda_alpha = lerp(legenda_alpha, _mostrar_legenda ? 1 : 0, 1-exp(-14*min(delta_time/1000000,0.1)));
