var _escala_entrada = 1;
if (entrada_visual_timer > 0) {
    var _entrada_p = 1 - entrada_visual_timer / entrada_visual_duracao;
    _escala_entrada = 0.55 + (1 - power(1 - _entrada_p, 3)) * 0.45 + sin(_entrada_p * pi) * 0.09;
    draw_set_alpha((1 - _entrada_p) * 0.65);
    draw_set_color(dono == "jogador" ? c_aqua : c_red);
    draw_circle(x, y + sprite_height * 0.35, 12 + _entrada_p * 35, true);
    draw_set_alpha(1);
    draw_set_color(c_white);
    entrada_visual_timer--;
}

// Quando a carta possui arte, ela própria vira o visual da construção no campo.
// escala_visual_base também é aplicada ao image_xscale para manter a área de clique correta.
var _escala_desenho = escala_visual_base * _escala_entrada;
draw_sprite_ext(sprite_index, image_index, x, y, _escala_desenho, _escala_desenho, 0, c_white, 1);

// Sprites genéricos ainda precisam do nome; artes completas já trazem o título impresso.
if (!usa_sprite_carta) {
    var _largura_maxima = sprite_width;
    var _largura_texto = string_width(nome_construcao);
    var _escala_texto = (_largura_texto > _largura_maxima) ? (_largura_maxima / _largura_texto) : 1;
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text_transformed(x, y - sprite_height / 2 - 20, nome_construcao, _escala_texto, _escala_texto, 0);
}

// Mesmo padrão das tropas: mostra apenas a vida atual sobre o canto superior esquerdo.
var _largura_visual = sprite_get_width(sprite_index) * escala_visual_base * _escala_entrada;
var _altura_visual = sprite_get_height(sprite_index) * escala_visual_base * _escala_entrada;
var _vida_x = x - _largura_visual / 2 + _largura_visual * vida_pos_x;
var _vida_y = y - _altura_visual / 2 + _altura_visual * vida_pos_y;
var _escala_vida = usa_sprite_carta ? max(0.28, escala_visual_base * 1.55) : 0.65;

draw_set_font(Fontenil);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
// Uma sombra curta mantém o número legível sem criar uma barra de vida.
draw_set_color(usa_sprite_carta ? c_white : c_black);
draw_text_transformed(_vida_x + 1, _vida_y + 1, string(vida), _escala_vida, _escala_vida, 0);
draw_set_color(usa_sprite_carta ? c_black : c_white);
draw_text_transformed(_vida_x, _vida_y, string(vida), _escala_vida, _escala_vida, 0);

draw_set_font(-1);
draw_set_color(c_white);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
