// =============================================================================
// obj_controlador — Step Event
// =============================================================================

#region Watchdog de segurança
// Se rolagens_pendentes ficar travado (algum dado/moeda não decrementou por bug),
// força o reset depois de 10 segundos pra nunca deixar o "Passar Turno" travado pra sempre.
if (rolagens_pendentes > 0) {
    rolagens_pendentes_timer += 1;
    if (rolagens_pendentes_timer > 600) {
        show_debug_message("AVISO: rolagens_pendentes travado em " + string(rolagens_pendentes) + ", forçando reset.");
        rolagens_pendentes = 0;
        rolagens_pendentes_timer = 0;
    }
} else {
    rolagens_pendentes_timer = 0;
}
#endregion

atualizar_animacao_dano_castelo();

// Opção vinda da tela inicial: abre o livro assim que a instância da room existir.
if (abrir_livro_pendente && instance_exists(obj_livro)) {
    obj_livro.preview_ativo = true;
    obj_livro.mostrando_sumario = true;
    abrir_livro_pendente = false;
    exit;
}

// Compatibilidade com partidas abertas antes do botão de Histórico existir.
if (!variable_instance_exists(id, "historico_aberto")) historico_aberto = false;
if (!variable_instance_exists(id, "hud_deslocamento_esquerda")) hud_deslocamento_esquerda = 160;
if (!variable_instance_exists(id, "hud_deslocamento_direita")) hud_deslocamento_direita = 180;

// Abas do HUD: só se revelam quando o mouse se aproxima do respectivo canto.
var _hud_mouse_x = device_mouse_x_to_gui(0);
var _hud_mouse_y = device_mouse_y_to_gui(0);
var _hud_largura_animacao = display_get_gui_width();
var _mostrar_esquerda = historico_aberto || (_hud_mouse_x < 215 && _hud_mouse_y >= 190 && _hud_mouse_y <= 270);
var _mostrar_direita = cemiterio_aberto || (_hud_mouse_x > _hud_largura_animacao - 220 && _hud_mouse_y >= 10 && _hud_mouse_y <= 210);
var _alvo_esquerda = _mostrar_esquerda ? 0 : 160;
var _alvo_direita = _mostrar_direita ? 0 : 180;
hud_deslocamento_esquerda += (_alvo_esquerda - hud_deslocamento_esquerda) * 0.22;
hud_deslocamento_direita += (_alvo_direita - hud_deslocamento_direita) * 0.22;

// Tela final: bloqueia a partida e permite recomeçar sem fechar o jogo.
if (vida_jogador <= 0 || vida_inimigo <= 0) {
    var _fim_gui_x = device_mouse_x_to_gui(0);
    var _fim_gui_y = device_mouse_y_to_gui(0);
    var _fim_centro_x = display_get_gui_width() / 2;
    var _fim_centro_y = display_get_gui_height() / 2;
    var _clicou_reiniciar = point_in_rectangle(_fim_gui_x, _fim_gui_y, _fim_centro_x - 120, _fim_centro_y + 85, _fim_centro_x + 120, _fim_centro_y + 130);
    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("R")) || (mouse_check_button_pressed(mb_left) && _clicou_reiniciar)) {
        room_restart();
    }
    exit;
}

// Tutorial opcional: quando aberto, pausa as interações da partida.
var _tutorial_gui_x = device_mouse_x_to_gui(0);
var _tutorial_gui_y = device_mouse_y_to_gui(0);
var _tutorial_largura_gui = display_get_gui_width();
var _tutorial_altura_gui = display_get_gui_height();
if (tutorial_ativo) {
    var _tutorial_cx = _tutorial_largura_gui / 2;
    var _tutorial_cy = _tutorial_altura_gui / 2;
    if (keyboard_check_pressed(vk_escape) || mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _tutorial_cx + 250, _tutorial_cy - 190, _tutorial_cx + 290, _tutorial_cy - 150)) {
        tutorial_ativo = false;
    } else if (keyboard_check_pressed(vk_left) || mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _tutorial_cx - 230, _tutorial_cy + 150, _tutorial_cx - 70, _tutorial_cy + 195)) {
        tutorial_pagina = max(0, tutorial_pagina - 1);
    } else if (keyboard_check_pressed(vk_right) || mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _tutorial_cx + 70, _tutorial_cy + 150, _tutorial_cx + 230, _tutorial_cy + 195)) {
        tutorial_pagina = min(array_length(tutorial_paginas) - 1, tutorial_pagina + 1);
    }
    exit;
}

