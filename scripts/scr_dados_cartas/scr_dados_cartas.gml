// =============================================================================
// KARTHA — núcleo da partida
// Tabuleiro e fluxo de turnos compartilhados por todos os sistemas.
// =============================================================================

#region Debug / Configuração
// Liga/desliga os logs de rastreamento de combate (rolagens, dano, habilidades).
// Deixe true enquanto ainda estiver ajustando balanceamento/bugs;
// mude pra false quando quiser um console limpo pra jogar de verdade.
// (o valor inicial é definido no Create Event do obj_controlador)
function debug_combate(_msg) {
    if (global.DEBUG_COMBATE) {
        show_debug_message(_msg);
    }

    // Histórico curto e visível na partida, independente do console de debug.
    if (instance_exists(obj_controlador)) {
        var _controle = instance_find(obj_controlador, 0);
        if (!variable_instance_exists(_controle, "historico_combate") || !is_array(_controle.historico_combate)) {
            _controle.historico_combate = [];
        }
        if (!variable_instance_exists(_controle, "max_historico_combate") || _controle.max_historico_combate < 15) {
            _controle.max_historico_combate = 15;
        }
        array_push(_controle.historico_combate, _msg);
        while (array_length(_controle.historico_combate) > _controle.max_historico_combate) {
            array_delete(_controle.historico_combate, 0, 1);
        }
    }
}
#endregion

#region Tabuleiro — grade e posições
// Grade central da room: 3 lanes (colunas) por 5 posições (linhas).
// posicao: 0 = base inimiga, 1 = assalto do jogador, 2 = MEIO (centro do combate),
//          3 = assalto do inimigo, 4 = base do jogador.
// Identifica lane/posicao de cada obj_slot_batalha automaticamente pela posição na room.
function organizar_grade_batalha() {
    var _linhas_y = [];
    var _colunas_x = [];

    with (obj_slot_batalha) {
        if (array_get_index(_linhas_y, y) == -1) array_push(_linhas_y, y);
        if (array_get_index(_colunas_x, x) == -1) array_push(_colunas_x, x);
    }

    array_sort(_linhas_y, true);
    array_sort(_colunas_x, true);

    with (obj_slot_batalha) {
        posicao = array_get_index(_linhas_y, y);
        lane = array_get_index(_colunas_x, x);
    }
}

// Organiza a lane dos slots de construção SEPARADAMENTE por dono (jogador/inimigo).
// Precisa ser por dono porque a numeração não pode se misturar entre os dois lados,
// senão não bate com as lanes do campo de batalha na hora de mirar um ataque.
function ordenar_lane_por_dono(_obj, _dono_alvo) {
    var _lista = [];
    with (_obj) {
        if (dono == _dono_alvo) array_push(_lista, id);
    }

    var _n = array_length(_lista);
    for (var i = 0; i < _n - 1; i++) {
        for (var j = 0; j < _n - i - 1; j++) {
            if (_lista[j].x > _lista[j+1].x) {
                var _temp = _lista[j];
                _lista[j] = _lista[j+1];
                _lista[j+1] = _temp;
            }
        }
    }

    for (var i = 0; i < _n; i++) {
        _lista[i].lane = i;
    }
}

function posicao_entrada(_dono) {
    return (_dono == "jogador") ? 4 : 0;
}

function posicao_ataque() {
    return 2; // o MEIO — tropas podem combater aqui, mas ainda não atingem o castelo
}

function direcao_avanco(_dono) {
    return (_dono == "jogador") ? -1 : 1;
}

// Para causar dano direto ao castelo, a tropa precisa sair do meio e avançar
function partida_local_ativa() {
    return instance_exists(obj_controlador) && (obj_controlador.modo_partida == "local" || obj_controlador.modo_partida == "online");
}

function lado_oposto(_dono) {
    return (_dono == "jogador") ? "inimigo" : "jogador";
}

function nome_jogador_lado(_dono) {
    if (instance_exists(obj_controlador) && obj_controlador.modo_partida == "online")
        return (_dono == "jogador") ? global.online_nome_jogador : global.online_nome_inimigo;
    if (partida_local_ativa()) return (_dono == "jogador") ? "JOGADOR 1" : "JOGADOR 2";
    return (_dono == "jogador") ? "JOGADOR" : "INIMIGO";
}

