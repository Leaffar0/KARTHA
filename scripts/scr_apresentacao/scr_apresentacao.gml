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
    if (!instance_exists(obj_controlador)) return false;
    return array_length(obj_controlador.apresentacao.fila) > 0 || array_length(obj_controlador.fila_dano_castelo) > 0
        || (obj_controlador.dano_castelo_ativo && !obj_controlador.dano_castelo_aplicado);
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
        var _carta_contra = online_encontrar_carta_campo(_dados.counter.cardId);
        if (instance_exists(_carta_contra)) apresentar_contra_ataque(_carta_contra);
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
                if (atacante.dono != online_lado_local()) return;
                obj_controlador.ui_modal.critico_contexto = {
                    atacante: atacante, defensor: alvo, qtd_usada: qtd, dado_usado: dado, online: true
                };
                obj_controlador.ui_modal.critico_escolha_ativa = true;
                obj_controlador.carta_menu_aberto = noone;
            } else if (!acertou) {
                if (instance_exists(atacante) && instance_exists(alvo))
                    registrar_trajeto_erro(atacante, alvo, _prefixo + "Errou · " + string(total));
                else mostrar_feedback(_prefixo + "ERROU — " + string(total), px, py - 58, c_gray, 68);
                if (instance_exists(atacante)) registrar_jogada_recente(atacante.dono, "Ataque errou", atacante.lane_atual);
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
    ligar_efeito_alvo(_mimic,_inimigo,c_purple);
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
    var _grupo="magia_arcana";
    switch(_chave) {
        case "golpe_duplo": _grupo="ataque_lamina"; break;
        case "carnica_frenetica": _grupo="ataque_corpo"; break;
        case "imitacao": _grupo="imitacao"; break;
        case "digestao": _grupo="digestao"; break;
        case "ferida_exposta": _grupo="ferida"; break;
        case "sombra_translucida": _grupo="sombra"; break;
        case "visao_do_veu": _grupo="magia_veu"; break;
    }
    return tocar_som_variado(_grupo,volume_grupo_som(_grupo));
}

// Um único desenho para a partida e o laboratório; coordenadas já estão na GUI.
function desenhar_ativacao_habilidade_gui(_px,_py,_altura_gui,_chave,_tempo) {
    if(_tempo<0 || _tempo>=84) return;
    var _t=_tempo/84, _a=min(1,(1-_t)*5);
    var _gw=display_get_gui_width(), _gh=display_get_gui_height();
    draw_set_font(Fontenil);draw_set_halign(fa_center);draw_set_valign(fa_middle);
        var _cor = make_color_rgb(245, 197, 104);
        var _raio_base = max(65,_altura_gui*0.6);
        var _raio = _raio_base * (0.65 + 0.65 * (1 - power(1 - min(1, _t * 2), 3)));
        draw_set_color(_cor); draw_set_alpha(_a * max(0, 1 - _t * 2) * min(1,fator_efeitos_visuais()));
        for (var _i = 0; _i < 12; _i++) {
            var _ang = _i * 30 + _t * 40;
            draw_line_width(_px + lengthdir_x(_raio, _ang), _py + lengthdir_y(_raio, _ang),
                _px + lengthdir_x(_raio + 18, _ang), _py + lengthdir_y(_raio + 18, _ang), 2);
        }
        var _nome = string_upper(obter_nome_exibicao_habilidade(_chave));
        var _w = min(_gw - 32, max(250, string_width(_nome) * 0.75 + 36));
        var _bx = clamp(_px, _w / 2 + 16, _gw - _w / 2 - 16);
        var _by = clamp(_py - _altura_gui*0.5 - 36 - min(1, _t * 6) * 12, 40, _gh - 40);
        draw_set_alpha(_a * 0.94); draw_set_color(make_color_rgb(22, 15, 30));
        draw_rectangle(_bx - _w/2, _by - 25, _bx + _w/2, _by + 25, false);
        draw_set_color(_cor); draw_set_alpha(_a);
        draw_rectangle(_bx - _w/2, _by - 25, _bx + _w/2, _by + 25, true);
        var _s = min(0.75, (_w - 24) / max(1, string_width(_nome)));
        draw_text_transformed(_bx, _by - 5, _nome, _s, _s, 0);
        draw_text_transformed(_bx, _by + 14, "HABILIDADE ATIVADA", 0.32, 0.32, 0);
    draw_set_alpha(1);draw_set_color(c_white);
    draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_font(-1);
}
function desenhar_ativacoes_habilidade() {
    var _cam=view_camera[0], _gw=display_get_gui_width(), _gh=display_get_gui_height();
    with(obj_carta) if(visual_habilidade_timer>0) {
        desenhar_ativacao_habilidade_gui((x-camera_get_view_x(_cam))*_gw/camera_get_view_width(_cam),
            (y-camera_get_view_y(_cam))*_gh/camera_get_view_height(_cam),
            sprite_get_height(sprite_index)*abs(image_yscale)*_gh/camera_get_view_height(_cam),
            visual_habilidade_chave,84-visual_habilidade_timer);
    }
}

// Som cosmético: alterna arquivos sem interferir nas rolagens da partida.
function tocar_som_variado(_grupo, _volume = 0.3, _pitch = 1) {
    var _grupos=catalogo_sons_jogo();
    static _indices = {};
    static _instantes = {};
    static _vozes = {};
    if (!variable_struct_exists(_grupos, _grupo)) return noone;
    if (variable_struct_exists(_instantes, _grupo)
        && current_time - variable_struct_get(_instantes, _grupo) < 75) return noone;
    var _sons = variable_struct_get(_grupos, _grupo);
    var _indice = variable_struct_exists(_indices, _grupo) ? variable_struct_get(_indices, _grupo) : 0;
    variable_struct_set(_indices, _grupo, (_indice + 1) mod array_length(_sons));
    variable_struct_set(_instantes, _grupo, current_time);
    // No máximo duas vozes por categoria, mesmo em sequências rápidas.
    var _ativas = variable_struct_exists(_vozes, _grupo) ? variable_struct_get(_vozes, _grupo) : [];
    for (var _v = array_length(_ativas) - 1; _v >= 0; _v--) {
        if (!audio_is_playing(_ativas[_v])) array_delete(_ativas, _v, 1);
    }
    if (array_length(_ativas) >= 2) {
        audio_stop_sound(_ativas[0]);
        array_delete(_ativas, 0, 1);
    }
    var _voz = audio_play_sound(_sons[_indice], 1, false, clamp(_volume, 0, 1), 0, _pitch);
    array_push(_ativas, _voz);
    variable_struct_set(_vozes, _grupo, _ativas);
    return _voz;
}