// Antes da primeira ação, os dois lados jogam D20. Empates são rolados novamente;
// quem vencer escolhe qual lado começa.
if (disputa_inicial_estado != "concluida") {
    var _iniciativa_cx = _tutorial_largura_gui / 2;
    var _iniciativa_cy = _tutorial_altura_gui / 2;

    if (disputa_inicial_estado == "aguardando") {
        disputa_inicial_timer -= 1;
        if (disputa_inicial_timer <= 0 && rolagens_pendentes <= 0) rolar_disputa_inicial();
    } else if (disputa_inicial_estado == "resultado" && rolagens_pendentes <= 0) {
        disputa_inicial_timer -= 1;
        if (disputa_inicial_timer <= 0) {
            if (disputa_inicial_resultado_jogador == disputa_inicial_resultado_inimigo) {
                disputa_inicial_estado = "aguardando";
                disputa_inicial_timer = 35;
                disputa_inicial_resultado_jogador = -1;
                disputa_inicial_resultado_inimigo = -1;
            } else if (disputa_inicial_resultado_jogador > disputa_inicial_resultado_inimigo) {
                disputa_inicial_vencedor = "jogador";
                disputa_inicial_estado = "escolha_jogador";
            } else {
                disputa_inicial_vencedor = "inimigo";
                disputa_inicial_estado = "escolha_inimigo";
                disputa_inicial_timer = 65;
            }
        }
    } else if (disputa_inicial_estado == "escolha_jogador") {
        var _escolher_jogador = mouse_check_button_pressed(mb_left)
            && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _iniciativa_cx - 215, _iniciativa_cy + 55, _iniciativa_cx - 15, _iniciativa_cy + 105);
        var _escolher_inimigo = mouse_check_button_pressed(mb_left)
            && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _iniciativa_cx + 15, _iniciativa_cy + 55, _iniciativa_cx + 215, _iniciativa_cy + 105);
        if (_escolher_jogador) finalizar_disputa_inicial("jogador");
        else if (_escolher_inimigo) finalizar_disputa_inicial("inimigo");
    } else if (disputa_inicial_estado == "escolha_inimigo") {
        disputa_inicial_timer -= 1;
        if (disputa_inicial_timer <= 0) finalizar_disputa_inicial("inimigo");
    }
    exit;
}

// Só abre a próxima escolha quando todos os dados da ação anterior terminarem.
if (!critico_escolha_ativa && array_length(criticos_pendentes) > 0 && rolagens_pendentes <= 0) {
    abrir_proxima_escolha_critico();
}

// O crítico pausa novas interações até o jogador escolher a forma do dano.
if (critico_escolha_ativa) {
    var _critico_cx = _tutorial_largura_gui / 2;
    var _critico_cy = _tutorial_altura_gui / 2;
    var _clicou_dois_dados = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _critico_cx - 225, _critico_cy + 55, _critico_cx - 15, _critico_cy + 112);
    var _clicou_dobrar_resultado = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _critico_cx + 15, _critico_cy + 55, _critico_cx + 225, _critico_cy + 112);
    if (_clicou_dois_dados) resolver_escolha_critico("dobrar_dados");
    else if (_clicou_dobrar_resultado) resolver_escolha_critico("dobrar_resultado");
    exit;
}

// Armadilhas preparadas pela IA continuam secretas e são resolvidas assim que
// uma tropa do jogador entra no espaço vigiado. As armadilhas do jogador permanecem manuais.
if (partida_iniciada && turno == "jogador" && ia_ativar_armadilhas_prontas()) exit;

