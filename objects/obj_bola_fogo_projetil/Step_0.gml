if (!impactou) {
    var _x_anterior = x;
    var _y_anterior = y;

    progresso += 1 / duracao;
    var _p = clamp(progresso, 0, 1);
    var _suave = _p * _p * (3 - 2 * _p);
    var _onda = sin(_p * pi);

    x = lerp(origem_x, destino_x, _suave);
    y = lerp(origem_y, destino_y, _suave) - (_onda * altura_arco);

    // Só recalcula a direção se o movimento nesse frame for significativo,
    // evitando que ela "trema" perto do pico do arco ou perto do destino.
    var _dist_movida = point_distance(_x_anterior, _y_anterior, x, y);
    if (_dist_movida > 0.3) {
        var _direcao_alvo = point_direction(_x_anterior, _y_anterior, x, y);
        image_angle = lerp_angulo(image_angle, _direcao_alvo + 270, 0.35);
    }

    if (_p >= 1) {
        impactou = true;
        x = destino_x;
        y = destino_y;

        if (som_voo != noone && audio_is_playing(som_voo)) {
            audio_stop_sound(som_voo);
        }

        som_impacto_volume = 0.6;
        som_impacto = audio_play_sound(snd_bola_fogo_impacto, 1, 0, som_impacto_volume, 0, random_range(.9, 1.1));

        criar_poeira(x, y, 40);

        image_xscale = 1;
        image_yscale = 1;
        tween(id, "image_yscale", 0.35, tween_animation.quad_out, 5, method(id, function() {
            if (!instance_exists(self)) return;
            tween(self, "image_yscale", 0, tween_animation.quad_in, 8);
        }));
        tween(id, "image_xscale", 1.5, tween_animation.quad_out, 5, method(id, function() {
            if (!instance_exists(self)) return;
            tween(self, "image_xscale", 0, tween_animation.quad_in, 8);
        }));

        alarm[2] = 12;
        alarm[1] = 20;
        alarm[0] = 36;
    }
}

// Fade do som de impacto, sumindo com o tempo em vez de cortar seco
if (som_impacto != noone && audio_is_playing(som_impacto)) {
    som_impacto_volume -= 0.02;
    som_impacto_volume = max(som_impacto_volume, 0);
    audio_sound_gain(som_impacto, som_impacto_volume, 0);

    if (som_impacto_volume <= 0) {
        audio_stop_sound(som_impacto);
    }
}