// Resíduos usam tempo visual e uma fila limitada; não alteram o tabuleiro.
function registrar_marca_mesa(_x, _y, _magica = false) {
    if (!instance_exists(obj_controlador)) return;
    var _c = obj_controlador;
    array_push(_c.marcas_mesa, {x:_x, y:_y, magica:_magica, tempo:0});
    if (array_length(_c.marcas_mesa) > 24) array_delete(_c.marcas_mesa, 0, 1);
}
function desenhar_marca_mesa(_x, _y, _tempo, _magica) {
    var _p = clamp(_tempo / 150, 0, 1);
    var _a = (1 - _p) * 0.38 * min(1.3,fator_efeitos_visuais());
    draw_set_color(_magica ? make_color_rgb(125, 92, 190) : make_color_rgb(30, 20, 16));
    draw_set_alpha(_a);
    var _r = 36 + min(1, _tempo / 14) * 24;
    if (_magica) {
        draw_circle(_x, _y, _r, true);
        for (var i=0; i<8; i++) {
            var _ang=i*45 + _tempo*0.25;
            draw_circle(_x+lengthdir_x(_r,_ang), _y+lengthdir_y(_r,_ang), 2, false);
        }
    } else {
        draw_ellipse(_x-_r, _y-9, _x+_r, _y+9, false);
        for (var i=0; i<7; i++) {
            var _ang=i*51+12;
            draw_line_width(_x+lengthdir_x(12,_ang), _y+lengthdir_y(9,_ang),
                _x+lengthdir_x(_r+8,_ang), _y+lengthdir_y(_r*0.5,_ang), 2);
        }
    }
    draw_set_alpha(1); draw_set_color(c_white);
}
function personalidade_visual(_nome, _voa, _tempo) {
    var _s = 1, _y = 0, _r = 0;
    if (_voa) _y = -2 - sin(_tempo * 0.0018) * 2;
    else if (string_pos("slim", string_lower(_nome)) > 0) _s = 1 + sin(_tempo * 0.0014) * 0.018;
    else if (string_pos("mimic", string_lower(_nome)) > 0) {
        var _fase = (_tempo mod 7600) / 7600;
        if (_fase > 0.90) _r = sin((_fase-0.90)*180) * sin((_fase-0.90)*10*pi) * 0.65;
    }
    return {escala:_s, y:_y, rotacao:_r};
}
function apresentar_contra_ataque(_carta) {
    if (!instance_exists(_carta)) return;
    _carta.contra_visual_timer = 60;
    _carta.contra_ataque_pendente = true;
    mostrar_feedback("CONTRA-ATAQUE", _carta.x, _carta.y-70, c_yellow, 65);
    tocar_som_variado("empurrao", 0.23);
}
function desenhar_quebra_castelo(_x, _y, _tempo, _escala = 1) {
    // Doze quadros de antecipação, depois cada pedaço segue sua própria trajetória.
    var _p = clamp((_tempo - 12) / 42, 0, 1);
    draw_set_color(make_color_rgb(223, 182, 104)); draw_set_alpha(1-_p);
    for (var i=0; i<5; i++) {
        var _sx = _x + ((i-2)*16 + (i-2)*_p*40) * _escala;
        var _sy = _y + (-sin(_p*pi)*30 + _p*_p*70 + (i mod 2)*_p*16) * _escala;
        draw_rectangle(_sx-7*_escala,_sy-15*_escala,_sx+7*_escala,_sy+16*_escala,false);
        draw_rectangle(_sx-7*_escala,_sy-24*_escala,_sx-1*_escala,_sy-15*_escala,false);
        draw_rectangle(_sx+2*_escala,_sy-24*_escala,_sx+7*_escala,_sy-15*_escala,false);
    }
    draw_set_alpha(1); draw_set_color(c_white);
}

function abrir_laboratorio_visual() {
    if (!instance_exists(obj_controlador) || obj_controlador.modo_partida == "online") return;
    global.laboratorio_origem = room;
    global.laboratorio_persistencia = room_persistent;
    global.laboratorio_views = view_enabled;
    global.laboratorio_voltando = false;
    obj_controlador.ui_modal.pausa_ativa = true;
    room_persistent = true;
    if (!variable_global_exists("laboratorio_room")) {
        global.laboratorio_room = room_add();
        room_instance_add(global.laboratorio_room,0,0,obj_laboratorio);
    }
    room_goto(global.laboratorio_room);
}
function laboratorio_reiniciar(_lab) {
    for(var _i=0;_i<array_length(_lab.sons_combate);_i++) audio_stop_sound(_lab.sons_combate[_i]);
    _lab.sons_combate=[];
    _lab.pausado=false;
    if (_lab.som_previa!=noone) audio_stop_sound(_lab.som_previa);
    _lab.som_previa=noone;
    _lab.tempo=0; _lab.som_contato=false;
    switch (_lab.modo) {
        case 0: if(_lab.magia_previa) _lab.som_previa=tocar_som_magia("arcana"); break;
        case 1: if(_lab.magia==1) _lab.som_previa=audio_play_sound(snd_bola_fogo_voo,1,false,0.5);
            else _lab.som_previa=tocar_som_magia(["arcana","bola_fogo","veneno","gelo","choque"][_lab.magia]); break;
        case 3: _lab.som_previa=tocar_som_variado("empurrao",0.23); break;
        case 5: _lab.som_previa=tocar_som_variado("deslize",0.38); break;
        case 6: _lab.som_previa=apresentar_ativacao_habilidade(_lab,_lab.habilidades[_lab.habilidade]); break;
        case 7:
            var _sons=variable_struct_get(catalogo_sons_jogo(),_lab.grupos[_lab.grupo]);
            _lab.variacao_som=clamp(_lab.variacao_som,0,array_length(_sons)-1);
            _lab.som_previa=audio_play_sound(_sons[_lab.variacao_som],1,false,volume_grupo_som(_lab.grupos[_lab.grupo]));
            break;
    }
}

function escala_pulso_vida(_inicio) {
    var _p = clamp((current_time - _inicio) / 360, 0, 1);
    return 1 + 0.65 * sin(_p*pi) * (1-_p) * fator_efeitos_visuais();
}