function lado_controlado_localmente(_dono) {
    if (!instance_exists(obj_controlador)) return false;
    if (obj_controlador.modo_partida == "online") {
        return online_ativo() && !obj_controlador.passagem_turno_ativa
            && obj_controlador.turno == _dono && online_lado_local() == _dono;
    }
    if (partida_local_ativa()) {
        return !obj_controlador.passagem_turno_ativa && obj_controlador.turno == _dono;
    }
    return _dono == "jogador";
}

function primeiro_turno_do_lado(_dono) {
    return (_dono == "jogador") ? obj_controlador.primeiro_turno_jogador
        : obj_controlador.primeiro_turno_inimigo;
}

function recurso_ja_colocado_no_turno(_dono) {
    return (_dono == "jogador") ? obj_controlador.recurso_colocado_no_turno
        : obj_controlador.recurso_colocado_no_turno_inimigo;
}
// mais uma casa. A regra é espelhada para jogador e inimigo.
function posicao_assalto(_dono) {
    return posicao_ataque() + direcao_avanco(_dono);
}

// Cada lado pode manter no máximo uma tropa em cada coluna, independentemente
// da posição em que ela esteja. Tropas morrendo já não bloqueiam a coluna.
function buscar_tropa_na_coluna(_lane, _dono, _ignorar = noone) {
    var _resultado = noone;
    with (obj_carta) {
        if (id != _ignorar && travada && !morrendo && categoria == "tropa"
            && lane_atual == _lane && dono == _dono) {
            _resultado = id;
            break;
        }
    }
    return _resultado;
}

function total_posicoes_batalha() {
    return 5;
}
#endregion

#region Turnos — fluxo do jogador e da IA
function preparar_dado_disputa_inicial() {
    if (obj_controlador.rolagens_pendentes > 0) return;
    if (instance_exists(obj_controlador.dado_iniciativa_id)) instance_destroy(obj_controlador.dado_iniciativa_id);

    var _dado = instance_create_layer(room_width * 0.50, room_height * 0.68, "Instances", obj_dado);
    _dado.tamanho_dado = 20;
    _dado.valor_final = -1;
    _dado.interativo_iniciativa = true;
    _dado.ocultar_resultado_ate_rolar = true;
    _dado.girando = false;
    _dado.escala_base_dado = 3.25;
    _dado.image_xscale = _dado.escala_base_dado;
    _dado.image_yscale = _dado.escala_base_dado;
    _dado.iniciativa_mesa_x = _dado.x;
    _dado.iniciativa_mesa_y = _dado.y;
    obj_controlador.dado_iniciativa_id = _dado;
    obj_controlador.disputa_inicial_estado = "aguardando_arremesso";
}

