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
    _texto = "", _cor = c_red, _critico = false, _defesa = 0) {
    if (_eh_castelo)
        return evento_dano_castelo_criar(_atacante, _lado_castelo, _dano, _texto, _cor);
    if (instance_exists(_alvo) && _alvo.object_index == obj_construcao)
        return evento_dano_construcao_criar(_atacante, _alvo, _dano,
            _aplicar_destruicao, _texto, _cor, _critico);
    return evento_dano_tropa_criar(_atacante, _alvo, _dano, _tipo_ataque,
        _defesa, _aplicar_destruicao, _texto, _cor, _critico);
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

    if (variable_struct_exists(_dados, "illusionSourceRoll")) {
        apresentar_teste_imitacao(online_encontrar_carta_campo(_dados.illusionSourceId), _atacante,
            _dados.illusionSourceRoll, _dados.illusionEnemyRoll);
        _atraso += 130;
    }
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
            modo: (tem_condicao(_atacante, "berserker") && !tem_condicao(_atacante, "confusao")) ? "VANTAGEM"
                : ((tem_condicao(_atacante, "confusao") && !tem_condicao(_atacante, "berserker")) ? "DESVANTAGEM" : "")
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
        var _critico = variable_struct_exists(_dados, "critical") && _dados.critical;
        var _cor = _critico ? c_yellow : c_red;
        var _contexto_impacto = {
            atacante: _atacante, alvo: _alvo, dano: _dados.damage,
            tipo_ataque: _tipo_ataque, texto: _texto, cor: _cor, critico: _critico,
            defesa: variable_struct_exists(_dados, "defense") ? _dados.defense : 0,
            castelo: variable_struct_exists(_dados, "target") && _dados.target == "castle",
            lado_castelo: (_atacante.dono == "jogador") ? "inimigo" : "jogador"
        };
        var _callback_impacto = method(_contexto_impacto, function(_ignorado) {
            var _evento = apresentacao_evento_impacto(atacante, alvo, dano, tipo_ataque,
                castelo, lado_castelo, false, texto, cor, critico, defesa);
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
            "DANO " + string(_dados.damage), c_red,
            variable_struct_exists(_dados, "critical") && _dados.critical,
            variable_struct_exists(_dados, "defense") ? _dados.defense : 0);
        apresentacao_enfileirar(_evento_sem_dado, _atraso);
    }

    if (_tipo_mensagem == "choose_critical" && variable_struct_exists(_dados, "followUp")
        && is_struct(_dados.followUp)) {
        _dados.followUp.visualDelay = 260 + _quantidade * 75;
        apresentacao_animar_ataque_confirmado("attack", _dados.followUp);
    }
}


function atualizar_efeitos_identidade(_carta) {
    if (_carta.visual_habilidade_timer > 0) _carta.visual_habilidade_timer--;
    if (obj_controlador.modo_partida != "online"
        && _carta.habilidade_usada_este_turno && !_carta.visual_habilidade_usada
        && _carta.visual_habilidade_chave != "")
        apresentar_ativacao_habilidade(_carta, _carta.visual_habilidade_chave);
    _carta.visual_habilidade_usada = _carta.habilidade_usada_este_turno;
    if (_carta.ilusao_timer > 0) _carta.ilusao_timer--;
    if (_carta.olhar_timer > 0) _carta.olhar_timer--;
    if (_carta.morrendo) return;
    if (_carta.visual_iludida != _carta.iludido_por_imitacao) {
        _carta.visual_iludida = _carta.iludido_por_imitacao;
        _carta.ilusao_rompida = !_carta.visual_iludida;
        _carta.ilusao_timer = 32;
        audio_play_sound(snd_moeda_impacto, 1, false, 0.16, 0,
            _carta.ilusao_rompida ? 1.55 : 0.65);
    }
    if (!_carta.visual_olhar_testado && _carta.testado_olhar_vazio) {
        _carta.visual_olhar_testado = true;
        _carta.olhar_timer = 36;
        var _slot = buscar_slot(_carta.lane_atual, _carta.posicao_atual + direcao_avanco(_carta.dono));
        if (_slot != noone && instance_exists(_slot.carta_atual)
            && tem_habilidade(_slot.carta_atual, "olhar_vazio")) _slot.carta_atual.olhar_timer = 36;
        audio_play_sound(snd_bencao, 1, false, 0.16, 0, 0.65);
    }
    if (_carta.evoluindo && !_carta.visual_evoluindo)
        tocar_som_variado("abrir", 0.28, 0.90);
    _carta.visual_evoluindo = _carta.evoluindo;
}

