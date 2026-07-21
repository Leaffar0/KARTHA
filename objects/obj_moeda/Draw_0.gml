draw_sprite_ext(sprite_index, image_index, x, y, escala_moeda, escala_moeda, 0, c_white, 1);

if (!girando) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    var _texto = (resultado_final == 1) ? "CARA" : "COROA";
    draw_text(x, y + (sprite_height * escala_moeda)/2 + 10, _texto);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}