function fator_efeitos_visuais() {
    var _nivel=variable_global_exists("intensidade_visual")?global.intensidade_visual:1;
    return _nivel==0?0.35:(_nivel==2?1.35:1);
}
function alternar_efeitos_visuais() {
    global.intensidade_visual=(global.intensidade_visual+1) mod 3;
    salvar_configuracoes();
}
function ligar_efeito_alvo(_origem,_alvo,_cor=c_aqua) {
    if (!instance_exists(_origem)||!instance_exists(_alvo)||!instance_exists(obj_controlador)) return;
    array_push(obj_controlador.ligacoes_visuais,{x1:_origem.x,y1:_origem.y,x2:_alvo.x,y2:_alvo.y,cor:_cor,t:0,
        raio:max(40,sprite_get_width(_alvo.sprite_index)*abs(_alvo.image_xscale)*0.65)});
    if(array_length(obj_controlador.ligacoes_visuais)>12) array_delete(obj_controlador.ligacoes_visuais,0,1);
}
function registrar_trajeto_erro(_atacante, _alvo, _rotulo) {
    if (!instance_exists(_atacante) || !instance_exists(_alvo)) return;
    var _lista = obj_controlador.ligacoes_visuais;
    array_push(_lista, { erro: _rotulo, t: 0,
        x1: _atacante.x - _atacante.sprite_width*0.53, y1: _atacante.y,
        x2: _alvo.x - _alvo.sprite_width*0.53, y2: _alvo.y });
    if (array_length(_lista) > 12) array_delete(_lista, 0, 1);
    obj_controlador.ligacoes_visuais = _lista;
}

function desenhar_ligacao_gui(_x1,_y1,_x2,_y2,_r,_cor,_tempo) {
    if(_tempo<0 || _tempo>=54) return;
    var _p=_tempo/54, _forca=clamp(fator_efeitos_visuais(),0.55,1.2);
        var _fade=min(1,(1-_p)*3);
        draw_set_color(_cor);
        for(var j=11;j>=0;j--) {
            var _a=clamp(_p*1.75-j*0.025,0,1);
            var _x=lerp(_x1,_x2,_a), _y=lerp(_y1,_y2,_a)-sin(_a*pi)*_r*0.55;
            var _size=max(2,_r*(0.13-j*0.007));
            draw_set_alpha(_fade*_forca*(0.85-j*0.05));
            draw_circle(_x,_y,_size,false);
        }
        // O pulso confirma o alvo mesmo quando origem e destino coincidem.
        if(_p>0.40) {
            var _impacto=clamp((_p-0.40)/0.60,0,1);
            var _raio=_r*(0.65+_impacto*0.65);
            draw_set_alpha((1-_impacto)*0.85*_forca);
            draw_circle(_x2,_y2,_raio,true);
            draw_circle(_x2,_y2,_raio+3,true);
            for(var k=0;k<10;k++) {
                var _ang=k*36;
                draw_line_width(_x2+lengthdir_x(_raio,_ang),_y2+lengthdir_y(_raio,_ang),
                    _x2+lengthdir_x(_raio+12,_ang),_y2+lengthdir_y(_raio+12,_ang),2);
            }
        }
    draw_set_alpha(1);draw_set_color(c_white);
}
function desenhar_ligacoes_visuais() {
    var _c=obj_controlador, _cam=view_camera[0];
    var _sx=display_get_gui_width()/camera_get_view_width(_cam),_sy=display_get_gui_height()/camera_get_view_height(_cam);
    var _vx=camera_get_view_x(_cam),_vy=camera_get_view_y(_cam);
    for(var i=0;i<array_length(_c.ligacoes_visuais);i++) {
        var _l=_c.ligacoes_visuais[i];
        if (variable_struct_exists(_l, "erro")) {
            var _p = clamp(_l.t / 42, 0, 1);
            if (_p < 1) {
                draw_set_alpha(min(1, (1-_p)*2));
                desenhar_trajeto_ataque((_l.x1-_vx)*_sx, (_l.y1-_vy)*_sy,
                    (_l.x2-_vx)*_sx-9, (_l.y2-_vy)*_sy, make_color_rgb(201,183,157), _p);
                desenhar_rotulo_resultado_ataque(_l.erro, (_l.x2-_vx)*_sx-48, (_l.y2-_vy)*_sy-12, 76);
                draw_set_alpha(1);
                draw_set_color(c_white);
            }
            continue;
        }
        desenhar_ligacao_gui((_l.x1-_vx)*_sx,(_l.y1-_vy)*_sy,(_l.x2-_vx)*_sx,(_l.y2-_vy)*_sy,
            max(36,_l.raio*max(_sx,_sy)),_l.cor,_l.t);
    }
}

// O aviso guarda apenas informação pública e continua legível se a carta sair de campo.
function registrar_jogada_recente(_lado, _texto, _lane = -1, _tropa_movida = noone) {
    var _c = obj_controlador;
    if (_lado != "inimigo") return;
    _c.jogada_recente_lado = _lado;
    _c.jogada_recente_tropa = instance_exists(_tropa_movida) && !tropa_oculta_nevoa(_tropa_movida)
        ? _tropa_movida.nome_carta : "";
    _c.jogada_recente_texto = _texto + (_lane >= 0 ? " · coluna " + string(_lane+1) : "");
    _c.jogada_recente_tempo = 4;
}

function desenhar_jogada_recente() {
    var _c = obj_controlador;
    if (_c.jogada_recente_tempo <= 0 || controlador_modal_atual(_c) != ""
        || _c.ui_modal.historico_aberto || _c.carta_preview != noone || _c.painel_regras_animacao >= 0.005) return;
    var _alpha = min(1, _c.jogada_recente_tempo / 0.45);
    var _x = 20 - max(0, _c.jogada_recente_tempo-3.8)*22;
    var _y = layout_painel_regras().y > 100 ? 150 : 118;
    var _largura = 230;
    draw_set_alpha(_alpha * 0.94);
    draw_set_color(make_color_rgb(28, 26, 27));
    draw_roundrect(_x, _y, _x+_largura, _y+49, false);
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(212, 181, 134));
    draw_rectangle(_x, _y+4, _x+2, _y+45, false);
    desenhar_texto_ajustado_ui("ÚLTIMA JOGADA · " + nome_jogador_lado(_c.jogada_recente_lado),
        _x+10, _y+4, _largura-20, 0.49);
    draw_set_color(make_color_rgb(241, 235, 222));
    var _texto = _c.jogada_recente_texto;
    if (_c.jogada_recente_tropa != "" && !lado_oculto_nevoa(_c.jogada_recente_lado))
        _texto = string_replace(_texto, "Tropa", _c.jogada_recente_tropa);
    desenhar_texto_ajustado_ui(_texto, _x+10, _y+22, _largura-20, 0.70);
    draw_set_color(c_white);
    draw_set_alpha(1);
}

