#region Arrasto do livro fechado
if (arrastando) {
    x = mouse_x;
    y = mouse_y;
    if (mouse_check_button_released(mb_left)) {
        arrastando = false;
    }
}
#endregion

#region Animação de virar página
if (virando) {
    flip_progresso += 1 / flip_duracao;

    // troca o conteúdo exatamente na metade -- é o instante em que a página
    // está "de perfil" (escala 0), então a troca fica invisível pro jogador
    if (flip_progresso >= 0.5 && pagina_atual != flip_pagina_alvo) {
        pagina_atual = flip_pagina_alvo;
    }

    if (flip_progresso >= 1) {
        virando = false;
        flip_progresso = 0;
    }
}
#endregion

#region Resposta visual do livro fechado
if (!preview_ativo && !arrastando) {
    var _meia_largura_hover = livro_largura / 2;
    var _meia_altura_hover = livro_altura / 2;
    var _sobre_livro = point_in_rectangle(mouse_x, mouse_y, x - _meia_largura_hover, y - _meia_altura_hover, x + _meia_largura_hover, y + _meia_altura_hover);
    var _escala_alvo_livro = _sobre_livro ? (livro_escala * 1.16) : livro_escala;
    livro_escala_atual += (_escala_alvo_livro - livro_escala_atual) * 0.18;
    livro_bob += 0.08;
    image_xscale = livro_escala_atual;
    image_yscale = livro_escala_atual;
    image_angle = _sobre_livro ? (sin(livro_bob) * 2) : 0;
}
#endregion

#region Abrir e fechar a prévia
if (mouse_check_button_pressed(mb_right)) {
    if (preview_ativo) {
        preview_ativo = false;
    } else if (!arrastando) {
        var _meia_largura = livro_largura / 2;
        var _meia_altura = livro_altura / 2;
        if (point_in_rectangle(mouse_x, mouse_y, x - _meia_largura, y - _meia_altura, x + _meia_largura, y + _meia_altura)) {
            preview_ativo = true;
            mostrando_sumario = true; // sempre entra pelo sumário
            virando = false;
            flip_progresso = 0;
        }
    }
}
#endregion

#region Navegação da prévia
if (preview_ativo) {
    var _gui_largura = display_get_gui_width();
    var _gui_altura = display_get_gui_height();
    var _cx = _gui_largura / 2;
    var _cy = _gui_altura / 2;
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    if (mostrando_sumario) {
        #region Sumário: hover e clique nos capítulos
        var _largura_pagina_sum = preview_largura / 2;
        var _pagina_esquerda_x_sum = _cx - (_largura_pagina_sum / 2);
        var _pagina_direita_x_sum = _cx + (_largura_pagina_sum / 2);

        var _n_total = array_length(sumario);
        var _por_coluna = ceil(_n_total / 2);
        var _altura_item = 30;
        var _margem_topo_lista = preview_altura * 0.18;
        var _largura_item = _largura_pagina_sum * 0.82;

        sumario_hover_index = -1;

        for (var i = 0; i < _n_total; i++) {
            var _coluna = (i < _por_coluna) ? 0 : 1;
            var _linha = (_coluna == 0) ? i : (i - _por_coluna);
            var _centro_x_item = (_coluna == 0) ? _pagina_esquerda_x_sum : _pagina_direita_x_sum;
            var _y_item = _cy - preview_altura/2 + _margem_topo_lista + _linha * _altura_item;

            var _x1 = _centro_x_item - _largura_item/2;
            var _x2 = _centro_x_item + _largura_item/2;
            var _y1 = _y_item;
            var _y2 = _y_item + _altura_item - 4;

            if (point_in_rectangle(_mx, _my, _x1, _y1, _x2, _y2)) {
                sumario_hover_index = i;
                break;
            }
        }

        if (mouse_check_button_pressed(mb_left) && sumario_hover_index != -1) {
            abrir_pagina_do_sumario(sumario[sumario_hover_index].indice_pagina);
        }
        #endregion
    } else {
        #region Botões de navegação (Anterior / Sumário / Próxima)
        if (mouse_check_button_pressed(mb_left)) {
            var _btn_largura = 110;
            var _btn_altura = 40;
            var _btn_y = _cy + preview_altura/2 + 30;
            var _btn_prev_x = _cx - 150;
            var _btn_sumario_x = _cx;
            var _btn_next_x = _cx + 150;

            if (point_in_rectangle(_mx, _my, _btn_prev_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_prev_x + _btn_largura/2, _btn_y + _btn_altura/2)) {
                iniciar_flip(-1);
            } else if (point_in_rectangle(_mx, _my, _btn_next_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_next_x + _btn_largura/2, _btn_y + _btn_altura/2)) {
                iniciar_flip(1);
            } else if (point_in_rectangle(_mx, _my, _btn_sumario_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_sumario_x + _btn_largura/2, _btn_y + _btn_altura/2)) {
                mostrando_sumario = true;
            }
        }

        if (keyboard_check_pressed(vk_right)) iniciar_flip(1);
        if (keyboard_check_pressed(vk_left)) iniciar_flip(-1);
        #endregion
    }
}
#endregion