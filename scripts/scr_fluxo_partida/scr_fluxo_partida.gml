// =============================================================================
// KARTHA — fluxo da partida e estado transitório de interface
// Centraliza a prioridade dos modais que antes dependia da ordem dos ifs no Step.
// =============================================================================

function controlador_criar_estado_modal() {
    return {
        tipo_ativo: "",
        tutorial_ativo: false,
        tutorial_pagina: 0,
        pausa_ativa: false,
        opcoes_pausa_ativa: false,
        critico_escolha_ativa: false,
        criticos_pendentes: [],
        critico_contexto: noone,
        dados_manipulados_escolha_ativa: false,
        dados_manipulados_escolha_atual: noone,
        maquina_ima_escolha_ativa: false,
        maquina_ima_escolha_atual: noone,
        confirmacao_recurso_ativa: false,
        recurso_pendente_retirada: noone,
        confirmacao_descarte_ativa: false,
        carta_pendente_descarte: noone,
        descarte_aberto: false,
        descarte_preview_indice: -1,
        cemiterio_aberto: false,
        historico_aberto: false,
        visao_veu_ativa: false,
        visao_veu_origem: noone,
        visao_veu_opcoes: [],
        mitose_selecao_ativa: false,
        mitose_dados_pendentes: noone,
        mitose_funcao_pendente: noone,
        mitose_dono_pendente: "jogador",
        mitose_slots_pendentes: [],
        digestao_selecao_ativa: false,
        digestao_origem: noone,
        troca_item_selecao_ativa: false,
        troca_item_origem: noone
    };
}

function partida_encerrada(_controle) {
    if (_controle.modo_partida == "online") return _controle.online_vencedor != "";
    return _controle.vida_jogador <= 0 || _controle.vida_inimigo <= 0;
}

function controlador_modal_atual(_controle) {
    if (!instance_exists(_controle) || !variable_instance_exists(_controle, "ui_modal")
        || !is_struct(_controle.ui_modal)) return "";
    var _ui = _controle.ui_modal;

    // Esta lista é a regra de prioridade. Adicionar um modal novo exige colocá-lo
    // aqui, em vez de depender acidentalmente da posição de um if no Step.
    if (partida_encerrada(_controle)) return "fim_partida";
    if (_ui.tutorial_ativo) return "tutorial";
    if (_controle.disputa_inicial_estado != "concluida") return "iniciativa";
    if (_ui.dados_manipulados_escolha_ativa) return "dados_manipulados";
    if (_ui.maquina_ima_escolha_ativa) return "maquina_ima";
    if (_ui.visao_veu_ativa) return "visao_veu";
    if (_ui.critico_escolha_ativa) return "critico";
    if (_ui.confirmacao_recurso_ativa) return "confirmacao_recurso";
    if (_ui.confirmacao_descarte_ativa) return "confirmacao_descarte";
    if (_ui.descarte_aberto) return "descarte";
    if (_ui.pausa_ativa) return _ui.opcoes_pausa_ativa ? "opcoes" : "pausa";
    if (_ui.mitose_selecao_ativa) return "mitose";
    if (_ui.digestao_selecao_ativa) return "digestao";
    if (_ui.troca_item_selecao_ativa) return "transferir_item";
    return "";
}

function controlador_atualizar_fluxo(_controle) {
    if (!instance_exists(_controle)) return;
    if (!variable_instance_exists(_controle, "ui_modal") || !is_struct(_controle.ui_modal))
        _controle.ui_modal = controlador_criar_estado_modal();
    _controle.ui_modal.tipo_ativo = controlador_modal_atual(_controle);
}