// Read-only attack preview: never rolls dice, pays costs or changes the selected weapon.
function dados_previa_ataque(_carta,_opcao) {
    if (!instance_exists(_carta) || string_pos("Atacar",_opcao)!=1 || string_pos("[",_opcao)>0) return noone;
    var _magica=_opcao=="Atacar (Mágica)",_arma=noone;
    if (string_pos("Atacar com ",_opcao)==1) {
        var _nome=string_delete(_opcao,1,string_length("Atacar com "));
        for(var i=0;i<array_length(_carta.itens_equipados);i++)
            if(_carta.itens_equipados[i].nome==_nome) _arma=_carta.itens_equipados[i];
        if(!is_struct(_arma)) return noone;
    }
    var _alcance=!is_struct(_arma) && tem_habilidade(_carta,_magica?"alcance_magico":"alcance");
    var _sentido=direcao_avanco(_carta.dono),_alvo=noone,_nome_alvo="Sem alvo válido",_defesa=0;
    var _slot=buscar_slot(_carta.lane_atual,_carta.posicao_atual+_sentido);
    if((_slot==noone||!_slot.ocupado)&&_alcance) _slot=buscar_slot(_carta.lane_atual,_carta.posicao_atual+_sentido*2);
    if(_slot!=noone && _slot.ocupado && instance_exists(_slot.carta_atual)) {
        var _c=_slot.carta_atual;
        if(_c.dono!=_carta.dono && !_c.sombra_ativa
            && !(_carta.posicao_atual==posicao_assalto(_carta.dono) && _c.posicao_atual==posicao_entrada(_c.dono) && !_c.defendendo_castelo)
            && (!tem_habilidade(_c,"voar")||tem_habilidade(_carta,"voar")||tem_habilidade(_carta,"alcance")||tem_habilidade(_carta,"alcance_magico"))) _alvo=_c;
    }
    if(_alvo==noone && _carta.posicao_atual==posicao_assalto(_carta.dono)) {
        _alvo=_alcance?buscar_construcao(_carta.lane_atual,lado_oposto(_carta.dono)):noone;
        if(_alvo==noone) _alvo=buscar_defensor_castelo(_carta.lane_atual,lado_oposto(_carta.dono));
        if(_alvo==noone) _nome_alvo="Castelo inimigo";
    }
    var _castelo = _alvo == noone && _carta.posicao_atual == posicao_assalto(_carta.dono);
    if (_carta.carnica_estado_proximo_ataque == "autoataque" && !tem_aliado_adjacente(_carta)) {
        _alvo = _carta;
        _castelo = false;
    }
    if(instance_exists(_alvo)) {
        _nome_alvo=_alvo.nome_carta;
        if(_alvo.object_index==obj_carta) _defesa=(_magica?calcular_defesa_magica_total(_alvo):calcular_defesa_fisica_total(_alvo))+obj_controlador.terreno_bonus_defesa;
    }
    var _qtd=_magica?_carta.qtd_dados_dano_magico:_carta.qtd_dados_dano;
    var _dado=_magica?_carta.dado_dano_magico:_carta.dado_dano;
    var _mod=_magica?_carta.mod_dano_magico:_carta.mod_dano;
    if(is_struct(_arma)) { _qtd=1;_dado=_arma.dado;_mod=_arma.modificador; }
    var _texto=_carta.nome_carta+" > "+_nome_alvo+"\nDados base: "+string(_qtd)+"D"+string(_dado)+" + "+string(_mod)+" | Defesa: "+string(_defesa);
    _texto+="\nBônus, condições e testes são resolvidos ao atacar.";
    if(_carta.iludido_por_imitacao) _texto+="\nImitação: exige novo teste; pode provocar contra-ataque.";
    else if(instance_exists(_alvo)&&_alvo.object_index==obj_carta&&_alvo.dado_dano>0) _texto+="\nFalha crítica pode provocar contra-ataque.";
    return {alvo:_alvo, castelo:_castelo, texto:_texto};
}
// A seta contorna as cartas pela esquerda, deixando livres a ilustração e o menu.
function desenhar_trajeto_ataque(_x1, _y1, _x2, _y2, _cor, _erro = 0) {
    var _margem = min(_x1, _x2) - 14;
    var _pontos_x = [_x1, _margem, _margem, _x2];
    var _pontos_y = [_y1, _y1, _y2, _y2];
    var _extensao = (_x1-_margem) + abs(_y2-_y1) + (_x2-_margem);
    var _apagado = _extensao * sqr(_erro);
    var _distancia = 0;
    var _fase = frac(current_time / 680) * 14;
    for (var i = 0; i < 3; i++) {
        var _ax = _pontos_x[i], _ay = _pontos_y[i];
        var _bx = _pontos_x[i+1], _by = _pontos_y[i+1];
        var _comprimento = point_distance(_ax, _ay, _bx, _by);
        if (_comprimento < 1) continue;
        draw_set_color(make_color_rgb(28, 23, 23));
        var _inicio = clamp((_apagado - _distancia) / _comprimento, 0, 1);
        if (_inicio < 1) draw_line_width(lerp(_ax,_bx,_inicio), lerp(_ay,_by,_inicio), _bx, _by, 4);
        draw_set_color(_cor);
        for (var d = _fase - (_distancia mod 14) - 14; d < _comprimento; d += 14) {
            var _de = max(_inicio, clamp(d, 0, _comprimento) / _comprimento);
            var _ate = clamp(d + 8, 0, _comprimento) / _comprimento;
            if (_ate > _de) draw_line_width(lerp(_ax,_bx,_de), lerp(_ay,_by,_de),
                lerp(_ax,_bx,_ate), lerp(_ay,_by,_ate), 2);
        }
        _distancia += _comprimento;
    }
    if (_erro == 0) draw_circle(_x1, _y1, 3, false);
    draw_triangle(_x2, _y2, _x2-8, _y2-5, _x2-8, _y2+5, false);
}