// Confirmação do descarte manual: a carta só sai da mão após a escolha do jogador.
if (confirmacao_descarte_ativa) {
    var _confirmacao_cx = _tutorial_largura_gui / 2;
    var _confirmacao_cy = _tutorial_altura_gui / 2;
    var _confirmar_descarte = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _confirmacao_cx - 180, _confirmacao_cy + 42, _confirmacao_cx - 12, _confirmacao_cy + 82);
    var _cancelar_descarte = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _confirmacao_cx + 12, _confirmacao_cy + 42, _confirmacao_cx + 180, _confirmacao_cy + 82);

    if (_confirmar_descarte && instance_exists(carta_pendente_descarte)) {
        var _carta_descarte = carta_pendente_descarte;
        var _indice_mao_descarte = array_get_index(mao, _carta_descarte);
        if (_indice_mao_descarte != -1) {
            array_delete(mao, _indice_mao_descarte, 1);
            organizar_mao();
        }
        registrar_descarte(_carta_descarte);
        mostrar_feedback("DESCARTADA", _carta_descarte.x, _carta_descarte.y - 30, c_gray, 35);
        instance_destroy(_carta_descarte);
        carta_pendente_descarte = noone;
        confirmacao_descarte_ativa = false;
    } else if (keyboard_check_pressed(vk_escape) || _cancelar_descarte || !instance_exists(carta_pendente_descarte)) {
        if (instance_exists(carta_pendente_descarte)) {
            carta_pendente_descarte.x = carta_pendente_descarte.origem_x;
            carta_pendente_descarte.y = carta_pendente_descarte.origem_y;
            carta_pendente_descarte.esta_na_mao = true;
        }
        carta_pendente_descarte = noone;
        confirmacao_descarte_ativa = false;
    }
    exit;
}

// A pilha de descarte é apenas de consulta, mas bloqueia ações enquanto estiver aberta.
if (descarte_aberto) {
    var _descarte_cx = _tutorial_largura_gui / 2;
    var _descarte_cy = _tutorial_altura_gui / 2;
    var _fechar_descarte = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _descarte_cx + 240, _descarte_cy - 180, _descarte_cx + 280, _descarte_cy - 140);
    var _primeira_carta_descarte = max(0, array_length(descarte_jogador) - 12);
    var _linha_descarte = floor((_tutorial_gui_y - (_descarte_cy - 110)) / 21);
    var _clicou_linha_descarte = mouse_check_button_pressed(mb_left)
        && descarte_preview_indice == -1
        && _tutorial_gui_x >= _descarte_cx - 245 && _tutorial_gui_x <= _descarte_cx + 245
        && _linha_descarte >= 0 && _linha_descarte < array_length(descarte_jogador) - _primeira_carta_descarte;
    var _clicou_voltar_descarte = mouse_check_button_pressed(mb_left)
        && descarte_preview_indice != -1
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _descarte_cx - 245, _descarte_cy + 145, _descarte_cx - 80, _descarte_cy + 180);

    if (keyboard_check_pressed(vk_escape) || _fechar_descarte) {
        if (descarte_preview_indice != -1) descarte_preview_indice = -1;
        else descarte_aberto = false;
    } else if (_clicou_voltar_descarte) {
        descarte_preview_indice = -1;
    } else if (_clicou_linha_descarte) {
        descarte_preview_indice = _primeira_carta_descarte + _linha_descarte;
    }
    exit;
}

var _botoes_direita_x1 = _tutorial_largura_gui - 205 + hud_deslocamento_direita;
var _botoes_direita_x2 = _tutorial_largura_gui - 15 + hud_deslocamento_direita;
if (!pausa_ativa && (keyboard_check_pressed(vk_f1) || (turno == "jogador" && mouse_check_button_pressed(mb_left)
    && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _botoes_direita_x1, 30, _botoes_direita_x2, 62)))) {
    tutorial_ativo = true;
    tutorial_pagina = 0;
    carta_preview = noone;
    carta_menu_aberto = noone;
    exit;
}

// Pausa manual: mantém o jogo aberto e impede qualquer ação enquanto o painel estiver visível.
var _pausa_x1 = _botoes_direita_x1;
var _pausa_x2 = _botoes_direita_x2;
var _clicou_pausa = mouse_check_button_pressed(mb_left)
    && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_x1, 152, _pausa_x2, 184);
