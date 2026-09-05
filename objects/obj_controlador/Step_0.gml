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

// Atualizações visuais independentes da lógica: continuam durante modais e fim da partida.
if (onda_turno_timer > 0) onda_turno_timer--;
if (visao_veu_ativa) visao_veu_revelacao_timer++;
for (var _i_anim_item = array_length(animacoes_item) - 1; _i_anim_item >= 0; _i_anim_item--) {
    animacoes_item[_i_anim_item].timer++;
    if (animacoes_item[_i_anim_item].timer >= animacoes_item[_i_anim_item].duracao) {
        array_delete(animacoes_item, _i_anim_item, 1);
    }
}
if (vida_jogador <= 0 || vida_inimigo <= 0) fim_animacao_timer = min(fim_animacao_duracao, fim_animacao_timer + 1);

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

// Abertura interativa: primeiro arremesse o D20; após a escolha, compre a mão.
if (disputa_inicial_estado != "concluida") {
    var _iniciativa_cx = _tutorial_largura_gui / 2;
    var _iniciativa_cy = _tutorial_altura_gui / 2;

    if (disputa_inicial_estado == "preparando_dado") {
        disputa_inicial_timer--;
        if (disputa_inicial_timer <= 0 && rolagens_pendentes <= 0) preparar_dado_disputa_inicial();
    } else if (disputa_inicial_estado == "resultado" && rolagens_pendentes <= 0) {
        disputa_inicial_timer--;
        if (disputa_inicial_timer <= 0) {
            if (disputa_inicial_resultado_jogador == disputa_inicial_resultado_inimigo) {
                disputa_inicial_estado = "preparando_dado";
                disputa_inicial_timer = 35;
                disputa_inicial_resultado_jogador = -1;
                disputa_inicial_resultado_inimigo = -1;
                dado_iniciativa_id = noone;
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
        disputa_inicial_timer--;
        if (disputa_inicial_timer <= 0) finalizar_disputa_inicial("inimigo");
    } else if (disputa_inicial_estado == "aguardando_deck") {
        var _deck_inicial = instance_find(obj_deck, 0);
        if (_deck_inicial != noone && mouse_check_button_pressed(mb_left)
            && point_in_rectangle(mouse_x, mouse_y,
                _deck_inicial.x - _deck_inicial.sprite_width * 0.65,
                _deck_inicial.y - _deck_inicial.sprite_height * 0.65,
                _deck_inicial.x + _deck_inicial.sprite_width * 0.65,
                _deck_inicial.y + _deck_inicial.sprite_height * 0.65)) {
            comprar_mao_inicial();
            comprar_mao_inicial_ia();
            disputa_inicial_estado = "distribuindo";
            disputa_inicial_timer = quantidade_inicial * 7 + 45;
        }
    } else if (disputa_inicial_estado == "distribuindo") {
        disputa_inicial_timer--;
        if (disputa_inicial_timer <= 0) {
            finalizar_disputa_inicial(disputa_inicial_primeiro_escolhido);
        }
    }
    exit;
}

// Dados Manipulados pausa apenas a resolução que depende daquele dado.
if (!dados_manipulados_escolha_ativa && array_length(dados_manipulados_escolhas) > 0) {
    dados_manipulados_escolha_atual = dados_manipulados_escolhas[0];
    array_delete(dados_manipulados_escolhas, 0, 1);
    dados_manipulados_escolha_ativa = true;
}
if (dados_manipulados_escolha_ativa) {
    var _dados_cx = _tutorial_largura_gui / 2;
    var _dados_cy = _tutorial_altura_gui / 2;
    if (mouse_check_button_pressed(mb_left)) {
        if (point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _dados_cx - 190, _dados_cy + 35, _dados_cx - 10, _dados_cy + 82))
            resolver_escolha_dados_manipulados(false);
        else if (point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _dados_cx + 10, _dados_cy + 35, _dados_cx + 190, _dados_cy + 82))
            resolver_escolha_dados_manipulados(true);
    }
    exit;
}

// A Máquina Imã pede qual equipamento da tropa derrotada volta à mão.
if (!maquina_ima_escolha_ativa && array_length(maquina_ima_pendencias) > 0) {
    maquina_ima_escolha_atual = maquina_ima_pendencias[0];
    array_delete(maquina_ima_pendencias, 0, 1);
    maquina_ima_escolha_ativa = true;
}
if (maquina_ima_escolha_ativa) {
    var _ima_cx = _tutorial_largura_gui / 2;
    var _ima_cy = _tutorial_altura_gui / 2;
    if (mouse_check_button_pressed(mb_left)) {
        for (var _ima_i = 0; _ima_i < array_length(maquina_ima_escolha_atual.itens); _ima_i++) {
            var _ima_y = _ima_cy - 35 + _ima_i * 36;
            if (point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _ima_cx - 210, _ima_y, _ima_cx + 210, _ima_y + 30)) {
                resolver_escolha_maquina_ima(_ima_i);
                break;
            }
        }
    }
    exit;
}

