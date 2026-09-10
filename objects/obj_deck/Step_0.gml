// Sincroniza a quantidade visual com o monte real e detecta quando uma carta foi comprada.
if (instance_exists(obj_controlador)) {
    var _monte_visivel = (obj_controlador.modo_partida == "online") ? [] : ((partida_local_ativa() && obj_controlador.turno == "inimigo")
        ? obj_controlador.monte_inimigo : obj_controlador.monte);
    var _quantidade_real = (obj_controlador.modo_partida == "online") ? global.online_deck_count : array_length(_monte_visivel);

    if (_quantidade_real < quantidade_cartas) {
        // Uma ou mais cartas saíram do monte: dispara o "solavanco" de compra.
        pulso_timer = pulso_duracao;
        criar_poeira(x, y - sprite_height / 4, sprite_width * 0.6);
        audio_play_sound(snd_shuffle, 1, 0, .4, 0, random_range(.7, 1.3));
    }

    quantidade_cartas = _quantidade_real;
}

// Pulso de compra: achata e estica rapidamente, como se reagisse à carta saindo.
if (pulso_timer > 0) {
    var _progresso = pulso_timer / pulso_duracao;
    var _onda = sin(_progresso * pi);
    escala_deck_x = 1 + _onda * 0.14;
    escala_deck_y = 1 - _onda * 0.10;
    offset_y_pulso = -_onda * 5;
    pulso_timer--;
} else {
    escala_deck_x += (1 - escala_deck_x) * 0.3;
    escala_deck_y += (1 - escala_deck_y) * 0.3;
    offset_y_pulso += (0 - offset_y_pulso) * 0.3;
}

offset_y_bob = offset_y_pulso;