if (pausa_ativa) {
    var _pausa_cx = _tutorial_largura_gui / 2;
    var _pausa_cy = _tutorial_altura_gui / 2;
    if (opcoes_pausa_ativa) {
        var _musica_y = _pausa_cy - 35;
        var _efeitos_y = _pausa_cy + 10;
        var _tela_y = _pausa_cy + 55;
        var _voltar_y = _pausa_cy + 110;
        if (keyboard_check_pressed(vk_escape)) {
            opcoes_pausa_ativa = false;
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 160, _musica_y - 18, _pausa_cx - 90, _musica_y + 18)) {
            global.volume_musica = clamp(global.volume_musica - 0.1, 0, 1);
            aplicar_config_audio();
            salvar_configuracoes();
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx + 90, _musica_y - 18, _pausa_cx + 160, _musica_y + 18)) {
            global.volume_musica = clamp(global.volume_musica + 0.1, 0, 1);
            aplicar_config_audio();
            salvar_configuracoes();
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 160, _efeitos_y - 18, _pausa_cx - 90, _efeitos_y + 18)) {
            global.volume_efeitos = clamp(global.volume_efeitos - 0.1, 0, 1);
            aplicar_config_audio();
            salvar_configuracoes();
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx + 90, _efeitos_y - 18, _pausa_cx + 160, _efeitos_y + 18)) {
            global.volume_efeitos = clamp(global.volume_efeitos + 0.1, 0, 1);
            aplicar_config_audio();
            salvar_configuracoes();
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 160, _tela_y - 18, _pausa_cx + 160, _tela_y + 18)) {
            window_set_fullscreen(!window_get_fullscreen());
            salvar_configuracoes();
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 150, _voltar_y - 22, _pausa_cx + 150, _voltar_y + 22)) {
            opcoes_pausa_ativa = false;
        }
        exit;
    }
    var _clicou_continuar = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 125, _pausa_cy + 35, _pausa_cx + 125, _pausa_cy + 75);
    var _clicou_opcoes = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 125, _pausa_cy + 90, _pausa_cx + 125, _pausa_cy + 130);
    var _clicou_sair = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 125, _pausa_cy + 145, _pausa_cx + 125, _pausa_cy + 185);
    if (_clicou_sair) {
        game_end();
    } else if (_clicou_opcoes) {
        opcoes_pausa_ativa = true;
    } else if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("P")) || _clicou_continuar) {
        pausa_ativa = false;
    } else if (keyboard_check_pressed(vk_f1)) {
        pausa_ativa = false;
        tutorial_ativo = true;
        tutorial_pagina = 0;
    }
    exit;
}
if (keyboard_check_pressed(ord("P")) || _clicou_pausa) {
    pausa_ativa = true;
    opcoes_pausa_ativa = false;
    carta_preview = noone;
    carta_menu_aberto = noone;
    tropa_selecionada = noone;
    exit;
}

// Abre/fecha a lista do cemitério pelo botão do HUD.
var _mouse_gui_x_cemiterio = device_mouse_x_to_gui(0);
var _mouse_gui_y_cemiterio = device_mouse_y_to_gui(0);
var _gui_largura_cemiterio = display_get_gui_width();
if (turno == "jogador" && mouse_check_button_pressed(mb_left)
    && point_in_rectangle(_mouse_gui_x_cemiterio, _mouse_gui_y_cemiterio, 14 - hud_deslocamento_esquerda, 210, 190 - hud_deslocamento_esquerda, 242)) {
    historico_aberto = !historico_aberto;
    exit;
}
if (turno == "jogador" && mouse_check_button_pressed(mb_left)
    && point_in_rectangle(_mouse_gui_x_cemiterio, _mouse_gui_y_cemiterio, _gui_largura_cemiterio - 205 + hud_deslocamento_direita, 72, _gui_largura_cemiterio - 15 + hud_deslocamento_direita, 104)) {
    cemiterio_aberto = !cemiterio_aberto;
    exit;
}

// Enquanto a IA joga, o turno é processado em etapas e o jogador não pode interagir.
if (turno == "inimigo" && ia_ativa) {
    processar_turno_ia();
    exit;
}

#region Atalhos de teclado (debug/teste)
if (keyboard_check_pressed(vk_escape)) {
    var _fechou_algum_preview = false;

    // Preview de carta ampliada (botão direito numa carta)
    if (carta_preview != noone) {
        carta_preview = noone;
        _fechou_algum_preview = true;
    }

    // Preview do livro de regras
    if (instance_exists(obj_livro) && obj_livro.preview_ativo) {
        obj_livro.preview_ativo = false;
        _fechou_algum_preview = true;
    }

    // Sem preview, ESC abre a pausa em vez de encerrar a partida por acidente.
    if (!_fechou_algum_preview) {
        pausa_ativa = true;
    }
}
if (keyboard_check_pressed(ord("R")) && global.DEBUG_COMBATE) {
    room_restart();
}

