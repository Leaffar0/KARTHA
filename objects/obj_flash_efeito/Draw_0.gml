var _alpha_flash = (vida_flash / vida_flash_max) * 0.35; // discreto: pico de 35% de opacidade
draw_set_alpha(_alpha_flash);
draw_set_color(c_white);
draw_circle(x, y, tamanho_flash, false);
draw_set_alpha(1);