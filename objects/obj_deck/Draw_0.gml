// desenha várias cópias levemente deslocadas pra simular uma pilha
var _max_visivel = min(quantidade_cartas, 20); // não desenha mais que 5 pra não pesar

for (var i = 0; i < _max_visivel; i++) {
    draw_sprite(sprite_index, image_index, x - i, y - i);
}

// mostra quantas cartas restam
draw_set_halign(fa_center);
draw_set_valign(fa_top);


draw_set_font(fnt_botao)
draw_set_font(-1)
draw_text(x, y + sprite_height/2 + 8, string(quantidade_cartas) + " cartas");
draw_set_halign(fa_left);
draw_set_valign(fa_top);