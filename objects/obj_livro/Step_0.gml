#region Arrasto do livro fechado
if (arrastando) {
    x = mouse_x;
    y = mouse_y;
    if (mouse_check_button_released(mb_left)) {
        arrastando = false;
    }
}
#endregion

#region Abrir e fechar a prévia
// botão direito: abre o preview se clicar no livro fechado; fecha se já estiver aberto
if (mouse_check_button_pressed(mb_right)) {
    if (preview_ativo) {
        preview_ativo = false;
    } else if (!arrastando) {
        var _meia_largura = livro_largura / 2;
        var _meia_altura = livro_altura / 2;
        if (point_in_rectangle(mouse_x, mouse_y, x - _meia_largura, y - _meia_altura, x + _meia_largura, y + _meia_altura)) {
            preview_ativo = true;
        }
    }
}
#endregion

#region Navegação da prévia
// navegação só funciona com o preview aberto
if (preview_ativo) {
    if (mouse_check_button_pressed(mb_left)) {
        var _gui_largura = display_get_gui_width();
        var _gui_altura = display_get_gui_height();
        var _cx = _gui_largura / 2;
        var _cy = _gui_altura / 2;

        var _btn_largura = 110;
        var _btn_altura = 40;
        var _btn_y = _cy + preview_altura/2 + 30;
        var _btn_prev_x = _cx - 80;
        var _btn_next_x = _cx + 80;

        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);

        if (point_in_rectangle(_mx, _my, _btn_prev_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_prev_x + _btn_largura/2, _btn_y + _btn_altura/2)) {
            iniciar_flip(-1);
        } else if (point_in_rectangle(_mx, _my, _btn_next_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_next_x + _btn_largura/2, _btn_y + _btn_altura/2)) {
            iniciar_flip(1);
        }
    }

    if (keyboard_check_pressed(vk_right)) iniciar_flip(1);
    if (keyboard_check_pressed(vk_left)) iniciar_flip(-1);
}
#endregion

#region Animação de virada de página
if (virando) {
    flip_progresso += flip_velocidade;

    if (flip_progresso >= 1 && !trocou_pagina) {
        pagina_atual += direcao_flip;
        pagina_atual = clamp(pagina_atual, 0, array_length(paginas) - 1);
        trocou_pagina = true;
    }

    if (flip_progresso >= 2) {
        virando = false;
        flip_progresso = 0;
        trocou_pagina = false;
    }
}
#endregion
