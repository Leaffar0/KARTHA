// O SDK usa uma fila de eventos; ela precisa ser processada a cada frame.
if (colyseus_is_ready()) colyseus_process();
if (online_copiado_timer > 0) online_copiado_timer--;

if (online_aberto) {
    var _online_cx = room_width / 2;
    var _online_cy = room_height / 2;
    var _online_conectado = online_ativo();
    var _online_ocupado = global.online_status == "conectando" || global.online_status == "reconectando";

    if (keyboard_check_pressed(vk_escape)) {
        if (_online_conectado || _online_ocupado) online_desconectar();
        else online_aberto = false;
        keyboard_string = "";
        exit;
    }

    if (!_online_conectado && !_online_ocupado) {
        if (mouse_check_button_pressed(mb_left)) {
            if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 190, _online_cy - 105, _online_cx + 190, _online_cy - 69)) {
                online_foco = 0; keyboard_string = online_nome_input;
            } else if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 190, _online_cy - 55, _online_cx + 190, _online_cy - 19)) {
                online_foco = 1; keyboard_string = online_codigo_input;
            } else if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 190, _online_cy - 5, _online_cx + 190, _online_cy + 31)) {
                online_foco = 2; keyboard_string = online_servidor_input;
            } else if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 190, _online_cy + 55, _online_cx - 10, _online_cy + 101)) {
                online_conectar(true, "", online_nome_input, online_servidor_input);
            } else if (point_in_rectangle(mouse_x, mouse_y, _online_cx + 10, _online_cy + 55, _online_cx + 190, _online_cy + 101)) {
                if (string_length(string_trim(online_codigo_input)) > 0)
                    online_conectar(false, online_codigo_input, online_nome_input, online_servidor_input);
                else global.online_erro = "Digite o código da sala.";
            } else if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 100, _online_cy + 130, _online_cx + 100, _online_cy + 170)) {
                online_aberto = false;
            }
        }

        if (keyboard_check_pressed(vk_tab)) {
            online_foco = (online_foco + 1) mod 3;
            keyboard_string = (online_foco == 0) ? online_nome_input
                : ((online_foco == 1) ? online_codigo_input : online_servidor_input);
        }

       if (online_foco == 0) {
    online_nome_input = string_copy(keyboard_string, 1, 24);
    keyboard_string = online_nome_input;

} else if (online_foco == 1) {
    online_codigo_input = string_copy(keyboard_string, 1, 64);
    keyboard_string = online_codigo_input;

	} else if (online_foco == 2) {

	    if (keyboard_check_pressed(ord("V")) && keyboard_check(vk_control)) {

	        show_debug_message("CTRL+V detectado");

	        var _tem_clip = clipboard_has_text();
	        show_debug_message("clipboard_has_text = " + string(_tem_clip));

	        var _clip = clipboard_get_text();
	        show_debug_message("clipboard_get_text = [" + _clip + "]");

	        if (_clip != "") {
	            online_servidor_input = string_copy(_clip, 1, 200);
	            keyboard_string = online_servidor_input;
	        }

	    } else {
	        online_servidor_input = string_copy(keyboard_string, 1, 200);
	        keyboard_string = online_servidor_input;
	    }
	}
    } else if (_online_conectado) {
        if (mouse_check_button_pressed(mb_left)) {
            if (global.online_fase == "waiting"
                && point_in_rectangle(mouse_x, mouse_y, _online_cx - 105, _online_cy + 35, _online_cx + 105, _online_cy + 75)) {
                clipboard_set_text(global.net_room_id);
                online_copiado_timer = 90;
            } else if (global.online_fase == "initiative"
                && global.online_assento >= 0 && global.online_iniciativa[global.online_assento] < 0
                && point_in_rectangle(mouse_x, mouse_y, _online_cx - 130, _online_cy + 45, _online_cx + 130, _online_cy + 95)) {
                online_rolar_iniciativa();
            } else if (global.online_fase == "choose_first"
                && global.online_vencedor_iniciativa == global.online_assento) {
                if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 205, _online_cy + 45, _online_cx - 5, _online_cy + 95))
                    online_escolher_primeiro(global.online_assento);
                else if (point_in_rectangle(mouse_x, mouse_y, _online_cx + 5, _online_cy + 45, _online_cx + 205, _online_cy + 95))
                    online_escolher_primeiro(1 - global.online_assento);
            }
            if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 100, _online_cy + 140, _online_cx + 100, _online_cy + 178)) {
                online_desconectar();
            }
        }
    }
    exit;
}

#region Atualização da animação e posição dos botões
tempo_menu += 0.03;

