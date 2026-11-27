if (os_type == os_linux) kartha_clipboard_poll();
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
var _clique = mouse_check_button_pressed(mb_left);
var _mouse_moveu = mouse_x != menu_mouse_x || mouse_y != menu_mouse_y;
if (_mouse_moveu || _clique) menu_por_teclado = false;
menu_mouse_x = mouse_x;
menu_mouse_y = mouse_y;
var _confirmar = false;
if ((_menu_livre || modo_jogo_aberto) && !transicao_sala_ativa()
    && (_menu_livre || painel_menu_abertura >= 0.85)) {
    if (modo_jogo_aberto && !menu_por_teclado) {
        for (var _i_modo = 0; _i_modo < 2; _i_modo++) {
            var _carta_modo = carta_modo_menu(_i_modo, centro_painel_menu(id));
            if (ponto_carta_menu(_carta_modo, mouse_x, mouse_y)) modo_foco = _i_modo;
        }
    }
    var _direcao = (keyboard_check_pressed(vk_right) || keyboard_check_pressed(vk_down))
        - (keyboard_check_pressed(vk_left) || keyboard_check_pressed(vk_up));
    _confirmar = keyboard_check_pressed(vk_enter) && !_clique;
    if (_direcao != 0 || _confirmar) menu_por_teclado = true;
    if (_menu_livre) menu_foco = clamp(menu_foco + _direcao, 0, 3);
    else modo_foco = clamp(modo_foco + _direcao, 0, 1);
}
var _menu_sobre=-1;
for(var _i=0;_i<4;_i++) {
    var _mc=carta_menu_layout(_i,false,tempo_menu,room_width,room_height,menu_hover[_i]);
    var _ativo = _menu_livre && (menu_por_teclado ? menu_foco == _i : ponto_carta_menu(_mc,mouse_x,mouse_y));
    if (_ativo) menu_foco = _i;
    menu_hover[_i]=lerp(menu_hover[_i],_ativo?1:0,0.18);
    if(_ativo) _menu_sobre=_i;
}
if(_menu_sobre>=0 && _menu_sobre!=menu_hover_anterior) tocar_som_variado("pagina",0.10);
menu_hover_anterior=_menu_sobre;
// O SDK usa uma fila de eventos; ela precisa ser processada a cada frame.
if (colyseus_is_ready()) {
    colyseus_process();
    online_verificar_sincronizacao();
}
if (transicao_sala_ativa()) exit;
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
        var _atalho_colar = (keyboard_check(vk_control) && keyboard_check_pressed(ord("V")))
            || (keyboard_check(vk_shift) && keyboard_check_pressed(vk_insert));
        if (!_atalho_colar || online_foco == 0) {
            if (online_foco == 0) online_nome_input = string_copy(keyboard_string, 1, 24);
            else if (online_foco == 1) online_codigo_input = string_copy(keyboard_string, 1, 64);
            else online_servidor_input = string_copy(keyboard_string, 1, 200);
        }
        var _botao_colar = false;
        if (mouse_check_button_pressed(mb_left)) {
            if (point_in_rectangle(mouse_x, mouse_y, _online_cx + 125, _online_cy - 55, _online_cx + 190, _online_cy - 19)) {
                online_foco = 1;
                _botao_colar = true;
            } else if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 190, _online_cy - 105, _online_cx + 190, _online_cy - 69)) {
                online_foco = 0;
            } else if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 190, _online_cy - 55, _online_cx + 190, _online_cy - 19)) {
                online_foco = 1;
            } else if (point_in_rectangle(mouse_x, mouse_y, _online_cx - 190, _online_cy - 5, _online_cx + 190, _online_cy + 31)) {
                online_foco = 2;
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
        }

        if (online_foco == 1 && (_botao_colar || _atalho_colar)) {
            var _codigo = online_colar_codigo_sala();
            if (_codigo != "") {
                online_codigo_input = _codigo;
                global.online_erro = "";
            } else global.online_erro = "Não há código para colar.";
        } else if (online_foco == 2 && _atalho_colar) {
            var _servidor = string_trim(online_ler_area_transferencia());
            if (_servidor != "") online_servidor_input = string_copy(_servidor, 1, 200);
        }
        keyboard_string = (online_foco == 0) ? online_nome_input
            : ((online_foco == 1) ? online_codigo_input : online_servidor_input);
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



