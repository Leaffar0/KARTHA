// A arte é independente do sprite original, que preserva a área de colocação.
var _w=sprite_get_width(sprite_index)*abs(image_xscale);
var _h=sprite_get_height(sprite_index)*abs(image_yscale);
var _ox=(sprite_get_width(sprite_index)/2-sprite_get_xoffset(sprite_index))*image_xscale;
var _oy=(sprite_get_height(sprite_index)/2-sprite_get_yoffset(sprite_index))*image_yscale;
var _cx=x+_ox*dcos(image_angle)+_oy*dsin(image_angle);
var _cy=y-_ox*dsin(image_angle)+_oy*dcos(image_angle);
draw_set_alpha(image_alpha);
desenhar_slot_gravado(_cx,_cy,_w,_h,image_angle,make_color_rgb(46,49,146),ocupado,"recurso",gravura_hover,gravura_pressao);
draw_set_alpha(1);