var offset_x = sin(tempo_menu) * 8;
var offset_y = cos(tempo_menu * 0.7) * 4;

var jogar_x = room_width/2 + offset_x;
var jogar_y = room_height - 145 + offset_y;
var opcoes_y = room_height - 95 + offset_y;
var baralho_y = room_height - 195 + offset_y;

if (deck_aviso_timer > 0) deck_aviso_timer--;

if (deck_aberto) {
    var _deck_cx = room_width / 2;
    var _deck_inicio_y = room_height / 2 - 115;
    var _deck_inicio = deck_pagina * deck_por_pagina;
    if (mouse_check_button_pressed(mb_left)) {
        for (var _dr = 0; _dr < deck_por_pagina; _dr++) {
            var _deck_indice = _deck_inicio + _dr;
            if (_deck_indice >= array_length(deck_catalogo_menu)) break;
            var _deck_y = _deck_inicio_y + _dr * 31;
            if (point_in_rectangle(mouse_x, mouse_y, _deck_cx + 105, _deck_y - 12, _deck_cx + 145, _deck_y + 12))
                global.deck_contagens[_deck_indice] = max(0, global.deck_contagens[_deck_indice] - 1);
            else if (point_in_rectangle(mouse_x, mouse_y, _deck_cx + 190, _deck_y - 12, _deck_cx + 230, _deck_y + 12))
                global.deck_contagens[_deck_indice] += 1;
        }
        var _paginas_deck = ceil(array_length(deck_catalogo_menu) / deck_por_pagina);
        if (point_in_rectangle(mouse_x, mouse_y, _deck_cx - 220, room_height / 2 + 150, _deck_cx - 80, room_height / 2 + 185))
            deck_pagina = max(0, deck_pagina - 1);
        else if (point_in_rectangle(mouse_x, mouse_y, _deck_cx + 80, room_height / 2 + 150, _deck_cx + 220, room_height / 2 + 185))
            deck_pagina = min(_paginas_deck - 1, deck_pagina + 1);
        else if (point_in_rectangle(mouse_x, mouse_y, _deck_cx - 70, room_height / 2 + 150, _deck_cx + 70, room_height / 2 + 185)) {
            if (validar_contagens_baralho(deck_catalogo_menu, global.deck_contagens)) {
                salvar_contagens_baralho(global.deck_contagens);
                deck_aberto = false;
            } else deck_aviso_timer = 120;
        }
    }
    if (keyboard_check_pressed(vk_escape)) {
        if (validar_contagens_baralho(deck_catalogo_menu, global.deck_contagens)) {
            salvar_contagens_baralho(global.deck_contagens);
            deck_aberto = false;
        } else deck_aviso_timer = 120;
    }
    exit;
}

var sair_x = room_width/2 + offset_x;
var sair_y = room_height - 45 + offset_y;
#endregion

if (modo_jogo_aberto) {
    var _modo_cx = room_width / 2;
    var _modo_cy = room_height / 2;
    if (keyboard_check_pressed(vk_escape)) {
        modo_jogo_aberto = false;
    } else if (mouse_check_button_pressed(mb_left)) {
        if (point_in_rectangle(mouse_x, mouse_y,
            _modo_cx - 170, _modo_cy - 42, _modo_cx + 170, _modo_cy + 2)) {
            global.modo_partida = "ia";
            room_goto(rm_jogo);
        } else if (point_in_rectangle(mouse_x, mouse_y,
            _modo_cx - 170, _modo_cy + 15, _modo_cx + 170, _modo_cy + 59)) {
            global.modo_partida = "local";
            room_goto(rm_jogo);
        } else if (point_in_rectangle(mouse_x, mouse_y,
            _modo_cx - 170, _modo_cy + 72, _modo_cx + 170, _modo_cy + 116)) {
            modo_jogo_aberto = false;
            online_aberto = true;
            online_foco = 0;
            keyboard_string = online_nome_input;
        } else if (point_in_rectangle(mouse_x, mouse_y,
            _modo_cx - 100, _modo_cy + 135, _modo_cx + 100, _modo_cy + 175)) {
            modo_jogo_aberto = false;
        }
    }
    exit;
}

#region Cliques do menu
if (!opcoes_abertas && mouse_check_button_pressed(mb_left))
{
    if (point_in_rectangle(mouse_x, mouse_y, jogar_x - 100, baralho_y - 22, jogar_x + 100, baralho_y + 22)) {
        deck_aberto = true;
    } else if (point_in_rectangle(
        mouse_x, mouse_y,
        jogar_x - 80, jogar_y - 25,
        jogar_x + 80, jogar_y + 25))
    {
        modo_jogo_aberto = true;
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