// =============================================================================
// KARTHA — inteligência artificial
// Decisões da IA para tropas, recursos, itens, magias e construções.
// =============================================================================

#region IA — jogar cartas, recursos e construções
// A IA guarda a mão em structs, então avalia a força da tropa antes de criá-la.
function ia_valor_tropa_dados(_dados) {
    var _qtd_fisica = variable_struct_exists(_dados, "qtd_dados_dano") ? _dados.qtd_dados_dano : 1;
    var _qtd_magica = variable_struct_exists(_dados, "qtd_dados_dano_magico") ? _dados.qtd_dados_dano_magico : 1;
    var _fisico = _qtd_fisica * ((_dados.dado_dano + 1) / 2) + _dados.mod_dano;
    var _magico = _qtd_magica * ((_dados.dado_dano_magico + 1) / 2) + _dados.mod_dano_magico;
    var _habilidades = variable_struct_exists(_dados, "habilidades") ? array_length(_dados.habilidades) : 0;
    return _dados.vida * 0.45 + max(_fisico, _magico) * 1.8 + _dados.defesa_fisica + _dados.defesa_magica + _habilidades * 2;
}

// O Hemodrenário gera Sangue ao ver uma tropa inimiga morrer na própria fileira.
function ia_escolher_indice_tropa() {
    var _melhor_indice = -1;
    var _melhor_valor = -999999;

    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _dados = obj_controlador.mao_inimigo[i]();
        if (_dados.categoria != "tropa" || !pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;

        var _valor = ia_valor_tropa_dados(_dados);
        if (_valor > _melhor_valor) {
            _melhor_valor = _valor;
            _melhor_indice = i;
        }
    }
    return _melhor_indice;
}

// Escolhe a faixa com um alvo mais próximo/vulnerável e evita bloquear a própria tropa.
function ia_escolher_slot_entrada() {
    var _melhor_slot = noone;
    var _melhor_pontuacao = -999999;

    with (obj_slot_batalha) {
        if (posicao != posicao_entrada("inimigo") || ocupado) continue;
        if (buscar_tropa_na_coluna(lane, "inimigo") != noone) continue;

        var _pontuacao = 8;
        var _bloqueio = buscar_slot(lane, 1);
        if (_bloqueio != noone && _bloqueio.ocupado && _bloqueio.carta_atual.dono == "inimigo") {
            _pontuacao -= 1000;
        }

        // Quanto mais perto do centro estiver a ameaça do jogador, maior a prioridade.
        for (var _pos = posicao_ataque(); _pos < total_posicoes_batalha(); _pos++) {
            var _slot_jogador = buscar_slot(lane, _pos);
            if (_slot_jogador == noone || !_slot_jogador.ocupado) continue;
            var _alvo = _slot_jogador.carta_atual;
            if (_alvo.dono != "jogador") continue;

            _pontuacao += (total_posicoes_batalha() - _pos) * 12;
            _pontuacao += ia_poder_ataque(_alvo) * 2;
            _pontuacao += (_alvo.vida_maxima - _alvo.vida) * 1.5;
            break;
        }

        if (_pontuacao > _melhor_pontuacao) {
            _melhor_pontuacao = _pontuacao;
            _melhor_slot = id;
        }
    }
    return _melhor_slot;
}

function ia_pontuacao_alvo_magia(_dados, _alvo) {
    var _pontuacao = ia_poder_ataque(_alvo) * 5 + (_alvo.vida_maxima - _alvo.vida);
    switch (_dados.nome) {
        case "Bola de Fogo":
            var _dano_medio = (_dados.dado_efeito + 1) / 2;
            if (_alvo.vida <= _dano_medio) _pontuacao += 100;
            _pontuacao += (_alvo.vida_maxima - _alvo.vida) * 2;
        break;
        case "Veneno Mortal":
            _pontuacao += _alvo.vida_maxima * 2;
            if (tem_condicao(_alvo, "envenenado")) _pontuacao -= 1000;
        break;
        case "Congelante":
            if (tem_condicao(_alvo, "congelado") || tem_condicao(_alvo, "paralisado")) _pontuacao -= 1000;
        break;
        case "Choque Elétrico":
            if (tem_condicao(_alvo, "paralisado")) _pontuacao -= 1000;
        break;
    }
    return _pontuacao;
}

