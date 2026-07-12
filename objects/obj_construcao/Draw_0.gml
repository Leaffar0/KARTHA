draw_self();

var _largura_maxima = sprite_width * 0.85;
var _largura_texto = string_width(nome_construcao);
var _escala_texto = 1;

if (_largura_texto > _largura_maxima) {
    _escala_texto = _largura_maxima / _largura_texto;
}

draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_text_transformed(x, y - sprite_height/2 - 20, nome_construcao, _escala_texto, _escala_texto, 0);

draw_text(x, y + sprite_height/2 + 4, string(vida) + "/" + string(vida_maxima));
draw_set_halign(fa_left);
draw_set_valign(fa_top);