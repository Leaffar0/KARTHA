#region Movimento do fundo e posicionamento dos botões
var offset_x = sin(tempo_menu) * 8;
var offset_y = cos(tempo_menu * 0.7) * 4;

// Fundo inteiro se mexendo
draw_sprite_stretched(
    spr_menu,
    0,
    offset_x - 20,
    offset_y - 20,
    room_width + 40,
    room_height + 40
);

// Botões acompanham o movimento
var jogar_x = room_width/2 + offset_x;
var jogar_y = room_height - 145 + offset_y;
var opcoes_y = room_height - 95 + offset_y;

var sair_x = room_width/2 + offset_x;
var sair_y = room_height - 45 + offset_y;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(Fontenil);
#endregion

#region Botão Jogar
// Hover JOGAR
if (point_in_rectangle(
    mouse_x, mouse_y,
    jogar_x - 80, jogar_y - 25,
    jogar_x + 80, jogar_y + 25))
{
    draw_text(jogar_x, jogar_y, "> JOGAR <");
}
else
{
    draw_text(jogar_x, jogar_y, "JOGAR");
}
#endregion

#region Botão Opções
if (point_in_rectangle(mouse_x, mouse_y, jogar_x - 90, opcoes_y - 22, jogar_x + 90, opcoes_y + 22)) {
    draw_text(jogar_x, opcoes_y, "> OPÇÕES <");
} else {
    draw_text(jogar_x, opcoes_y, "OPÇÕES");
}
#endregion

#region Botão Sair
// Hover SAIR
if (point_in_rectangle(
    mouse_x, mouse_y,
    sair_x - 80, sair_y - 25,
    sair_x + 80, sair_y + 25))
{
    draw_text(sair_x, sair_y, "> SAIR <");
}
else
{
    draw_text(sair_x, sair_y, "SAIR");
}
#endregion

#region Painel de opções
if (opcoes_abertas) {
    var _opcoes_x = room_width / 2;
    var _opcoes_y = room_height / 2;
    var _musica_y = _opcoes_y - 35;
    var _efeitos_y = _opcoes_y + 10;
    var _tela_y = _opcoes_y + 55;
    var _voltar_y = _opcoes_y + 110;
    draw_set_alpha(0.8);
    draw_set_color(c_black);
    draw_rectangle(_opcoes_x - 210, _opcoes_y - 105, _opcoes_x + 210, _opcoes_y + 150, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_rectangle(_opcoes_x - 210, _opcoes_y - 105, _opcoes_x + 210, _opcoes_y + 150, true);
    draw_text(_opcoes_x, _opcoes_y - 65, "OPÇÕES");
    draw_text(_opcoes_x - 125, _musica_y, "<");
    draw_text(_opcoes_x + 125, _musica_y, ">");
    draw_text(_opcoes_x, _musica_y, "MÚSICA  " + string(round(global.volume_musica * 100)) + "%");
    draw_text(_opcoes_x - 125, _efeitos_y, "<");
    draw_text(_opcoes_x + 125, _efeitos_y, ">");
    draw_text(_opcoes_x, _efeitos_y, "EFEITOS  " + string(round(global.volume_efeitos * 100)) + "%");
    draw_set_color(c_gray);
    draw_text(_opcoes_x, _tela_y, "TELA CHEIA: " + (window_get_fullscreen() ? "SIM" : "NÃO"));
    draw_set_color(c_white);
    draw_text(_opcoes_x, _voltar_y, "VOLTAR");
}
#endregion

draw_set_font(-1);
