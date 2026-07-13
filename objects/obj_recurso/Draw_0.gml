var _rotacao = virado ? 90 : 0;

draw_sprite_ext(sprite_index, image_index, x, y, 0.7, 0.7, _rotacao, c_white, 1);

var _texto = string_upper(tipo);
var _largura_maxima = sprite_width * 0.6;
var _largura_texto = string_width(_texto);
var _escala_texto = 0.7;

if (_largura_texto > _largura_maxima) {
    _escala_texto = _largura_maxima / _largura_texto;
}

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text_transformed(x, y, _texto, _escala_texto, _escala_texto, _rotacao);
draw_set_halign(fa_left);
draw_set_valign(fa_top);