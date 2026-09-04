// D20 físico da iniciativa: pode ser pego e precisa ser arremessado.
if (interativo_iniciativa) {
    var _meia_dado_x = sprite_width * image_xscale * 0.55;
    var _meia_dado_y = sprite_height * image_yscale * 0.55;
    if (!iniciativa_arrastando && mouse_check_button_pressed(mb_left)
        && point_in_rectangle(mouse_x, mouse_y, x - _meia_dado_x, y - _meia_dado_y, x + _meia_dado_x, y + _meia_dado_y)) {
        iniciativa_arrastando = true;
        iniciativa_inicio_x = x;
        iniciativa_inicio_y = y;
        iniciativa_mouse_anterior_x = mouse_x;
        iniciativa_mouse_anterior_y = mouse_y;
        iniciativa_velocidade_x = 0;
        iniciativa_velocidade_y = 0;
        depth = -100000;
    }

    if (iniciativa_arrastando) {
        var _dx_dado = mouse_x - iniciativa_mouse_anterior_x;
        var _dy_dado = mouse_y - iniciativa_mouse_anterior_y;
        iniciativa_velocidade_x = lerp(iniciativa_velocidade_x, _dx_dado, 0.45);
        iniciativa_velocidade_y = lerp(iniciativa_velocidade_y, _dy_dado, 0.45);
        iniciativa_mouse_anterior_x = mouse_x;
        iniciativa_mouse_anterior_y = mouse_y;
        x += (mouse_x - x) * 0.72;
        y += (mouse_y - y) * 0.72;
        // Enquanto está na mão, apenas acompanha o cursor; o giro começa ao soltar.
        image_angle = 0;
        image_index = 0;
        image_xscale = lerp(image_xscale, escala_base_dado * 1.10, 0.28);
        image_yscale = lerp(image_yscale, escala_base_dado * 1.10, 0.28);

        if (mouse_check_button_released(mb_left)) {
            iniciativa_arrastando = false;
            var _velocidade_dado = point_distance(0, 0, iniciativa_velocidade_x, iniciativa_velocidade_y);
            var _distancia_dado = point_distance(iniciativa_inicio_x, iniciativa_inicio_y, x, y);
            if (_velocidade_dado >= 1.5 || _distancia_dado >= 26) {
                lancar_dado_disputa_inicial(id, max(_velocidade_dado, _distancia_dado / 10));
            } else {
                x = iniciativa_mesa_x;
                y = iniciativa_mesa_y;
                image_angle = 0;
                image_xscale = escala_base_dado;
                image_yscale = escala_base_dado;
                depth = -2000;
            }
        }
    } else {
        x = iniciativa_mesa_x;
        y = iniciativa_mesa_y;
        image_angle = 0;
        image_index = 0;
        image_xscale = escala_base_dado;
        image_yscale = escala_base_dado;
    }
    exit;
}

if (girando) {
    if (atraso_inicio > 0) {
        atraso_inicio -= 1;
        if (atraso_inicio <= 0) image_alpha = 1;
        exit;
    }

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
        if (is_struct(grupo_soma) && !grupo_soma_pouso_registrado) {
            grupo_soma_pouso_registrado = true;
            grupo_soma.pousados += 1;
        }
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
