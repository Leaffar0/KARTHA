// =============================================================================
// KARTHA — diretor de apresentação
// Mantém a fila visual separada das regras e aceita eventos locais ou do servidor.
// =============================================================================

function apresentacao_inicializar(_controle) {
    _controle.apresentacao = {
        fila: [],
        proxima_ordem: 0,
        bloqueios: 0
    };
}

function apresentacao_enfileirar(_evento, _atraso = 0) {
    if (!instance_exists(obj_controlador) || !is_struct(_evento)) return;
    if (!variable_instance_exists(obj_controlador, "apresentacao") || !is_struct(obj_controlador.apresentacao))
        apresentacao_inicializar(obj_controlador);
    var _item = {
        evento: _evento,
        atraso: max(0, _atraso),
        ordem: obj_controlador.apresentacao.proxima_ordem
    };
    obj_controlador.apresentacao.proxima_ordem += 1;
    array_push(obj_controlador.apresentacao.fila, _item);
}

function apresentacao_atualizar(_controle) {
    if (!instance_exists(_controle) || !variable_instance_exists(_controle, "apresentacao")
        || !is_struct(_controle.apresentacao)) return;
    var _fila = _controle.apresentacao.fila;
    for (var i = array_length(_fila) - 1; i >= 0; i--) {
        _fila[i].atraso -= 1;
        if (_fila[i].atraso > 0) continue;
        evento_partida_aplicar(_fila[i].evento);
        array_delete(_fila, i, 1);
    }
    _controle.apresentacao.fila = _fila;
}

function apresentacao_tem_pendencias() {
    return instance_exists(obj_controlador)
        && variable_instance_exists(obj_controlador, "apresentacao")
        && is_struct(obj_controlador.apresentacao)
        && array_length(obj_controlador.apresentacao.fila) > 0;
}

function apresentacao_evento_impacto(_atacante, _alvo, _dano, _tipo_ataque,
    _eh_castelo = false, _lado_castelo = "", _aplicar_destruicao = true,
    _texto = "", _cor = c_red) {
    if (_eh_castelo)
        return evento_dano_castelo_criar(_atacante, _lado_castelo, _dano, _texto, _cor);
    if (instance_exists(_alvo) && _alvo.object_index == obj_construcao)
        return evento_dano_construcao_criar(_atacante, _alvo, _dano,
            _aplicar_destruicao, _texto, _cor);
    return evento_dano_tropa_criar(_atacante, _alvo, _dano, _tipo_ataque,
        0, _aplicar_destruicao, _texto, _cor);
}