function controlador_processar_fluxo_e_modais(_controle) {
    var _processar = method(_controle, function() {
// Tela final: bloqueia a partida e permite recomeçar sem fechar o jogo.
if (partida_encerrada(id)) {
    if (fim_animacao_timer < 55) return true;
    var _fim_gui_x = device_mouse_x_to_gui(0);
    var _fim_gui_y = device_mouse_y_to_gui(0);
    var _fim_centro_x = display_get_gui_width() / 2;
    var _fim_centro_y = display_get_gui_height() / 2;
    var _clicou_reiniciar = point_in_rectangle(_fim_gui_x, _fim_gui_y, _fim_centro_x - 120, _fim_centro_y + 85, _fim_centro_x + 120, _fim_centro_y + 130);
    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("R")) || (mouse_check_button_pressed(mb_left) && _clicou_reiniciar)) {
        if (modo_partida != "online") room_restart();
        else if (!online_oponente_saiu && online_ativo()) online_solicitar_revanche();
        else { online_desconectar(); trocar_sala_suave(rm_menu); }
    } else if (modo_partida == "online" && keyboard_check_pressed(vk_escape)) {
        online_desconectar();
        trocar_sala_suave(rm_menu);
    }
    return true;
}

// Tutorial opcional: quando aberto, pausa as interações da partida.
var _tutorial_gui_x = device_mouse_x_to_gui(0);
var _tutorial_gui_y = device_mouse_y_to_gui(0);
var _tutorial_largura_gui = display_get_gui_width();
var _tutorial_altura_gui = display_get_gui_height();
if (ui_modal.tutorial_ativo) {
    var _tutorial_cx = _tutorial_largura_gui / 2;
    var _tutorial_cy = _tutorial_altura_gui / 2;
    if (keyboard_check_pressed(vk_escape) || mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _tutorial_cx + 250, _tutorial_cy - 190, _tutorial_cx + 290, _tutorial_cy - 150)) {
        ui_modal.tutorial_ativo = false;
    } else if (keyboard_check_pressed(vk_left) || mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _tutorial_cx - 230, _tutorial_cy + 150, _tutorial_cx - 70, _tutorial_cy + 195)) {
        ui_modal.tutorial_pagina = max(0, ui_modal.tutorial_pagina - 1);
    } else if (keyboard_check_pressed(vk_right) || mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _tutorial_cx + 70, _tutorial_cy + 150, _tutorial_cx + 230, _tutorial_cy + 195)) {
        ui_modal.tutorial_pagina = min(array_length(tutorial_paginas) - 1, ui_modal.tutorial_pagina + 1);
    }
    return true;
}

// Abertura: compre a mão, aguarde a distribuição e então dispute a iniciativa.
if (disputa_inicial_estado != "concluida") {
    var _iniciativa_cx = _tutorial_largura_gui / 2;
    var _iniciativa_cy = _tutorial_altura_gui / 2;

    if (disputa_inicial_estado == "online_iniciativa") {
        disputa_inicial_resultado_jogador = global.online_iniciativa[global.online_assento];
        disputa_inicial_resultado_inimigo = global.online_iniciativa[1 - global.online_assento];
        if (mouse_check_button_pressed(mb_left)) {
            if (global.online_fase == "initiative"
                && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _iniciativa_cx-100, _iniciativa_cy+55, _iniciativa_cx+100, _iniciativa_cy+105)) online_rolar_iniciativa();
            else if (global.online_fase == "choose_first" && global.online_vencedor_iniciativa == global.online_assento) {
                if (point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _iniciativa_cx-215, _iniciativa_cy+55, _iniciativa_cx-15, _iniciativa_cy+105)) online_escolher_primeiro(global.online_assento);
                else if (point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _iniciativa_cx+15, _iniciativa_cy+55, _iniciativa_cx+215, _iniciativa_cy+105)) online_escolher_primeiro(1-global.online_assento);
            }
        }
    } else if (disputa_inicial_estado == "online_preparar") {
        if (instance_exists(obj_deck) && variable_global_exists("online_estado_publico")
            && is_struct(global.online_estado_publico)) {
            online_reconstruir_mao_privada();
            online_aplicar_estado_publico(global.online_estado_publico);
        }
    } else if (disputa_inicial_estado == "preparando_dado") {
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
            } else {
                disputa_inicial_vencedor = (disputa_inicial_resultado_jogador > disputa_inicial_resultado_inimigo)
                    ? "jogador" : "inimigo";
                if (disputa_inicial_vencedor == "jogador") {
                    disputa_inicial_estado = "escolha_jogador";
                } else {
                    disputa_inicial_estado = "escolha_inimigo";
                    disputa_inicial_timer = 65;
                }
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
            if (modo_partida == "online") {
                if (online_comprar_mao_inicial()) {
                    disputa_inicial_estado = "online_aguardando_mao";
                    _deck_inicial.pulso_timer = _deck_inicial.pulso_duracao;
                }
            } else {
                comprar_mao_inicial();
                comprar_mao_inicial_ia();
                disputa_inicial_estado = "distribuindo";
                disputa_inicial_timer = quantidade_inicial * 7 + 45;
            }
        }
    } else if (disputa_inicial_estado == "distribuindo") {
        disputa_inicial_timer--;
        if (disputa_inicial_timer <= 0) {
            disputa_inicial_estado = "preparando_dado";
            disputa_inicial_timer = 18;
        }
    }
    return true;
}

// Dados Manipulados pausa apenas a resolução que depende daquele dado.
if (!ui_modal.dados_manipulados_escolha_ativa && array_length(dados_manipulados_escolhas) > 0) {
    ui_modal.dados_manipulados_escolha_atual = dados_manipulados_escolhas[0];
    array_delete(dados_manipulados_escolhas, 0, 1);
    ui_modal.dados_manipulados_escolha_ativa = true;
}
if (ui_modal.dados_manipulados_escolha_ativa) {
    var _dados_cx = _tutorial_largura_gui / 2;
    var _dados_cy = _tutorial_altura_gui / 2;
    if (mouse_check_button_pressed(mb_left)) {
        if (point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _dados_cx - 190, _dados_cy + 35, _dados_cx - 10, _dados_cy + 82))
            resolver_escolha_dados_manipulados(false);
        else if (point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _dados_cx + 10, _dados_cy + 35, _dados_cx + 190, _dados_cy + 82))
            resolver_escolha_dados_manipulados(true);
    }
    return true;
}