function ia_escolher_alvo_magia(_dados) {
    var _escolha = { tipo: "", alvo: noone, dono_castelo: "", pontuacao: -999999 };

    if (_dados.nome == "Dados Manipulados") return { tipo: "propria", alvo: noone, dono_castelo: "", pontuacao: 85 };
    if (_dados.nome == "Sangue Suga") return { tipo: "propria", alvo: noone, dono_castelo: "", pontuacao: 70 };
    if (variable_struct_exists(_dados, "efeitos") && is_array(_dados.efeitos) && array_length(_dados.efeitos) > 0) {
        var _modo_alvo_decl = variable_struct_exists(_dados, "alvo") ? _dados.alvo : "inimigo";
        if (_modo_alvo_decl == "nenhum")
            return { tipo: "propria", alvo: noone, dono_castelo: "", pontuacao: 65 };

        with (obj_carta) {
            if (!travada || sombra_ativa) continue;
            var _valido_decl = (_modo_alvo_decl == "qualquer")
                || (_modo_alvo_decl == "aliado" && dono == "inimigo")
                || (_modo_alvo_decl == "inimigo" && dono == "jogador");
            if (!_valido_decl) continue;
            var _p_decl = (_modo_alvo_decl == "aliado")
                ? (vida_maxima - vida) * 5 + ia_valor_tropa_campo(id)
                : ia_pontuacao_alvo_magia(_dados, id);
            if (_p_decl > _escolha.pontuacao) {
                _escolha.tipo = "tropa";
                _escolha.alvo = id;
                _escolha.pontuacao = _p_decl;
            }
        }
        return _escolha;
    }
    if (_dados.nome == "Refração Temporal" && ultima_carta_jogada("inimigo") != noone)
        return { tipo: "propria", alvo: noone, dono_castelo: "", pontuacao: 75 };
    if (_dados.nome == "Bloqueio de Recurso") {
        with (obj_recurso) {
            if (dono != "jogador" || bloqueado_turnos > 0) continue;
            var _p = virado ? 35 : 90;
            if (_p > _escolha.pontuacao) {
                _escolha.tipo = "recurso"; _escolha.alvo = id; _escolha.pontuacao = _p;
            }
        }
        return _escolha;
    }

    with (obj_carta) {
        if (!travada || dono != "jogador" || sombra_ativa) continue;
        if (_dados.nome == "Eutanásia" && vida > 5) continue;
        if ((_dados.nome == "Veneno Mortal" || _dados.nome == "Congelante")
            && tem_condicao(id, _dados.nome == "Veneno Mortal" ? "envenenado" : "congelado")) continue;
        var _pontuacao = ia_pontuacao_alvo_magia(_dados, id);
        if (_dados.nome == "Eutanásia") _pontuacao += 500;
        if (_pontuacao > _escolha.pontuacao) {
            _escolha.tipo = "tropa";
            _escolha.alvo = id;
            _escolha.pontuacao = _pontuacao;
        }
    }

    if (_dados.nome == "Bola de Fogo") {
        var _media = (_dados.dado_efeito + 1) / 2;
        with (obj_construcao) {
            if (dono != "jogador") continue;
            var _pontuacao_construcao = 45 + (vida_maxima - vida) * 3;
            if (vida <= _media) _pontuacao_construcao += 120;
            if (nome_construcao == "Hemodrenário") _pontuacao_construcao += 35;
            if (_pontuacao_construcao > _escolha.pontuacao) {
                _escolha.tipo = "construcao";
                _escolha.alvo = id;
                _escolha.pontuacao = _pontuacao_construcao;
            }
        }

        var _pontuacao_castelo = 70 + (20 - obj_controlador.vida_jogador) * 4;
        if (obj_controlador.vida_jogador <= _dados.dado_efeito) _pontuacao_castelo += 1000;
        if (_pontuacao_castelo > _escolha.pontuacao) {
            _escolha.tipo = "castelo";
            _escolha.alvo = noone;
            _escolha.dono_castelo = "jogador";
            _escolha.pontuacao = _pontuacao_castelo;
        }
    }
    return _escolha;
}

// Usa no máximo uma magia por turno e considera tropas, construções e castelo
// quando a carta escolhida for Bola de Fogo.
function ia_jogar_magias() {
    if (obj_controlador.primeiro_turno_inimigo || obj_controlador.magias_usadas_este_turno >= 2) return false;

    var _melhor_indice = -1;
    var _melhor_escolha = noone;
    var _melhor_pontuacao = -999999;
    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _dados = obj_controlador.mao_inimigo[i]();
        if (_dados.categoria != "magica" || !pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;
        var _escolha = ia_escolher_alvo_magia(_dados);
        if (_escolha.tipo == "" || _escolha.pontuacao <= _melhor_pontuacao) continue;
        _melhor_pontuacao = _escolha.pontuacao;
        _melhor_indice = i;
        _melhor_escolha = _escolha;
    }
    if (_melhor_indice == -1 || !is_struct(_melhor_escolha)) return false;

    var _funcao_magia = obj_controlador.mao_inimigo[_melhor_indice];
    var _magia = _funcao_magia();
    pagar_custo(_magia.custo, "inimigo", _magia.categoria, _melhor_escolha.alvo);
    array_delete(obj_controlador.mao_inimigo, _melhor_indice, 1);
    registrar_descarte_dados(_magia, "inimigo");
    registrar_ultima_carta_jogada(_funcao_magia, "inimigo");

    switch (_magia.nome) {
        case "Bola de Fogo":
            lancar_bola_de_fogo(_melhor_escolha.alvo, _magia.dado_efeito, _magia.chance_queimar,
                _melhor_escolha.tipo, _melhor_escolha.dono_castelo, "inimigo");
        break;
        case "Veneno Mortal": aplicar_envenenado(_melhor_escolha.alvo); break;
        case "Congelante": aplicar_congelado(_melhor_escolha.alvo); break;
        case "Choque Elétrico": aplicar_eletrocutado(_melhor_escolha.alvo); break;
        case "Eutanásia": destruir_tropa(_melhor_escolha.alvo, true); break;
        case "Bloqueio de Recurso": bloquear_recurso(_melhor_escolha.alvo, 3); break;
        case "Sangue Suga": buscar_recurso_no_deck("sangue", "inimigo"); break;
        case "Dados Manipulados": ativar_dados_manipulados("inimigo", room_width / 2, 90); break;
        case "Refração Temporal":
            var _ultima_ia = ultima_carta_jogada("inimigo");
            if (_ultima_ia != noone) {
                var _ctx_refracao = { base: _ultima_ia };
                array_push(obj_controlador.mao_inimigo, method(_ctx_refracao, function() {
                    var _copia = base();
                    if (_copia.categoria == "construcao") _copia.vida = max(1, ceil(_copia.vida * 0.5));
                    return _copia;
                }));
            }
        break;
        default:
            if (variable_struct_exists(_magia, "efeitos") && is_array(_magia.efeitos)
                && array_length(_magia.efeitos) > 0)
                executar_efeitos_declarativos(_magia.efeitos, _melhor_escolha.alvo, "inimigo");
            else if (variable_struct_exists(_magia, "efeito_tipo"))
                aplicar_condicao_por_chave(_melhor_escolha.alvo, _magia.efeito_tipo);
        break;
    }

    var _nome_alvo = "efeito próprio";
    if (_melhor_escolha.tipo == "castelo") _nome_alvo = "castelo do jogador";
    else if (_melhor_escolha.tipo == "construcao") _nome_alvo = _melhor_escolha.alvo.nome_construcao;
    else if (_melhor_escolha.tipo == "tropa")
        _nome_alvo = instance_exists(_melhor_escolha.alvo) ? _melhor_escolha.alvo.nome_carta : "tropa";
    else if (_melhor_escolha.tipo == "recurso") _nome_alvo = "recurso do jogador";
    obj_controlador.magias_usadas_este_turno += 1;
    registrar_jogada_recente("inimigo", "Usou " + _magia.nome);
    debug_combate("IA usou " + _magia.nome + " em " + _nome_alvo + ".");
    return true;
}

