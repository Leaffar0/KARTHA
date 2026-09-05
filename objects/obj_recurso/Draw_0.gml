if (pulso_virada_timer > 0) {
    var _pag_p = pulso_virada_timer / pulso_virada_duracao;
    var _pag_cor = virado ? c_yellow : c_aqua;
    draw_set_alpha(_pag_p * 0.72); draw_set_color(_pag_cor);
    draw_circle(x, y, 14 + (1 - _pag_p) * 25, true);
    for (var _fa = 0; _fa < 6; _fa++) {
        var _fa_ang = _fa * 60 + pulso_virada_timer * 9;
        var _fa_raio = 12 + (1 - _pag_p) * 22;
        draw_circle(x + lengthdir_x(_fa_raio, _fa_ang), y + lengthdir_y(_fa_raio, _fa_ang), 2, false);
    }
    draw_set_alpha(1); draw_set_color(c_white);
}
draw_sprite_ext(sprite_index, image_index, x, y, escala_recurso * escala_animacao, escala_recurso * escala_animacao, rotacao_atual, c_white, alpha_animacao);

var _texto = string_upper(tipo);
var _largura_maxima = sprite_width * 0.6;
var _largura_texto = string_width(_texto);
var _escala_texto = 0.7;

if (_largura_texto > _largura_maxima) {
    _escala_texto = _largura_maxima / _largura_texto;
}

if (bloqueado_turnos > 0) {
    draw_set_alpha(0.58);
    draw_set_color(make_color_rgb(110, 45, 165));
    draw_circle(x, y, max(sprite_width, sprite_height) * 0.23, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(x, y, string(bloqueado_turnos), 0.45, 0.45, 0);
}
