if (entrando) {
    entrada_progresso += 1 / entrada_duracao;
    var _progresso = clamp(entrada_progresso, 0, 1);

    // Queda com ease-out: acelera no início e desacelera perto do chão
    var _suave = 1 - power(1 - _progresso, 3);

    x = lerp(origem_x, destino_x, _suave);
    y = lerp(origem_y, destino_y, _suave);

    // Giro dramático desacelerando, terminando exatamente no ângulo final (-90°)
    var _giro_total_final = rotacoes_extras * 360 + angulo_final;
    image_angle = _giro_total_final * (1 - power(1 - _progresso, 2));

    if (_progresso >= 1) {
        entrando = false;
        x = destino_x;
        y = destino_y;
        image_angle = angulo_final;

        pulso_x = 1;
        pulso_y = 1;

        // Impacto: achata rápido e depois estica de volta com quicada elástica
        tween(id, "pulso_y", 0.55, tween_animation.quad_out, 5, method(id, function() {
            if (!instance_exists(self)) return;
            tween(self, "pulso_y", 1, tween_animation.elastic_out, 24);
        }));
        tween(id, "pulso_x", 1.4, tween_animation.quad_out, 5, method(id, function() {
            if (!instance_exists(self)) return;
            tween(self, "pulso_x", 1, tween_animation.elastic_out, 24);
        }));

        audio_play_sound(snd_colocar, 1, 0, .6, 0, random_range(.7, 1));
        criar_poeira(x, y + (sprite_height/2) * escala_base, sprite_width * escala_base);
    }
}