function ia_valor_tropa_campo(_carta) {
    return _carta.vida * 0.45 + ia_poder_ataque(_carta) * 1.8 + _carta.defesa_fisica + _carta.defesa_magica;
}

// Evolui só uma tropa por turno, dando prioridade à transformação que mais fortalece o campo.
function ia_evoluir_tropa() {
    if (!evolucoes_disponiveis("inimigo")) return;

    var _melhor_tropa = noone;
    var _melhor_ganho = 0;

    with (obj_carta) {
        if (!travada || dono != "inimigo" || funcao_evolucao == noone || turnos_no_campo < 1) continue;
        var _dados_evolucao = funcao_evolucao();
        if (!pode_pagar_custo(_dados_evolucao.custo, "inimigo")) continue;

        var _ganho = ia_valor_tropa_dados(_dados_evolucao) - ia_valor_tropa_campo(id);
        if (_ganho > _melhor_ganho) {
            _melhor_ganho = _ganho;
            _melhor_tropa = id;
        }
    }

    if (_melhor_tropa != noone) {
        debug_combate("IA evolui " + _melhor_tropa.nome_carta + " (ganho tático: " + string(round(_melhor_ganho)) + ").");
        evoluir_tropa(_melhor_tropa);
    }
}

// Retorna uma tropa do jogador que a carta inimiga consegue atingir neste momento.
function ia_alvo_atingivel(_carta) {
    if (!instance_exists(_carta) || _carta.slot_atual == noone) return noone;

    var _slot = _carta.slot_atual;
    var _sentido = direcao_avanco(_carta.dono);
    var _slot_alvo = buscar_slot(_slot.lane, _slot.posicao + _sentido);
    var _tem_alcance = tem_habilidade(_carta, "alcance") || tem_habilidade(_carta, "alcance_magico");

    if ((_slot_alvo == noone || !_slot_alvo.ocupado) && _tem_alcance) {
        var _slot_longe = buscar_slot(_slot.lane, _slot.posicao + _sentido * 2);
        if (_slot_longe != noone && _slot_longe.ocupado) _slot_alvo = _slot_longe;
    }

    if (_slot_alvo == noone || !_slot_alvo.ocupado) return noone;
    var _alvo = _slot_alvo.carta_atual;
    if (_alvo.dono != "jogador" || _alvo.sombra_ativa) return noone;
    if (tem_habilidade(_alvo, "voar") && !tem_habilidade(_carta, "voar") && !_tem_alcance) return noone;
    return _alvo;
}

// Verifica se uma tropa do jogador pode ameaçar esta carta no próximo ataque.
function ia_tropa_ameacada(_carta) {
    if (_carta.slot_atual == noone) return false;
    var _slot = _carta.slot_atual;
    var _sentido_jogador = direcao_avanco("jogador");

    for (var _distancia = 1; _distancia <= 2; _distancia++) {
        var _slot_inimigo = buscar_slot(_slot.lane, _slot.posicao - _sentido_jogador * _distancia);
        if (_slot_inimigo == noone || !_slot_inimigo.ocupado) continue;
        var _ameaca = _slot_inimigo.carta_atual;
        if (_ameaca.dono != "jogador") continue;
        if (_distancia == 2 && !tem_habilidade(_ameaca, "alcance") && !tem_habilidade(_ameaca, "alcance_magico")) continue;
        if (ia_poder_ataque(_ameaca) >= _carta.vida * 0.5) return true;
    }
    return false;
}

// Decide se uma tropa na base deve interceptar ataques ao castelo. A IA protege
// o castelo quando ele já sofreu dano ou quando a tropa sobreviveria a um golpe médio.
function ia_configurar_defesa_castelo() {
    with (obj_carta) {
        if (!travada || dono != "inimigo") continue;
        if (posicao_atual != posicao_entrada("inimigo")) {
            defendendo_castelo = false;
            continue;
        }
        defendendo_castelo = obj_controlador.vida_inimigo <= 15 || vida >= 6;
    }
}

