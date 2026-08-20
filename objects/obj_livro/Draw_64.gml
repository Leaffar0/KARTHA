#region Validação e fundo da prévia
if (!preview_ativo) exit;
if (array_length(paginas) == 0) exit;

var _gui_largura = display_get_gui_width();
var _gui_altura = display_get_gui_height();
var _cx = _gui_largura / 2;
var _cy = _gui_altura / 2;

draw_set_alpha(0.75);
draw_set_color(c_black);
draw_rectangle(0, 0, _gui_largura, _gui_altura, false);
draw_set_alpha(1);
#endregion

#region As duas folhas do livro aberto
var _largura_pagina = preview_largura / 2;
var _escala_pagina_x = _largura_pagina / 90;
var _escala_pagina_y = preview_altura / 128;
var _pagina_esquerda_x = _cx - (_largura_pagina / 2);
var _pagina_direita_x = _cx + (_largura_pagina / 2);

draw_sprite_ext(spr_livro_fundo, 0, _pagina_esquerda_x, _cy, _escala_pagina_x, _escala_pagina_y, 0, c_white, 1);
draw_sprite_ext(spr_livro_fundo, 0, _pagina_direita_x, _cy, _escala_pagina_x, _escala_pagina_y, 0, c_white, 1);

draw_set_color(c_black);
draw_set_alpha(0.28);
draw_rectangle(_cx - 5, _cy - preview_altura/2, _cx + 5, _cy + preview_altura/2, false);
draw_set_alpha(1);
draw_set_color(c_white);
#endregion

draw_set_font(Fontenil);

if (mostrando_sumario) {
    #region Sumário clicável
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text_transformed(_cx, _cy - preview_altura/2 + preview_altura * 0.06, "SUMÁRIO", 1, 1, 0);

    var _n_total = array_length(sumario);
    var _por_coluna = ceil(_n_total / 2);
    var _altura_item = 30;
    var _margem_topo_lista = preview_altura * 0.18;
    var _largura_item = _largura_pagina * 0.82;

    for (var i = 0; i < _n_total; i++) {
        var _coluna = (i < _por_coluna) ? 0 : 1;
        var _linha = (_coluna == 0) ? i : (i - _por_coluna);
        var _centro_x_item = (_coluna == 0) ? _pagina_esquerda_x : _pagina_direita_x;
        var _y_item = _cy - preview_altura/2 + _margem_topo_lista + _linha * _altura_item;

        var _x1 = _centro_x_item - _largura_item/2;
        var _x2 = _centro_x_item + _largura_item/2;
        var _y1 = _y_item;
        var _y2 = _y_item + _altura_item - 4;

        var _sobre_item = (i == sumario_hover_index);

        if (_sobre_item) {
            draw_set_alpha(0.18);
            draw_set_color(c_white);
            draw_rectangle(_x1, _y1, _x2, _y2, false);
            draw_set_alpha(1);
        }

        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_color(_sobre_item ? c_yellow : c_white);
        var _titulo_item = sumario[i].titulo;
        var _escala_item = calcular_escala_texto_ajustada(_titulo_item, _largura_item - 16, _altura_item, 0.5, 0.32);
        draw_text_transformed(_x1 + 8, (_y1 + _y2)/2, _titulo_item, _escala_item, _escala_item, 0);
        draw_set_color(c_white);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    #endregion
} else {
	
    #region Página esquerda (estática)
    if (pagina_atual < array_length(paginas)) {
        desenhar_pagina_do_livro(paginas[pagina_atual], _pagina_esquerda_x, _cy, _largura_pagina * 0.86, preview_altura * 0.86);
    }
    #endregion

    #region Página direita (a que vira)
    var _indice_direita = pagina_atual + 1;
    if (_indice_direita < array_length(paginas)) {
        var _escala_x = 1;
        if (virando) {
            _escala_x = (flip_progresso < 1) ? (1 - flip_progresso) : (flip_progresso - 1);
        }

        var _bulge = 1;
        if (virando) {
            var _fase_normalizada = flip_progresso / 2;
            _bulge = 1 + sin(_fase_normalizada * pi) * 0.035; // "incha" no meio da virada, simulando a curva elástica do papel
        }

        var _matriz_antiga = matrix_get(matrix_world);
        var _matriz = matrix_build(_pagina_direita_x, _cy, 0, 0, 0, 0, _escala_x, _bulge, 1);
        matrix_set(matrix_world, _matriz);

        desenhar_pagina_do_livro(paginas[_indice_direita], 0, 0, _largura_pagina * 0.86, preview_altura * 0.86);

        matrix_set(matrix_world, _matriz_antiga);

        var _sombra_alpha = (1 - abs(_escala_x)) * 0.35;
        if (_sombra_alpha > 0) {
            draw_set_alpha(_sombra_alpha);
            draw_set_color(c_black);
            var _sombra_x = _cx + ((direcao_flip < 0) ? -_largura_pagina/2 : _largura_pagina/2);
            draw_rectangle(_sombra_x - _largura_pagina/2, _cy - preview_altura/2, _sombra_x + _largura_pagina/2, _cy + preview_altura/2, false);
            draw_set_alpha(1);
            draw_set_color(c_white);
        }

        // realce de luz onde o papel curva mais (perto do meio da virada)
        var _realce_alpha = (1 - abs(_escala_x)) * 0.16;
        if (_realce_alpha > 0) {
            draw_set_alpha(_realce_alpha);
            draw_set_color(c_white);
            var _realce_x = _cx + ((direcao_flip < 0) ? -_largura_pagina/2 : _largura_pagina/2);
            draw_rectangle(_realce_x - _largura_pagina/4, _cy - preview_altura/2, _realce_x + _largura_pagina/4, _cy + preview_altura/2, false);
            draw_set_alpha(1);
            draw_set_color(c_white);
        }
    }
    #endregion

    #region Controles de navegação
    var _btn_largura = 110;
    var _btn_altura = 40;
    var _btn_y = _cy + preview_altura/2 + 30;
    var _btn_prev_x = _cx - 150;
    var _btn_sumario_x = _cx;
    var _btn_next_x = _cx + 150;

    draw_set_color(c_dkgray);
    draw_rectangle(_btn_prev_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_prev_x + _btn_largura/2, _btn_y + _btn_altura/2, false);
    draw_rectangle(_btn_sumario_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_sumario_x + _btn_largura/2, _btn_y + _btn_altura/2, false);
    draw_rectangle(_btn_next_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_next_x + _btn_largura/2, _btn_y + _btn_altura/2, false);
    draw_set_color(c_white);
    draw_rectangle(_btn_prev_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_prev_x + _btn_largura/2, _btn_y + _btn_altura/2, true);
    draw_rectangle(_btn_sumario_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_sumario_x + _btn_largura/2, _btn_y + _btn_altura/2, true);
    draw_rectangle(_btn_next_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_next_x + _btn_largura/2, _btn_y + _btn_altura/2, true);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_btn_prev_x, _btn_y, "< Anterior");
    draw_text(_btn_sumario_x, _btn_y, "Sumário");
    draw_text(_btn_next_x, _btn_y, "Próxima >");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    #endregion
}

draw_set_font(-1);