// Consome o resultado autoritativo do servidor. Esta função não calcula regra:
// apenas transforma o contrato semântico em dados, movimento, som e feedback.
function apresentacao_animar_ataque_confirmado(_tipo_mensagem, _dados) {
    if (!is_struct(_dados)) return;
    var _atacante = online_encontrar_carta_campo(_dados.cardId);
    if (!instance_exists(_atacante)) return;
    var _alvo = variable_struct_exists(_dados, "targetId")
        ? online_encontrar_carta_campo(_dados.targetId) : noone;
    if (!instance_exists(_alvo) && variable_struct_exists(_dados, "targetId"))
        _alvo = online_encontrar_construcao_campo(_dados.targetId);

    var _atraso = variable_struct_exists(_dados, "visualDelay") ? _dados.visualDelay : 0;
    var _destino_x = instance_exists(_alvo) ? _alvo.x : _atacante.x;
    var _destino_y = instance_exists(_alvo) ? _alvo.y : _atacante.y - 70;
    var _tipo_ataque = variable_struct_exists(_dados, "attackType") ? _dados.attackType : "fisica";

    if (variable_struct_exists(_dados, "stealRoll") && _dados.stealRoll > 0) {
        rolar_dado_visual(_atacante.x, _atacante.y, _destino_x, _destino_y - 70,
            10, _dados.stealRoll, noone, 0, _atraso, 105);
        if (variable_struct_exists(_dados, "stolenItem") && _dados.stolenItem != "")
            mostrar_feedback("ROUBOU O EQUIPAMENTO", _destino_x, _destino_y - 55, c_yellow, 65);
    }

    if (variable_struct_exists(_dados, "counter") && is_struct(_dados.counter)) {
        _dados.counter.visualDelay = _atraso + irandom_range(225, 275);
        apresentacao_animar_ataque_confirmado("attack", _dados.counter);
    }

    if (variable_struct_exists(_dados, "madnessNoDefense") && _dados.madnessNoDefense) {
        mostrar_feedback("SEM DEFESA — ACERTO AUTOMÁTICO", _destino_x, _destino_y - 58, c_yellow, 88);
    } else if (variable_struct_exists(_dados, "accuracy")) {
        var _natural = variable_struct_exists(_dados, "accuracyRoll") ? _dados.accuracyRoll : _dados.accuracy;
        var _abrir_critico = variable_struct_exists(_dados, "criticalChoice") && _dados.criticalChoice;
        var _acertou = !variable_struct_exists(_dados, "hit") || _dados.hit;
        var _contexto_d20 = {
            atacante: _atacante, alvo: _alvo, px: _destino_x, py: _destino_y,
            total: _dados.accuracy, acertou: _acertou, abrir_critico: _abrir_critico,
            qtd: variable_struct_exists(_dados, "dice") ? _dados.dice : 1,
            dado: variable_struct_exists(_dados, "die") ? _dados.die : 0,
            modo: (_atacante.condicao == "berserker") ? "VANTAGEM"
                : ((_atacante.condicao == "confusao") ? "DESVANTAGEM" : "")
        };
        var _callback_d20 = method(_contexto_d20, function(_ignorado) {
            var _prefixo = (modo == "") ? "" : modo + " — ";
            if (abrir_critico && instance_exists(atacante)) {
                mostrar_feedback(_prefixo + "ACERTO CRÍTICO!", px, py - 58, c_yellow, 78);
                obj_controlador.ui_modal.critico_contexto = {
                    atacante: atacante, defensor: alvo, qtd_usada: qtd, dado_usado: dado, online: true
                };
                obj_controlador.ui_modal.critico_escolha_ativa = true;
                obj_controlador.carta_menu_aberto = noone;
            } else if (!acertou) {
                mostrar_feedback(_prefixo + "ERROU — " + string(total), px, py - 58, c_gray, 68);
            } else {
                mostrar_feedback(_prefixo + "ACERTOU — " + string(total), px, py - 58, c_lime, 52);
            }
        });
        var _rolagens_d20 = variable_struct_exists(_dados, "accuracyRolls") && is_array(_dados.accuracyRolls)
            ? _dados.accuracyRolls : [_natural];
        for (var a = 0; a < array_length(_rolagens_d20); a++) {
            var _offset_d20 = (a - (array_length(_rolagens_d20) - 1) * 0.5) * 92;
            rolar_dado_visual(_atacante.x, _atacante.y, _destino_x + _offset_d20, _destino_y - 55,
                20, _rolagens_d20[a], (a == array_length(_rolagens_d20) - 1) ? _callback_d20 : noone,
                0, _atraso + a * irandom_range(25, 40), 108 + irandom_range(-4, 14));
        }
        if (!_acertou || _abrir_critico) return;
    }

    var _rolagens_dano = variable_struct_exists(_dados, "damageRolls") && is_array(_dados.damageRolls)
        ? _dados.damageRolls : [];
    var _quantidade = array_length(_rolagens_dano);
    if (_quantidade > 0) {
        // O servidor envia o dado utilizado. O fallback preserva mensagens de salas antigas.
        var _tamanho = variable_struct_exists(_dados, "die") ? _dados.die
            : ((_tipo_ataque == "magica") ? _atacante.dado_dano_magico : _atacante.dado_dano);
        var _texto = "DANO " + string(_dados.damage);
        if (_quantidade > 1) {
            _texto = "";
            for (var s = 0; s < _quantidade; s++) {
                if (s > 0) _texto += " + ";
                _texto += string(_rolagens_dano[s]);
            }
            _texto += " = DANO " + string(_dados.damage);
        }
        var _cor = (variable_struct_exists(_dados, "critical") && _dados.critical) ? c_yellow : c_red;
        var _contexto_impacto = {
            atacante: _atacante, alvo: _alvo, dano: _dados.damage,
            tipo_ataque: _tipo_ataque, texto: _texto, cor: _cor,
            castelo: variable_struct_exists(_dados, "target") && _dados.target == "castle",
            lado_castelo: (_atacante.dono == "jogador") ? "inimigo" : "jogador"
        };
        var _callback_impacto = method(_contexto_impacto, function(_ignorado) {
            var _evento = apresentacao_evento_impacto(atacante, alvo, dano, tipo_ataque,
                castelo, lado_castelo, false, texto, cor);
            evento_partida_aplicar(_evento);
        });
        for (var d = 0; d < _quantidade; d++) {
            var _deslocamento = (d - (_quantidade - 1) * 0.5) * 78;
            rolar_dado_visual(_atacante.x, _atacante.y, _destino_x + _deslocamento,
                _destino_y - 28, _tamanho, _rolagens_dano[d],
                (d == _quantidade - 1) ? _callback_impacto : noone, 0,
                _atraso + 135 + d * irandom_range(55, 75), 110 + irandom_range(-5, 16));
        }
    } else if (variable_struct_exists(_dados, "damage")) {
        var _evento_sem_dado = apresentacao_evento_impacto(_atacante, _alvo, _dados.damage,
            _tipo_ataque, variable_struct_exists(_dados, "target") && _dados.target == "castle",
            (_atacante.dono == "jogador") ? "inimigo" : "jogador", false,
            "DANO " + string(_dados.damage), c_red);
        apresentacao_enfileirar(_evento_sem_dado, _atraso);
    }

    if (_tipo_mensagem == "choose_critical" && variable_struct_exists(_dados, "followUp")
        && is_struct(_dados.followUp)) {
        _dados.followUp.visualDelay = 260 + _quantidade * 75;
        apresentacao_animar_ataque_confirmado("attack", _dados.followUp);
    }
}
