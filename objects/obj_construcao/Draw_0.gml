var _escala_construcao = 1;
if (entrada_visual_timer > 0) {
    var _entrada_p = 1 - entrada_visual_timer / entrada_visual_duracao;
    _escala_construcao = 0.55 + (1 - power(1 - _entrada_p, 3)) * 0.45 + sin(_entrada_p * pi) * 0.09;
    draw_set_alpha((1 - _entrada_p) * 0.65); draw_set_color(dono == "jogador" ? c_aqua : c_red);
    draw_circle(x, y + sprite_height * 0.35, 12 + _entrada_p * 35, true);
    draw_set_alpha(1); draw_set_color(c_white);
    entrada_visual_timer--;
}
draw_sprite_ext(sprite_index, image_index, x, y, _escala_construcao, _escala_construcao, 0, c_white, 1);

var _largura_maxima = sprite_width * 1;
var _largura_texto = string_width(nome_construcao);
var _escala_texto = 1;

if (_largura_texto > _largura_maxima) {
    _escala_texto = _largura_maxima / _largura_texto;
}

draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_text_transformed(x, y - sprite_height/2.5 - 20, nome_construcao, _escala_texto, _escala_texto, 0);

draw_text(x, y + sprite_height/2 + 2, string(vida) + "/" + string(vida_maxima));
draw_set_halign(fa_left);
draw_set_valign(fa_top);
