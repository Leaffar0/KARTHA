// =============================================================================
// KARTHA — eventos semânticos da partida
// As regras produzem eventos; estado e apresentação consomem o mesmo contrato.
// =============================================================================

function evento_partida_criar(_tipo, _dados) {
    return { tipo: _tipo, dados: _dados };
}

function evento_dano_tropa_criar(_atacante, _alvo, _dano, _tipo_ataque,
    _defesa = 0, _destruir = true, _texto = "", _cor = c_red) {
    return evento_partida_criar("dano_tropa", {
        atacante: _atacante,
        alvo: _alvo,
        dano: max(0, _dano),
        tipo_ataque: _tipo_ataque,
        defesa: max(0, _defesa),
        destruir: _destruir,
        texto: _texto,
        cor: _cor
    });
}

function evento_dano_construcao_criar(_atacante, _alvo, _dano,
    _destruir = true, _texto = "", _cor = c_red) {
    return evento_partida_criar("dano_construcao", {
        atacante: _atacante,
        alvo: _alvo,
        dano: max(0, _dano),
        destruir: _destruir,
        texto: _texto,
        cor: _cor
    });
}

function evento_dano_castelo_criar(_atacante, _lado, _dano, _texto = "", _cor = c_red) {
    return evento_partida_criar("dano_castelo", {
        atacante: _atacante,
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
            mostrar_feedback(_dados.texto, _dados.x, _dados.y, _dados.cor, _dados.duracao);
            return true;

        case "dano_tropa":
            if (!instance_exists(_dados.alvo)) return false;
            if (instance_exists(_dados.atacante))
                iniciar_animacao_ataque(_dados.atacante, _dados.alvo, 18, 18);
            aplicar_flash_dano(_dados.alvo, 18, _dados.atacante, _dados.defesa);
            _dados.alvo.vida = max(0, _dados.alvo.vida - _dados.dano);
            mostrar_dano_tropa(_dados.alvo, _dados.dano);
            if (_dados.texto != "")
                mostrar_feedback(_dados.texto, _dados.alvo.x, _dados.alvo.y - 55, _dados.cor, 82);
            debug_combate(_dados.alvo.nome_carta + " tomou " + string(_dados.dano)
                + " de dano " + _dados.tipo_ataque + "! Vida agora: " + string(_dados.alvo.vida));

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
                iniciar_animacao_ataque(_dados.atacante, _dados.alvo, 18, 18);
            _dados.alvo.vida = max(0, _dados.alvo.vida - _dados.dano);
            var _texto_construcao = (_dados.texto != "") ? _dados.texto : "-" + string(_dados.dano);
            mostrar_feedback(_texto_construcao, _dados.alvo.x, _dados.alvo.y - 44, _dados.cor, 55);
            if (_dados.destruir && _dados.alvo.vida <= 0) destruir_construcao(_dados.alvo);
            return true;

        case "dano_castelo":
            if (instance_exists(_dados.atacante)) iniciar_animacao_ataque(_dados.atacante, noone, 18, 18);
            causar_dano_castelo(_dados.lado, _dados.dano);
            if (_dados.texto != "") {
                var _y_castelo = (_dados.lado == "jogador") ? room_height - 92 : 92;
                mostrar_feedback(_dados.texto, room_width / 2, _y_castelo, _dados.cor, 82);
            }
            return true;
    }
    return false;
}

function eventos_partida_aplicar(_eventos) {
    if (!is_array(_eventos)) return;
    for (var i = 0; i < array_length(_eventos); i++) evento_partida_aplicar(_eventos[i]);
}