// Chamado pelo próprio D20 quando o jogador realmente o arrasta e solta.
function lancar_dado_disputa_inicial(_dado, _velocidade_arremesso) {
    if (!instance_exists(_dado) || obj_controlador.disputa_inicial_estado != "aguardando_arremesso") return;

    obj_controlador.disputa_inicial_estado = "rolando";
    // No segundo lançamento local, preserve o resultado do Jogador 1.
    if (!partida_local_ativa() || obj_controlador.iniciativa_rolador == "jogador")
        obj_controlador.disputa_inicial_resultado_jogador = -1;
    obj_controlador.disputa_inicial_resultado_inimigo = -1;

    // No modo local cada pessoa arremessa o proprio D20. Entre os lancamentos
    // a tela e escondida para que o segundo jogador possa assumir o computador.
    if (partida_local_ativa()) {
        var _lado_rolando = obj_controlador.iniciativa_rolador;
        var _resultado_local = irandom_range(1, 20);
        var _controle_local = {
            controle: instance_find(obj_controlador, 0),
            lado: _lado_rolando
        };
        var _margem_local = 58;
        var _destino_local_x = clamp(_dado.x + _dado.iniciativa_velocidade_x * 7,
            _margem_local, room_width - _margem_local);
        var _destino_local_y = clamp(_dado.y + _dado.iniciativa_velocidade_y * 7,
            90, room_height - 135);

        _dado.interativo_iniciativa = false;
        _dado.ocultar_resultado_ate_rolar = false;
        _dado.tamanho_dado = 20;
        _dado.valor_final = _resultado_local;
        _dado.modificador_exibido = 0;
        _dado.rotulo_resultado = "";
        _dado.cor_resultado = (_lado_rolando == "jogador") ? c_aqua : c_red;
        _dado.escala_texto_resultado = 1.22;
        _dado.offset_texto_resultado = 2;
        _dado.pos_inicial_x = _dado.x;
        _dado.pos_inicial_y = _dado.y;
        _dado.destino_x = _destino_local_x;
        _dado.destino_y = _destino_local_y;
        _dado.depth = -2000;
        _dado.altura_maxima_dado = 75 + min(55, _velocidade_arremesso * 3);
        _dado.tempo_total_giro = clamp(round(82 - _velocidade_arremesso * 1.5), 50, 82);
        _dado.tempo_girando = 0;
        _dado.girando = true;
        _dado.callback = method(_controle_local, function(_resultado) {
            if (!instance_exists(controle)) return;
            if (lado == "jogador") {
                controle.disputa_inicial_resultado_jogador = _resultado;
                controle.disputa_inicial_estado = "troca_dado_local";
            } else {
                controle.disputa_inicial_resultado_inimigo = _resultado;
                controle.disputa_inicial_estado = "resultado";
                controle.disputa_inicial_timer = 55;
            }
            controle.dado_iniciativa_id = noone;
        });
        obj_controlador.rolagens_pendentes += 1;
        return;
    }

    var _resultado_jogador = irandom_range(1, 20);
    var _resultado_inimigo = irandom_range(1, 20);
    var _controle_jogador = { controle: instance_find(obj_controlador, 0) };
    var _controle_inimigo = { controle: instance_find(obj_controlador, 0) };
    // O seu dado continua na direção do gesto; o da IA escolhe outro pouso a cada disputa.
    var _margem_dado = 58;
    var _destino_jogador_x = clamp(_dado.x + _dado.iniciativa_velocidade_x * 7,
        _margem_dado, room_width - _margem_dado);
    var _destino_jogador_y = clamp(_dado.y + _dado.iniciativa_velocidade_y * 7,
        90, room_height - 135);
    var _destino_ia_x = random_range(room_width * 0.18, room_width * 0.82);
    var _destino_ia_y = random_range(room_height * 0.14, room_height * 0.46);
    for (var _tentativa_ia = 0; _tentativa_ia < 6; _tentativa_ia++) {
        if (point_distance(_destino_jogador_x, _destino_jogador_y, _destino_ia_x, _destino_ia_y) >= 145) break;
        _destino_ia_x = random_range(room_width * 0.18, room_width * 0.82);
        _destino_ia_y = random_range(room_height * 0.14, room_height * 0.46);
    }

    _dado.interativo_iniciativa = false;
    _dado.ocultar_resultado_ate_rolar = false;
    _dado.tamanho_dado = 20;
    _dado.valor_final = _resultado_jogador;
    _dado.modificador_exibido = 0;
    _dado.rotulo_resultado = "";
    _dado.cor_resultado = c_white;
    _dado.escala_texto_resultado = 1.22;
    _dado.offset_texto_resultado = 2;
    _dado.pos_inicial_x = _dado.x;
    _dado.pos_inicial_y = _dado.y;
    _dado.destino_x = _destino_jogador_x;
    _dado.destino_y = _destino_jogador_y;
    _dado.depth = -2000;
    _dado.altura_maxima_dado = 75 + min(55, _velocidade_arremesso * 3);
    _dado.tempo_total_giro = clamp(round(82 - _velocidade_arremesso * 1.5), 50, 82);
    _dado.tempo_girando = 0;
    _dado.girando = true;
    _dado.callback = method(_controle_jogador, function(_resultado) {
        if (!instance_exists(controle)) return;
        controle.disputa_inicial_resultado_jogador = _resultado;
        if (controle.disputa_inicial_resultado_inimigo >= 0) {
            controle.disputa_inicial_estado = "resultado";
            controle.disputa_inicial_timer = 55;
        }
    });
    obj_controlador.rolagens_pendentes += 1;

    var _dado_ia = rolar_dado_visual(random_range(room_width * 0.32, room_width * 0.68), 55, _destino_ia_x, _destino_ia_y,
        20, _resultado_inimigo, method(_controle_inimigo, function(_resultado) {
            if (!instance_exists(controle)) return;
            controle.disputa_inicial_resultado_inimigo = _resultado;
            if (controle.disputa_inicial_resultado_jogador >= 0) {
                controle.disputa_inicial_estado = "resultado";
                controle.disputa_inicial_timer = 55;
            }
        }), 0, irandom_range(8, 15), 78 + irandom_range(-5, 12));
    _dado_ia.rotulo_resultado = "";
    _dado_ia.cor_resultado = c_white;
    _dado_ia.escala_texto_resultado = 1.22;
    _dado_ia.offset_texto_resultado = 2;
}