function desenhar_efeitos_identidade(_carta, _x, _y, _escala, _angulo, _alpha) {
    if (!_carta.travada || _carta.morrendo) return;
    var _w = sprite_get_width(_carta.sprite_index) * _escala;
    var _h = sprite_get_height(_carta.sprite_index) * _escala;
    if (_carta.ilusao_timer > 0) {
        var _p = 1 - _carta.ilusao_timer / 32;
        var _dist = _carta.ilusao_rompida ? 4 + _p * 18 : sin(_p * pi) * 5;
        for (var _lado = -1; _lado <= 1; _lado += 2) {
            draw_sprite_ext(_carta.sprite_index, _carta.image_index, _x + _lado * _dist, _y,
                _escala, _escala, _angulo + _lado * _p * 3,
                make_color_rgb(170, 138, 205), _alpha * (1 - _p) * 0.22);
        }
        if (_carta.ilusao_rompida) {
            draw_set_color(make_color_rgb(202, 192, 224));
            draw_set_alpha(_alpha * sqr(1 - _p) * 0.7);
            for (var _i = 0; _i < 6; _i++) {
                var _a = _i * 60 + 15;
                var _raio = _w * 0.4 + _p * 22;
                var _sx = _x + lengthdir_x(_raio, _a);
                var _sy = _y + lengthdir_y(_raio, _a);
                draw_line(_sx, _sy, _sx + lengthdir_x(5, _a + 35), _sy + lengthdir_y(5, _a + 35));
            }
        }
    }
    if (_carta.olhar_timer > 0) {
        var _p = 1 - _carta.olhar_timer / 36;
        draw_set_alpha(_alpha * sin(_p * pi) * 0.42);
        draw_set_color(tem_habilidade(_carta, "olhar_vazio") ? make_color_rgb(190, 170, 232) : c_black);
        var _faixa_y = _y - _h * 0.45 + _h * 0.9 * _p;
        draw_rectangle(_x - _w * 0.45, _faixa_y, _x + _w * 0.45, _faixa_y + 3, false);
    }
    if (_carta.vida > 0 && _carta.vida <= max(1, _carta.vida_maxima * 0.2)) {
        draw_set_alpha(_alpha * (0.28 + 0.08 * sin(current_time * 0.003)));
        draw_set_color(make_color_rgb(72, 39, 30));
        for (var _i = 0; _i < 4; _i++) {
            var _a = _angulo + 45 + _i * 90;
            var _rx = _w * 0.43 * ((_i == 0 || _i == 3) ? 1 : -1);
            var _ry = _h * 0.43 * (_i < 2 ? -1 : 1);
            var _cx = _x + lengthdir_x(_rx, _angulo) + lengthdir_x(_ry, _angulo - 90);
            var _cy = _y + lengthdir_y(_rx, _angulo) + lengthdir_y(_ry, _angulo - 90);
            draw_line(_cx, _cy, _cx + lengthdir_x(5, _a), _cy + lengthdir_y(5, _a));
        }
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

function apresentar_teste_imitacao(_mimic, _inimigo, _total_mimic, _total_inimigo, _contra = false) {
    if (!instance_exists(_mimic) || !instance_exists(_inimigo)) return;
    var _ctx = { mimic: _mimic, inimigo: _inimigo, contra: _contra };
    rolar_dado_visual(_mimic.x, _mimic.y, _mimic.x - 45, _mimic.y - 65,
        20, _total_mimic - _mimic.nivel_inteligencia, noone, _mimic.nivel_inteligencia, 0, 100, _mimic.dono);
    rolar_dado_visual(_inimigo.x, _inimigo.y, _inimigo.x + 45, _inimigo.y - 65,
        20, _total_inimigo - _inimigo.nivel_inteligencia,
        method(_ctx, function(_valor) {
            if (contra && instance_exists(mimic) && instance_exists(inimigo)
                && !mimic.morrendo && !inimigo.morrendo) executar_contra_ataque(inimigo, mimic);
        }), _inimigo.nivel_inteligencia, 18, 100);
}

function apresentar_ativacao_habilidade(_carta, _chave) {
    if (!instance_exists(_carta)) return;
    _carta.visual_habilidade_chave = _chave;
    _carta.visual_habilidade_timer = 84;
    if (_chave == "golpe_duplo" || _chave == "carnica_frenetica") {
        tocar_som_variado("golpe", _chave == "golpe_duplo" ? 0.32 : 0.26);
        return;
    }
    var _som = snd_bencao, _volume = 0.22;
    switch (_chave) {
        case "golpe_duplo": _som = snd_metal_golpe; _volume = 0.32; break;
        case "imitacao": _som = snd_madeira_mimic; _volume = 0.30; break;
        case "digestao": _som = snd_papel_digestao; _volume = 0.34; break;
        case "ferida_exposta": _som = snd_corte_ferida; _volume = 0.28; break;
        case "sombra_translucida": _som = snd_sussurro_sombra; _volume = 0.22; break;
        case "visao_do_veu": _som = snd_sussurro_sombra; _volume = 0.18; break;
        case "carnica_frenetica": _som = snd_metal_golpe; _volume = 0.26; break;
    }
    // Evita acumular vozes iguais quando várias tropas ativam na mesma atualização.
    if (!audio_is_playing(_som)) audio_play_sound(_som, 1, false, _volume, 0, 1);
}

function desenhar_ativacoes_habilidade() {
    var _cam = view_camera[0];
    var _gw = display_get_gui_width(), _gh = display_get_gui_height();
    draw_set_font(Fontenil);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    with (obj_carta) if (visual_habilidade_timer > 0) {
        var _t = 1 - visual_habilidade_timer / 84;
        var _a = min(1, (1 - _t) * 5);
        var _px = (x - camera_get_view_x(_cam)) * _gw / camera_get_view_width(_cam);
        var _py = (y - camera_get_view_y(_cam)) * _gh / camera_get_view_height(_cam);
        var _cor = make_color_rgb(245, 197, 104);
        var _raio = 25 + 95 * (1 - power(1 - min(1, _t * 2), 3));
        draw_set_color(_cor); draw_set_alpha(_a * max(0, 1 - _t * 2));
        for (var _i = 0; _i < 12; _i++) {
            var _ang = _i * 30 + _t * 40;
            draw_line_width(_px + lengthdir_x(_raio, _ang), _py + lengthdir_y(_raio, _ang),
                _px + lengthdir_x(_raio + 18, _ang), _py + lengthdir_y(_raio + 18, _ang), 2);
        }
        var _nome = string_upper(obter_nome_exibicao_habilidade(visual_habilidade_chave));
        var _w = min(_gw - 32, max(210, string_width(_nome) * 0.65 + 36));
        var _bx = clamp(_px, _w / 2 + 16, _gw - _w / 2 - 16);
        var _by = clamp(_py - 90 - min(1, _t * 6) * 12, 40, _gh - 40);
        draw_set_alpha(_a * 0.94); draw_set_color(make_color_rgb(22, 15, 30));
        draw_rectangle(_bx - _w/2, _by - 25, _bx + _w/2, _by + 25, false);
        draw_set_color(_cor); draw_set_alpha(_a);
        draw_rectangle(_bx - _w/2, _by - 25, _bx + _w/2, _by + 25, true);
        var _s = min(0.65, (_w - 24) / max(1, string_width(_nome)));
        draw_text_transformed(_bx, _by - 5, _nome, _s, _s, 0);
        draw_text_transformed(_bx, _by + 14, "HABILIDADE ATIVADA", 0.32, 0.32, 0);
    }
    draw_set_alpha(1); draw_set_color(c_white);
    draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_font(-1);
}

// Som cosmético: alterna arquivos sem interferir nas rolagens da partida.
function tocar_som_variado(_grupo, _volume = 0.3, _pitch = 1) {
    static _grupos = {
        deslize: [snd_papel_deslize, snd_papel_deslize_2, snd_papel_deslize_3],
        encaixe: [snd_papel_encaixe, snd_papel_encaixe_2, snd_papel_encaixe_3],
        dado: [snd_dado_mesa, snd_dado_mesa_2, snd_dado_mesa_3],
        metal: [snd_metal_defesa, snd_metal_defesa_2],
        golpe: [snd_metal_golpe, snd_metal_golpe_2, snd_metal_golpe_3],
        abrir: [snd_papel_abrir, snd_papel_abrir_2],
        empurrao: [snd_papel_empurrao, snd_papel_empurrao_2],
        recurso: [snd_recurso_toque, snd_recurso_toque_2]
    };
    static _indices = {};
    static _instantes = {};
    if (!variable_struct_exists(_grupos, _grupo)) return noone;
    if (variable_struct_exists(_instantes, _grupo)
        && current_time - variable_struct_get(_instantes, _grupo) < 75) return noone;
    var _sons = variable_struct_get(_grupos, _grupo);
    var _indice = variable_struct_exists(_indices, _grupo) ? variable_struct_get(_indices, _grupo) : 0;
    variable_struct_set(_indices, _grupo, (_indice + 1) mod array_length(_sons));
    variable_struct_set(_instantes, _grupo, current_time);
    return audio_play_sound(_sons[_indice], 1, false, clamp(_volume, 0, 1), 0, _pitch);
}