// A Máquina Imã pede qual equipamento da tropa derrotada volta à mão.
if (!ui_modal.maquina_ima_escolha_ativa && array_length(maquina_ima_pendencias) > 0) {
    ui_modal.maquina_ima_escolha_atual = maquina_ima_pendencias[0];
    array_delete(maquina_ima_pendencias, 0, 1);
    ui_modal.maquina_ima_escolha_ativa = true;
}
if (ui_modal.maquina_ima_escolha_ativa) {
    var _ima_cx = _tutorial_largura_gui / 2;
    var _ima_cy = _tutorial_altura_gui / 2;
    if (mouse_check_button_pressed(mb_left)) {
        for (var _ima_i = 0; _ima_i < array_length(ui_modal.maquina_ima_escolha_atual.itens); _ima_i++) {
            var _ima_y = _ima_cy - 35 + _ima_i * 36;
            if (point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _ima_cx - 210, _ima_y, _ima_cx + 210, _ima_y + 30)) {
                resolver_escolha_maquina_ima(_ima_i);
                break;
            }
        }
    }
    return true;
}

// Visão do Véu bloqueia as demais ações até escolher uma armadilha revelada
// ou a proteção contra a próxima armadilha.
if (ui_modal.visao_veu_ativa) {
    var _veu_cx = _tutorial_largura_gui / 2;
    var _veu_cy = _tutorial_altura_gui / 2;
    if (keyboard_check_pressed(vk_escape)) resolver_visao_veu_escolha(-1);
    else if (mouse_check_button_pressed(mb_left)) {
        var _escolheu_veu = false;
        for (var i = 0; i < array_length(ui_modal.visao_veu_opcoes); i++) {
            var _col = i mod 3;
            var _lin = floor(i / 3);
            var _x1 = _veu_cx - 270 + _col * 180;
            var _y1 = _veu_cy - 95 + _lin * 30;
            if (ui_modal.visao_veu_opcoes[i].armadilha && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _x1, _y1, _x1 + 170, _y1 + 24)) {
                resolver_visao_veu_escolha(i); _escolheu_veu = true; break;
            }
        }
        if (!_escolheu_veu && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _veu_cx - 190, _veu_cy + 125, _veu_cx + 190, _veu_cy + 170)) resolver_visao_veu_escolha(-1);
    }
    return true;
}

// Só abre a próxima escolha quando todos os dados da ação anterior terminarem.
if (!ui_modal.critico_escolha_ativa && array_length(ui_modal.criticos_pendentes) > 0 && rolagens_pendentes <= 0) {
    abrir_proxima_escolha_critico();
}

// O crítico pausa novas interações até o jogador escolher a forma do dano.
if (ui_modal.critico_escolha_ativa) {
    var _critico_cx = _tutorial_largura_gui / 2;
    var _critico_cy = _tutorial_altura_gui / 2;
    var _clicou_dois_dados = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _critico_cx - 225, _critico_cy + 55, _critico_cx - 15, _critico_cy + 112);
    var _clicou_dobrar_resultado = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _critico_cx + 15, _critico_cy + 55, _critico_cx + 225, _critico_cy + 112);
    if (_clicou_dois_dados) resolver_escolha_critico("dobrar_dados");
    else if (_clicou_dobrar_resultado) resolver_escolha_critico("dobrar_resultado");
    return true;
}

// Confirmação da retirada de recurso: só retira depois da escolha do jogador.
if (ui_modal.confirmacao_recurso_ativa) {
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

    if (_confirmar_recurso && instance_exists(ui_modal.recurso_pendente_retirada)) {
        retirar_recurso_do_campo(ui_modal.recurso_pendente_retirada);
        ui_modal.recurso_pendente_retirada = noone;
        ui_modal.confirmacao_recurso_ativa = false;
    } else if (keyboard_check_pressed(vk_escape) || _cancelar_recurso
        || !instance_exists(ui_modal.recurso_pendente_retirada)) {
        ui_modal.recurso_pendente_retirada = noone;
        ui_modal.confirmacao_recurso_ativa = false;
    }
    return true;
}

// Armadilhas preparadas pela IA continuam secretas e são resolvidas assim que
// uma tropa do jogador entra no espaço vigiado. As armadilhas do jogador permanecem manuais.
if (modo_partida == "ia" && partida_iniciada && turno == "jogador" && ia_ativar_armadilhas_prontas()) return true;