function desenhar_previa_ataque() {
    var _c=obj_controlador;
    if(!instance_exists(_c.carta_menu_aberto)||_c.menu_submenu!="ataque"||_c.opcao_hover_index<0
        ||controlador_modal_atual(_c)!=""||_c.carta_preview!=noone) return;
    var _opcoes=obter_opcoes_menu(_c.carta_menu_aberto);
    if(_c.opcao_hover_index>=array_length(_opcoes)) return;
    var _prev=dados_previa_ataque(_c.carta_menu_aberto,_opcoes[_c.opcao_hover_index]);
    if(!is_struct(_prev)) return;
    if(tropa_oculta_nevoa(_prev.alvo)) _prev.texto="TROPA OCULTA PELA NÉVOA\nVocê pode atacar este espaço, mas os atributos ficam ocultos até o fim do turno.";
    var _cam=view_camera[0],_gw=display_get_gui_width(),_gh=display_get_gui_height();
    var _sx = _gw/camera_get_view_width(_cam), _sy = _gh/camera_get_view_height(_cam);
    var _vx = camera_get_view_x(_cam), _vy = camera_get_view_y(_cam);
    var _origem = _c.carta_menu_aberto;
    var _cor = make_color_rgb(229, 195, 141);
    var _ox = (_origem.x-_vx - sprite_get_width(_origem.sprite_index)*abs(_origem.image_xscale)*0.53)*_sx;
    var _oy = (_origem.y-_vy)*_sy;
    var _topo_trajeto = _oy, _base_trajeto = _oy;
    var _refs = [_origem, _prev.alvo];
    draw_set_color(_cor);
    for(var i=0;i<2;i++) if(instance_exists(_refs[i])) {
        var _r=_refs[i];
        var _x=(_r.x-_vx)*_sx,_y=(_r.y-_vy)*_sy;
        var _w=sprite_get_width(_r.sprite_index)*abs(_r.image_xscale)*_sx*0.53;
        var _h=sprite_get_height(_r.sprite_index)*abs(_r.image_yscale)*_sy*0.53;
        _topo_trajeto = min(_topo_trajeto, _y-_h);
        _base_trajeto = max(_base_trajeto, _y+_h);
        draw_rectangle(_x-_w,_y-_h,_x+_w,_y+_h,true);
        if (i == 1) desenhar_trajeto_ataque(_ox, _oy, _x-_w, _y-(_r == _origem ? _h*0.6 : 0), _cor);
    }
    if (_prev.castelo) {
        var _destino = obter_posicao_castelo(lado_oposto(_origem.dono));
        var _cx = (_destino.x-_vx)*_sx, _cy = (_destino.y-_vy)*_sy;
        _topo_trajeto = min(_topo_trajeto, _cy-8);
        _base_trajeto = max(_base_trajeto, _cy+8);
        desenhar_trajeto_ataque(_ox, _oy, _cx-8, _cy, _cor);
        draw_circle(_cx, _cy, 8, true);
    }
    var _pw=min(520,_gw-24),_px=(_gw-_pw)/2;
    draw_set_font(Fontenil);draw_set_halign(fa_left);draw_set_valign(fa_top);
    var _paginas=paginar_detalhes_carta(_prev.texto,_pw-24,140,0.50);
    var _ph=min(164,string_height(_paginas[0])*0.5+24);
    var _py = 12;
    if (_topo_trajeto < _ph+24 && _gh-_base_trajeto > _topo_trajeto)
        _py = _gh-12-_ph;
    draw_set_color(make_color_rgb(28,26,27));draw_set_alpha(0.96);draw_roundrect(_px,_py,_px+_pw,_py+_ph,false);
    draw_set_alpha(1);draw_set_color(_cor);draw_roundrect(_px,_py,_px+_pw,_py+_ph,true);
    draw_set_color(c_white);draw_text_transformed(_px+12,_py+12,_paginas[0],0.5,0.5,0);
    draw_set_font(-1);draw_set_halign(fa_left);draw_set_valign(fa_top);
}

function desenhar_projetil_magia_gui(_sprite,_frame,_px,_py,_ex,_ey,_angulo,_cor,_alpha,_impacto,_tempo_impacto,_escala_tela) {
    draw_sprite_ext(_sprite,_frame,_px,_py,_ex*1.2,_ey*1.2,_angulo,_cor,_alpha);
    if(_impacto) {
        var _p=clamp(_tempo_impacto/36,0,1),_r=(24+_p*60)*_escala_tela;
        draw_set_alpha((1-_p)*0.75*min(1,fator_efeitos_visuais()));
        draw_set_color(make_color_rgb(255,155,45));
        draw_circle(_px,_py,_r,true);draw_circle(_px,_py,_r+3,true);
    }
    draw_set_color(c_white);draw_set_alpha(1);
}
function desenhar_projeteis_magia_gui() {
    var _cam=view_camera[0];
    var _sx=display_get_gui_width()/camera_get_view_width(_cam),_sy=display_get_gui_height()/camera_get_view_height(_cam);
    var _vx=camera_get_view_x(_cam),_vy=camera_get_view_y(_cam);
    with(obj_bola_fogo_projetil) desenhar_projetil_magia_gui(sprite_index,image_index,(x-_vx)*_sx,(y-_vy)*_sy,
        image_xscale*_sx,image_yscale*_sy,image_angle,image_blend,image_alpha,impactou,36-alarm[0],max(_sx,_sy));
}
function posicao_encaixe_equipamento(_ox,_oy,_fx,_fy,_altura,_rotacao,_p) {
    var _entrada=clamp(_p/0.45,0,1);_entrada=_entrada*_entrada*(3-2*_entrada);
    var _encaixe=clamp((_p-0.45)/0.55,0,1);_encaixe=1-power(1-_encaixe,3);
    var _ax=_fx+lengthdir_x(_altura*0.65,270+_rotacao);
    var _ay=_fy+lengthdir_y(_altura*0.65,270+_rotacao);
    return {x:lerp(lerp(_ox,_ax,_entrada),_fx,_encaixe),y:lerp(lerp(_oy,_ay,_entrada),_fy,_encaixe)};
}

