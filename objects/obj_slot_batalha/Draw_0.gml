// A arte é independente do sprite original, que preserva a área de colocação.
var _w=sprite_get_width(sprite_index)*abs(image_xscale);
var _h=sprite_get_height(sprite_index)*abs(image_yscale);
var _ox=(sprite_get_width(sprite_index)/2-sprite_get_xoffset(sprite_index))*image_xscale;
var _oy=(sprite_get_height(sprite_index)/2-sprite_get_yoffset(sprite_index))*image_yscale;
var _cx=x+_ox*dcos(image_angle)+_oy*dsin(image_angle);
var _cy=y-_ox*dsin(image_angle)+_oy*dcos(image_angle);
draw_set_alpha(image_alpha);
desenhar_slot_gravado(_cx,_cy,_w,_h,image_angle,make_color_rgb(238,28,36),ocupado,"tropa",gravura_hover,gravura_pressao);
if (gravura_disponivel > 0.01) {
    // Dois cantos opostos crescem até se encontrar nos outros dois cantos.
    var _traco = gravura_disponivel * lerp(0.14, 1, gravura_hover);
    draw_set_color(make_color_rgb(227, 216, 194));
    draw_set_alpha(image_alpha * gravura_disponivel * lerp(0.65, 0.94, gravura_hover));
    for (var _lado = -1; _lado <= 1; _lado += 2) {
        var _ex = _lado * 24;
        var _ey = _lado * 32;
        slot_traco(_cx, _cy, _w/48, _h/64, image_angle, _ex, _ey, lerp(_ex, -_ex, _traco), _ey);
        slot_traco(_cx, _cy, _w/48, _h/64, image_angle, _ex, _ey, _ex, lerp(_ey, -_ey, _traco));
    }
    draw_set_color(c_white);
}
draw_set_alpha(1);