if (keyboard_check_pressed(ord("K")) && global.DEBUG_COMBATE) {
    vida_inimigo = 0;
}

// NOVO: pede o nome de uma carta e coloca ela direto na mão (sem gastar do monte).
if (keyboard_check_pressed(ord("V")) && global.DEBUG_COMBATE) {
    var _estava_fullscreen = window_get_fullscreen();
    if (_estava_fullscreen) {
        window_set_fullscreen(false);
    }

    var _nome_digitado = get_string("DEBUG - Nome da carta (ou parte dele):", "");

    if (_estava_fullscreen) {
        window_set_fullscreen(true);
    }

    if (_nome_digitado != "") {
        debug_adicionar_carta_a_mao(_nome_digitado);
    }
}

// NOVO: enche os recursos do jogador instantaneamente.
if (keyboard_check_pressed(ord("F")) && global.DEBUG_COMBATE) {
    debug_encher_recursos("jogador");
}

if (keyboard_check_pressed(ord("C")) && global.DEBUG_COMBATE) {
    var _quantidade_debug = 10;
    for (var i = 0; i < _quantidade_debug; i++) {
        if (array_length(monte) == 0) break;
        comprar_carta_do_deck(obj_deck.x, obj_deck.y);
    }
    debug_combate("DEBUG: comprou " + string(_quantidade_debug) + " cartas pro jogador.");
}

if (keyboard_check_pressed(ord("M"))&& global.DEBUG_COMBATE) {
    jogar_moeda_visual(mao_x_centro, mao_y, room_width / 2, room_height / 2, noone);
}
#endregion

if (vida_jogador <= 0) exit; // jogo acabou, para de processar interação

#region Preview ampliado (botão direito numa carta da mão)
// detecta hover sobre carta travada no campo (pro preview funcionar lá também)
var _hover_campo = noone;
with (obj_carta) {
    if (!travada) continue;
    var _meia_largura = sprite_width / 2;
    var _meia_altura = sprite_height / 2;
    if (point_in_rectangle(mouse_x, mouse_y, x - _meia_largura, y - _meia_altura, x + _meia_largura, y + _meia_altura)) {
        _hover_campo = id;
        break;
    }
}

if (mouse_check_button_pressed(mb_right)) {
    if (carta_preview == noone) {
        var _alvo_preview = (hover_atual != noone) ? hover_atual : _hover_campo;
        if (_alvo_preview != noone) {
            carta_preview = _alvo_preview;
        }
    } else {
        carta_preview = noone;
    }
}

// enquanto o preview está ativo, ignora todo o resto do Step (hover, clique, arrasto, menu)
if (carta_preview != noone) {
    if (!instance_exists(carta_preview)) {
        carta_preview = noone;
    }
    exit;
}
#endregion

// A tropa destacada só existe enquanto ela continuar válida e no turno do jogador.
if (tropa_selecionada != noone && (!instance_exists(tropa_selecionada)
    || !tropa_selecionada.travada || tropa_selecionada.dono != "jogador" || turno != "jogador")) {
    tropa_selecionada = noone;
}

#region Hover e clique nas cartas da mão
var _total = array_length(mao);
var _melhor_carta = noone;
var _menor_distancia = 999999;

for (var i = 0; i < _total; i++) {
    var _carta = mao[i];
    if (!instance_exists(_carta)) continue;
    if (_carta.arrastando) continue;
    if (!_carta.esta_na_mao) continue;
    if (_carta.travada) continue;

    var _dentro_y = (mouse_y >= _carta.y - global.CARTA_ALTURA/2 - 40)
                  && (mouse_y <= _carta.y + global.CARTA_ALTURA/2);

    if (_dentro_y) {
        var _dist_x = abs(mouse_x - _carta.x);
        if (_dist_x < global.CARTA_LARGURA/2 && _dist_x < _menor_distancia) {
            _menor_distancia = _dist_x;
            _melhor_carta = _carta;
        }
    }
}

hover_atual = _melhor_carta;

for (var i = 0; i < _total; i++) {
    var _carta = mao[i];
    if (!instance_exists(_carta)) continue;
    _carta.hover_ativo_externo = (_carta == hover_atual);
}