function catalogo_sons_jogo() {
    static _grupos = {
        clique: [snd_ui_clique_1,snd_ui_clique_2],
        ajuste: [snd_ui_ajuste],
        aviso: [snd_ui_aviso],
        painel_abrir: [snd_foley_livro_abrir],
        painel_fechar: [snd_foley_livro_fechar],
        pagina: [snd_foley_pagina_1,snd_foley_pagina_2],
        ataque_corpo: [snd_impacto_corpo_1,snd_impacto_corpo_2],
        ataque_lamina: [snd_foley_lamina_1,snd_foley_lamina_2],
        defesa_escudo: [snd_impacto_escudo_1,snd_impacto_escudo_2],
        critico: [snd_impacto_pesado_1,snd_impacto_pesado_2],
        gelo: [snd_magia_gelo_1,snd_magia_gelo_2],
        gelo_estilhacos: [snd_impacto_gelo_1,snd_impacto_gelo_2],
        imitacao: [snd_mimic_bau_1,snd_mimic_bau_2],
        madeira_rangido: [snd_foley_mimic_1,snd_foley_mimic_2,snd_madeira_mimic],
        slime_ataque: [snd_slime_ataque],
        slime_dano: [snd_slime_dano],
        esqueleto: [snd_esqueleto_osso_1,snd_esqueleto_osso_2],
        mordida: [snd_monstro_mordida],
        sombra: [snd_foley_tecido,snd_sussurro_sombra],
        ferida: [snd_foley_corte_seco,snd_corte_ferida],
        digestao: [snd_papel_digestao],
        magia_impacto: [snd_impacto_gelo_1,snd_impacto_gelo_2],
        magia_arcana: [snd_magia_sombria],
        magia_antiga: [snd_arcano_1,snd_arcano_2,snd_arcano_3,snd_arcano_4,snd_arcano_5,snd_arcano_6,snd_arcano_7],
        magia_veneno: [snd_magia_sombria],
        magia_choque: [snd_magia_descarga,snd_magia_raio_2,snd_magia_raio_1],
        magia_cura: [snd_arcano_2],
        magia_escudo: [snd_arcano_5],
        magia_veu: [snd_magia_sombria],
        bola_fogo: [snd_bola_fogo_voo,snd_bola_fogo_impacto,snd_bola_fogo_fogo],
        ritual: [snd_bencao,snd_maldicao],
        moeda: [snd_moeda_arremesso,snd_moeda_impacto],
        baralho: [snd_shuffle],

        deslize: [snd_papel_deslize, snd_papel_deslize_2, snd_papel_deslize_3],
        encaixe: [snd_papel_encaixe, snd_papel_encaixe_2, snd_papel_encaixe_3],
        dado: [snd_dado_mesa, snd_dado_mesa_2, snd_dado_mesa_3],
        metal: [snd_metal_defesa, snd_metal_defesa_2],
        golpe: [snd_metal_golpe, snd_metal_golpe_2, snd_metal_golpe_3],
        abrir: [snd_papel_abrir, snd_papel_abrir_2],
        empurrao: [snd_papel_empurrao, snd_papel_empurrao_2],
        recurso: [snd_recurso_toque, snd_recurso_toque_2]
    };
    return _grupos;
}
function volume_grupo_som(_grupo) {
    switch(_grupo) {
        case "clique": return 0.20; case "ajuste": return 0.20; case "aviso": return 0.18;
        case "painel_abrir": case "painel_fechar": case "pagina": return 0.22;
        case "magia_arcana": case "magia_veneno": case "magia_choque": case "magia_cura": case "magia_escudo": case "magia_veu": return 0.24;
        case "sombra": return 0.22;
    }
    return 0.32;
}
function grupo_som_magia(_efeito) {
    switch(_efeito) {
        case "bola_fogo": return "";
        case "veneno": case "envenenado": return "magia_veneno";
        case "gelo": case "congelado": return "gelo";
        case "choque": case "raio": case "eletrocutado": return "magia_choque";
        case "curazinha": case "cura": return "magia_cura";
        case "escudo": return "magia_escudo";
    }
    return "magia_arcana";
}
function tocar_som_magia(_efeito) {
    var _grupo=grupo_som_magia(_efeito);
    if(_grupo=="") return noone;
    return tocar_som_variado(_grupo,volume_grupo_som(_grupo));
}

// Apenas apresentação: o nome identifica a família sem modificar regras da tropa.
function grupo_som_criatura(_nome, _recebendo = false) {
    _nome = string_lower(_nome);
    if (string_pos("slime", _nome) > 0) return _recebendo ? "slime_dano" : "slime_ataque";
    if (string_pos("esqueleto", _nome) > 0) return "esqueleto";
    if (!_recebendo && (string_pos("lobo", _nome) > 0 || string_pos("urso", _nome) > 0
        || string_pos("mimic", _nome) > 0 || string_pos("mímic", _nome) > 0)) return "mordida";
    return "";
}

function nome_tropa_sonora(_carta) {
    if (!instance_exists(_carta) || !variable_instance_exists(_carta, "nome_carta")) return "";
    return _carta.nome_carta;
}

function tocar_som_impacto_criatura(_dados) {
    var _vozes=[];
    if (_dados.dano <= 0) return _vozes;
    var _magica = variable_struct_exists(_dados, "magica") && _dados.magica;
    // O alvo pode já ter morrido quando o impacto agendado é apresentado.
    var _origem = variable_struct_exists(_dados, "nome_atacante") ? _dados.nome_atacante : nome_tropa_sonora(_dados.atacante);
    var _destino = variable_struct_exists(_dados, "nome_alvo") ? _dados.nome_alvo : nome_tropa_sonora(_dados.alvo);
    var _ataque = _magica ? "" : grupo_som_criatura(_origem);
    var _dano = grupo_som_criatura(_destino, true);
    if (_ataque != "") array_push(_vozes,tocar_som_variado(_ataque, 0.30));
    if (_dano != "" && _dano != _ataque) array_push(_vozes,tocar_som_variado(_dano, 0.26));
    if (_ataque == "" && _dano == "" && !_dados.critico && _dados.defesa <= 0)
        array_push(_vozes,tocar_som_variado(_magica ? "magia_impacto" : "ataque_corpo", 0.26, 0.98));
    return _vozes;
}

// Contato da peça com a superfície: repouso quase colado; altura só durante ações.
function desenhar_sombra_contato(_sprite, _frame, _x, _y, _sx, _sy, _rot, _altura = 0, _alpha = 1) {
    var _h = clamp(_altura, 0, 40);
    var _dist = 1 + _h*0.18;
    var _opacidade = lerp(0.38, 0.19, _h/40) * _alpha;
    draw_sprite_ext(_sprite,_frame,_x+_dist+1,_y+_dist+2,_sx*1.008,_sy*1.008,_rot,c_black,_opacidade*0.35);
    draw_sprite_ext(_sprite,_frame,_x+_dist,_y+_dist,_sx,_sy,_rot,c_black,_opacidade);
}

