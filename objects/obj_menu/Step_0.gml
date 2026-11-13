var _painel_atual=tipo_painel_menu(id);
if(_painel_atual!=painel_menu_anterior) {
    painel_menu_abertura=0;
    if(_painel_atual!="") tocar_som_variado("painel_abrir",0.22);
    else tocar_som_variado("painel_fechar",0.18);
    painel_menu_anterior=_painel_atual;
}
painel_menu_abertura=min(1,painel_menu_abertura+min(delta_time/1000000,0.05)*5);
tempo_menu += min(delta_time/1000000,0.05);
var _menu_livre=!(opcoes_abertas || modo_jogo_aberto || online_aberto || deck_aberto);
var _menu_sobre=-1;
for(var _i=0;_i<4;_i++) {
    var _mc=carta_menu_layout(_i,false,tempo_menu,room_width,room_height,menu_hover[_i]);
    var _ativo=_menu_livre && ponto_carta_menu(_mc,mouse_x,mouse_y);
    menu_hover[_i]=lerp(menu_hover[_i],_ativo?1:0,0.18);
    if(_ativo) _menu_sobre=_i;
}
if(_menu_sobre>=0 && _menu_sobre!=menu_hover_anterior) tocar_som_variado("pagina",0.10);
menu_hover_anterior=_menu_sobre;
// O SDK usa uma fila de eventos; ela precisa ser processada a cada frame.
if (colyseus_is_ready()) colyseus_process();
if (online_copiado_timer > 0) online_copiado_timer--;
if (_painel_atual!="" && painel_menu_abertura<0.85) exit;
if(opcoes_abertas && keyboard_check_pressed(vk_escape)) {opcoes_abertas=false;exit;}