// Confirmação do descarte manual: a carta só sai da mão após a escolha do jogador.
if (ui_modal.confirmacao_descarte_ativa) {
    var _confirmacao_cx = _tutorial_largura_gui / 2;
    var _confirmacao_cy = _tutorial_altura_gui / 2;
    var _confirmar_descarte = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _confirmacao_cx - 180, _confirmacao_cy + 42, _confirmacao_cx - 12, _confirmacao_cy + 82);
    var _cancelar_descarte = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _confirmacao_cx + 12, _confirmacao_cy + 42, _confirmacao_cx + 180, _confirmacao_cy + 82);

    if (_confirmar_descarte && instance_exists(ui_modal.carta_pendente_descarte)) {
        var _carta_descarte = ui_modal.carta_pendente_descarte;
        var _indice_mao_descarte = array_get_index(mao, _carta_descarte);
        if (_indice_mao_descarte != -1) {
            array_delete(mao, _indice_mao_descarte, 1);
            organizar_mao();
        }
        registrar_descarte(_carta_descarte);
        mostrar_feedback("DESCARTADA", _carta_descarte.x, _carta_descarte.y - 30, c_gray, 35);
        instance_destroy(_carta_descarte);
        ui_modal.carta_pendente_descarte = noone;
        ui_modal.confirmacao_descarte_ativa = false;
    } else if (keyboard_check_pressed(vk_escape) || _cancelar_descarte || !instance_exists(ui_modal.carta_pendente_descarte)) {
        if (instance_exists(ui_modal.carta_pendente_descarte)) {
            ui_modal.carta_pendente_descarte.x = ui_modal.carta_pendente_descarte.origem_x;
            ui_modal.carta_pendente_descarte.y = ui_modal.carta_pendente_descarte.origem_y;
            ui_modal.carta_pendente_descarte.esta_na_mao = true;
        }
        ui_modal.carta_pendente_descarte = noone;
        ui_modal.confirmacao_descarte_ativa = false;
    }
    return true;
}

// A pilha de descarte é apenas de consulta, mas bloqueia ações enquanto estiver aberta.
if (ui_modal.descarte_aberto) {
    var _descarte_cx = _tutorial_largura_gui / 2;
    var _descarte_cy = _tutorial_altura_gui / 2;
    var _fechar_descarte = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _descarte_cx + 240, _descarte_cy - 180, _descarte_cx + 280, _descarte_cy - 140);
    var _primeira_carta_descarte = max(0, array_length(descarte_jogador) - 12);
    var _linha_descarte = floor((_tutorial_gui_y - (_descarte_cy - 110)) / 21);
    var _clicou_linha_descarte = mouse_check_button_pressed(mb_left)
        && ui_modal.descarte_preview_indice == -1
        && _tutorial_gui_x >= _descarte_cx - 245 && _tutorial_gui_x <= _descarte_cx + 245
        && _linha_descarte >= 0 && _linha_descarte < array_length(descarte_jogador) - _primeira_carta_descarte;
    var _clicou_voltar_descarte = mouse_check_button_pressed(mb_left)
        && ui_modal.descarte_preview_indice != -1
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _descarte_cx - 245, _descarte_cy + 145, _descarte_cx - 80, _descarte_cy + 180);

    if (keyboard_check_pressed(vk_escape) || _fechar_descarte) {
        if (ui_modal.descarte_preview_indice != -1) ui_modal.descarte_preview_indice = -1;
        else ui_modal.descarte_aberto = false;
    } else if (_clicou_voltar_descarte) {
        ui_modal.descarte_preview_indice = -1;
    } else if (_clicou_linha_descarte) {
        ui_modal.descarte_preview_indice = _primeira_carta_descarte + _linha_descarte;
    }
    return true;
}

// A prévia recebe a entrada antes dos controles do HUD que ela cobre.
if (carta_preview != noone) {
    if (!instance_exists(carta_preview) || mouse_check_button_pressed(mb_right) || keyboard_check_pressed(vk_escape)) {
        carta_preview = noone;
    }
    if (turno == "inimigo" && ia_ativa) processar_turno_ia();
    return true;
}

var _botoes_direita_x1 = _tutorial_largura_gui - 205 + hud_deslocamento_direita;
var _botoes_direita_x2 = _tutorial_largura_gui - 15 + hud_deslocamento_direita;
if (!ui_modal.pausa_ativa && (keyboard_check_pressed(vk_f1) || (mouse_check_button_pressed(mb_left)
    && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _botoes_direita_x1, 30, _botoes_direita_x2, 62)))) {
    ui_modal.tutorial_ativo = true;
    ui_modal.tutorial_pagina = 0;
    carta_preview = noone;
    carta_menu_aberto = noone;
    return true;
}

