#region Validação e fundo da prévia
if (!preview_ativo) exit;
if (array_length(paginas) == 0) exit;

var _pagina = paginas[pagina_atual];

var _gui_largura = display_get_gui_width();
var _gui_altura = display_get_gui_height();
var _cx = _gui_largura / 2;
var _cy = _gui_altura / 2;

draw_set_alpha(0.75);
draw_set_color(c_black);
draw_rectangle(0, 0, _gui_largura, _gui_altura, false);
draw_set_alpha(1);
#endregion

#region Livro aberto, texto e animação de virada
var _largura_pagina = preview_largura / 2;
var _escala_pagina_x = _largura_pagina / 90;
var _escala_pagina_y = preview_altura / 128;
var _pagina_esquerda_x = _cx - (_largura_pagina / 2);
var _pagina_direita_x = _cx + (_largura_pagina / 2);

// As duas folhas tornam o preview um livro aberto de verdade.
draw_sprite_ext(spr_livro_fundo, 0, _pagina_esquerda_x, _cy, _escala_pagina_x, _escala_pagina_y, 0, c_white, 1);
draw_sprite_ext(spr_livro_fundo, 0, _pagina_direita_x, _cy, _escala_pagina_x, _escala_pagina_y, 0, c_white, 1);

// Lombada e sombra fixa entre as páginas.
draw_set_color(c_black);
draw_set_alpha(0.28);
draw_rectangle(_cx - 5, _cy - preview_altura/2, _cx + 5, _cy + preview_altura/2, false);
draw_set_alpha(1);
draw_set_color(c_white);

draw_set_font(Fontenil);
draw_set_halign(fa_center);
draw_set_valign(fa_top);

// Página esquerda: mantém o contexto da regra atual sem competir com o texto.
draw_set_color(c_white);
draw_text_transformed(_pagina_esquerda_x, _cy - preview_altura * 0.35, "LIVRO DE REGRAS", 0.95, 0.95, 0);
draw_set_color(c_white);
draw_text_ext_transformed(_pagina_esquerda_x - _largura_pagina * 0, _cy - preview_altura * 0.15, "CAPÍTULO\n" + _pagina.titulo, -1, _largura_pagina * 0.80, 0.8, 0.8, 0);
draw_set_color(c_white);
draw_text_transformed(_pagina_esquerda_x, _cy + preview_altura * 0.29, "Parte " + string(_pagina.parte) + " de " + string(_pagina.partes), 0.92, 0.92, 0);

// A folha direita comprime até a lombada e se abre novamente com o próximo conteúdo.
var _escala_x = 1;
if (virando) {
    _escala_x = (flip_progresso < 1) ? (1 - flip_progresso) : (flip_progresso - 1);
}

var _matriz_antiga = matrix_get(matrix_world);
var _matriz = matrix_build(_pagina_direita_x, _cy, 0, 0, 0, 0, _escala_x, 1, 1);
matrix_set(matrix_world, _matriz);

var _margem = _largura_pagina * 0.14;
var _largura_texto = _largura_pagina - (_margem * 2);
var _altura_titulo_reservada = preview_altura * 0.15;
var _altura_disponivel = preview_altura - _altura_titulo_reservada - (preview_altura * 0.14);
var _escala_titulo = calcular_escala_texto_ajustada(_pagina.titulo, _largura_texto, _altura_titulo_reservada * 0.75, 0.72, 0.48);
var _escala_texto = calcular_escala_texto_ajustada(_pagina.corpo, _largura_texto, _altura_disponivel, 0.62, 0.46);

draw_set_color(c_white);
draw_text_transformed(0, -preview_altura/2 + preview_altura * 0.09, _pagina.titulo, _escala_titulo, _escala_titulo, 0);
draw_set_halign(fa_left);
draw_text_ext_transformed(-_largura_texto/2, -preview_altura/2 + _altura_titulo_reservada, _pagina.corpo, -1, _largura_texto / _escala_texto, _escala_texto, _escala_texto, 0);

matrix_set(matrix_world, _matriz_antiga);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(-1);
#endregion

#region Sombra e controles de navegação
// sombra da dobra durante a virada
var _sombra_alpha = (1 - _escala_x) * 0.35;
if (_sombra_alpha > 0) {
    draw_set_alpha(_sombra_alpha);
    draw_set_color(c_black);
    var _sombra_x = _cx + ((direcao_flip < 0) ? -_largura_pagina/2 : _largura_pagina/2);
    draw_rectangle(_sombra_x - _largura_pagina/2, _cy - preview_altura/2, _sombra_x + _largura_pagina/2, _cy + preview_altura/2, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

var _btn_largura = 110;
var _btn_altura = 40;
var _btn_y = _cy + preview_altura/2 + 30;
var _btn_prev_x = _cx - 80;
var _btn_next_x = _cx + 80;

draw_set_color(c_dkgray);
draw_rectangle(_btn_prev_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_prev_x + _btn_largura/2, _btn_y + _btn_altura/2, false);
draw_rectangle(_btn_next_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_next_x + _btn_largura/2, _btn_y + _btn_altura/2, false);
draw_set_color(c_white);
draw_rectangle(_btn_prev_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_prev_x + _btn_largura/2, _btn_y + _btn_altura/2, true);
draw_rectangle(_btn_next_x - _btn_largura/2, _btn_y - _btn_altura/2, _btn_next_x + _btn_largura/2, _btn_y + _btn_altura/2, true);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(_btn_prev_x, _btn_y, "< Anterior");
draw_text(_btn_next_x, _btn_y, "Próxima >");
draw_set_halign(fa_left);
draw_set_valign(fa_top);

#endregion