if (deck_aberto) {
    var _deck_cx = room_width / 2;
    var _cy = centro_painel_menu(id);
    var _anterior = keyboard_check_pressed(vk_left) || (_clique && point_in_rectangle(mouse_x,mouse_y,_deck_cx-220,_cy+150,_deck_cx-80,_cy+185));
    var _proxima = keyboard_check_pressed(vk_right) || (_clique && point_in_rectangle(mouse_x,mouse_y,_deck_cx+80,_cy+150,_deck_cx+220,_cy+185));
    var _voltar = keyboard_check_pressed(vk_escape) || (_clique && (point_in_rectangle(mouse_x,mouse_y,_deck_cx-70,_cy+150,_deck_cx+70,_cy+185)
        || point_in_rectangle(mouse_x,mouse_y,_deck_cx+260,_cy-195,_deck_cx+298,_cy-162)));
    if (_voltar) {
        if (is_struct(deck_ficha)) deck_ficha = noone;
        else deck_aberto = false;
        exit;
    }
    if (is_struct(deck_ficha)) {
        deck_texto_pagina = clamp(deck_texto_pagina + _proxima - _anterior, 0, array_length(deck_textos)-1);
        exit;
    }
    var _total = array_length(deck_catalogo_menu);
    var _nova = clamp(deck_pagina + _proxima - _anterior, 0, ceil(_total/deck_por_pagina)-1);
    if (_nova != deck_pagina) deck_linha = 0;
    deck_pagina = _nova;
    var _linhas = min(deck_por_pagina, _total - deck_pagina * deck_por_pagina);
    deck_linha = clamp(deck_linha + keyboard_check_pressed(vk_down) - keyboard_check_pressed(vk_up), 0, _linhas-1);
    var _linha_mouse = floor((mouse_y - (_cy - 130)) / 31);
    var _sobre_linha = mouse_x >= _deck_cx-280 && mouse_x <= _deck_cx+280 && _linha_mouse >= 0 && _linha_mouse < _linhas;
    if (_sobre_linha && (_clique || _mouse_moveu)) deck_linha = _linha_mouse;
    if (_linhas > 0 && (keyboard_check_pressed(vk_enter) || (_clique && _sobre_linha))) {
        deck_ficha = { custo: noone, vida_pos_x: 0.10, vida_pos_y: 0.07 };
        aplicar_definicao_carta(deck_ficha, deck_catalogo_menu[deck_pagina * deck_por_pagina + deck_linha]);
        var _fonte = draw_get_font();
        draw_set_font(Fontenil);
        deck_textos = paginar_detalhes_carta(descricao_carta_preview(deck_ficha, true), 310, 242, 0.62);
        draw_set_font(_fonte);
        deck_texto_pagina = 0;
    }
    exit;
}

#endregion

if (modo_jogo_aberto) {
    var _cy=centro_painel_menu(id);
    if(keyboard_check_pressed(vk_escape)) modo_jogo_aberto=false;
    else if(_clique || _confirmar) {
        for(var _m=0;_m<2;_m++) {
            var _c=carta_modo_menu(_m,_cy);
            if (_confirmar ? _m == modo_foco : ponto_carta_menu(_c,mouse_x,mouse_y)) {
                tocar_som_variado("clique",0.20);
                if (_m == 0) {
                    global.modo_partida = "ia";
                    trocar_sala_suave(rm_jogo);
                } else {
                    modo_jogo_aberto = false;
                    online_aberto = true;
                    online_foco = 0;
                    keyboard_string = online_nome_input;
                    painel_menu_abertura = 0;
                }
                break;
            }
        }
        if(_clique && point_in_rectangle(mouse_x,mouse_y,room_width/2-100,_cy+135,room_width/2+100,_cy+175)) modo_jogo_aberto=false;
    }
    exit;
}

#region Cliques do menu
if (_menu_livre && _menu_sobre>=0 && (_clique || _confirmar)) {
    tocar_som_variado("clique",0.20);
    switch(_menu_sobre) {
        case 0: modo_jogo_aberto=true; modo_foco=0; break;
        case 1: deck_aberto=true; break;
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
    if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 85, _efeitos_y - 14, _opcoes_x + 85, _efeitos_y + 14)) {
        global.canal_audio_opcoes=(global.canal_audio_opcoes+1) mod 4;
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 147, _musica_y - 14, _opcoes_x - 103, _musica_y + 14)) {
        global.volume_musica = clamp(global.volume_musica - 0.1, 0, 1);
        aplicar_config_audio();
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x + 103, _musica_y - 14, _opcoes_x + 147, _musica_y + 14)) {
        global.volume_musica = clamp(global.volume_musica + 0.1, 0, 1);
        aplicar_config_audio();
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 147, _efeitos_y - 14, _opcoes_x - 103, _efeitos_y + 14)) {
        ajustar_canal_audio(-0.1);
        aplicar_config_audio();
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x + 103, _efeitos_y - 14, _opcoes_x + 147, _efeitos_y + 14)) {
        ajustar_canal_audio(0.1);
        aplicar_config_audio();
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 130, _tela_y - 14, _opcoes_x + 130, _tela_y + 14)) {
        window_set_fullscreen(!window_get_fullscreen());
        salvar_configuracoes();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 130, _interface_y - 14, _opcoes_x + 130, _interface_y + 14)) {
        alternar_tamanho_interface();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x-130, centro_painel_menu(id)+128, _opcoes_x+130, centro_painel_menu(id)+156)) {
        alternar_efeitos_visuais();
    } else if (point_in_rectangle(mouse_x, mouse_y, _opcoes_x - 110, _voltar_y - 14, _opcoes_x + 110, _voltar_y + 14)) {
        opcoes_abertas = false;
    }
}
#endregion
