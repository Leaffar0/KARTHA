draw_self();

draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_text(x, y + (sprite_height * image_yscale / 2) + 10, "D" + string(tamanho_dado) + ": " + string(valor_final));
draw_set_halign(fa_left);
draw_set_valign(fa_top);