// Visão do Véu bloqueia as demais ações até escolher uma armadilha revelada
// ou a proteção contra a próxima armadilha.
if (visao_veu_ativa) {
    var _veu_cx = _tutorial_largura_gui / 2;
    var _veu_cy = _tutorial_altura_gui / 2;
    if (keyboard_check_pressed(vk_escape)) resolver_visao_veu_escolha(-1);
    else if (mouse_check_button_pressed(mb_left)) {
        var _escolheu_veu = false;
        for (var i = 0; i < array_length(visao_veu_opcoes); i++) {
            var _col = i mod 3;
            var _lin = floor(i / 3);
            var _x1 = _veu_cx - 270 + _col * 180;
            var _y1 = _veu_cy - 95 + _lin * 30;
            if (visao_veu_opcoes[i].armadilha && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _x1, _y1, _x1 + 170, _y1 + 24)) {
                resolver_visao_veu_escolha(i); _escolheu_veu = true; break;
            }
        }
        if (!_escolheu_veu && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _veu_cx - 190, _veu_cy + 125, _veu_cx + 190, _veu_cy + 170)) resolver_visao_veu_escolha(-1);
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

// Confirmação da retirada de recurso: só retira depois da escolha do jogador.
if (confirmacao_recurso_ativa) {
    var _confirmacao_recurso_cx = _tutorial_largura_gui / 2;
    var _confirmacao_recurso_cy = _tutorial_altura_gui / 2;
    var _confirmar_recurso = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y,
            _confirmacao_recurso_cx - 180, _confirmacao_recurso_cy + 42,
            _confirmacao_recurso_cx - 12, _confirmacao_recurso_cy + 82);
    var _cancelar_recurso = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y,
            _confirmacao_recurso_cx + 12, _confirmacao_recurso_cy + 42,
            _confirmacao_recurso_cx + 180, _confirmacao_recurso_cy + 82);

    if (_confirmar_recurso && instance_exists(recurso_pendente_retirada)) {
        retirar_recurso_do_campo(recurso_pendente_retirada);
        recurso_pendente_retirada = noone;
        confirmacao_recurso_ativa = false;
    } else if (keyboard_check_pressed(vk_escape) || _cancelar_recurso
        || !instance_exists(recurso_pendente_retirada)) {
        recurso_pendente_retirada = noone;
        confirmacao_recurso_ativa = false;
    }
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
if (!pausa_ativa && (keyboard_check_pressed(vk_f1) || (mouse_check_button_pressed(mb_left)
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
if (mouse_check_button_pressed(mb_left)
    && point_in_rectangle(_mouse_gui_x_cemiterio, _mouse_gui_y_cemiterio, 14 - hud_deslocamento_esquerda, 210, 190 - hud_deslocamento_esquerda, 242)) {
    historico_aberto = !historico_aberto;
    exit;
}
if (mouse_check_button_pressed(mb_left)
    && point_in_rectangle(_mouse_gui_x_cemiterio, _mouse_gui_y_cemiterio, _gui_largura_cemiterio - 205 + hud_deslocamento_direita, 72, _gui_largura_cemiterio - 15 + hud_deslocamento_direita, 104)) {
    cemiterio_aberto = !cemiterio_aberto;
    exit;
}

// A IA continua processando em etapas, mas a interface não é congelada:
// o jogador ainda pode inspecionar o campo e reorganizar a própria mão.
if (turno == "inimigo" && ia_ativa) {
    processar_turno_ia();
}

// Espaço encerra o turno do jogador. Escolhas simples de alvo são canceladas;
// rolagens e a escolha de crítico precisam terminar antes para não cortar efeitos.
if (turno == "jogador" && partida_iniciada && keyboard_check_pressed(vk_space)) {
    if (rolagens_pendentes > 0 || critico_escolha_ativa || array_length(criticos_pendentes) > 0) {
        mostrar_aviso_regra("Aguarde a rolagem terminar", mouse_x, mouse_y);
    } else {
        digestao_selecao_ativa = false; digestao_origem = noone;
        troca_item_selecao_ativa = false; troca_item_origem = noone;
        carta_preview = noone; carta_menu_aberto = noone; tropa_selecionada = noone;
        passar_turno_jogador();
    }
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

// Construções também abrem a mesma prévia ampliada com o botão direito.
var _hover_construcao = noone;
with (obj_construcao) {
    var _meia_largura = sprite_width / 2;
    var _meia_altura = sprite_height / 2;
    if (point_in_rectangle(mouse_x, mouse_y, x - _meia_largura, y - _meia_altura, x + _meia_largura, y + _meia_altura)) {
        _hover_construcao = id;
        break;
    }
}

if (mouse_check_button_pressed(mb_right)) {
    if (carta_preview == noone) {
        var _alvo_preview = (hover_atual != noone) ? hover_atual
            : ((_hover_campo != noone) ? _hover_campo : _hover_construcao);
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

// A Mitose coloca o primeiro Slimet na casa da morte e deixa o jogador
// escolher uma das casas adjacentes livres para o segundo.
if (mitose_selecao_ativa) {
    if (mouse_check_button_pressed(mb_left)) {
        var _slot_mitose_escolhido = noone;
        var _menor_distancia_mitose = 38;
        for (var _mi = 0; _mi < array_length(mitose_slots_pendentes); _mi++) {
            var _slot_mi = mitose_slots_pendentes[_mi];
            if (_slot_mi != noone && !_slot_mi.ocupado) {
                var _dist_mi = point_distance(mouse_x, mouse_y, _slot_mi.x, _slot_mi.y);
                if (_dist_mi < _menor_distancia_mitose) { _menor_distancia_mitose = _dist_mi; _slot_mitose_escolhido = _slot_mi; }
            }
        }
        if (_slot_mitose_escolhido != noone) {
            criar_tropa_no_slot(mitose_dados_pendentes, _slot_mitose_escolhido, "jogador");
            mitose_selecao_ativa = false;
            mitose_slots_pendentes = [];
        } else mostrar_aviso_regra("Escolha uma casa adjacente destacada", mouse_x, mouse_y);
    } else if (keyboard_check_pressed(vk_escape)) {
        comprar_carta_do_deck_por_funcao(mitose_funcao_pendente, room_width / 2, obj_controlador.mao_y);
        mitose_selecao_ativa = false;
        mitose_slots_pendentes = [];
    }
    exit;
}

// Modos de escolha iniciados por habilidades e ações do menu.
if (digestao_selecao_ativa) {
    if (!instance_exists(digestao_origem) || keyboard_check_pressed(vk_escape) || mouse_check_button_pressed(mb_right)) {
        digestao_selecao_ativa = false; digestao_origem = noone;
    } else if (mouse_check_button_pressed(mb_left)) {
        var _alvo_digestao = instance_position(mouse_x, mouse_y, obj_carta);
        if (alvo_valido_digestao(digestao_origem, _alvo_digestao)) {
            resolver_digestao(digestao_origem, _alvo_digestao);
            digestao_selecao_ativa = false; digestao_origem = noone; tropa_selecionada = noone; carta_menu_aberto = noone;
        } else mostrar_aviso_regra("Escolha tropa adjacente com menos de 4 de vida", mouse_x, mouse_y);
    }
    exit;
}

if (troca_item_selecao_ativa) {
    if (!instance_exists(troca_item_origem) || keyboard_check_pressed(vk_escape) || mouse_check_button_pressed(mb_right)) {
        troca_item_selecao_ativa = false; troca_item_origem = noone;
    } else if (mouse_check_button_pressed(mb_left)) {
        var _destino_item = instance_position(mouse_x, mouse_y, obj_carta);
        if (instance_exists(_destino_item) && _destino_item != troca_item_origem && _destino_item.travada
            && _destino_item.dono == "jogador" && _destino_item.mochila > 0 && !_destino_item.troca_item_usada_este_turno) {
            transferir_item_equipado(troca_item_origem, _destino_item, array_length(troca_item_origem.itens_equipados) - 1);
            troca_item_selecao_ativa = false; troca_item_origem = noone; tropa_selecionada = noone; carta_menu_aberto = noone;
        } else mostrar_aviso_regra("Escolha uma tropa aliada com espaço na mochila", mouse_x, mouse_y);
    }
    exit;
}

// A seleção continua disponível para consulta até durante o turno inimigo.
if (tropa_selecionada != noone && (!instance_exists(tropa_selecionada)
    || !tropa_selecionada.travada || tropa_selecionada.dono != "jogador")) {
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
    } else if (hover_atual != noone && instance_exists(hover_atual)
        && hover_atual.categoria == "armadilha" && hover_atual.armadilha_estado == "vigiando") {
        mostrar_aviso_regra("Armadilha já posicionada", hover_atual.x, hover_atual.y - 35);
    } else if (hover_atual != noone && instance_exists(hover_atual) && !hover_atual.travada) {
        with (hover_atual) {
            arrastando = true;
            esta_na_mao = false;
            // Profundidade exclusiva: nenhuma carta da mão ou em animação passa na frente.
            depth = -100000;
            rotacao_atual = 0;
            escala_atual = 1;
            y_offset_atual = 0;
            arrasto_mouse_anterior_x = mouse_x;
            arrasto_mouse_anterior_y = mouse_y;
            arrasto_velocidade_x = 0;
            arrasto_velocidade_y = 0;
            arrasto_offset_visual_x = 0;
            arrasto_offset_visual_y = 0;
            arrasto_rotacao = 0;
            arrasto_escala = 1.04;
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

// Enquanto a carta cruza as demais, a mão abre espaço em tempo real.
var _carta_arrastada_mao = noone;
for (var _ri = 0; _ri < array_length(mao); _ri++) {
    if (instance_exists(mao[_ri]) && mao[_ri].arrastando) {
        _carta_arrastada_mao = mao[_ri];
        break;
    }
}
if (_carta_arrastada_mao != noone && mouse_na_faixa_da_mao(mouse_y)) {
    reordenar_carta_na_mao(_carta_arrastada_mao, mouse_x);
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

    var _largura_opcao = 170;
    var _altura_opcao = 23;
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