// Legenda pequena para objetos da mesa; preserva o estado de desenho do chamador.
function desenhar_legenda_mesa(_x, _y, _texto, _alpha) {
    if (_alpha < 0.015) return;
    var _font = draw_get_font(), _ha = draw_get_halign(), _va = draw_get_valign();
    var _cor = draw_get_color(), _a = draw_get_alpha();
    draw_set_font(Fontenil);
    // Estas legendas são desenhadas no mundo: respeitam os limites da câmera.
    var _vx = view_enabled ? view_xview[0] : 0;
    var _vy = view_enabled ? view_yview[0] : 0;
    var _vw = view_enabled ? view_wview[0] : room_width;
    var _vh = view_enabled ? view_hview[0] : room_height;
    var _esc = min(0.38, min(174,max(1,_vw-32))/max(1,string_width(_texto)));
    var _w = string_width(_texto)*_esc + 16;
    _x = clamp(_x, _vx+8+_w/2, _vx+_vw-8-_w/2);
    _y = clamp(_y, _vy+8, _vy+_vh-30);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(c_black); draw_set_alpha(_alpha*0.78);
    draw_roundrect(_x-_w/2,_y,_x+_w/2,_y+22,false);
    draw_set_alpha(_alpha); draw_set_color(make_color_rgb(220,220,220));
    draw_text_transformed(_x,_y+11,_texto,_esc,_esc,0);
    draw_set_font(_font); draw_set_halign(_ha); draw_set_valign(_va);
    draw_set_color(_cor); draw_set_alpha(_a);
}

// A borda se forma progressivamente; o interior translúcido preserva a arte.
function desenhar_escudo_defesa_formacao(_x,_y,_w,_form,_alpha) {
    if (_alpha<=0) return;
    var _a=draw_get_alpha(),_cor=draw_get_color();
    var _f=clamp(_form,0,1),_h=_w*1.24;
    var _px=[-0.44,0,0.44,0.39,0.25,0,-0.25,-0.39];
    var _py=[-0.40,-0.50,-0.40,0.08,0.32,0.51,0.32,0.08];
    draw_set_color(make_color_rgb(55,151,235));
    draw_set_alpha(_alpha*_f*0.25);
    draw_primitive_begin(pr_trianglefan);draw_vertex(_x,_y);
    for(var _i=0;_i<=8;_i++){var _j=_i mod 8;draw_vertex(_x+_px[_j]*_w,_y+_py[_j]*_h);}
    draw_primitive_end();
    for(var _b=0;_b<2;_b++) {
        var _esc=_b==0?1:0.88;
        draw_set_color(_b==0?make_color_rgb(127,211,255):make_color_rgb(65,158,229));
        draw_set_alpha(_alpha*(_b==0?0.85:0.42));
        for(var _i=0;_i<8;_i++) {
            var _q=clamp(_f*8-_i,0,1),_j=(_i+1) mod 8;
            if(_q<=0) continue;
            draw_line_width(_x+_px[_i]*_w*_esc,_y+_py[_i]*_h*_esc,
                _x+lerp(_px[_i],_px[_j],_q)*_w*_esc,
                _y+lerp(_py[_i],_py[_j],_q)*_h*_esc,max(1,_w*0.025));
        }
    }
    // Reflexo curto durante a formação, sem círculo em volta da tropa.
    if(_f>0 && _f<1) {
        draw_set_alpha(sin(_f*pi)*_alpha*0.6);draw_set_color(c_white);
        var _sy=_y+lerp(-0.26,0.20,_f)*_h;
        draw_line(_x-_w*0.18,_sy,_x+_w*0.18,_sy-_h*0.10);
    }
    draw_set_alpha(_a);draw_set_color(_cor);
}

function desenhar_escudo_bloqueio(_x,_y,_tamanho,_p,_total=true) {
    if(_p<0 || _p>=1) return;
    var _f=clamp(_p/0.24,0,1);
    var _esc=0.85+0.15*_f+sin(_f*pi)*0.08;
    var _alpha=(1-power(clamp((_p-0.5)/0.5,0,1),2))*(_total?1:0.65);
    _x+=sin(_p*55)*power(1-_f,2)*_tamanho*0.035*min(1,fator_efeitos_visuais());
    desenhar_escudo_defesa_formacao(_x,_y,_tamanho*_esc,_f,_alpha);
}

function desenhar_rotulo_resultado_ataque(_texto, _x, _y, _largura) {
    var _fonte = draw_get_font(), _ha = draw_get_halign(), _va = draw_get_valign();
    draw_set_font(Fontenil);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _esc = min(0.68, _largura/max(1, string_width(_texto)));
    var _hw = string_width(_texto)*_esc/2+4, _hh = string_height(_texto)*_esc/2;
    draw_set_color(make_color_rgb(36,32,30));
    draw_roundrect(_x-_hw,_y-_hh,_x+_hw,_y+_hh,false);
    draw_set_color(make_color_rgb(229,207,167));
    draw_text_transformed(_x,_y,_texto,_esc,_esc,0);
    draw_set_halign(_ha); draw_set_valign(_va); draw_set_font(_fonte);
}

function desenhar_escudos_bloqueio_gui() {
    var _cam=view_camera[0];
    var _sx=display_get_gui_width()/camera_get_view_width(_cam);
    var _sy=display_get_gui_height()/camera_get_view_height(_cam);
    var _vx=camera_get_view_x(_cam),_vy=camera_get_view_y(_cam);
    with(obj_carta) {
        if((defesa_impacto_timer<=0 && defesa_presenca<=0) || tropa_oculta_nevoa(id) || esta_na_mao) continue;
        var _x=(x+ataque_offset_x+recuo_dano_x-_vx)*_sx;
        var _y=(y+y_offset_atual+ataque_offset_y-ataque_elevacao+recuo_dano_y-_vy)*_sy;
        var _w=sprite_get_width(sprite_index)*abs(image_xscale)*_sx*0.72;
        if(defesa_impacto_timer>0) {
            var _p = 1-defesa_impacto_timer/defesa_impacto_duracao;
            desenhar_escudo_bloqueio(_x,_y,_w,_p,defesa_bloqueio_total);
            if (defesa_bloqueio_total) {
                var _hw = sprite_width*_sx*0.51, _hh = sprite_height*_sy*0.51;
                var _alpha = clamp((1-_p)*4, 0, 1);
                var _cor = make_color_rgb(229,207,167);
                draw_set_alpha(_alpha);
                draw_set_color(_cor);
                draw_rectangle(_x-_hw,_y-_hh,_x+_hw,_y+_hh,true);
                desenhar_rotulo_resultado_ataque("Bloqueado", _x, _y+_hh*0.64, _hw*2-4);
                draw_set_color(c_white); draw_set_alpha(1);
            }
        } else desenhar_escudo_defesa_formacao(_x,_y,_w,defesa_formacao,
            defesa_presenca*lerp(1,0.65,defesa_formacao));
    }
}