// Habilidades são usadas apenas quando têm impacto imediato ou proteção concreta.
function ia_usar_habilidades_tropas() {
    if (obj_controlador.primeiro_turno_inimigo) return;

    with (obj_carta) {
        if (!travada || dono != "inimigo" || habilidade_usada_este_turno) continue;

        var _ativas_ia = habilidades_ativas(id);
        for (var _ha_ia = 0; _ha_ia < array_length(_ativas_ia); _ha_ia++) {
        if (habilidade_usada_este_turno) break;
        var _habilidade = _ativas_ia[_ha_ia];
        switch (_habilidade) {
            case "golpe_duplo":
                if (!atacou_este_turno && (ia_alvo_atingivel(id) != noone || posicao_atual == posicao_assalto("inimigo"))) {
                    usar_habilidade(id, _habilidade);
                }
            break;
            case "ferida_exposta":
            case "imitacao":
                // Essas duas habilidades exigem uma tropa imediatamente à frente.
                var _slot_frente = buscar_slot(lane_atual, posicao_atual + direcao_avanco("inimigo"));
                if (_slot_frente != noone && _slot_frente.ocupado && _slot_frente.carta_atual.dono == "jogador") {
                    usar_habilidade(id, _habilidade);
                }
            break;
            case "sombra_translucida":
                var _custo_sombra = { tipo: "mana", quantidade: 2 };
                if (sombra_cooldown <= 0 && ia_tropa_ameacada(id) && pode_pagar_custo(_custo_sombra, "inimigo")) {
                    usar_habilidade(id, _habilidade);
                }
            break;
            case "visao_do_veu":
                if (!visao_do_veu_usada) usar_habilidade(id, _habilidade);
            break;
            case "digestao":
                if (digestao_usos < usos_maximos_digestao(id)) {
                    if (digestao_cadaver_disponivel) usar_habilidade(id, _habilidade);
                    else {
                        var _pode_digerir = false;
                        with (obj_carta) if (alvo_valido_digestao(other.id, id)) { _pode_digerir = true; break; }
                        if (_pode_digerir) usar_habilidade(id, _habilidade);
                    }
                }
            break;
            case "carnica_frenetica":
                if (carnica_estado_proximo_ataque == "" && pode_pagar_custo({ tipo: "sangue", quantidade: 2 }, "inimigo")) usar_habilidade(id, _habilidade);
            break;
        }
    }
}
}

function ia_consumir_carta_da_mao(_indice, _dados, _funcao, _destino) {
    pagar_custo(_dados.custo, "inimigo", _dados.categoria, _destino);
    array_delete(obj_controlador.mao_inimigo, _indice, 1);
    registrar_descarte_dados(_dados, "inimigo");
    registrar_ultima_carta_jogada(_funcao, "inimigo");
}

