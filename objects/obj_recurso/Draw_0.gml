var _pulso = 1 + 0.035 * sin(pulso_virada_timer / pulso_virada_duracao * pi);
desenhar_sombra_contato(sprite_index,image_index,x,y,escala_recurso*escala_animacao*_pulso,escala_recurso*escala_animacao*_pulso,rotacao_atual,0,alpha_animacao);
draw_sprite_ext(sprite_index, image_index, x, y, escala_recurso * escala_animacao * _pulso, escala_recurso * escala_animacao * _pulso, rotacao_atual, c_white, alpha_animacao);

if (quantidade > 1) {
    draw_set_halign(fa_right);
    draw_set_valign(fa_bottom);
    draw_set_color(c_white);
    draw_text_transformed(x + sprite_width * 0.28, y + sprite_height * 0.28, "×" + string(quantidade), 0.55, 0.55, 0);
}

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
