var _largura = 1000;
var _altura = 560;

var _escala_x = _largura / sprite_get_width(sprite_index);
var _escala_y = _altura / sprite_get_height(sprite_index);

var _escala = min(_escala_x, _escala_y);

draw_sprite_ext(
    sprite_index,
    0,
    room_width / 2,
    room_height / 2,
    _escala,
    _escala,
    0,
    c_white,
    1
);