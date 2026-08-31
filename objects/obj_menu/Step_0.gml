#region Atualização da animação e posição dos botões
tempo_menu += 0.03;

var offset_x = sin(tempo_menu) * 8;
var offset_y = cos(tempo_menu * 0.7) * 4;

var jogar_x = room_width/2 + offset_x;
var jogar_y = room_height - 145 + offset_y;
var opcoes_y = room_height - 95 + offset_y;

var sair_x = room_width/2 + offset_x;
var sair_y = room_height - 45 + offset_y;
#endregion

#region Cliques do menu
if (!opcoes_abertas && mouse_check_button_pressed(mb_left))
{
    if (point_in_rectangle(
        mouse_x, mouse_y,
        jogar_x - 80, jogar_y - 25,
        jogar_x + 80, jogar_y + 25))
    {
        room_goto(rm_jogo);
    }

    if (point_in_rectangle(mouse_x, mouse_y, jogar_x - 90, opcoes_y - 22, jogar_x + 90, opcoes_y + 22)) opcoes_abertas = true;

    if (point_in_rectangle(
        mouse_x, mouse_y,
        sair_x - 80, sair_y - 25,
        sair_x + 80, sair_y + 25))
    {
        game_end();
    }
}

if (opcoes_abertas && mouse_check_button_pressed(mb_left)) {
    var _opcoes_x = room_width / 2;
    var _musica_y = room_height / 2 - 35;
    var _efeitos_y = room_height / 2 + 10;
    var _tela_y = room_height / 2 + 55;
    var _voltar_y = room_height / 2 + 110;
    if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 160, _musica_y - 18, _opcoes_x - 90, _musica_y + 18)) {
        global.volume_musica = clamp(global.volume_musica - 0.1, 0, 1);
        aplicar_config_audio();
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x + 90, _musica_y - 18, _opcoes_x + 160, _musica_y + 18)) {
        global.volume_musica = clamp(global.volume_musica + 0.1, 0, 1);
        aplicar_config_audio();
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 160, _efeitos_y - 18, _opcoes_x - 90, _efeitos_y + 18)) {
        global.volume_efeitos = clamp(global.volume_efeitos - 0.1, 0, 1);
        aplicar_config_audio();
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x + 90, _efeitos_y - 18, _opcoes_x + 160, _efeitos_y + 18)) {
        global.volume_efeitos = clamp(global.volume_efeitos + 0.1, 0, 1);
        aplicar_config_audio();
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 160, _tela_y - 18, _opcoes_x + 160, _tela_y + 18)) {
        window_set_fullscreen(!window_get_fullscreen());
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 150, _voltar_y - 22, _opcoes_x + 150, _voltar_y + 22)) {
        opcoes_abertas = false;
    }
}
#endregion