if (online_aberto) {
    var _online_cx = room_width / 2;
    var _online_cy = centro_painel_menu(id);
    var _online_conectado = online_ativo();
    var _online_ocupado = global.online_status == "conectando" || global.online_status == "reconectando";
    if(_online_ocupado && !_online_conectado && mouse_check_button_pressed(mb_left)
        && point_in_rectangle(mouse_x,mouse_y,_online_cx-100,_online_cy+130,_online_cx+100,_online_cy+170)) {
        online_desconectar();
        exit;
    }

    if (keyboard_check_pressed(vk_escape)) {
        if (_online_conectado || _online_ocupado) online_desconectar();
        else online_aberto = false;
        keyboard_string = "";
        exit;
    }

    if (!_online_conectado && !_online_ocupado) {
        if (online_foco == 0) online_nome_input = string_copy(keyboard_string, 1, 24);
        else if (online_foco == 1) online_codigo_input = string_copy(keyboard_string, 1, 64);
        else if (online_foco == 2) online_servidor_input = string_copy(keyboard_string, 1, 200);
        if (mouse_check_button_pressed(mb_left)) {
            if (point_in_rectangle(mouse_x, mouse_y, _online_cx + 125, _online_cy - 55, _online_cx + 190, _online_cy - 19)) {
                online_foco = 1;
                var _codigo_clicado = online_colar_codigo_sala();
                if (_codigo_clicado != "") { online_codigo_input = _codigo_clicado; keyboard_string = online_codigo_input; global.online_erro = ""; }
                else global.online_erro = "Não há código para colar.";
            } else if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 190, _online_cy - 105, _online_cx + 190, _online_cy - 69)) {
                online_foco = 0; keyboard_string = online_nome_input;
            } else if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 190, _online_cy - 55, _online_cx + 190, _online_cy - 19)) {
                online_foco = 1; keyboard_string = online_codigo_input;
            } else if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 190, _online_cy - 5, _online_cx + 190, _online_cy + 31)) {
                online_foco = 2; keyboard_string = online_servidor_input;
            } else if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 190, _online_cy + 55, _online_cx - 10, _online_cy + 101)) {
                online_salvar_endpoint(online_servidor_input);
                online_conectar(true, "", online_nome_input, online_servidor_input);
            } else if (point_in_rectangle(mouse_x, mouse_y, _online_cx + 10, _online_cy + 55, _online_cx + 190, _online_cy + 101)) {
                if (string_length(string_trim(online_codigo_input)) > 0) {
                    online_salvar_endpoint(online_servidor_input);
                    online_conectar(false, online_codigo_input, online_nome_input, online_servidor_input);
                } else global.online_erro = "Digite o código da sala.";
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
    var _atalho_colar_codigo = keyboard_check(vk_control) && keyboard_check_pressed(ord("V"));
    var _atalho_inserir_codigo = keyboard_check(vk_shift) && keyboard_check_pressed(vk_insert);
    if (_atalho_colar_codigo || _atalho_inserir_codigo) {
        var _codigo_da_area = online_colar_codigo_sala();
        if (_codigo_da_area != "") {
            online_codigo_input = _codigo_da_area;
            keyboard_string = online_codigo_input;
            global.online_erro = "";
        } else global.online_erro = "Não há código para colar.";
    } else {
        online_codigo_input = string_copy(keyboard_string, 1, 64);
        keyboard_string = online_codigo_input;
    }

	} else if (online_foco == 2) {

	    if (keyboard_check_pressed(ord("V")) && keyboard_check(vk_control)) {

	        var _tem_clip = clipboard_has_text();

	        var _clip = clipboard_get_text();

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
                online_copiar_codigo_sala();
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



if (deck_aviso_timer > 0) deck_aviso_timer--;

if (deck_aberto) {
    var _deck_cx = room_width / 2;
    var _deck_inicio_y = centro_painel_menu(id) - 115;
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
        if (point_in_rectangle(mouse_x, mouse_y, _deck_cx - 220, centro_painel_menu(id) + 150, _deck_cx - 80, centro_painel_menu(id) + 185))
            deck_pagina = max(0, deck_pagina - 1);
        else if (point_in_rectangle(mouse_x, mouse_y, _deck_cx + 80, centro_painel_menu(id) + 150, _deck_cx + 220, centro_painel_menu(id) + 185))
            deck_pagina = min(_paginas_deck - 1, deck_pagina + 1);
        else if (point_in_rectangle(mouse_x, mouse_y, _deck_cx - 70, centro_painel_menu(id) + 150, _deck_cx + 70, centro_painel_menu(id) + 185)) {
            if (validar_contagens_baralho(deck_catalogo_menu, global.deck_contagens)) {
                salvar_contagens_baralho(global.deck_contagens);
                deck_aberto = false;
            } else deck_aviso_timer = 120;
        }
    }
    if (keyboard_check_pressed(vk_escape) || (mouse_check_button_pressed(mb_left)
        && point_in_rectangle(mouse_x,mouse_y,_deck_cx+260,centro_painel_menu(id)-195,_deck_cx+298,centro_painel_menu(id)-162))) {
        global.deck_contagens=array_create(array_length(deck_backup_menu),0);
        array_copy(global.deck_contagens,0,deck_backup_menu,0,array_length(deck_backup_menu));
        deck_aberto=false;
    }
    exit;
}

#endregion

if (modo_jogo_aberto) {
    var _cy=centro_painel_menu(id);
    if(keyboard_check_pressed(vk_escape)) modo_jogo_aberto=false;
    else if(mouse_check_button_pressed(mb_left)) {
        for(var _m=0;_m<3;_m++) {
            var _c=carta_modo_menu(_m,_cy);
            if(ponto_carta_menu(_c,mouse_x,mouse_y)) {
                tocar_som_variado("clique",0.20);
                if(_m<2) {global.modo_partida=_m==0?"ia":"local";room_goto(rm_jogo);}
                else {modo_jogo_aberto=false;online_aberto=true;online_foco=0;keyboard_string=online_nome_input;painel_menu_abertura=0;}
            }
        }
        if(point_in_rectangle(mouse_x,mouse_y,room_width/2-100,_cy+135,room_width/2+100,_cy+175)) modo_jogo_aberto=false;
    }
    exit;
}

#region Cliques do menu
if (_menu_livre && _menu_sobre>=0 && mouse_check_button_pressed(mb_left)) {
    tocar_som_variado("clique",0.20);
    switch(_menu_sobre) {
        case 0: modo_jogo_aberto=true; break;
        case 1: deck_backup_menu=array_create(array_length(global.deck_contagens),0);
            array_copy(deck_backup_menu,0,global.deck_contagens,0,array_length(global.deck_contagens));
            deck_aberto=true; break;
        case 2: opcoes_abertas=true; break;
        case 3: game_end(); break;
    }
    painel_menu_abertura=0;
    exit;
}

if (opcoes_abertas && mouse_check_button_pressed(mb_left)) {
    var _opcoes_x = room_width / 2;
    var _musica_y = centro_painel_menu(id) - 35;
    var _efeitos_y = centro_painel_menu(id) + 10;
    var _tela_y = centro_painel_menu(id) + 55;
    var _interface_y = centro_painel_menu(id) + 98;
    var _voltar_y = centro_painel_menu(id) + 190;
    if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 85, _efeitos_y - 18, _opcoes_x + 85, _efeitos_y + 18)) {
        global.canal_audio_opcoes=(global.canal_audio_opcoes+1) mod 4;
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 160, _musica_y - 18, _opcoes_x - 90, _musica_y + 18)) {
        global.volume_musica = clamp(global.volume_musica - 0.1, 0, 1);
        aplicar_config_audio();
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x + 90, _musica_y - 18, _opcoes_x + 160, _musica_y + 18)) {
        global.volume_musica = clamp(global.volume_musica + 0.1, 0, 1);
        aplicar_config_audio();
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 160, _efeitos_y - 18, _opcoes_x - 90, _efeitos_y + 18)) {
        ajustar_canal_audio(-0.1);
        aplicar_config_audio();
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x + 90, _efeitos_y - 18, _opcoes_x + 160, _efeitos_y + 18)) {
        ajustar_canal_audio(0.1);
        aplicar_config_audio();
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 160, _tela_y - 18, _opcoes_x + 160, _tela_y + 18)) {
        window_set_fullscreen(!window_get_fullscreen());
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 150, _interface_y - 18, _opcoes_x + 150, _interface_y + 18)) {
        alternar_tamanho_interface();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x-150, centro_painel_menu(id)+124, _opcoes_x+150, centro_painel_menu(id)+160)) {
        alternar_efeitos_visuais();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 150, _voltar_y - 22, _opcoes_x + 150, _voltar_y + 22)) {
        opcoes_abertas = false;
    }
}
#endregion
