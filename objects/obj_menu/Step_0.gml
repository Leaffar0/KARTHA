tempo_menu += 0.03;

var offset_x = sin(tempo_menu) * 8;
var offset_y = cos(tempo_menu * 0.7) * 4;

var jogar_x = room_width/2 - 140 + offset_x;
var jogar_y = room_height - 120 + offset_y;

var sair_x = room_width/2 + 140 + offset_x;
var sair_y = room_height - 120 + offset_y;

if (mouse_check_button_pressed(mb_left))
{
    if (point_in_rectangle(
        mouse_x, mouse_y,
        jogar_x - 80, jogar_y - 25,
        jogar_x + 80, jogar_y + 25))
    {
        room_goto(rm_jogo);
    }

    if (point_in_rectangle(
        mouse_x, mouse_y,
        sair_x - 80, sair_y - 25,
        sair_x + 80, sair_y + 25))
    {
        game_end();
    }
}