// Compatibilidade com chamadas antigas: agora apenas coloca o D20 sobre a mesa.
function rolar_disputa_inicial() {
    preparar_dado_disputa_inicial();
}

function finalizar_disputa_inicial(_primeiro) {
    if (!obj_controlador.mao_inicial_comprada) {
        obj_controlador.disputa_inicial_primeiro_escolhido = _primeiro;
        obj_controlador.disputa_inicial_estado = "aguardando_deck";
        obj_controlador.disputa_inicial_vencedor = "";
        mostrar_feedback(nome_jogador_lado(_primeiro) + " COMEÇA — COMPRE A MÃO",
            obj_deck.x, obj_deck.y - 55, (_primeiro == "jogador") ? c_aqua : c_red, 80);
        return;
    }

    if (partida_local_ativa()) {
        obj_controlador.disputa_inicial_estado = "concluida";
        obj_controlador.disputa_inicial_vencedor = "";
        obj_controlador.partida_iniciada = true;
        if (_primeiro == "inimigo") {
            var _mao_primeiro = obj_controlador.mao;
            obj_controlador.mao = obj_controlador.mao_oculta;
            obj_controlador.mao_oculta = _mao_primeiro;
        }
        obj_controlador.turno = _primeiro;
        obj_controlador.passagem_turno_destino = _primeiro;
        obj_controlador.passagem_turno_ativa = (obj_controlador.modo_partida == "local");
        organizar_mao();
        return;
    }

    obj_controlador.disputa_inicial_estado = "concluida";
    obj_controlador.disputa_inicial_vencedor = "";
    obj_controlador.partida_iniciada = true;
    debug_combate((_primeiro == "jogador" ? "Jogador" : "Inimigo") + " foi escolhido para começar a partida.");

    if (_primeiro == "jogador") {
        obj_controlador.turno = "jogador";
        anunciar_turno("jogador");
    } else {
        iniciar_turno_inimigo(false);
    }
}

function aplicar_fim_turno_multijogador() {
    if (!instance_exists(obj_controlador)) return;
    var _lado_atual = obj_controlador.turno;
    if (_lado_atual != "jogador" && _lado_atual != "inimigo") return;
    if (_lado_atual == "inimigo") obj_controlador.turnos_completos += 1;
    obj_controlador.carta_menu_aberto = noone;
    if (_lado_atual == "jogador") obj_controlador.primeiro_turno_jogador = false;
    else obj_controlador.primeiro_turno_inimigo = false;
    expirar_condicoes(_lado_atual);

    var _troca_mao = obj_controlador.mao;
    obj_controlador.mao = obj_controlador.mao_oculta;
    obj_controlador.mao_oculta = _troca_mao;
    obj_controlador.online_aguardando_turno = false;
    iniciar_turno_local(lado_oposto(_lado_atual));
}

function online_aplicar_fim_turno() {
    if (!instance_exists(obj_controlador) || obj_controlador.modo_partida != "online") return;
    aplicar_fim_turno_multijogador();
}

