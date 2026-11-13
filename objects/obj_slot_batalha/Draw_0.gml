// A arte é independente do sprite original, que preserva a área de colocação.
var _w=sprite_get_width(sprite_index)*abs(image_xscale);
var _h=sprite_get_height(sprite_index)*abs(image_yscale);
var _sx=_w/sprite_get_width(spr_slot_moldura_v2);
var _sy=_h/sprite_get_height(spr_slot_moldura_v2);
var _ox=(sprite_get_width(sprite_index)/2-sprite_get_xoffset(sprite_index))*image_xscale;
var _oy=(sprite_get_height(sprite_index)/2-sprite_get_yoffset(sprite_index))*image_yscale;
var _cx=x+_ox*dcos(image_angle)+_oy*dsin(image_angle);
var _cy=y-_ox*dsin(image_angle)+_oy*dcos(image_angle);
draw_sprite_ext(spr_slot_moldura_v2,0,_cx,_cy,_sx,_sy,image_angle,image_blend,image_alpha*(ocupado?0.70:1.0));
