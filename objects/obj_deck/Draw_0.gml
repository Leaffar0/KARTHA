#region Pilha visual de cartas
draw_set_font(Fontenil);
var _max_visivel = min(quantidade_cartas, 20);

for (var i = 0; i < _max_visivel; i++) {
    draw_sprite_ext(
        sprite_index,
        image_index,
        x - i,
        y - i + offset_y_bob,
        escala_deck_x,
        escala_deck_y,
        0,
        c_white,
        1
    );
}
#endregion

#region Contador de cartas restantes
draw_set_halign(fa_center);
draw_set_valign(fa_top);

draw_set_font(fnt_botao)
draw_text(x, y + sprite_height/2 + 8 + offset_y_bob, string(array_length(obj_controlador.monte)) + " cartas");
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(-1)
#endregion