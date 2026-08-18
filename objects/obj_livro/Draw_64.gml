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

#region Página e animação de virada
// achatamento horizontal durante a virada (só existe aqui, no livro aberto)
var _escala_x = 1;
if (virando) {
    _escala_x = (flip_progresso < 1) ? (1 - flip_progresso) : (flip_progresso - 1);
}

var _matriz_antiga = matrix_get(matrix_world);
var _matriz = matrix_build(_cx, _cy, 0, 0, 0, 0, _escala_x, 1, 1);
matrix_set(matrix_world, _matriz);

draw_sprite_ext(spr_livro_fundo, 0, 0, 0, preview_largura / 90, preview_altura / 128, 0, c_white, 1);

draw_set_font(Fontenil);

var _margem = preview_largura * 0.12;
var _largura_texto = preview_largura - (_margem * 2);
var _altura_titulo_reservada = preview_altura * 0.16;
var _altura_disponivel = preview_altura - _altura_titulo_reservada - (preview_altura * 0.10);

var _escala_titulo = 0.9;
var _escala_texto = calcular_escala_texto_ajustada(_pagina.corpo, _largura_texto, _altura_disponivel, 0.65, 0.3);

draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_top);

draw_text_transformed(0, -preview_altura/2 + preview_altura * 0.06, _pagina.titulo, _escala_titulo, _escala_titulo, 0);
draw_text_ext_transformed(0, -preview_altura/2 + _altura_titulo_reservada, _pagina.corpo, -1, _largura_texto / _escala_texto, _escala_texto, _escala_texto, 0);

draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(-1);

matrix_set(matrix_world, _matriz_antiga);
#endregion

#region Sombra e controles de navegação
// sombra da dobra durante a virada
var _sombra_alpha = (1 - _escala_x) * 0.35;
if (_sombra_alpha > 0) {
    draw_set_alpha(_sombra_alpha);
    draw_set_color(c_black);
    draw_rectangle(_cx - preview_largura/2, _cy - preview_altura/2, _cx + preview_largura/2, _cy + preview_altura/2, false);
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

draw_text(_cx - 30, _btn_y + 40, string(pagina_atual + 1) + " / " + string(array_length(paginas)));
draw_text(20, _gui_altura - 40, "Clique com o botão direito pra fechar");
#endregion