function ia_jogar_bencaos_maldicoes() {
    for (var i = array_length(obj_controlador.mao_inimigo) - 1; i >= 0; i--) {
        var _funcao_efeito_ia = obj_controlador.mao_inimigo[i];
        var _dados = _funcao_efeito_ia();
        if ((_dados.categoria != "bencao" && _dados.categoria != "maldicao")
            || !pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;
        var _sucesso = (_dados.categoria == "bencao")
            ? adicionar_bencao("inimigo", _dados.efeito, _dados.nome, _dados.sprite_carta)
            : adicionar_maldicao("jogador", _dados.efeito, _dados.nome, _dados.sprite_carta);
        if (!_sucesso) continue;
        pagar_custo(_dados.custo, "inimigo", _dados.categoria);
        array_delete(obj_controlador.mao_inimigo, i, 1);
        registrar_ultima_carta_jogada(_funcao_efeito_ia, "inimigo");
        iniciar_animacao_bencao_maldicao(_dados.categoria, _dados.nome);
        debug_combate("IA ativou " + _dados.nome + ".");
    }
}

function ia_jogar_terreno() {
    if (obj_controlador.primeiro_turno_inimigo || obj_controlador.terrenos_jogados_este_turno >= 1) return;
    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _funcao_terreno_ia = obj_controlador.mao_inimigo[i];
        var _dados = _funcao_terreno_ia();
        if (_dados.categoria != "terreno" || !pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;

        pagar_custo(_dados.custo, "inimigo", _dados.categoria, instance_find(obj_slot_terreno, 0));
        array_delete(obj_controlador.mao_inimigo, i, 1);
        registrar_ultima_carta_jogada(_funcao_terreno_ia, "inimigo");
        obj_controlador.terrenos_jogados_este_turno += 1;
        obj_controlador.terreno_bonus_defesa = _dados.bonus_defesa_global;
        obj_controlador.terreno_ativo = variable_struct_exists(_dados, "efeito_terreno") ? _dados.efeito_terreno : "";
        obj_controlador.terreno_anuncio_texto = string_upper(_dados.nome);
        obj_controlador.terreno_anuncio_timer = obj_controlador.terreno_anuncio_duracao;

        var _slot_terreno = instance_find(obj_slot_terreno, 0);
        if (_slot_terreno != noone) {
            if (_slot_terreno.ocupado && instance_exists(_slot_terreno.terreno_atual)) {
                if (is_struct(_slot_terreno.terreno_atual.dados_carta))
                    registrar_descarte_dados(_slot_terreno.terreno_atual.dados_carta, _slot_terreno.terreno_atual.dono);
                instance_destroy(_slot_terreno.terreno_atual);
            }
            var _visual = instance_create_layer(room_width / 2, 20, "Instances", obj_terreno_ativo);
            _visual.sprite_index = (_dados.sprite_carta != noone) ? _dados.sprite_carta : spr_carta_placeholder;
            _visual.dados_carta = _dados;
            _visual.dono = "inimigo";
            _visual.escala_base = global.TERRENO_LARGURA_ALVO / sprite_get_height(_visual.sprite_index);
            _visual.destino_x = _slot_terreno.x;
            _visual.destino_y = _slot_terreno.y;
            _visual.origem_x = room_width / 2;
            _visual.origem_y = 20;
            _slot_terreno.ocupado = true;
            _slot_terreno.terreno_atual = _visual.id;
        }
        debug_combate("IA colocou o terreno " + _dados.nome + ".");
        return;
    }
}

function ia_melhor_tropa_propria(_exigir_mochila = false, _inteligencia_minima = -999) {
    var _melhor = noone;
    var _valor = -999999;
    with (obj_carta) {
        if (!travada || dono != "inimigo" || tem_condicao(id, "adormecido") || tem_condicao(id, "loucura")) continue;
        if (_exigir_mochila && (mochila <= 0 || troca_item_usada_este_turno)) continue;
        if (nivel_inteligencia < _inteligencia_minima) continue;
        var _pontuacao = ia_valor_tropa_campo(id);
        if (_pontuacao > _valor) {
            _valor = _pontuacao;
            _melhor = id;
        }
    }
    return _melhor;
}

function ia_melhor_tropa_ferida() {
    var _melhor = noone;
    var _vida_faltando = 0;
    with (obj_carta) {
        if (!travada || dono != "inimigo") continue;
        var _faltando = vida_maxima - vida;
        if (_faltando > _vida_faltando) {
            _vida_faltando = _faltando;
            _melhor = id;
        }
    }
    return _melhor;
}

function ia_melhor_alvo_corrosao() {
    var _melhor = noone;
    var _valor = -999999;
    with (obj_carta) {
        if (!travada || dono != "jogador" || tem_condicao(id, "corrosao")) continue;
        var _pontuacao = ia_valor_tropa_campo(id);
        if (_pontuacao > _valor) {
            _valor = _pontuacao;
            _melhor = id;
        }
    }
    return _melhor;
}

function ia_jogar_itens() {
    if (obj_controlador.primeiro_turno_inimigo) return;
    var _usos = 0;
    while (_usos < 3) {
        var _usou = false;
        for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
            var _funcao_item_ia = obj_controlador.mao_inimigo[i];
            var _dados = _funcao_item_ia();
            if ((_dados.categoria != "item_equipavel" && _dados.categoria != "item_consumivel")
                || !pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;

            if (_dados.categoria == "item_equipavel") {
                var _requisito = variable_struct_exists(_dados, "requisito_inteligencia") ? _dados.requisito_inteligencia : 0;
                var _alvo_equipar = ia_melhor_tropa_propria(true, _requisito);
                if (_alvo_equipar == noone) continue;
                var _item_ia = criar_dados_item_equipado(_dados.nome,
                    variable_struct_exists(_dados, "sprite_carta") ? _dados.sprite_carta : spr_carta_placeholder,
                    _funcao_item_ia,
                    variable_struct_exists(_dados, "bonus_mod_dano") ? _dados.bonus_mod_dano : 0,
                    variable_struct_exists(_dados, "bonus_defesa") ? _dados.bonus_defesa : 0,
                    variable_struct_exists(_dados, "sobrescreve_dado_dano") ? _dados.sobrescreve_dado_dano : 0,
                    variable_struct_exists(_dados, "sobrescreve_mod_dano") ? _dados.sobrescreve_mod_dano : 0,
                    variable_struct_exists(_dados, "efeito_item") ? _dados.efeito_item : "",
                    variable_struct_exists(_dados, "sinergias") ? _dados.sinergias : []);
                equipar_item_dados(_alvo_equipar, _item_ia);
                _alvo_equipar.troca_item_usada_este_turno = true;
                pagar_custo(_dados.custo, "inimigo", _dados.categoria, _alvo_equipar);
                array_delete(obj_controlador.mao_inimigo, i, 1);
                registrar_ultima_carta_jogada(_funcao_item_ia, "inimigo");
                debug_combate("IA equipou " + _dados.nome + " em " + _alvo_equipar.nome_carta + ".");
                _usou = true;
            } else {
                var _efeito = variable_struct_exists(_dados, "efeito_tipo") ? _dados.efeito_tipo : "cura";
                var _destino_item = noone;
                var _executou = false;
                if (variable_struct_exists(_dados, "efeitos") && is_array(_dados.efeitos)
                    && array_length(_dados.efeitos) > 0) {
                    var _modo_item_decl = variable_struct_exists(_dados, "alvo") ? _dados.alvo : "inimigo";
                    var _alvo_item_decl = noone;
                    var _valor_item_decl = -999999;
                    if (_modo_item_decl != "nenhum") {
                        with (obj_carta) {
                            if (!travada || sombra_ativa) continue;
                            var _valido_item_decl = (_modo_item_decl == "qualquer")
                                || (_modo_item_decl == "aliado" && dono == "inimigo")
                                || (_modo_item_decl == "inimigo" && dono == "jogador");
                            if (!_valido_item_decl) continue;
                            var _p_item_decl = (_modo_item_decl == "aliado")
                                ? (vida_maxima - vida) * 5 + ia_valor_tropa_campo(id)
                                : ia_valor_tropa_campo(id);
                            if (_p_item_decl > _valor_item_decl) {
                                _valor_item_decl = _p_item_decl;
                                _alvo_item_decl = id;
                            }
                        }
                    }
                    _destino_item = _alvo_item_decl;
                    if (_modo_item_decl == "nenhum" || _alvo_item_decl != noone)
                        _executou = executar_efeitos_declarativos(_dados.efeitos, _alvo_item_decl, "inimigo");
                } else if (string_pos("buscar_", _efeito) == 1) {
                    var _tipo_recurso = string_delete(_efeito, 1, string_length("buscar_"));
                    _executou = buscar_recurso_no_deck(_tipo_recurso, "inimigo");
                } else if (_efeito == "comprar_cartas") {
                    comprar_varias_cartas(_dados.quantidade_efeito, "inimigo");
                    _executou = true;
                } else if (_efeito == "aplicar_corrosao") {
                    var _alvo_corrosao = ia_melhor_alvo_corrosao();
                    if (_alvo_corrosao != noone) {
                        _destino_item = _alvo_corrosao;
                        aplicar_corrosao(_alvo_corrosao);
                        _executou = true;
                    }
                } else if (_efeito == "revirar_sangue") {
                    _executou = revirar_recurso("sangue", "inimigo");
                } else if (_efeito == "aumentar_intelig") {
                    var _alvo_inteligencia = ia_melhor_tropa_propria();
                    if (_alvo_inteligencia != noone) {
                        _destino_item = _alvo_inteligencia;
                        _alvo_inteligencia.nivel_inteligencia += _dados.quantidade_efeito;
                        _executou = true;
                    }
                } else {
                    var _alvo_cura = ia_melhor_tropa_ferida();
                    if (_alvo_cura != noone) {
                        _destino_item = _alvo_cura;
                        _alvo_cura.vida = min(_alvo_cura.vida_maxima, _alvo_cura.vida + _dados.cura);
                        _executou = true;
                    }
                }
                if (!_executou) continue;
                ia_consumir_carta_da_mao(i, _dados, _funcao_item_ia, _destino_item);
                debug_combate("IA usou " + _dados.nome + ".");
                _usou = true;
            }

            if (_usou) {
                _usos += 1;
                obj_controlador.itens_usados_este_turno += 1;
                break;
            }
        }
        if (!_usou) break;
    }
}

function ia_slot_tem_armadilha(_lane, _posicao) {
    return slot_tem_armadilha(_lane, _posicao);
}

function ia_preparar_armadilha() {
    var _indice = -1;
    var _dados = noone;
    var _funcao_armadilha = noone;
    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _teste = obj_controlador.mao_inimigo[i]();
        if (_teste.categoria == "armadilha" && pode_pagar_custo(_teste.custo, "inimigo")) {
            _indice = i;
            _dados = _teste;
            _funcao_armadilha = obj_controlador.mao_inimigo[i];
            break;
        }
    }
    if (_indice == -1) return;

    var _slot_escolhido = noone;
    var _melhor_pontuacao = -999999;
    with (obj_slot_batalha) {
        if (posicao > posicao_ataque() || ia_slot_tem_armadilha(lane, posicao)) continue;
        var _lane_armadilha = lane;
        var _posicao_armadilha = posicao;
        var _pontuacao = 5 - _posicao_armadilha;
        with (obj_carta) {
            if (travada && dono == "jogador" && lane_atual == _lane_armadilha) {
                _pontuacao += 30 - abs(posicao_atual - _posicao_armadilha) * 5;
            }
        }
        if (_pontuacao > _melhor_pontuacao) {
            _melhor_pontuacao = _pontuacao;
            _slot_escolhido = id;
        }
    }
    if (_slot_escolhido == noone) return;

    pagar_custo(_dados.custo, "inimigo", _dados.categoria);
    array_delete(obj_controlador.mao_inimigo, _indice, 1);
    registrar_ultima_carta_jogada(_funcao_armadilha, "inimigo");
    var _armadilha = instance_create_layer(_slot_escolhido.x, _slot_escolhido.y, "Instances", obj_carta);
    _armadilha.nome_carta = _dados.nome;
    _armadilha.categoria = "armadilha";
    _armadilha.dono = "inimigo";
    _armadilha.sprite_index = (_dados.sprite_carta != noone) ? _dados.sprite_carta : spr_carta_placeholder;
    _armadilha.dado_efeito = _dados.dado_efeito;
    _armadilha.qtd_dados_efeito = variable_struct_exists(_dados, "qtd_dados_efeito") ? _dados.qtd_dados_efeito : 1;
    _armadilha.efeito_tipo = variable_struct_exists(_dados, "efeito_tipo") ? _dados.efeito_tipo : "armadilha_urso";
    _armadilha.armadilha_lane = _slot_escolhido.lane;
    _armadilha.armadilha_posicao = _slot_escolhido.posicao;
    _armadilha.armadilha_estado = "vigiando";
    _armadilha.esta_na_mao = false;
    _armadilha.travada = false;
    _armadilha.visible = false;
    debug_combate("IA preparou uma armadilha oculta.");
}

