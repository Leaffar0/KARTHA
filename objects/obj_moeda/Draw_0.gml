desenhar_sombra_mesa(x, y + altura_voo + sprite_get_height(sprite_index) * escala_moeda * 0.30,
    sprite_get_width(sprite_index) * escala_moeda, altura_voo / max(1, altura_maxima_moeda));
draw_sprite_ext(sprite_index, image_index, x, y, escala_moeda * moeda_escala_x, escala_moeda * moeda_escala_y, angulo_moeda, c_white, 1);

if (!girando && progresso_revelacao_moeda > 0) {
    draw_set_alpha(1 - sqr(1 - progresso_revelacao_moeda));
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    var _texto = (resultado_final == 1) ? "CARA" : "COROA";
    var _rotulo_y = y + sprite_get_height(sprite_index) * escala_moeda * 0.5 + 10;
    draw_set_color(c_black);
    draw_text(x + 1, _rotulo_y + 1, _texto);
    draw_set_color(c_white);
    draw_text(x, _rotulo_y, _texto);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}