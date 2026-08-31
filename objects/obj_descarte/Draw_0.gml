var _hover = point_in_rectangle(mouse_x, mouse_y, x, y, x + sprite_width, y + sprite_height);
var _carta_sobre_descarte = false;
for (var i = 0; i < instance_number(obj_carta); i++) {
    var _carta = instance_find(obj_carta, i);
    if (_carta.arrastando && _carta.dono == "jogador"
        && point_in_rectangle(_carta.x, _carta.y, x - 20, y - 20, x + sprite_width + 20, y + sprite_height + 20)) {
        _carta_sobre_descarte = true;
        break;
    }
}

var _ativo = _hover || _carta_sobre_descarte;
var _escala = _ativo ? 1.08 : 1;
var _pulso_alpha = _ativo ? (0.45 + sin(pulso) * 0.12) : 0;

draw_set_alpha(_pulso_alpha);
draw_set_color(c_yellow);
draw_rectangle(x - 3, y - 3, x + sprite_width + 3, y + sprite_height + 3, false);
draw_set_alpha(1);
draw_set_color(c_white);
draw_sprite_ext(sprite_index, image_index, x, y, _escala, _escala, 0, c_white, 1);

draw_set_font(fnt_botao);
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_text(x + sprite_width / 2, y + sprite_height + 6, "DESCARTE");
draw_text(x + sprite_width / 2, y + sprite_height + 22, string(array_length(obj_controlador.descarte_jogador)) + " cartas");
if (_carta_sobre_descarte) {
    draw_set_color(c_yellow);
    draw_text(x + sprite_width / 2, y - 20, "SOLTE PARA DESCARTAR");
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_font(-1);