// Pausa manual: mantém o jogo aberto e impede qualquer ação enquanto o painel estiver visível.
var _pausa_x1 = _botoes_direita_x1;
var _pausa_x2 = _botoes_direita_x2;
var _clicou_pausa = mouse_check_button_pressed(mb_left)
    && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_x1, 152, _pausa_x2, 184);
if (ui_modal.pausa_ativa) {
    var _pausa_cx = _tutorial_largura_gui / 2;
    var _pausa_cy = _tutorial_altura_gui / 2;
    if (ui_modal.opcoes_pausa_ativa) {
        var _musica_y = _pausa_cy - 35;
        var _efeitos_y = _pausa_cy + 10;
        var _tela_y = _pausa_cy + 55;
        var _interface_y = _pausa_cy + 98;
        var _voltar_y = _pausa_cy + 190;
        if (keyboard_check_pressed(vk_escape)) {
            ui_modal.opcoes_pausa_ativa = false;
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx-85, _efeitos_y-18, _pausa_cx+85, _efeitos_y+18)) {
            global.canal_audio_opcoes=(global.canal_audio_opcoes+1) mod 4;
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 147, _musica_y - 14, _pausa_cx - 103, _musica_y + 14)) {
            global.volume_musica = clamp(global.volume_musica - 0.1, 0, 1);
            aplicar_config_audio();
            salvar_configuracoes();
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx + 103, _musica_y - 14, _pausa_cx + 147, _musica_y + 14)) {
            global.volume_musica = clamp(global.volume_musica + 0.1, 0, 1);
            aplicar_config_audio();
            salvar_configuracoes();
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 147, _efeitos_y - 14, _pausa_cx - 103, _efeitos_y + 14)) {
            ajustar_canal_audio(-0.1);
            aplicar_config_audio();
            salvar_configuracoes();
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx + 103, _efeitos_y - 14, _pausa_cx + 147, _efeitos_y + 14)) {
            ajustar_canal_audio(0.1);
            aplicar_config_audio();
            salvar_configuracoes();
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 130, _tela_y - 14, _pausa_cx + 130, _tela_y + 14)) {
            window_set_fullscreen(!window_get_fullscreen());
            salvar_configuracoes();
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 130, _interface_y - 14, _pausa_cx + 130, _interface_y + 14)) {
            alternar_tamanho_interface();
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x,_tutorial_gui_y,_pausa_cx-130,_pausa_cy+128,_pausa_cx+130,_pausa_cy+156)) {
            alternar_efeitos_visuais();
        } else if (mouse_check_button_pressed(mb_left) && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 110, _voltar_y - 14, _pausa_cx + 110, _voltar_y + 14)) {
            ui_modal.opcoes_pausa_ativa = false;
        }
        return true;
    }
    var _clicou_continuar = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 125, _pausa_cy + 35, _pausa_cx + 125, _pausa_cy + 75);
    var _clicou_opcoes = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 125, _pausa_cy + 90, _pausa_cx + 125, _pausa_cy + 130);
    var _clicou_sair = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(_tutorial_gui_x, _tutorial_gui_y, _pausa_cx - 125, _pausa_cy + 145, _pausa_cx + 125, _pausa_cy + 185);
    if (_clicou_sair) {
        if (modo_partida == "online" && online_ativo()) {
            colyseus_send(global.net_room, "concede", {});
            online_desconectar();
        }
        ui_modal.pausa_ativa = false;
        trocar_sala_suave(rm_menu);
    } else if (_clicou_opcoes) {
        ui_modal.opcoes_pausa_ativa = true;
    } else if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("P")) || _clicou_continuar) {
        ui_modal.pausa_ativa = false;
    } else if (keyboard_check_pressed(vk_f1)) {
        ui_modal.pausa_ativa = false;
        ui_modal.tutorial_ativo = true;
        ui_modal.tutorial_pagina = 0;
    }
    return true;
}
if (keyboard_check_pressed(ord("P")) || _clicou_pausa) {
    ui_modal.pausa_ativa = true;
    ui_modal.opcoes_pausa_ativa = false;
    carta_preview = noone;
    carta_menu_aberto = noone;
    tropa_selecionada = noone;
    return true;
}

// Abre/fecha a lista do cemitério pelo botão do HUD.
var _mouse_gui_x_cemiterio = device_mouse_x_to_gui(0);
var _mouse_gui_y_cemiterio = device_mouse_y_to_gui(0);
var _gui_largura_cemiterio = display_get_gui_width();
if (mouse_check_button_pressed(mb_left)
    && point_in_rectangle(_mouse_gui_x_cemiterio, _mouse_gui_y_cemiterio, 14 - hud_deslocamento_esquerda, 210, 190 - hud_deslocamento_esquerda, 242)) {
    ui_modal.historico_aberto = !ui_modal.historico_aberto;
    return true;
}
if (mouse_check_button_pressed(mb_left)
    && point_in_rectangle(_mouse_gui_x_cemiterio, _mouse_gui_y_cemiterio, _gui_largura_cemiterio - 205 + hud_deslocamento_direita, 72, _gui_largura_cemiterio - 15 + hud_deslocamento_direita, 104)) {
    ui_modal.cemiterio_aberto = !ui_modal.cemiterio_aberto;
    return true;
}

