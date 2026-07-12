// desenha a carta virada 90 graus se estiver usada
var _rotacao = virado ? 90 : 0;

draw_sprite_ext(sprite_index, image_index, x, y, 1, 1, _rotacao, c_white, 1);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(x, y, string_upper(tipo));
draw_set_halign(fa_left);
draw_set_valign(fa_top);