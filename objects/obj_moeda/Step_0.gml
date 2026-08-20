if (girando) {
    tempo_girando += 1;

    var _progresso = clamp(tempo_girando / tempo_total_giro, 0, 1);
    var _restante = 1 - _progresso;
    var _progresso_suave = 1 - (_restante * _restante); // ease-out: chega suave no destino

    // Trajetória balística: sobe e desce em arco, como um lançamento real
    var _onda = sin(_progresso * pi);
    altura_voo = _onda * altura_maxima_moeda;

    x = lerp(pos_inicial_x, destino_x, _progresso_suave) + (sin(_progresso * pi * 2) * desvio_lateral_moeda * _onda);
    y = lerp(pos_inicial_y, destino_y, _progresso_suave) - altura_voo;

    // Torque: gira rápido no ar e desacelera perto do chão, como um giro real perdendo momento
    velocidade_rotacao = 18 + (_onda * 10);
    angulo_moeda += velocidade_rotacao;

    // Alterna as faces enquanto gira (efeito visual de "cara ou coroa" piscando)
    if (tempo_girando mod 5 == 0) {
        image_index = irandom_range(0, sprite_get_number(sprite_index) - 1);
    }

    if (tempo_girando >= tempo_total_giro) {
        girando = false;
        altura_voo = 0;
        angulo_moeda = 0;
        image_index = (resultado_final == 1) ? 0 : 4;
        x = destino_x;
        y = destino_y;

        // Impacto elástico: achata (squash) rápido e depois estica de volta (stretch),
        // quicando levemente até assentar -- efeito de moeda batendo na mesa.
        moeda_escala_x = 1;
        moeda_escala_y = 1;

        tween(id, "moeda_escala_y", 0.6, tween_animation.quad_out, 4, method(id, function() {
            if (!instance_exists(self)) return;
            tween(self, "moeda_escala_y", 1, tween_animation.elastic_out, 22);
        }));
        tween(id, "moeda_escala_x", 1.35, tween_animation.quad_out, 4, method(id, function() {
            if (!instance_exists(self)) return;
            tween(self, "moeda_escala_x", 1, tween_animation.elastic_out, 22);
        }));

        alarm[0] = 120;
    }
}