// A tinta acompanha o papel durante giros, ampliações e animações de dano.
function desenhar_carta_mesa(_sprite, _frame, _x, _y, _sx, _sy, _rot, _cor, _alpha, _inspecao = 0) {
    // A escala de entrada se refere à máscara original, inclusive em cartas sem ilustração.
    if (_sprite == spr_deck || _sprite == spr_carta_placeholder) {
        var _arte = _sprite == spr_deck ? spr_verso_kartha : spr_papel_carvao;
        _sx *= sprite_get_width(_sprite) / sprite_get_width(_arte);
        _sy *= sprite_get_height(_sprite) / sprite_get_height(_arte);
        _sprite = _arte;
    }
    var _papel = _sprite != spr_verso_kartha && shader_is_compiled(shd_papel_carta);
    if (_papel) {
        static _recorte = shader_get_uniform(shd_papel_carta, "u_recorte");
        static _pixels = shader_get_uniform(shd_papel_carta, "u_pixels");
        static _gesto = shader_get_uniform(shd_papel_carta, "u_gesto");
        var _uv = sprite_get_uvs(_sprite, floor(_frame) mod sprite_get_number(_sprite));
        shader_set(shd_papel_carta);
        shader_set_uniform_f(_recorte, _uv[0], _uv[1], _uv[2], _uv[3]);
        var _tipo = 0, _dx = 0, _dy = 0;
        if (_inspecao > 0 && (_sprite == spr_carta_gato_mago || _sprite == spr_carta_esqueleto)) {
            shader_set_uniform_f(_pixels, _uv[4], _uv[5],
                _uv[6] * sprite_get_width(_sprite), _uv[7] * sprite_get_height(_sprite));
            var _intensidade = min(1, fator_efeitos_visuais());
            if (_sprite == spr_carta_gato_mago) {
                _tipo = 1;
                var _olhos_y = _y + (128 - sprite_get_yoffset(_sprite)) * _sy;
                _dx = clamp((device_mouse_x_to_gui(0) - _x) / (70 * _sx), -1, 1) * 2.2 * _intensidade;
                _dy = clamp((device_mouse_y_to_gui(0) - _olhos_y) / (70 * _sy), -1, 1) * 1.1 * _intensidade;
            } else {
                _tipo = 2;
                var _batida = clamp((_inspecao - 0.52) / 0.42, 0, 1);
                _dy = sin(_batida * pi) * 2.4 * _intensidade;
            }
        }
        shader_set_uniform_f(_gesto, _tipo, _dx, _dy);
    }
    draw_sprite_ext(_sprite, _frame, _x, _y, _sx, _sy, _rot, _cor, _alpha);
    if (_papel) shader_reset();
}

function registrar_rastro_pagamento(_recurso, _destino, _ordem) {
    if (!instance_exists(obj_controlador)) return;
    var _ox = _recurso.x, _oy = _recurso.y;
    // Efeitos sem alvo e ações ocultas deixam a marca junto ao próprio recurso.
    var _fx = _ox, _fy = _oy - 21;
    if (instance_exists(_destino)) {
        var _dx = _ox - _destino.x, _dy = _oy - _destino.y;
        var _borda = max(1, abs(_dx) / 21, abs(_dy) / 27);
        _fx = _destino.x + _dx / _borda;
        _fy = _destino.y + _dy / _borda;
    }
    array_push(obj_controlador.rastros_pagamento, {
        ox: _ox, oy: _oy, fx: _fx, fy: _fy,
        sprite: _recurso.sprite_index, tempo: -min(0.18, _ordem * 0.045)
    });
}

function desenhar_rastros_pagamento(_rastros) {
    if (array_length(_rastros) == 0) return;
    var _a = draw_get_alpha(), _c = draw_get_color();
    var _tinta = make_color_rgb(224, 214, 192);
    var _forca = min(1, fator_efeitos_visuais());
    for (var i = 0; i < array_length(_rastros); i++) {
        var _r = _rastros[i];
        if (_r.tempo < 0) continue;
        var _p = clamp(_r.tempo / 0.48, 0, 1);
        var _opacidade = min(1, _p * 12, (1 - _p) * 6) * _forca;
        var _px = _r.ox, _py = _r.oy;
        // Três pinceladas curtas seguem o símbolo, todas em coordenadas da mesa.
        for (var j = 0; j <= 3; j++) {
            var _t = max(0, _p - (3 - j) * 0.045);
            var _suave = _t * _t * (3 - 2 * _t);
            var _nx = lerp(_r.ox, _r.fx, _suave);
            var _ny = lerp(_r.oy, _r.fy, _suave) - sin(_t * pi) * 9;
            if (j > 0) {
                draw_set_color(_tinta);
                draw_set_alpha(_opacidade * j / 6);
                draw_line(_px, _py, _nx, _ny);
            }
            _px = _nx; _py = _ny;
        }
        if (shader_is_compiled(shd_tinta_recurso)) {
            // O miolo das quatro cartas contém o símbolo impresso na mesma área.
            var _esc = 0.12 * (0.8 + 0.2 * sin(_p * pi));
            shader_set(shd_tinta_recurso);
            draw_sprite_part_ext(_r.sprite, 0, 72, 98, 144, 164,
                _px - 72 * _esc + 0.7, _py - 82 * _esc + 1, _esc, _esc, c_black, _opacidade);
            draw_sprite_part_ext(_r.sprite, 0, 72, 98, 144, 164,
                _px - 72 * _esc, _py - 82 * _esc, _esc, _esc, _tinta, _opacidade);
            shader_reset();
        }
    }
    draw_set_alpha(_a); draw_set_color(_c);
}
