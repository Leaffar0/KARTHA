// =============================================================================
// KARTHA — eventos semânticos da partida
// As regras produzem eventos; estado e apresentação consomem o mesmo contrato.
// =============================================================================

function evento_partida_criar(_tipo, _dados) {
    return { tipo: _tipo, dados: _dados };
}

function evento_dano_tropa_criar(_atacante, _alvo, _dano, _tipo_ataque,
    _defesa = 0, _destruir = true, _texto = "", _cor = c_red, _critico = false) {
    return evento_partida_criar("dano_tropa", {
        atacante: _atacante,
        alvo: _alvo,
        dano: max(0, _dano),
        tipo_ataque: _tipo_ataque,
        defesa: max(0, _defesa),
        destruir: _destruir,
        critico: _critico,
        texto: _texto,
        cor: _cor
    });
}

function evento_dano_construcao_criar(_atacante, _alvo, _dano,
    _destruir = true, _texto = "", _cor = c_red, _critico = false) {
    return evento_partida_criar("dano_construcao", {
        atacante: _atacante,
        alvo: _alvo,
        dano: max(0, _dano),
        destruir: _destruir,
        critico: _critico,
        texto: _texto,
        cor: _cor
    });
}

function evento_dano_castelo_criar(_atacante, _lado, _dano, _texto = "", _cor = c_red) {
    return evento_partida_criar("dano_castelo", {
        atacante: _atacante,
        origem: instance_exists(_atacante) ? _atacante.nome_carta : "",
        lado: _lado,
        dano: max(0, _dano),
        texto: _texto,
        cor: _cor
    });
}

function evento_feedback_criar(_texto, _x, _y, _cor = c_white, _duracao = 55) {
    return evento_partida_criar("feedback", {
        texto: _texto, x: _x, y: _y, cor: _cor, duracao: _duracao
    });
}

function evento_partida_aplicar(_evento) {
    if (!is_struct(_evento) || !variable_struct_exists(_evento, "tipo")
        || !variable_struct_exists(_evento, "dados") || !is_struct(_evento.dados)) return false;

    var _dados = _evento.dados;
    switch (_evento.tipo) {
        case "feedback":
            if (variable_struct_exists(_dados, "som_critico") && _dados.som_critico)
                tocar_som_variado("critico", 0.40, 0.90);
            mostrar_feedback(_dados.texto, _dados.x, _dados.y, _dados.cor, _dados.duracao);
            return true;

        case "impacto_tropa":
            registrar_marca_mesa(_dados.x, _dados.y + 32, variable_struct_exists(_dados, "magica") && _dados.magica);
            tocar_som_impacto_criatura(_dados);
            if (_dados.critico && _dados.dano > 0)
                tocar_som_variado("critico", 0.40, 0.90);
            if (instance_exists(_dados.alvo)) {
                aplicar_flash_dano(_dados.alvo, 18, _dados.atacante, _dados.defesa, _dados.critico);
                if (_dados.defesa <= 0) _dados.alvo.defesa_impacto_timer = 0;
                if (_dados.defesa > 0) {
                    _dados.alvo.defesa_bloqueio_total = _dados.dano <= 0;
                    if (!_dados.critico || _dados.dano <= 0)
                        tocar_som_variado((variable_struct_exists(_dados,"magica") && _dados.magica)?"magia_escudo":"defesa_escudo", 0.25, 1);
                    if (_dados.dano <= 0) {
                        _dados.alvo.dano_flash_timer = 0;
                        _dados.alvo.recuo_dano_x *= 0.2;
                        _dados.alvo.recuo_dano_y *= 0.2;
                    }
                }
                mostrar_dano_tropa(_dados.alvo, _dados.dano);
            } else if (_dados.dano > 0) {
                mostrar_feedback("-" + string(_dados.dano), _dados.x, _dados.y, c_red, 42);
            }
            if (_dados.texto != "" && !(_dados.defesa > 0 && _dados.dano == 0))
                mostrar_feedback(_dados.texto, _dados.x, _dados.y - 55, _dados.cor, 82);
            return true;

        case "dano_tropa":
            if (!instance_exists(_dados.alvo)) return false;
            if (instance_exists(_dados.atacante))
                registrar_jogada_recente(_dados.atacante.dono, _dados.dano == 0 && _dados.defesa > 0
                    ? "Ataque bloqueado" : "Tropa recebeu " + string(_dados.dano) + " de dano", _dados.alvo.lane_atual);
            apresentar_impacto_tropa(_dados.atacante, _dados.alvo, _dados.dano, _dados.defesa, _dados.texto, _dados.cor, _dados.critico, _dados.tipo_ataque == "magica");
            _dados.alvo.vida = max(0, _dados.alvo.vida - _dados.dano);
            debug_combate(_dados.alvo.nome_carta + " tomou " + string(_dados.dano)
                + " de dano " + _dados.tipo_ataque + "! Vida agora: " + string(_dados.alvo.vida), [_dados.atacante, _dados.alvo]);

            if (_dados.destruir && _dados.alvo.vida <= 0) {
                if (instance_exists(_dados.atacante) && tem_habilidade(_dados.atacante, "digestao"))
                    _dados.atacante.digestao_cadaver_disponivel = true;
                _dados.alvo.tipo_morte_visual = (_dados.tipo_ataque == "magica") ? "magica" : "fisica";
                destruir_tropa(_dados.alvo);
            }
            return true;

        case "dano_construcao":
            if (!instance_exists(_dados.alvo)) return false;
            if (instance_exists(_dados.atacante))
                registrar_jogada_recente(_dados.atacante.dono, "Construção recebeu " + string(_dados.dano) + " de dano", _dados.alvo.lane_atual);
            var _atraso_construcao = iniciar_animacao_ataque(_dados.atacante, _dados.alvo,
                _dados.critico ? 21 : 18, 18, _dados.critico);
            _dados.alvo.vida = max(0, _dados.alvo.vida - _dados.dano);
            if (_dados.dano > 0) _dados.alvo.vida_pulso_inicio = current_time;
            var _texto_construcao = (_dados.texto != "") ? _dados.texto : "-" + string(_dados.dano);
            var _feedback_construcao = evento_feedback_criar(_texto_construcao, _dados.alvo.x,
                _dados.alvo.y - 44, _dados.cor, 55);
            _feedback_construcao.dados.som_critico = _dados.critico && _dados.dano > 0;
            if (_atraso_construcao > 0 && instance_exists(obj_controlador))
                apresentacao_enfileirar(_feedback_construcao, _atraso_construcao);
            else evento_partida_aplicar(_feedback_construcao);
            if (_dados.destruir && _dados.alvo.vida <= 0) destruir_construcao(_dados.alvo);
            return true;

        case "dano_castelo":
            if (instance_exists(_dados.atacante))
                registrar_jogada_recente(_dados.atacante.dono, "Castelo recebeu " + string(_dados.dano) + " de dano", _dados.atacante.lane_atual);
            if (instance_exists(_dados.atacante)) iniciar_animacao_ataque(_dados.atacante, noone, 18, 18);
            causar_dano_castelo(_dados.lado, _dados.dano, _dados.origem);
            if (_dados.texto != "") {
                var _y_castelo = (_dados.lado == "jogador") ? room_height - 92 : 92;
                mostrar_feedback(_dados.texto, room_width / 2, _y_castelo, _dados.cor, 82);
            }
            return true;
    }
    return false;
}
