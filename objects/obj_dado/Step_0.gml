if (girando) {
    tempo_girando += 1;

    // Tween ease-out: sai rápido da origem e desacelera naturalmente antes de pousar.
    var _progresso = clamp(tempo_girando / tempo_total_giro, 0, 1);
    var _restante = 1 - _progresso;
    var _progresso_suave = 1 - (_restante * _restante * _restante);
    var _onda = sin(_progresso * pi);
    altura_voo = _onda * altura_maxima_dado;

    x = lerp(pos_inicial_x, destino_x, _progresso_suave) + (sin(_progresso * pi * 2) * desvio_lateral * _onda);
    y = lerp(pos_inicial_y, destino_y, _progresso_suave) - altura_voo;
    image_angle += 28 + (_onda * 14);
    image_xscale = escala_base_dado * (0.88 + (_onda * 0.24));
    image_yscale = escala_base_dado * (1.10 - (_onda * 0.16));

    // Os lados passam muito rápido no começo e ficam mais legíveis perto do pouso.
    var _intervalo_faces = max(2, floor(2 + (_progresso * 8)));
    if (tempo_girando mod _intervalo_faces == 0) {
        image_index = irandom_range(0, sprite_get_number(sprite_index) - 1);
    }

    if (tempo_girando >= tempo_total_giro) {
        girando = false;
        x = destino_x;
        y = destino_y;
        altura_voo = 0;
        image_angle = 0;
        image_xscale = escala_base_dado;
        image_yscale = escala_base_dado;
        // Há sprites de seis faces, inclusive quando a rolagem lógica é D20.
        // O texto mostra o valor exato e esta linha mantém um lado válido no sprite.
        image_index = (valor_final - 1) mod sprite_get_number(sprite_index);
        tempo_pouso = duracao_pouso;
        progresso_revelacao = 0;
        alarm[0] = 90;
    }
} else {
    if (tempo_pouso > 0) {
        // Pequena acomodação visual após tocar o chão.
        var _pulso = tempo_pouso / duracao_pouso;
        image_xscale = escala_base_dado * (1 + sin(_pulso * pi) * 0.08);
        image_yscale = escala_base_dado * (1 - sin(_pulso * pi) * 0.06);
        tempo_pouso--;
    }

    // O resultado só começa a surgir depois do pouso.
    progresso_revelacao = min(1, progresso_revelacao + 0.12);
}
