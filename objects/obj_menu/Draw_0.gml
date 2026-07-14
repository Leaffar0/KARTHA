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
var jogar_x = room_width/2 - 140 + offset_x;
var jogar_y = room_height - 120 + offset_y;

var sair_x = room_width/2 + 140 + offset_x;
var sair_y = room_height - 120 + offset_y;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);

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