function passar_turno_jogador() {
    if (obj_controlador.rolagens_pendentes > 0 || obj_controlador.ui_modal.critico_escolha_ativa
        || array_length(obj_controlador.ui_modal.criticos_pendentes) > 0) return;

    if (obj_controlador.modo_partida == "online") {
        if (!lado_controlado_localmente(obj_controlador.turno)
            || obj_controlador.online_aguardando_turno) return;
        obj_controlador.online_aguardando_turno = true;
        if (!online_enviar_acao("end_turn", {})) obj_controlador.online_aguardando_turno = false;
        return;
    }

    if (partida_local_ativa()) {
        aplicar_fim_turno_multijogador();
        return;
    }

    if (obj_controlador.turno != "jogador") return;
    obj_controlador.carta_menu_aberto = noone;
    obj_controlador.primeiro_turno_jogador = false;
    expirar_condicoes("jogador");
    iniciar_turno_inimigo();
}
function iniciar_turno_local(_dono, _comprar_no_inicio = true) {
    obj_controlador.turno = _dono;
    obj_controlador.ia_ativa = false;
    obj_controlador.ia_texto_acao = "";
    obj_controlador.carta_menu_aberto = noone;
    obj_controlador.tropa_selecionada = noone;

    reiniciar_acoes_tropas(_dono);
    processar_condicoes(_dono);
    desvirar_recursos(_dono);
    processar_construcoes_inicio_turno(_dono);

    obj_controlador.itens_usados_este_turno = 0;
    obj_controlador.magias_usadas_este_turno = 0;
    obj_controlador.construcoes_jogadas_este_turno = 0;
    obj_controlador.terrenos_jogados_este_turno = 0;
    obj_controlador.cartas_jogadas_no_turno = 0;

    if (_comprar_no_inicio && instance_exists(obj_deck)) {
        comprar_carta_do_deck(obj_deck.x, obj_deck.y, _dono);
    }

    organizar_mao();
    obj_controlador.passagem_turno_destino = _dono;
    obj_controlador.passagem_turno_ativa = (obj_controlador.modo_partida == "local");
}


function anunciar_turno(_dono) {
    obj_controlador.onda_turno_timer = obj_controlador.onda_turno_duracao;
    obj_controlador.anuncio_turno_texto = partida_local_ativa()
        ? nome_jogador_lado(_dono) + " — SEU TURNO" : ((_dono == "jogador") ? "SEU TURNO" : "TURNO DO INIMIGO");
    obj_controlador.anuncio_turno_timer = obj_controlador.anuncio_turno_duracao;
}

function iniciar_turno_inimigo(_comprar_no_inicio = true) {
    obj_controlador.turno = "inimigo";
    anunciar_turno("inimigo");

    obj_controlador.itens_usados_este_turno = 0;
    obj_controlador.magias_usadas_este_turno = 0;
    obj_controlador.construcoes_jogadas_este_turno = 0;
    obj_controlador.terrenos_jogados_este_turno = 0;

	reiniciar_acoes_tropas("inimigo");

    processar_condicoes("inimigo");
    desvirar_recursos("inimigo");
    processar_construcoes_inicio_turno("inimigo");
    if (_comprar_no_inicio) comprar_carta_do_deck_ia();

    obj_controlador.ia_ativa = true;
    obj_controlador.ia_etapa = 0;
    obj_controlador.ia_tempo_espera = 45;
    obj_controlador.ia_texto_acao = "intenção: planejar o campo";
}

