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

#region Cálculo da animação de virar página
var _escala_flip_x = 1;
if (virando) {
    _escala_flip_x = (flip_progresso < 0.5)
        ? (1 - (flip_progresso / 0.5))
        : ((flip_progresso - 0.5) / 0.5);
    _escala_flip_x = clamp(_escala_flip_x, 0.015, 1);
}
var _sombra_flip_alpha = virando ? (1 - abs(_escala_flip_x - 0.5) * 2) * 0.35 : 0;

// qual lado fisicamente dobra: Próxima (direcao 1) -> direita | Anterior (direcao -1) -> esquerda
var _vira_direita = virando && (flip_direcao == 1);
var _vira_esquerda = virando && (flip_direcao == -1);
#endregion

#region As duas folhas do livro aberto (moldura primeiro, pergaminho por cima)
var _largura_pagina = preview_largura / 2;
var _overscan_pagina = 1.06;
var _escala_pagina_x = (_largura_pagina / sprite_get_width(spr_livro_pagina)) * _overscan_pagina;
var _escala_pagina_y = (preview_altura / sprite_get_height(spr_livro_pagina)) * _overscan_pagina;
var _pagina_esquerda_x = _cx - (_largura_pagina / 2);
var _pagina_direita_x = _cx + (_largura_pagina / 2);
var _spine_x = _cx;

// moldura desenhada ANTES -- fica embaixo
var _moldura_escala_x = (preview_largura / 0.8383) / sprite_get_width(spr_livro_moldura);
var _moldura_escala_y = (preview_altura / 0.85) / sprite_get_height(spr_livro_moldura);
draw_sprite_ext(spr_livro_moldura, 0, _cx, _cy, _moldura_escala_x, _moldura_escala_y, 0, c_white, 1);

// --- página esquerda: dobra a partir da lombada quando é ela que está virando ---
var _meia_largura_esquerda = (sprite_get_width(spr_livro_pagina) / 2) * abs(_escala_pagina_x) * (_vira_esquerda ? _escala_flip_x : 1);
var _centro_esquerda_atual = _vira_esquerda ? (_spine_x - _meia_largura_esquerda) : _pagina_esquerda_x;
var _escala_x_esquerda_atual = _escala_pagina_x * (_vira_esquerda ? _escala_flip_x : 1);
draw_sprite_ext(spr_livro_pagina, 0, _centro_esquerda_atual, _cy, _escala_x_esquerda_atual, _escala_pagina_y, 0, c_white, 1);

// --- página direita: dobra a partir da lombada quando é ela que está virando ---
var _meia_largura_direita = (sprite_get_width(spr_livro_pagina) / 2) * abs(_escala_pagina_x) * (_vira_direita ? _escala_flip_x : 1);
var _centro_direita_atual = _vira_direita ? (_spine_x + _meia_largura_direita) : _pagina_direita_x;
var _escala_x_direita_atual = -_escala_pagina_x * (_vira_direita ? _escala_flip_x : 1);
draw_sprite_ext(spr_livro_pagina, 0, _centro_direita_atual, _cy, _escala_x_direita_atual, _escala_pagina_y, 0, c_white, 1);
#endregion

var _cor_tinta = make_color_rgb(64, 44, 27);

draw_set_font(Fontenil);
draw_set_color(_cor_tinta);

if (mostrando_sumario) {
    #region Sumário clicável
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text_transformed(_cx - 190, _cy - preview_altura/2 + preview_altura * 0.06, "SUMÁRIO", 1, 1, 0);

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
            draw_set_alpha(0.16);
            draw_set_color(make_color_rgb(120, 40, 30));
            draw_rectangle(_x1, _y1, _x2, _y2, false);
            draw_set_alpha(1);
        }

        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_color(_sobre_item ? make_color_rgb(120, 40, 30) : _cor_tinta);
        var _titulo_item = sumario[i].titulo;
        var _escala_item = calcular_escala_texto_ajustada(_titulo_item, _largura_item - 16, _altura_item, 0.5, 0.32);
        draw_text_transformed(_x1 + 8, (_y1 + _y2)/2, _titulo_item, _escala_item, _escala_item, 0);
        draw_set_color(_cor_tinta);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    #endregion
} else {

#region Página esquerda (o texto some/aparece junto com a dobra, se for ela que está virando)
    if (pagina_atual < array_length(paginas)) {
        var _alpha_conteudo_esquerda = _vira_esquerda ? _escala_flip_x : 1;
        if (_alpha_conteudo_esquerda > 0.02) {
            draw_set_alpha(_alpha_conteudo_esquerda);
            desenhar_pagina_do_livro(paginas[pagina_atual], _pagina_esquerda_x, _cy, _largura_pagina * 0.86, preview_altura * 0.86);
            draw_set_alpha(1);
        }
    }
    #endregion

#region Página direita (o texto some/aparece junto com a dobra, se for ela que está virando)
var _indice_direita = pagina_atual + 1;
if (_indice_direita < array_length(paginas)) {
    var _alpha_conteudo_direita = _vira_direita ? _escala_flip_x : 1;
    if (_alpha_conteudo_direita > 0.02) {
        draw_set_alpha(_alpha_conteudo_direita);
        desenhar_pagina_do_livro(paginas[_indice_direita], _pagina_direita_x, _cy, _largura_pagina * 0.86, preview_altura * 0.86);
        draw_set_alpha(1);
    }
}
#endregion

#region Sombra de profundidade durante a virada (aparece do lado que está dobrando)
if (virando && _sombra_flip_alpha > 0) {
    draw_set_alpha(_sombra_flip_alpha);
    draw_set_color(c_black);
    if (_vira_direita) {
        draw_rectangle(_cx, _cy - preview_altura/2, _pagina_direita_x + _largura_pagina/2, _cy + preview_altura/2, false);
    } else {
        draw_rectangle(_pagina_esquerda_x - _largura_pagina/2, _cy - preview_altura/2, _cx, _cy + preview_altura/2, false);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}
#endregion

#region Controles de navegação (estilo selo de cera / etiqueta de couro)
    var _btn_largura = 110;
    var _btn_altura = 40;
    var _btn_y = _cy + preview_altura/2 + 30;
    var _btn_prev_x = _cx - 150;
    var _btn_sumario_x = _cx;
    var _btn_next_x = _cx + 150;

    var _cor_botao_fill = make_color_rgb(200, 172, 122);
    var _cor_botao_borda = make_color_rgb(80, 54, 32);

    draw_set_color(_cor_botao_fill);
    draw_roundrect(_btn_prev_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_prev_x + _btn_largura/2, _btn_y + _btn_altura/2, false);
    draw_roundrect(_btn_sumario_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_sumario_x + _btn_largura/2, _btn_y + _btn_altura/2, false);
    draw_roundrect(_btn_next_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_next_x + _btn_largura/2, _btn_y + _btn_altura/2, false);
    draw_set_color(_cor_botao_borda);
    draw_roundrect(_btn_prev_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_prev_x + _btn_largura/2, _btn_y + _btn_altura/2, true);
    draw_roundrect(_btn_sumario_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_sumario_x + _btn_largura/2, _btn_y + _btn_altura/2, true);
    draw_roundrect(_btn_next_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_next_x + _btn_largura/2, _btn_y + _btn_altura/2, true);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_cor_botao_borda);
    draw_text(_btn_prev_x, _btn_y, "< Anterior");
    draw_text(_btn_sumario_x, _btn_y, "Sumário");
    draw_text(_btn_next_x, _btn_y, "Próxima >");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    #endregion
}

draw_set_color(c_white);
draw_set_font(-1);