function ia_ativar_armadilhas_prontas() {
    if (obj_controlador.rolagens_pendentes > 0) return false;
    var _pronta = noone;
    with (obj_carta) {
        if (categoria == "armadilha" && dono == "inimigo" && armadilha_estado == "pronta") {
            _pronta = id;
            break;
        }
    }
    if (_pronta == noone) return false;
    ativar_armadilha(_pronta);
    return true;
}

function ia_jogar_cartas() {
    var _indice_mao_escolhido = ia_escolher_indice_tropa();
    var _slot_escolhido = ia_escolher_slot_entrada();
    if (_indice_mao_escolhido == -1 || _slot_escolhido == noone) return;

    var _cartas_jogadas = 0;
    var _max_cartas = 1;
	 
    with (obj_slot_batalha) {
        if (_cartas_jogadas >= _max_cartas) continue;
		if (id != _slot_escolhido) continue;

        if (posicao == posicao_entrada("inimigo") && !ocupado
            && buscar_tropa_na_coluna(lane, "inimigo") == noone) {
            if (array_length(obj_controlador.mao_inimigo) > 0) {

                var _indice_mao = _indice_mao_escolhido;
                var _funcao_sorteada = obj_controlador.mao_inimigo[_indice_mao];
                var _dados = _funcao_sorteada();

				if (_dados.categoria == "bencao") {
				    if (adicionar_bencao("inimigo", _dados.efeito, _dados.nome, _dados.sprite_carta)) {
				        array_delete(obj_controlador.mao_inimigo, _indice_mao, 1);
				    }
				    continue;
				}
				if (_dados.categoria == "maldicao") {
				    if (adicionar_maldicao("jogador", _dados.efeito, _dados.nome, _dados.sprite_carta)) {
				        array_delete(obj_controlador.mao_inimigo, _indice_mao, 1);
				    }
				    continue;
				}
				if (_dados.categoria != "tropa") continue;
				if (!pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;

                pagar_custo(_dados.custo, "inimigo", _dados.categoria, id);
                array_delete(obj_controlador.mao_inimigo, _indice_mao, 1);

                var _carta = instance_create_layer(x, y, "Instances", obj_carta);
                _carta.nome_carta = _dados.nome;
                _carta.sprite_index = (_dados.sprite_carta != noone) ? _dados.sprite_carta : spr_carta_placeholder;
                _carta.escala_base = global.CARTA_LARGURA / sprite_get_width(_carta.sprite_index);
                _carta.tem_arte_propria = (_dados.sprite_carta != noone);
                _carta.categoria = _dados.categoria;
                _carta.tags = variable_struct_exists(_dados, "tags") ? _dados.tags : [];
                _carta.vida = _dados.vida;
                _carta.vida_maxima = _dados.vida;
				_carta.vida_pos_x = variable_struct_exists(_dados, "vida_pos_x") ? _dados.vida_pos_x : 0.11;
				_carta.vida_pos_y = variable_struct_exists(_dados, "vida_pos_y") ? _dados.vida_pos_y : 0.07;
				_carta.selo_abissal = variable_struct_exists(_dados, "selo_abissal") ? _dados.selo_abissal : false;
				_carta.funcao_evolucao = variable_struct_exists(_dados, "evolucao") ? _dados.evolucao : noone;
                _carta.custo_sacrificio = _dados.sacrificio;
                _carta.dado_dano = _dados.dado_dano;
				_carta.qtd_dados_dano = variable_struct_exists(_dados, "qtd_dados_dano") ? _dados.qtd_dados_dano : 1;
				_carta.qtd_dados_dano_magico = variable_struct_exists(_dados, "qtd_dados_dano_magico") ? _dados.qtd_dados_dano_magico : 1;
                _carta.mod_dano = _dados.mod_dano;
                _carta.defesa_fisica = _dados.defesa_fisica;
                _carta.defesa_magica = _dados.defesa_magica;
                _carta.habilidades = variable_struct_exists(_dados, "habilidades") ? _dados.habilidades : [];
				_carta.funcao_mitose = variable_struct_exists(_dados, "mitose") ? _dados.mitose : noone;
				_carta.nivel_inteligencia = variable_struct_exists(_dados, "inteligencia") ? _dados.inteligencia : 1;
				_carta.dado_dano_magico = variable_struct_exists(_dados, "dado_dano_magico") ? _dados.dado_dano_magico : 0;
				_carta.mod_dano_magico = variable_struct_exists(_dados, "mod_dano_magico") ? _dados.mod_dano_magico : 0;
				_carta.mochila = variable_struct_exists(_dados, "mochila") ? _dados.mochila : 1;
				_carta.mochila_maxima = _carta.mochila;
				_carta.dado_dano_base = _carta.dado_dano;
				_carta.mod_dano_base = _carta.mod_dano;
				_carta.defesa_fisica_base = _carta.defesa_fisica;
        _carta.defesa_magica_base = _carta.defesa_magica;

				_carta.vida_pos_x = variable_struct_exists(_dados, "vida_pos_x") ? _dados.vida_pos_x : 0.10;
				_carta.vida_pos_y = variable_struct_exists(_dados, "vida_pos_y") ? _dados.vida_pos_y : 0.07;
				_carta.int_pos_x = variable_struct_exists(_dados, "int_pos_x") ? _dados.int_pos_x : 0.91;
				_carta.int_pos_y = variable_struct_exists(_dados, "int_pos_y") ? _dados.int_pos_y : 0.073;
				_carta.mochila_pos_x = variable_struct_exists(_dados, "mochila_pos_x") ? _dados.mochila_pos_x : 0.91;
				_carta.mochila_pos_y = variable_struct_exists(_dados, "mochila_pos_y") ? _dados.mochila_pos_y : 0.185;
				_carta.atk_pos_x = variable_struct_exists(_dados, "atk_pos_x") ? _dados.atk_pos_x : 0.12;
				_carta.atk_pos_y = variable_struct_exists(_dados, "atk_pos_y") ? _dados.atk_pos_y : 0.92;
				_carta.atk_magico_pos_x = variable_struct_exists(_dados, "atk_magico_pos_x") ? _dados.atk_magico_pos_x : 0.37;
				_carta.atk_magico_pos_y = variable_struct_exists(_dados, "atk_magico_pos_y") ? _dados.atk_magico_pos_y : 0.92;
				_carta.def_pos_x = variable_struct_exists(_dados, "def_pos_x") ? _dados.def_pos_x : 0.62;
				_carta.def_pos_y = variable_struct_exists(_dados, "def_pos_y") ? _dados.def_pos_y : 0.92;
				_carta.def_magico_pos_x = variable_struct_exists(_dados, "def_magico_pos_x") ? _dados.def_magico_pos_x : 0.87;
				_carta.def_magico_pos_y = variable_struct_exists(_dados, "def_magico_pos_y") ? _dados.def_magico_pos_y : 0.92;

                _carta.esta_na_mao = false;
                _carta.travada = true;
                _carta.depth = -100;
                _carta.dono = "inimigo";
                _carta.lane_atual = lane;
                _carta.posicao_atual = posicao;
                _carta.destino_x = x;
                _carta.destino_y = y;
                _carta.slot_atual = id;

                ocupado = true;
                carta_atual = _carta.id;

                _carta.x = room_width / 2;
                _carta.y = -global.CARTA_ALTURA;
                iniciar_pulo_tropa(_carta, x, y, true);

                _cartas_jogadas += 1;
				
            }
        }
			
    }
}

function ia_jogar_recursos() {
    // filtra na mão da IA só as cartas de recurso disponíveis
    var _indices_recurso = [];
    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _dados_teste = obj_controlador.mao_inimigo[i]();
        if (_dados_teste.categoria == "recurso") {
            array_push(_indices_recurso, i);
        }
    }

    if (array_length(_indices_recurso) == 0) {
        debug_combate("IA não tem carta de recurso na mão pra jogar.");
        return;
    }

    // Prefere, entre as opções que ela TEM na mão, o tipo que está em menor quantidade em campo.
    var _tipos = ["sangue", "ossos", "sucata", "mana"];
    var _contagens = [0, 0, 0, 0];

    var _recursos = obj_controlador.recursos_inimigo;
    for (var i = 0; i < array_length(_recursos); i++) {
        var _recurso = _recursos[i];
        if (!instance_exists(_recurso)) continue;
        for (var j = 0; j < array_length(_tipos); j++) {
            if (_recurso.tipo == _tipos[j]) {
                _contagens[j] += max(1, _recurso.quantidade);
                break;
            }
        }
    }

    var _melhor_indice_mao = _indices_recurso[0];
    var _melhor_contagem = 9999;

    for (var i = 0; i < array_length(_indices_recurso); i++) {
        var _indice_mao = _indices_recurso[i];
        var _dados = obj_controlador.mao_inimigo[_indice_mao]();
        var _tipo_idx = array_get_index(_tipos, _dados.tipo_recurso);
        var _contagem_tipo = (_tipo_idx != -1) ? _contagens[_tipo_idx] : 0;

        if (_contagem_tipo < _melhor_contagem) {
            _melhor_contagem = _contagem_tipo;
            _melhor_indice_mao = _indice_mao;
        }
    }

    var _funcao_recurso_ia = obj_controlador.mao_inimigo[_melhor_indice_mao];
    var _dados_escolhidos = _funcao_recurso_ia();
    // Recurso vem da área oculta da mão inimiga, igual antes.
    var _resultado = colocar_recurso(_dados_escolhidos.tipo_recurso, "inimigo", room_width / 2, -global.CARTA_ALTURA,
        noone, variable_struct_exists(_dados_escolhidos, "valor_recurso") ? _dados_escolhidos.valor_recurso : 1,
        _funcao_recurso_ia);

    if (_resultado == "colocado") {
        array_delete(obj_controlador.mao_inimigo, _melhor_indice_mao, 1);
        registrar_ultima_carta_jogada(_funcao_recurso_ia, "inimigo");
    }
}

