draw_sprite_ext(sprite_index, image_index, x, y, escala_recurso * escala_animacao, escala_recurso * escala_animacao, rotacao_atual, c_white, alpha_animacao);

var _texto = string_upper(tipo);
var _largura_maxima = sprite_width * 0.6;
var _largura_texto = string_width(_texto);
var _escala_texto = 0.7;

if (_largura_texto > _largura_maxima) {
    _escala_texto = _largura_maxima / _largura_texto;
}