// A IA continua processando em etapas, mas a interface não é congelada:
// o jogador ainda pode inspecionar o campo e reorganizar a própria mão.
if (turno == "inimigo" && ia_ativa) {
    processar_turno_ia();
}

// Espaço encerra o turno do jogador. Escolhas simples de alvo são canceladas;
// rolagens e a escolha de crítico precisam terminar antes para não cortar efeitos.
if (lado_controlado_localmente(turno) && partida_iniciada && keyboard_check_pressed(vk_space)) {
    if (rolagens_pendentes > 0 || ui_modal.critico_escolha_ativa || array_length(ui_modal.criticos_pendentes) > 0) {
        mostrar_aviso_regra("Aguarde a rolagem terminar", mouse_x, mouse_y);
    } else {
        ui_modal.digestao_selecao_ativa = false; ui_modal.digestao_origem = noone;
        ui_modal.troca_item_selecao_ativa = false; ui_modal.troca_item_origem = noone;
        carta_preview = noone; carta_menu_aberto = noone; tropa_selecionada = noone;
        passar_turno_jogador();
    }
    return true;
}

        return false;
    });
    return _processar();
}

function controlador_processar_interacao(_controle) {
    var _processar = method(_controle, function() {
#region Atalhos de teclado (debug/teste)
if (keyboard_check_pressed(vk_escape)) {
    if (instance_exists(obj_livro) && obj_livro.preview_ativo) {
        obj_livro.preview_ativo = false;
    } else {
        ui_modal.pausa_ativa = true;
    }
}
if (keyboard_check_pressed(ord("R")) && global.DEBUG_COMBATE && modo_partida != "online") {
    room_restart();
}

if (keyboard_check_pressed(ord("K")) && global.DEBUG_COMBATE && modo_partida != "online") {
    vida_inimigo = 0;
}

// NOVO: pede o nome de uma carta e coloca ela direto na mão (sem gastar do monte).
if (keyboard_check_pressed(ord("V")) && global.DEBUG_COMBATE && modo_partida != "online") {
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
if (keyboard_check_pressed(ord("F")) && global.DEBUG_COMBATE && modo_partida != "online") {
    debug_encher_recursos("jogador");
}

if (keyboard_check_pressed(ord("C")) && global.DEBUG_COMBATE && modo_partida != "online") {
    var _quantidade_debug = 10;
    for (var i = 0; i < _quantidade_debug; i++) {
        if (array_length(monte) == 0) break;
        comprar_carta_do_deck(obj_deck.x, obj_deck.y);
    }
    debug_combate("DEBUG: comprou " + string(_quantidade_debug) + " cartas pro jogador.");
}

if (keyboard_check_pressed(ord("M"))&& global.DEBUG_COMBATE && modo_partida != "online") {
    jogar_moeda_visual(mao_x_centro, mao_y, room_width / 2, room_height / 2, noone);
}
#endregion

if (vida_jogador <= 0) return true; // jogo acabou, para de processar interação

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
    var _alvo_preview = (hover_atual != noone) ? hover_atual
        : ((_hover_campo != noone) ? _hover_campo : _hover_construcao);
    if (tropa_oculta_nevoa(_alvo_preview)) {
        mostrar_aviso_regra("Tropa oculta pela névoa até o fim do turno",mouse_x,mouse_y);
        return true;
    }
    if (_alvo_preview != noone) {
        carta_preview = _alvo_preview;
        return true;
    }
}
#endregion

// A Mitose coloca o primeiro Slimet na casa da morte e deixa o jogador
// escolher uma das casas adjacentes livres para o segundo.
if (ui_modal.mitose_selecao_ativa) {
    if (mouse_check_button_pressed(mb_left)) {
        var _slot_mitose_escolhido = noone;
        var _menor_distancia_mitose = 38;
        for (var _mi = 0; _mi < array_length(ui_modal.mitose_slots_pendentes); _mi++) {
            var _slot_mi = ui_modal.mitose_slots_pendentes[_mi];
            if (_slot_mi != noone && !_slot_mi.ocupado) {
                var _dist_mi = point_distance(mouse_x, mouse_y, _slot_mi.x, _slot_mi.y);
                if (_dist_mi < _menor_distancia_mitose) { _menor_distancia_mitose = _dist_mi; _slot_mitose_escolhido = _slot_mi; }
            }
        }
        if (_slot_mitose_escolhido != noone) {
            if (modo_partida == "online") {
                online_enviar_acao("choose_mitosis", { lane: _slot_mitose_escolhido.lane, position: _slot_mitose_escolhido.posicao });
                ui_modal.mitose_selecao_ativa = false;
                ui_modal.mitose_slots_pendentes = [];
                return true;
            }
            criar_tropa_no_slot(ui_modal.mitose_dados_pendentes, _slot_mitose_escolhido, ui_modal.mitose_dono_pendente);
            ui_modal.mitose_selecao_ativa = false;
            ui_modal.mitose_slots_pendentes = [];
        } else mostrar_aviso_regra("Escolha uma casa adjacente destacada", mouse_x, mouse_y);
    } else if (keyboard_check_pressed(vk_escape)) {
        if (modo_partida == "online") { mostrar_aviso_regra("Escolha onde colocar o segundo Slimet"); return true; }
        comprar_carta_do_deck_por_funcao(ui_modal.mitose_funcao_pendente, room_width / 2, obj_controlador.mao_y, ui_modal.mitose_dono_pendente);
        ui_modal.mitose_selecao_ativa = false;
        ui_modal.mitose_slots_pendentes = [];
    }
    return true;
}

// Modos de escolha iniciados por habilidades e ações do menu.
if (ui_modal.digestao_selecao_ativa) {
    if (!instance_exists(ui_modal.digestao_origem) || keyboard_check_pressed(vk_escape) || mouse_check_button_pressed(mb_right)) {
        ui_modal.digestao_selecao_ativa = false; ui_modal.digestao_origem = noone;
    } else if (mouse_check_button_pressed(mb_left)) {
        var _alvo_digestao = instance_position(mouse_x, mouse_y, obj_carta);
        if (alvo_valido_digestao(ui_modal.digestao_origem, _alvo_digestao)) {
            if (modo_partida == "online") {
                online_enviar_acao("use_ability", { cardId: ui_modal.digestao_origem.online_instance_id,
                    ability: "digestao", targetId: _alvo_digestao.online_instance_id });
            } else resolver_digestao(ui_modal.digestao_origem, _alvo_digestao);
            ui_modal.digestao_selecao_ativa = false; ui_modal.digestao_origem = noone; tropa_selecionada = noone; carta_menu_aberto = noone;
        } else mostrar_aviso_regra("Escolha tropa adjacente com menos de 4 de vida", mouse_x, mouse_y);
    }
    return true;
}

if (ui_modal.troca_item_selecao_ativa) {
    if (!instance_exists(ui_modal.troca_item_origem) || keyboard_check_pressed(vk_escape) || mouse_check_button_pressed(mb_right)) {
        ui_modal.troca_item_selecao_ativa = false; ui_modal.troca_item_origem = noone;
    } else if (mouse_check_button_pressed(mb_left)) {
        var _destino_item = instance_position(mouse_x, mouse_y, obj_carta);
        if (instance_exists(_destino_item) && _destino_item != ui_modal.troca_item_origem && _destino_item.travada
            && _destino_item.dono == ui_modal.troca_item_origem.dono && _destino_item.mochila > 0 && !_destino_item.troca_item_usada_este_turno) {
            if (modo_partida == "online") {
                online_enviar_acao("transfer_item", { cardId: ui_modal.troca_item_origem.online_instance_id,
                    targetId: _destino_item.online_instance_id });
            } else transferir_item_equipado(ui_modal.troca_item_origem, _destino_item, array_length(ui_modal.troca_item_origem.itens_equipados) - 1);
            ui_modal.troca_item_selecao_ativa = false; ui_modal.troca_item_origem = noone; tropa_selecionada = noone; carta_menu_aberto = noone;
        } else mostrar_aviso_regra("Escolha uma tropa aliada com espaço na mochila", mouse_x, mouse_y);
    }
    return true;
}

// A seleção continua disponível para consulta até durante o turno inimigo.
if (tropa_selecionada != noone && (!instance_exists(tropa_selecionada)
    || !tropa_selecionada.travada || tropa_selecionada.dono != turno)) {
    tropa_selecionada = noone;
}

#region Hover e clique nas cartas da mão
var _total = array_length(mao);
var _melhor_carta = noone;
var _menor_distancia = 999999;

for (var i = 0; i < _total; i++) {
    var _carta = mao[i];
    if (!instance_exists(_carta)) continue;
    if (_carta.arrastando || _carta.compra_animando) continue;
    if (!_carta.esta_na_mao) continue;
    if (_carta.travada) continue;

    var _meia_altura_mao = global.CARTA_ALTURA * 0.5 * global.escala_interface;
    var _dentro_y = (mouse_y >= _carta.y - _meia_altura_mao - 40 * global.escala_interface)
                  && (mouse_y <= _carta.y + _meia_altura_mao);

    if (_dentro_y) {
        var _dist_x = abs(mouse_x - _carta.x);
        if (_dist_x < global.CARTA_LARGURA * 0.5 * global.escala_interface && _dist_x < _menor_distancia) {
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
        if (modo_partida == "online") online_enviar_acao("activate_trap", { trapId: hover_atual.online_instance_id });
        else ativar_armadilha(hover_atual.id);
    } else if (hover_atual != noone && instance_exists(hover_atual)
        && hover_atual.categoria == "armadilha" && hover_atual.armadilha_estado == "vigiando") {
        mostrar_aviso_regra("Armadilha já posicionada", hover_atual.x, hover_atual.y - 35);
    } else if (hover_atual != noone && instance_exists(hover_atual) && !hover_atual.travada) {
        with (hover_atual) {
            arrastando = true;
            esta_na_mao = false;
            // Profundidade exclusiva: nenhuma carta da mão ou em animação passa na frente.
            depth = -12000;
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
    var _alcance_mao = (global.CARTA_ALTURA * 0.5 + 40) * global.escala_interface;
    var _dentro_faixa_mao = abs(mouse_y - mao_y) <= _alcance_mao;

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

    var _layout_menu = layout_menu_tropa(_carta, _n);
    var _largura_opcao = _layout_menu.largura;
    var _altura_opcao = _layout_menu.altura;
    var _espaco_opcao = _layout_menu.espaco;
    var _base_x = _layout_menu.x;
    var _base_y = _layout_menu.y;

    for (var i = 0; i < _n; i++) {
        var _opt_y = _base_y + i * (_altura_opcao + _espaco_opcao);
        if (mouse_x > _base_x && mouse_x < _base_x + _largura_opcao + 12
            && mouse_y > _opt_y - 2 && mouse_y < _opt_y + _altura_opcao + 2) {
            opcao_hover_index = i;
            if (mouse_check_button_pressed(mb_left)) menu_opcao_pressionada = i;

            if (mouse_check_button_released(mb_left) && menu_opcao_pressionada == i) {
                var _opcao_clicada = _opcoes[i];
                if (_opcao_clicada == "Ataque") {
                    menu_submenu = "ataque";
                    opcao_hover_index = -1;
                    menu_escala = 0.88;
                    menu_opcao_hover_anim = [];
                    menu_opcao_press_anim = [];
                } else if (_opcao_clicada == "Movimento") {
                    menu_submenu = "movimento";
                    opcao_hover_index = -1;
                    menu_escala = 0.88;
                    menu_opcao_hover_anim = [];
                    menu_opcao_press_anim = [];
                } else if (_opcao_clicada == "Itens") {
                    menu_submenu = "itens";
                    opcao_hover_index = -1;
                    menu_escala = 0.88;
                    menu_opcao_hover_anim = [];
                    menu_opcao_press_anim = [];
                } else if (_opcao_clicada == "Voltar") {
                    menu_submenu = "";
                    opcao_hover_index = -1;
                    menu_escala = 0.88;
                    menu_opcao_hover_anim = [];
                    menu_opcao_press_anim = [];
                } else {
                    executar_opcao_menu(_carta, _opcao_clicada);
                    carta_menu_aberto = noone;
                    menu_submenu = "";
                    tropa_selecionada = noone;
                }
            }
            break;
        }
    }
}

if (mouse_check_button_released(mb_left)) menu_opcao_pressionada = -1;

if (carta_menu_aberto != noone && instance_exists(carta_menu_aberto)) {
    var _opcoes_animadas = obter_opcoes_menu(carta_menu_aberto);
    var _qtd_opcoes_animadas = array_length(_opcoes_animadas);
    array_resize(menu_opcao_hover_anim, _qtd_opcoes_animadas);
    array_resize(menu_opcao_press_anim, _qtd_opcoes_animadas);
    for (var _anim_i = 0; _anim_i < _qtd_opcoes_animadas; _anim_i++) {
        if (is_undefined(menu_opcao_hover_anim[_anim_i])) menu_opcao_hover_anim[_anim_i] = 0;
        if (is_undefined(menu_opcao_press_anim[_anim_i])) menu_opcao_press_anim[_anim_i] = 0;
        var _alvo_hover_opcao = (_anim_i == opcao_hover_index) ? 1 : 0;
        var _alvo_press_opcao = (_anim_i == menu_opcao_pressionada && mouse_check_button(mb_left)) ? 1 : 0;
        menu_opcao_hover_anim[_anim_i] = lerp(menu_opcao_hover_anim[_anim_i], _alvo_hover_opcao, 0.28);
        menu_opcao_press_anim[_anim_i] = lerp(menu_opcao_press_anim[_anim_i], _alvo_press_opcao, 0.42);
    }
} else {
    menu_opcao_pressionada = -1;
    menu_opcao_hover_anim = [];
    menu_opcao_press_anim = [];
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

        return false;
    });
    return _processar();
}
