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
if (instance_exists(obj_controlador) && obj_controlador.disputa_inicial_estado == "aguardando_deck") {
    var _pulso_inicio = 0.52 + sin(current_time / 130) * 0.025;
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    var _texto_compra_inicial = (obj_controlador.disputa_inicial_primeiro_escolhido == "jogador")
        ? "VOCÊ COMEÇA — CLIQUE PARA COMPRAR"
        : "INIMIGO COMEÇA — CLIQUE PARA COMPRAR";
    draw_set_color(c_black);
    draw_text_transformed(x + 2, y - sprite_height / 2 - 12 + 2, _texto_compra_inicial, _pulso_inicio, _pulso_inicio, 0);
    draw_set_color(c_yellow);
    draw_text_transformed(x, y - sprite_height / 2 - 12, _texto_compra_inicial, _pulso_inicio, _pulso_inicio, 0);
    draw_set_color(c_white);
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