// Executa uma ação por vez. As pausas deixam claros os movimentos da IA,
// mas o texto é genérico para a mão inimiga continuar secreta.
function processar_turno_ia() {
    if (!obj_controlador.ia_ativa) return;
    if (obj_controlador.rolagens_pendentes > 0) {
        obj_controlador.ia_texto_acao = "resolvendo efeitos...";
        return;
    }
    if (ia_ativar_armadilhas_prontas()) {
        obj_controlador.ia_texto_acao = "ativando uma armadilha...";
        obj_controlador.ia_tempo_espera = 35;
        return;
    }
    if (obj_controlador.ia_tempo_espera > 0) {
        obj_controlador.ia_tempo_espera--;
        return;
    }

    switch (obj_controlador.ia_etapa) {
        case 0:
            obj_controlador.ia_texto_acao = "intenção: preparar recursos e efeitos";
            ia_jogar_recursos();
            ia_jogar_bencaos_maldicoes();
            obj_controlador.ia_etapa = 1;
            obj_controlador.ia_tempo_espera = 55;
        break;
        case 1:
            obj_controlador.ia_texto_acao = "intenção: controlar o campo";
            ia_jogar_construcao();
            ia_usar_construcoes();
            ia_jogar_terreno();
            obj_controlador.ia_etapa = 2;
            obj_controlador.ia_tempo_espera = 55;
        break;
        case 2:
            obj_controlador.ia_texto_acao = "intenção: convocar uma tropa";
            ia_jogar_cartas();
            obj_controlador.ia_etapa = 3;
            obj_controlador.ia_tempo_espera = 65;
        break;
        case 3:
            obj_controlador.ia_texto_acao = "intenção: usar itens e preparar defesas";
            ia_jogar_itens();
            ia_preparar_armadilha();
            obj_controlador.ia_etapa = 4;
            obj_controlador.ia_tempo_espera = 60;
        break;
        case 4:
            obj_controlador.ia_texto_acao = "intenção: evoluir e usar habilidades";
            ia_evoluir_tropa();
            ia_usar_grimorios();
            ia_usar_habilidades_tropas();
            obj_controlador.ia_etapa = 5;
            obj_controlador.ia_tempo_espera = 55;
        break;
        case 5:
            obj_controlador.ia_texto_acao = "intenção: avançar tropas";
            mover_tropas_automatico("inimigo");
            ia_configurar_defesa_castelo();
            obj_controlador.ia_etapa = 6;
            obj_controlador.ia_tempo_espera = 70;
        break;
        case 6:
            obj_controlador.ia_texto_acao = "intenção: escolher magias e alvos";
            if (ia_jogar_magias()) {
                obj_controlador.ia_tempo_espera = 45;
            } else {
                obj_controlador.ia_etapa = 7;
                obj_controlador.ia_tempo_espera = 35;
            }
        break;
        case 7:
            obj_controlador.ia_texto_acao = "intenção: atacar";
            if (!obj_controlador.primeiro_turno_inimigo) processar_combate("inimigo");
            obj_controlador.ia_etapa = 8;
            obj_controlador.ia_tempo_espera = 45;
        break;
        case 8:
            expirar_condicoes("inimigo");
            obj_controlador.primeiro_turno_inimigo = false;
            obj_controlador.ia_ativa = false;
            obj_controlador.ia_texto_acao = "";
            obj_controlador.turno = "jogador";
            obj_controlador.turnos_completos += 1;
            anunciar_turno("jogador");

            reiniciar_acoes_tropas("jogador");
            processar_condicoes("jogador");
            desvirar_recursos("jogador");
            processar_construcoes_inicio_turno("jogador");
            if (instance_exists(obj_deck) && array_length(obj_controlador.monte) > 0) {
                comprar_carta_do_deck(obj_deck.x, obj_deck.y);
            }
            obj_controlador.itens_usados_este_turno = 0;
            obj_controlador.magias_usadas_este_turno = 0;
            obj_controlador.construcoes_jogadas_este_turno = 0;
            obj_controlador.terrenos_jogados_este_turno = 0;
            obj_controlador.cartas_jogadas_no_turno = 0;
        break;
    }
}

function reiniciar_acoes_tropas(_lado) {
    with (obj_carta) {
        if (dono == _lado && travada) {
            moveu_este_turno = false;
            atacou_este_turno = false;
            habilidade_usada_este_turno = false;
            troca_item_usada_este_turno = false;
            grimorio_usado_este_turno = false;
            if (grimorio_escudo_ativo) {
                defesa_magica = max(0, defesa_magica - 2);
                grimorio_escudo_ativo = false;
            }
            turnos_no_campo += 1;
        }
    }

    with (obj_construcao) {
        if (dono == _lado) {
            habilidade_usada_este_turno = false;
        }
    }

    if (_lado == "jogador") {
        obj_controlador.evolucoes_jogador_este_turno = 0;
    } else {
        obj_controlador.evolucoes_inimigo_este_turno = 0;
    }
}
#endregion