if (mouse_check_button_pressed(mb_left)) {
    if (hover_atual != noone && instance_exists(hover_atual) && hover_atual.armadilha_estado == "pronta") {
        ativar_armadilha(hover_atual.id);
    } else if (hover_atual != noone && instance_exists(hover_atual) && !hover_atual.travada) {
        with (hover_atual) {
            arrastando = true;
            esta_na_mao = false;
            rotacao_atual = 0;
            escala_atual = 1;
            y_offset_atual = 0;
			arrastar_inicio_x = x;
			arrastar_inicio_y = y;

            if (slot_atual != noone) {
                slot_atual.ocupado = false;
                slot_atual.carta_atual = noone;
                slot_atual = noone;
            }
        }
    }
}
#endregion

#region Scroll horizontal da mão (perto das bordas da tela, só quando o mouse está sobre a mão)
if (mao_scroll_max > 0) {
    var _mouse_gui_x = device_mouse_x_to_gui(0);
    var _zona_scroll_h = 100;
    var _velocidade_scroll_h = 15;

    // só ativa se o mouse estiver na altura da mão (não em qualquer lugar da tela)
    var _dentro_faixa_mao = (mouse_y >= mao_y - global.CARTA_ALTURA/2 - 40) 
                          && (mouse_y <= mao_y + global.CARTA_ALTURA/2 + 40);

    if (_dentro_faixa_mao) {
        if (_mouse_gui_x < _zona_scroll_h) {
            mao_scroll_offset_alvo += _velocidade_scroll_h;
        } else if (_mouse_gui_x > (display_get_gui_width() - _zona_scroll_h)) {
            mao_scroll_offset_alvo -= _velocidade_scroll_h;
        }
    }

    mao_scroll_offset_alvo = clamp(mao_scroll_offset_alvo, -mao_scroll_max, mao_scroll_max);
}

mao_scroll_offset += (mao_scroll_offset_alvo - mao_scroll_offset) * 0.15;
#endregion

#region Menu de ação (animação + clique nas opções)
var _alvo_escala_menu = (carta_menu_aberto != noone && instance_exists(carta_menu_aberto)) ? 1 : 0;
menu_escala += (_alvo_escala_menu - menu_escala) * 0.25;
if (_alvo_escala_menu == 0 && menu_escala < 0.02) {
    menu_escala = 0;
}

opcao_hover_index = -1;

if (carta_menu_aberto != noone && instance_exists(carta_menu_aberto) && menu_escala > 0.9) {
    var _carta = carta_menu_aberto;
    var _opcoes = obter_opcoes_menu(_carta);
    var _n = array_length(_opcoes);

    var _largura_opcao = 100;
    var _altura_opcao = 20;
    var _espaco_opcao = 6;
    var _altura_total = _n * _altura_opcao + (_n - 1) * _espaco_opcao;

    var _base_x = _carta.x + (global.CARTA_LARGURA * 0.5);
    var _base_y = _carta.y - _altura_total/2;

    for (var i = 0; i < _n; i++) {
        var _opt_y = _base_y + i * (_altura_opcao + _espaco_opcao);
        if (mouse_x > _base_x && mouse_x < _base_x + _largura_opcao && mouse_y > _opt_y && mouse_y < _opt_y + _altura_opcao) {
            opcao_hover_index = i;

            if (mouse_check_button_pressed(mb_left)) {
                executar_opcao_menu(_carta, _opcoes[i]);
                carta_menu_aberto = noone;
                // Depois de escolher qualquer ação, a tropa deixa de ficar destacada.
                // Mesmo quando a regra impedir a ação, o jogador pode selecionar novamente se quiser.
                tropa_selecionada = noone;
            }
            break;
        }
    }
}
#endregion

#region Tooltip do nome da habilidade (hover na opção "Habilidade")
var _mostrar_tooltip = false;
if (carta_menu_aberto != noone && opcao_hover_index != -1) {
    var _opcoes_atuais = obter_opcoes_menu(carta_menu_aberto);
    if (opcao_hover_index < array_length(_opcoes_atuais) && _opcoes_atuais[opcao_hover_index] == "Habilidade") {
        _mostrar_tooltip = true;
    }
}

var _alvo_tooltip = _mostrar_tooltip ? 1 : 0;
tooltip_escala += (_alvo_tooltip - tooltip_escala) * 0.3;
if (_alvo_tooltip == 0 && tooltip_escala < 0.02) {
    tooltip_escala = 0;
}
#endregion