function ia_jogar_construcao() {
    if (obj_controlador.construcoes_jogadas_este_turno >= 1) return;

    // filtra na mão da IA só as cartas de construção disponíveis
    var _indices_construcao = [];
    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _dados_teste = obj_controlador.mao_inimigo[i]();
        if (_dados_teste.categoria == "construcao") {
            array_push(_indices_construcao, i);
        }
    }

    if (array_length(_indices_construcao) == 0) return;

    var _slot_livre = noone;
    with (obj_slot_construcao) {
        if (!ocupado && dono == "inimigo") {
            _slot_livre = id;
            break;
        }
    }

    if (_slot_livre == noone) return;

    // tenta cada construção que ela tem na mão até achar uma que dê pra pagar
    for (var i = 0; i < array_length(_indices_construcao); i++) {
        var _indice_mao = _indices_construcao[i];
        var _funcao_construcao_ia = obj_controlador.mao_inimigo[_indice_mao];
        var _dados = _funcao_construcao_ia();

        if (!pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;

        pagar_custo(_dados.custo, "inimigo", _dados.categoria, _slot_livre);
        array_delete(obj_controlador.mao_inimigo, _indice_mao, 1);
        registrar_ultima_carta_jogada(_funcao_construcao_ia, "inimigo");

        var _construcao = instance_create_layer(_slot_livre.x, _slot_livre.y, "Instances", obj_construcao);
        _construcao.nome_construcao = _dados.nome;
        _construcao.nome_carta = _dados.nome;
        _construcao.custo = _dados.custo;
        if (variable_struct_exists(_dados, "sprite_carta") && _dados.sprite_carta != noone) {
            _construcao.sprite_index = _dados.sprite_carta;
            _construcao.usa_sprite_carta = true;
            _construcao.tem_arte_propria = true;
            _construcao.escala_visual_base = min((global.CARTA_LARGURA * 0.60) / sprite_get_width(_dados.sprite_carta),
                (global.CARTA_ALTURA * 0.60) / sprite_get_height(_dados.sprite_carta));
            _construcao.image_xscale = _construcao.escala_visual_base;
            _construcao.image_yscale = _construcao.escala_visual_base;
            _construcao.vida_pos_x = clamp((variable_struct_exists(_dados, "vida_pos_x") ? _dados.vida_pos_x : 0.11) + 0.05, 0, 1);
            _construcao.vida_pos_y = clamp((variable_struct_exists(_dados, "vida_pos_y") ? _dados.vida_pos_y : 0.07) + 0.05, 0, 1);
        }
        _construcao.vida = _dados.vida;
        _construcao.vida_maxima = _dados.vida;
        _construcao.dono = "inimigo";
        _construcao.lane_atual = _slot_livre.lane;
        _construcao.slot_atual = _slot_livre;
        _construcao.efeito_construcao = variable_struct_exists(_dados, "efeito_construcao") ? _dados.efeito_construcao : "";
        _construcao.dado_efeito = variable_struct_exists(_dados, "dado_efeito") ? _dados.dado_efeito : 0;
        _construcao.tem_habilidade_construcao = (_construcao.efeito_construcao != "");

        _slot_livre.ocupado = true;
        _slot_livre.construcao_atual = _construcao.id;
        obj_controlador.construcoes_jogadas_este_turno += 1;
        registrar_jogada_recente("inimigo", "Construção colocada", _slot_livre.lane);
        break; // já construiu, para de tentar
    }
}
	
function ia_usar_construcoes() {
    with (obj_construcao) {
        if (dono == "inimigo" && efeito_construcao == "hemodrenario" && !habilidade_usada_este_turno) {
            usar_habilidade_hemodrenario(id);
        }
    }
}
#endregion

