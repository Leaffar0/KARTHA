// =============================================================================
// KARTHA — combate
// Movimento, ataques, dano, condições e habilidades de campo.
// =============================================================================

#region Movimento das tropas
function iniciar_pulo_tropa(_carta, _novo_x, _novo_y, _entrada_no_campo = false) {
    _carta.pulando = true;
    _carta.pulo_origem_x = _carta.x;
    _carta.pulo_origem_y = _carta.y;
    _carta.pulo_destino_x = _novo_x;
    _carta.pulo_destino_y = _novo_y;
    _carta.pulo_progresso = 0;
	// Na entrada, começa no tamanho da mão e encolhe suavemente até a escala do campo
	_carta.pulo_escala_origem = _entrada_no_campo ? (global.escala_interface / _carta.escala_no_campo) : 1;
	_carta.escala_animacao = _carta.pulo_escala_origem;
	_carta.pulo_poeira_ao_pousar = true;
    if (_entrada_no_campo && obj_controlador.modo_partida != "online")
        registrar_jogada_recente(_carta.dono, "Tropa convocada", _carta.lane_atual);
    _carta.pulo_som_ao_pousar = _entrada_no_campo;
    _carta.impacto_colocacao_timer = 0;
}

// Consulta o destino sem disparar armadilhas. Retorna o slot livre ou o motivo do bloqueio.
function destino_movimento_tropa(_carta, _direcao) {
    // A tropa precisa sobreviver até o próximo turno do próprio dono antes de avançar.
    if (_carta.turnos_no_campo < 1) return "recem_colocada";

    if (_carta.posicao_atual == posicao_assalto(_carta.dono) && _direcao == 1) {
        return "ja_no_assalto"; // daqui ela já pode atingir construção/castelo
    }

    var _sentido = direcao_avanco(_carta.dono);
    var _nova_posicao = _carta.posicao_atual + (_direcao * _sentido);

    if (_nova_posicao < 0 || _nova_posicao >= total_posicoes_batalha()) return "fora_do_tabuleiro";

    var _slot_destino = buscar_slot(_carta.lane_atual, _nova_posicao);
    if (_slot_destino == noone) return "invalido";

    if (_slot_destino.ocupado) {
        var _ocupante = _slot_destino.carta_atual;
        if (_ocupante.dono == _carta.dono && !(tem_habilidade(_carta, "voar") && !tem_habilidade(_ocupante, "voar"))) {
            return "bloqueado";
        } else {
            // Uma tropa voadora atravessa uma tropa terrestre e pousa na próxima casa livre.
            if (tem_habilidade(_carta, "voar") && !tem_habilidade(_ocupante, "voar")) {
                var _posicao_apos_voo = _nova_posicao + (_direcao * _sentido);
                var _passou_do_assalto = (_carta.dono == "jogador")
                    ? (_posicao_apos_voo < posicao_assalto(_carta.dono))
                    : (_posicao_apos_voo > posicao_assalto(_carta.dono));
                var _slot_apos_voo = buscar_slot(_carta.lane_atual, _posicao_apos_voo);
                if (_slot_apos_voo != noone && !_slot_apos_voo.ocupado && !_passou_do_assalto) {
                    _slot_destino = _slot_apos_voo;
                } else {
                    return "ataque_necessario";
                }
            } else {
            return "ataque_necessario";
            }
        }
    }

    return _slot_destino;
}

function mover_tropa(_carta, _direcao) {
    var _slot_destino = destino_movimento_tropa(_carta, _direcao);
    if (is_string(_slot_destino)) return _slot_destino;
    // Só dispara após confirmar que existe um deslocamento válido.
    if (ativar_raizes_espinhosas_ao_mover(_carta)) {
        _carta.moveu_este_turno = true;
        return "armadilha";
    }

    _carta.slot_atual.ocupado = false;
    _carta.slot_atual.carta_atual = noone;

    _slot_destino.ocupado = true;
    _slot_destino.carta_atual = _carta.id;
    _carta.slot_atual = _slot_destino;
    _carta.posicao_atual = _slot_destino.posicao;
    _carta.defendendo_castelo = false;

    iniciar_pulo_tropa(_carta, _slot_destino.x, _slot_destino.y);

    verificar_olhar_vazio(_carta);
    var _frente_olhar = buscar_slot(_carta.lane_atual, _carta.posicao_atual + direcao_avanco(_carta.dono));
    if (_frente_olhar != noone && instance_exists(_frente_olhar.carta_atual))
        verificar_olhar_vazio(_frente_olhar.carta_atual);

    registrar_jogada_recente(_carta.dono, _direcao == 1 ? "Tropa avançou" : "Tropa recuou", _carta.lane_atual, _carta);
    debug_combate(_carta.nome_carta + " avançou na fileira " + string(_carta.lane_atual + 1) + ".", [_carta]);

    return "movido";
}

// Move todas as tropas de um lado que ainda não chegaram à posição de assalto.
function mover_tropas_automatico(_dono) {
    with (obj_carta) {
        if (dono == _dono && travada && !moveu_este_turno && turnos_no_campo >= 1 && posicao_atual != posicao_assalto(_dono) && tropa_pode_agir(id)) {
            if (mover_tropa(id, 1) == "movido") moveu_este_turno = true;
        }
    }
}
#endregion

#region Combate — dados, dano e resolução
function iniciar_animacao_ataque(_carta, _alvo = noone, _intensidade = 10, _duracao = 15, _critico = false) {
    if (!instance_exists(_carta) || _carta.morrendo) return 0;

    var _dir_x = 0;
    var _dir_y = direcao_avanco(_carta.dono);
    var _alcance = _intensidade * 1.65;
    if (instance_exists(_alvo)) {
        var _dx = _alvo.x - _carta.x;
        var _dy = _alvo.y - _carta.y;
        var _distancia = point_distance(0, 0, _dx, _dy);
        if (_distancia > 0) {
            _dir_x = _dx / _distancia;
            _dir_y = _dy / _distancia;
            _alcance = min(_alcance, _distancia * 0.55);
        }
    }
    var _contra = variable_instance_exists(_carta, "contra_ataque_pendente") && _carta.contra_ataque_pendente;
    if (_contra) { _carta.contra_ataque_pendente = false; _duracao = 16; _alcance *= 1.18; }
    var _preparo = _contra ? 7 : max(3, round(_duracao * 0.23));
    var _golpe = max(3, round(_duracao * 0.17));
    _carta.ataque_animacao = { quadro: 0, preparo: _preparo, contato: _preparo + _golpe, pausa_contato: _critico ? 2 : 0,
        retorno: max(7, _duracao - _preparo - _golpe), dir_x: _dir_x, dir_y: _dir_y,
        alcance: _alcance, recuo: _contra ? 10 : min(6, _intensidade * 0.32) };
    return _preparo + _golpe;
}

function atualizar_animacao_ataque(_carta) {
    var _anim = _carta.ataque_animacao;
    if (_anim == noone) return;
    if (_anim.quadro == _anim.contato && _anim.pausa_contato > 0) {
        _anim.pausa_contato--;
        return;
    }
    _anim.quadro += 1;
    var _distancia;
    var _altura;
    if (_anim.quadro <= _anim.preparo) {
        var _p = _anim.quadro / _anim.preparo;
        _distancia = -_anim.recuo * _p * _p;
        _altura = 3 * _p;
    } else if (_anim.quadro <= _anim.contato) {
        var _p_golpe = (_anim.quadro - _anim.preparo) / (_anim.contato - _anim.preparo);
        _distancia = lerp(-_anim.recuo, _anim.alcance, _p_golpe * _p_golpe);
        _altura = 3 * (1 - _p_golpe);
    } else {
        var _resto = max(0, 1 - (_anim.quadro - _anim.contato) / _anim.retorno);
        _distancia = _anim.alcance * _resto * _resto;
        _altura = 0;
        if (_resto == 0) _carta.ataque_animacao = noone;
    }
    _carta.ataque_offset_x = _anim.dir_x * _distancia;
    _carta.ataque_offset_y = _anim.dir_y * _distancia;
    _carta.ataque_elevacao = _altura;
    _carta.ataque_escala_extra = _altura * 0.012;
}

// O impacto visual acompanha o golpe. A resolução da vida continua no evento de combate.
function apresentar_impacto_tropa(_atacante, _alvo, _dano, _defesa = 0, _texto = "", _cor = c_red, _critico = false, _magica = false) {
    if (_magica && instance_exists(_atacante)) tocar_som_magia("arcana");
    var _atraso = iniciar_animacao_ataque(_atacante, _alvo, _critico ? 21 : 18, 18, _critico);
    var _impacto = evento_partida_criar("impacto_tropa", { atacante: _atacante, alvo: _alvo,
        nome_atacante: nome_tropa_sonora(_atacante), nome_alvo: nome_tropa_sonora(_alvo),
        dano: _dano, defesa: _defesa, texto: _texto, cor: _cor, critico: _critico, magica: _magica, x: _alvo.x, y: _alvo.y });
    if (_atraso > 0 && instance_exists(obj_controlador)) apresentacao_enfileirar(_impacto, _atraso);
    else evento_partida_aplicar(_impacto);
}

// Realça o impacto e desloca a carta na direção oposta ao golpe.
function aplicar_flash_dano(_carta, _duracao = 18, _origem = noone, _defesa = 0, _critico = false) {
    if (!instance_exists(_carta)) return;
    _carta.dano_flash_duracao = max(1, _duracao);
    _carta.dano_flash_timer = _carta.dano_flash_duracao;
    if (_defesa > 0) _carta.defesa_impacto_timer = _carta.defesa_impacto_duracao;
    if (instance_exists(_origem)) {
        var _direcao = point_direction(_origem.x, _origem.y, _carta.x, _carta.y);
        var _recuo = (_critico ? 11 : 7) * fator_efeitos_visuais();
        _carta.recuo_dano_x = lengthdir_x(_recuo, _direcao);
        _carta.recuo_dano_y = lengthdir_y(_recuo, _direcao);
    }
}

// Número de dano sobre a tropa, desenhado pelo HUD acima de todas as cartas.
function mostrar_dano_tropa(_carta, _dano) {
    if (!instance_exists(_carta) || _dano <= 0) return;
    _carta.vida_pulso_inicio = current_time;
    var _texto = instance_create_layer(_carta.x, _carta.y - _carta.sprite_height * 0.45, "Instances", obj_texto_flutuante);
    _texto.texto = "-" + string(_dano);
    _texto.cor_texto = c_red;
    _texto.vida_texto_max = 42;
    _texto.velocidade_subida = 0.35;
    _texto.oscilacao_intensidade = 1.2;
}

function buscar_slot(_lane, _posicao) {
    var _resultado = noone;
    with (obj_slot_batalha) {
        if (lane == _lane && posicao == _posicao) {
            _resultado = id;
        }
    }
    return _resultado;
}

function buscar_construcao(_lane, _dono) {
    var _resultado = noone;
    with (obj_construcao) {
        if (lane_atual == _lane && dono == _dono) {
            _resultado = id;
        }
    }
    return _resultado;
}

// Uma tropa na casa inicial pode se oferecer para receber ataques que chegariam
// diretamente ao castelo da sua própria fileira.
function buscar_defensor_castelo(_lane, _dono) {
    var _resultado = noone;
    with (obj_carta) {
        if (travada && dono == _dono && defendendo_castelo
            && lane_atual == _lane && posicao_atual == posicao_entrada(_dono)) {
            _resultado = id;
            break;
        }
    }
    return _resultado;
}

// Ritual visual sem depender de sprites novos. As partículas reforçam a leitura
// angelical/demoníaca e o anúncio principal é desenhado pelo controlador em Draw GUI.
function iniciar_animacao_bencao_maldicao(_categoria, _nome) {
    obj_controlador.ritual_tipo = _categoria;
    obj_controlador.ritual_texto = string_upper(_nome);
    obj_controlador.ritual_timer = obj_controlador.ritual_duracao;
    obj_controlador.ritual_fade_final_iniciado = false;

    var _som_ritual = (_categoria == "bencao") ? snd_bencao : snd_maldicao;
    // Começa inaudível e sobe suavemente junto com a primeira expansão visual.
    obj_controlador.ritual_som = audio_play_sound(_som_ritual, 1, false, 0, 0, 1);
    audio_sound_gain(obj_controlador.ritual_som, 0.8, 550);

    var _cor = (_categoria == "bencao") ? make_color_rgb(255, 220, 95) : make_color_rgb(190, 45, 70);
    var _direcao_base = (_categoria == "bencao") ? 270 : 90;
    for (var i = 0; i < 18; i++) {
        var _particula = instance_create_layer(room_width / 2 + random_range(-95, 95), room_height / 2 + random_range(-30, 30), "Instances", obj_particula_poeira);
        _particula.image_blend = _cor;
        _particula.direcao_movimento = _direcao_base + random_range(-28, 28);
        _particula.velocidade_particula = random_range(1.3, 3.2);
        _particula.vida_particula = irandom_range(35, 60);
        _particula.vida_particula_max = _particula.vida_particula;
        _particula.escala_inicial = random_range(0.25, 0.55);
        _particula.escala_final = random_range(0.8, 1.4);
    }
}

// Estimativa determinística para as decisões da IA. Não altera o combate real:
// os dados continuam sendo rolados normalmente quando o ataque acontece.
function ia_dano_esperado(_atacante, _defensor, _tipo_ataque) {
    var _dado = (_tipo_ataque == "magica") ? _atacante.dado_dano_magico : _atacante.dado_dano;
    var _quantidade = (_tipo_ataque == "magica") ? _atacante.qtd_dados_dano_magico : _atacante.qtd_dados_dano;
    var _modificador = (_tipo_ataque == "magica") ? _atacante.mod_dano_magico : _atacante.mod_dano;
    var _defesa = (_tipo_ataque == "magica") ? calcular_defesa_magica_total(_defensor) : calcular_defesa_fisica_total(_defensor);

    if (_dado <= 0) return 0;
    var _original = _quantidade * ((_dado + 1) / 2);
    if (tem_condicao(_atacante, "berserker")) _original *= 2;
    return max(0, _original + _modificador + bonus_cemiterio_dano(_atacante) - _defesa - obj_controlador.terreno_bonus_defesa);
}

// Escolhe entre ataque físico e mágico usando o dano médio depois da defesa do alvo.
function ia_escolher_tipo_ataque(_atacante, _defensor) {
    if (_atacante.dado_dano_magico <= 0) return "fisica";
    if (_atacante.dado_dano <= 0) return "magica";

    var _fisico = ia_dano_esperado(_atacante, _defensor, "fisica");
    var _magico = ia_dano_esperado(_atacante, _defensor, "magica");
    return (_magico > _fisico) ? "magica" : "fisica";
}

// Para atacar o castelo sem um defensor, não há defesa física/mágica a comparar.
// A IA escolhe simplesmente o tipo com maior dano médio bruto.
function ia_escolher_tipo_ataque_direto(_carta) {
    _carta.item_ataque_atual = melhor_item_ataque(_carta);
    var _fisico = _carta.qtd_dados_dano * ((_carta.dado_dano + 1) / 2) + _carta.mod_dano;
    if (is_struct(_carta.item_ataque_atual)) {
        _fisico = (_carta.item_ataque_atual.dado + 1) / 2 + modificador_item_ataque(_carta, _carta.item_ataque_atual);
    }
    var _magico = (_carta.dado_dano_magico > 0)
        ? _carta.qtd_dados_dano_magico * ((_carta.dado_dano_magico + 1) / 2) + _carta.mod_dano_magico
        : -1;
    if (_magico > _fisico) {
        _carta.item_ataque_atual = noone;
        return "magica";
    }
    return "fisica";
}

// Rola todos os dados do ataque escolhido. É usado quando o alvo é o castelo,
// pois não existe uma tropa para aplicar defesas.
function rolar_dano_direto(_carta, _tipo_ataque) {
    var _usando_item = (_tipo_ataque == "fisica" && is_struct(_carta.item_ataque_atual) && _carta.item_ataque_atual.dado > 0);
    var _dado = _usando_item ? _carta.item_ataque_atual.dado : ((_tipo_ataque == "magica") ? _carta.dado_dano_magico : _carta.dado_dano);
    var _quantidade = _usando_item ? 1 : ((_tipo_ataque == "magica") ? _carta.qtd_dados_dano_magico : _carta.qtd_dados_dano);
    var _modificador = _usando_item ? modificador_item_ataque(_carta, _carta.item_ataque_atual) : ((_tipo_ataque == "magica") ? _carta.mod_dano_magico : _carta.mod_dano);

    var _dano_original = 0;
    for (var i = 0; i < _quantidade; i++) {
        _dano_original += irandom_range(1, _dado);
    }
    if (tem_condicao(_carta, "berserker")) _dano_original *= 2;
    return max(0, _dano_original + _modificador);
}

// Versão visual do dano direto. Mantém grupos de Golpe Duplo afastados e
// entrega ao callback o total dos dados já somado ao modificador.
// Todo ataque direto contra construção ou castelo também exige o D20 de acerto.
function rolar_ataque_direto_com_acerto(_carta, _alvo, _tipo_ataque, _callback_final, _indice_ataque = 0, _total_ataques = 1) {
    if (!tentar_romper_imitacao(_carta)) return;
    var _resultado = irandom_range(1, 20);
    var _offset = (_indice_ataque - ((_total_ataques - 1) / 2)) * 110;
    var _atraso = (_indice_ataque == 0) ? 0 : _indice_ataque * irandom_range(68, 92);
    var _contexto = { carta: _carta, alvo: _alvo, tipo: _tipo_ataque, callback_final: _callback_final,
        indice: _indice_ataque, total: _total_ataques, bonus: bonus_cemiterio_acerto(_carta) };
    rolar_dado_visual(_carta.x + _offset * 0.22, _carta.y, _carta.x + _offset, _carta.y - 55,
        20, _resultado, method(_contexto, function(_d20) {
            if (!instance_exists(carta)) return;
            var _total_acerto = clamp(_d20 + bonus, 1, 20);
            if (_total_acerto <= 10) {
                if (carta.carnica_estado_proximo_ataque == "bonus") carta.carnica_estado_proximo_ataque = "";
                if (instance_exists(alvo)) registrar_trajeto_erro(carta, alvo, "Errou · " + string(_total_acerto));
                else mostrar_feedback("ERROU — " + string(_total_acerto), carta.x, carta.y - 48, c_gray, 55);
                registrar_jogada_recente(carta.dono, "Ataque errou", carta.lane_atual);
                debug_combate(carta.nome_carta + " errou o ataque direto no D20 (" + string(_d20) + ").");
                return;
            }
            mostrar_feedback(_d20 == 20 ? "ACERTO CRÍTICO!" : "ACERTOU — " + string(_total_acerto),
                carta.x, carta.y - 48, _d20 == 20 ? c_yellow : c_lime, 45);
            if (_d20 == 20) {
                if (tem_habilidade(carta, "tiro_burro")) {
                    var _alvos_tiro_burro = [];
                    with (obj_carta) if (travada && !morrendo) array_push(_alvos_tiro_burro, id);
                    if (array_length(_alvos_tiro_burro) > 0) {
                        processar_resultado_acerto(_total_acerto, carta,
                            _alvos_tiro_burro[irandom(array_length(_alvos_tiro_burro) - 1)], tipo, _d20);
                        return;
                    }
                }
                var _usa_item_crit = (tipo == "fisica" && is_struct(carta.item_ataque_atual) && carta.item_ataque_atual.dado > 0);
                var _dado_crit = _usa_item_crit ? carta.item_ataque_atual.dado : ((tipo == "magica") ? carta.dado_dano_magico : carta.dado_dano);
                var _qtd_crit = _usa_item_crit ? 1 : ((tipo == "magica") ? carta.qtd_dados_dano_magico : carta.qtd_dados_dano);
                var _mod_crit = _usa_item_crit ? modificador_item_ataque(carta, carta.item_ataque_atual) : ((tipo == "magica") ? carta.mod_dano_magico : carta.mod_dano);
                var _crit_direto = { atacante: carta, defensor: noone, tipo_ataque: tipo,
                    dado_usado: _dado_crit, qtd_usada: _qtd_crit, mod_usado: _mod_crit,
                    direto: true, callback_final: callback_final, indice: indice, total: total };
                if (carta.dono == "jogador") enfileirar_escolha_critico(_crit_direto);
                else resolver_critico_direto(_crit_direto, "dobrar_resultado");
                return;
            }
            rolar_dano_direto_visual(carta, tipo, callback_final, indice, total);
        }), 0, _atraso, 78 + ((_total_ataques > 1) ? irandom_range(-7, 16) : 0), _carta.dono);
}

function resolver_critico_direto(_contexto, _modo) {
    if (!is_struct(_contexto) || !instance_exists(_contexto.atacante)) return;
    var _quantidade = _contexto.qtd_usada * ((_modo == "dobrar_dados") ? 2 : 1);
    var _multiplicador = ((_modo == "dobrar_resultado") ? 2 : 1)
        * ((tem_condicao(_contexto.atacante, "berserker")) ? 2 : 1);
    var _dados_crit_direto = { callback_final: _contexto.callback_final,
        multiplicador: _multiplicador, modificador: _contexto.mod_usado };
    rolar_varios_dados_visuais(_contexto.atacante.x, _contexto.atacante.y,
        _contexto.atacante.x, _contexto.atacante.y + direcao_avanco(_contexto.atacante.dono) * 115,
        _quantidade, _contexto.dado_usado,
        method(_dados_crit_direto, function(_total_dados) {
            var _finalizar = callback_final;
            _finalizar(max(0, _total_dados * multiplicador + modificador), true);
        }), _contexto.mod_usado, 0, _contexto.atacante.dono);
}

function rolar_dano_direto_visual(_carta, _tipo_ataque, _callback_final, _indice_ataque = 0, _total_ataques = 1) {
    var _usando_item = (_tipo_ataque == "fisica" && is_struct(_carta.item_ataque_atual) && _carta.item_ataque_atual.dado > 0);
    var _dado = _usando_item ? _carta.item_ataque_atual.dado : ((_tipo_ataque == "magica") ? _carta.dado_dano_magico : _carta.dado_dano);
    var _quantidade = _usando_item ? 1 : ((_tipo_ataque == "magica") ? _carta.qtd_dados_dano_magico : _carta.qtd_dados_dano);
    var _modificador = _usando_item ? modificador_item_ataque(_carta, _carta.item_ataque_atual) : ((_tipo_ataque == "magica") ? _carta.mod_dano_magico : _carta.mod_dano);
    var _offset_grupo = (_indice_ataque - ((_total_ataques - 1) / 2)) * 250;
    var _atraso_grupo = (_indice_ataque == 0) ? 0 : _indice_ataque * irandom_range(70, 95);

    var _bonus_carnica = (_carta.carnica_estado_proximo_ataque == "bonus");
    if (_bonus_carnica) _carta.carnica_estado_proximo_ataque = "";
    var _dados_diretos = {
        callback_final: _callback_final,
        carta: _carta,
        modificador: _modificador,
        multiplicador_original: (tem_condicao(_carta, "berserker")) ? 2 : 1,
        bonus_carnica: _bonus_carnica
    };
    var _callback_dados = method(_dados_diretos, function(_total_dados) {
        var _base = max(0, _total_dados * multiplicador_original + modificador);
        if (!bonus_carnica) {
            var _finalizar = callback_final;
            _finalizar(_base);
            return;
        }
        var _resultado_extra = irandom_range(1, 8);
        var _dados_extra = { callback_final: callback_final, base: _base };
        rolar_dado_visual(carta.x, carta.y, carta.x, carta.y - 55, 8, _resultado_extra,
            method(_dados_extra, function(_extra) {
                var _finalizar = callback_final;
                _finalizar(base + _extra);
            }), 0, 0, -1, carta.dono);
    });

    rolar_varios_dados_visuais(
        _carta.x + _offset_grupo * 0.12,
        _carta.y,
        _carta.x + _offset_grupo,
        _carta.y + direcao_avanco(_carta.dono) * 115,
        _quantidade,
        _dado,
        _callback_dados,
        _modificador,
        _atraso_grupo,
        _carta.dono
    );
}

// O dano direto entra numa fila visual. A vida só é reduzida no momento em que
// o número vermelho alcança o indicador no HUD.
function causar_dano_castelo(_dono, _dano, _origem = "") {
    if (_dano <= 0) return;
    var _controle = instance_find(obj_controlador, 0);
    if (_controle == noone) return;
    // Também cobre uma partida que ficou aberta durante a atualização do código.
    if (!variable_instance_exists(_controle, "fila_dano_castelo") || !is_array(_controle.fila_dano_castelo)) {
        _controle.fila_dano_castelo = [];
    }
    array_push(_controle.fila_dano_castelo, { dono: _dono, valor: _dano, origem: _origem });
    debug_combate("Castelo do " + _dono + " recebeu " + string(_dano) + " de dano.");
}

function atualizar_animacao_dano_castelo() {
    var _controle = instance_find(obj_controlador, 0);
    if (_controle == noone) return;

    // Compatibilidade com uma instância criada antes desses campos existirem.
    if (!variable_instance_exists(_controle, "fila_dano_castelo") || !is_array(_controle.fila_dano_castelo)) {
        _controle.fila_dano_castelo = [];
    }
    if (!variable_instance_exists(_controle, "dano_castelo_ativo")) {
        _controle.dano_castelo_ativo = false;
        _controle.dano_castelo_dono = "";
        _controle.dano_castelo_valor = 0;
        _controle.dano_castelo_timer = 0;
        _controle.dano_castelo_duracao = 45;
        _controle.dano_castelo_aplicado = false;
        _controle.dano_castelo_impacto_timer = 0;
    }

    if (!_controle.dano_castelo_ativo && array_length(_controle.fila_dano_castelo) > 0) {
        var _evento = _controle.fila_dano_castelo[0];
        array_delete(_controle.fila_dano_castelo, 0, 1);
        _controle.dano_castelo_ativo = true;
        _controle.dano_castelo_dono = _evento.dono;
        _controle.dano_castelo_valor = _evento.valor;
        _controle.dano_castelo_origem = _evento.origem;
        _controle.dano_castelo_timer = _controle.dano_castelo_duracao;
        _controle.dano_castelo_aplicado = false;
        var _vida_final = _evento.dono == "jogador" ? _controle.vida_jogador : _controle.vida_inimigo;
        _controle.dano_castelo_pausa_final = _evento.valor >= _vida_final ? 8 : 0;
    }

    if (!_controle.dano_castelo_ativo) return;
    if (_controle.dano_castelo_timer == 16 && _controle.dano_castelo_pausa_final > 0) {
        _controle.dano_castelo_pausa_final--; return;
    }

    _controle.dano_castelo_timer -= 1;
    // Os últimos 15 frames são o impacto: a vida diminui exatamente aqui.
    if (!_controle.dano_castelo_aplicado && _controle.dano_castelo_timer <= 15) {
        var _vida_antes = _controle.dano_castelo_dono == "jogador" ? _controle.vida_jogador : _controle.vida_inimigo;
        if (_controle.modo_partida != "online" && _vida_antes > 0 && _vida_antes <= _controle.dano_castelo_valor
            && _controle.vida_jogador > 0 && _controle.vida_inimigo > 0) {
            _controle.golpe_final_origem = _controle.dano_castelo_origem;
            _controle.golpe_final_vida = _vida_antes;
        }
        if (_controle.dano_castelo_dono == "jogador") {
            _controle.vida_jogador -= _controle.dano_castelo_valor;
        } else {
            _controle.vida_inimigo -= _controle.dano_castelo_valor;
        }
        _controle.dano_castelo_aplicado = true;
        _controle.dano_castelo_impacto_timer = 10;
    }

    if (_controle.dano_castelo_impacto_timer > 0) _controle.dano_castelo_impacto_timer -= 1;
    if (_controle.dano_castelo_timer <= 0) _controle.dano_castelo_ativo = false;
}

function ia_poder_ataque(_carta) {
    var _multiplicador = (tem_condicao(_carta, "berserker")) ? 2 : 1;
    var _fisico = max(0, _carta.qtd_dados_dano * ((_carta.dado_dano + 1) / 2) * _multiplicador + _carta.mod_dano);
    var _magico = max(0, _carta.qtd_dados_dano_magico * ((_carta.dado_dano_magico + 1) / 2) * _multiplicador + _carta.mod_dano_magico);
    return max(_fisico, _magico);
}

function tem_aliado_adjacente(_carta) {
    var _encontrou = false;
    with (obj_carta) {
        if (id == _carta || !travada || dono != _carta.dono) continue;
        if (abs(lane_atual - _carta.lane_atual) + abs(posicao_atual - _carta.posicao_atual) == 1) {
            _encontrou = true;
            break;
        }
    }
    return _encontrou;
}

// Retorna true quando a Coroa da Carniça substituiu o ataque normal por autoataque.
function resolver_autoataque_carnica(_carta) {
    if (_carta.carnica_estado_proximo_ataque != "autoataque") return false;
    _carta.carnica_estado_proximo_ataque = "";
    if (tem_aliado_adjacente(_carta)) return false;
    if (!tentar_romper_imitacao(_carta)) return true;

    var _dados_autoataque = { carta: _carta };
    rolar_dano_direto_visual(_carta, "fisica", method(_dados_autoataque, function(_dano) {
        if (!instance_exists(carta)) return;
        carta.vida -= _dano;
        aplicar_flash_dano(carta);
        mostrar_dano_tropa(carta, _dano);
        debug_combate(carta.nome_carta + " atacou a si mesma por Carniça Frenética.");
        if (carta.vida <= 0) destruir_tropa(carta, false);
    }));
    return true;
}

// Processa o ataque de TODAS as tropas de um lado de uma vez (usada pela IA).
// Cadeia de alvo: tropa inimiga na frente > construção na lane > vida direto.
function processar_combate(_lado_atacante) {
    var _lado_defensor = (_lado_atacante == "jogador") ? "inimigo" : "jogador";
    var _sentido = direcao_avanco(_lado_atacante);

    with (obj_slot_batalha) {
        if (ocupado && carta_atual.dono == _lado_atacante
            && !carta_atual.atacou_este_turno && tropa_pode_agir(carta_atual)) {
            var _atacante = carta_atual;
            if (resolver_autoataque_carnica(_atacante)) {
                _atacante.atacou_este_turno = true;
                continue;
            }
            var _tem_alcance = tem_habilidade(_atacante, "alcance") || tem_habilidade(_atacante, "alcance_magico");
			var _proxima_posicao = posicao + _sentido;
			var _slot_alvo = buscar_slot(lane, _proxima_posicao);


			if ((_slot_alvo == noone || !_slot_alvo.ocupado) && _tem_alcance) {
			    var _slot_longe = buscar_slot(lane, posicao + _sentido * 2);
			    if (_slot_longe != noone && _slot_longe.ocupado) _slot_alvo = _slot_longe;
			}

			var _pode_mirar_alvo = _slot_alvo != noone && _slot_alvo.ocupado && _slot_alvo.carta_atual.dono == _lado_defensor 
			    && !_slot_alvo.carta_atual.sombra_ativa
			    && !(posicao == posicao_assalto(_lado_atacante)
			        && _slot_alvo.posicao == posicao_entrada(_lado_defensor)
			        && !_slot_alvo.carta_atual.defendendo_castelo)
			    && (!tem_habilidade(_slot_alvo.carta_atual, "voar") || tem_habilidade(_atacante, "voar") || _tem_alcance);

			if (_pode_mirar_alvo) {
				_atacante.item_ataque_atual = melhor_item_ataque(_atacante);
				var _tipo_escolhido = ia_escolher_tipo_ataque(_atacante, _slot_alvo.carta_atual);
                if (abs(posicao - _slot_alvo.posicao) > 1) {
                    _atacante.item_ataque_atual = noone;
                    _tipo_escolhido = tem_habilidade(_atacante, "alcance_magico") ? "magica" : "fisica";
                }
                _atacante.atacou_este_turno = true;
				rolar_combate(_atacante, _slot_alvo.carta_atual, _tipo_escolhido);

            } else if (posicao == posicao_assalto(_lado_atacante)) {
                _atacante.atacou_este_turno = true;
                // Dano direto só é permitido depois de avançar uma casa além do meio.
                var _construcao_alvo = _tem_alcance ? buscar_construcao(lane, _lado_defensor) : noone;

                if (_construcao_alvo != noone) {
                    var _tipo_construcao = ia_escolher_tipo_ataque_direto(_atacante);
                    var _dados_construcao = { alvo: _construcao_alvo, atacante: _atacante };
                    rolar_ataque_direto_com_acerto(_atacante, _construcao_alvo, _tipo_construcao,
                        method(_dados_construcao, function(_dano_construcao, _critico = false) {
                            if (!instance_exists(alvo)) return;
                            evento_partida_aplicar(evento_dano_construcao_criar(
                                atacante, alvo, _dano_construcao, true, "", c_red, _critico));
                        })
                    );
                } else {
                    var _defensor_castelo = buscar_defensor_castelo(lane, _lado_defensor);
                    if (_defensor_castelo != noone) {
                        debug_combate(_defensor_castelo.nome_carta + " defende o castelo!");
                        rolar_combate(_atacante, _defensor_castelo, ia_escolher_tipo_ataque(_atacante, _defensor_castelo));
                    } else {
                        var _tipo_direto = ia_escolher_tipo_ataque_direto(_atacante);
                        var _dados_castelo = { lado_defensor: _lado_defensor, atacante: _atacante };
                        if (tentar_romper_imitacao(_atacante)) rolar_dano_direto_visual(_atacante, _tipo_direto,
                            method(_dados_castelo, function(_dano_direto) {
                                evento_partida_aplicar(evento_dano_castelo_criar(
                                    atacante, lado_defensor, _dano_direto));
                            })
                        );
                    }
                }
            }
            // Sem alvo e fora do assalto: não ataca o castelo; ainda precisa avançar.
        }
    }
}

// Versão do combate pra UMA tropa só (usada pelo menu de ação do jogador).
// Mesma cadeia de alvo que processar_combate(), só que pra 1 tropa específica.
function processar_combate_tropa(_carta, _tipo_ataque, _indice_ataque = 0, _total_ataques = 1) {
    if (primeiro_turno_do_lado(_carta.dono) || !tropa_pode_agir(_carta)) return false;
    if (!instance_exists(_carta) || !_carta.travada || _carta.slot_atual == noone) return false;

    var _slot = _carta.slot_atual;
    var _lado_atacante = _carta.dono;
    var _lado_defensor = (_lado_atacante == "jogador") ? "inimigo" : "jogador";
    var _sentido = direcao_avanco(_lado_atacante);
    if (resolver_autoataque_carnica(_carta)) return true;

    var _tem_alcance = !is_struct(_carta.item_ataque_atual)
        && tem_habilidade(_carta, _tipo_ataque == "magica" ? "alcance_magico" : "alcance");
    var _proxima_posicao = _slot.posicao + _sentido;
    var _slot_alvo = buscar_slot(_slot.lane, _proxima_posicao);

    if ((_slot_alvo == noone || !_slot_alvo.ocupado) && _tem_alcance) {
        var _slot_longe = buscar_slot(_slot.lane, _slot.posicao + _sentido * 2);
        if (_slot_longe != noone && _slot_longe.ocupado) _slot_alvo = _slot_longe;
    }

    var _pode_mirar_alvo = _slot_alvo != noone && _slot_alvo.ocupado && _slot_alvo.carta_atual.dono == _lado_defensor
        && !_slot_alvo.carta_atual.sombra_ativa
        && !(_slot.posicao == posicao_assalto(_lado_atacante)
            && _slot_alvo.posicao == posicao_entrada(_lado_defensor)
            && !_slot_alvo.carta_atual.defendendo_castelo)
        && (!tem_habilidade(_slot_alvo.carta_atual, "voar") || tem_habilidade(_carta, "voar") || tem_habilidade(_carta, "alcance") || tem_habilidade(_carta, "alcance_magico"));

    if (_pode_mirar_alvo) {
        rolar_combate(_carta, _slot_alvo.carta_atual, _tipo_ataque, _indice_ataque, _total_ataques);
        return true;
    } else if (_slot.posicao == posicao_assalto(_lado_atacante)) {
        var _construcao_alvo = _tem_alcance ? buscar_construcao(_slot.lane, _lado_defensor) : noone;
        var _dado_usado = (_tipo_ataque == "magica") ? _carta.dado_dano_magico : _carta.dado_dano;
        var _mod_usado = (_tipo_ataque == "magica") ? _carta.mod_dano_magico : _carta.mod_dano;

        if (_construcao_alvo != noone) {
            var _dados_construcao = { alvo: _construcao_alvo, atacante: _carta };
            rolar_ataque_direto_com_acerto(_carta, _construcao_alvo, _tipo_ataque,
                method(_dados_construcao, function(_dano_construcao, _critico = false) {
                    if (!instance_exists(alvo)) return;
                    evento_partida_aplicar(evento_dano_construcao_criar(
                        atacante, alvo, _dano_construcao, true, "", c_red, _critico));
                }),
                _indice_ataque,
                _total_ataques
            );
        } else {
            var _defensor_castelo = buscar_defensor_castelo(_slot.lane, _lado_defensor);
            if (_defensor_castelo != noone) {
                debug_combate(_defensor_castelo.nome_carta + " defende o castelo!");
                rolar_combate(_carta, _defensor_castelo, _tipo_ataque);
            } else {
                var _dados_castelo = { lado_defensor: _lado_defensor, atacante: _carta };
                if (tentar_romper_imitacao(_carta)) rolar_dano_direto_visual(_carta, _tipo_ataque,
                    method(_dados_castelo, function(_dano_direto) {
                        evento_partida_aplicar(evento_dano_castelo_criar(
                            atacante, lado_defensor, _dano_direto));
                    }),
                    _indice_ataque,
                    _total_ataques
                );
            }
        }
        return true;
    } else {
        debug_combate(_carta.nome_carta + " não tem alvo na frente ainda (precisa avançar mais).");
        mostrar_aviso_regra("Avance além do centro para atacar o castelo", _carta.x, _carta.y);
        return false;
    }
}

// Rola o teste de acerto com suporte genérico a vantagem e desvantagem.
// Berserker usa o maior D20; Confusão usa o menor D20.
function rolar_teste_acerto_visual(_atacante, _defensor, _tipo_ataque, _indice_ataque = 0, _total_ataques = 1) {
    var _modo = (tem_condicao(_atacante, "berserker") && !tem_condicao(_atacante, "confusao")) ? "vantagem"
        : ((tem_condicao(_atacante, "confusao") && !tem_condicao(_atacante, "berserker")) ? "desvantagem" : "normal");
    var _bonus = bonus_cemiterio_acerto(_atacante);
    var _offset_golpe = (_indice_ataque - ((_total_ataques - 1) / 2)) * 110;
    var _atraso_golpe = (_indice_ataque == 0) ? 0 : _indice_ataque * irandom_range(68, 92);

    if (_modo == "normal") {
        var _resultado_natural = irandom_range(1, 20);
        var _dados_normais = {
            atacante: _atacante, defensor: _defensor, tipo_ataque: _tipo_ataque, bonus: _bonus
        };
        rolar_dado_visual(_atacante.x + _offset_golpe * 0.22, _atacante.y,
            _defensor.x + _offset_golpe, _defensor.y, 20, _resultado_natural,
            method(_dados_normais, function(_valor) {
                processar_resultado_acerto(clamp(_valor + bonus, 1, 20), atacante, defensor, tipo_ataque, _valor);
            }), _bonus, _atraso_golpe, 78 + ((_total_ataques > 1) ? irandom_range(-7, 16) : 0), _atacante.dono);
        return;
    }

    var _dados_duplos = {
        atacante: _atacante,
        defensor: _defensor,
        tipo_ataque: _tipo_ataque,
        modo: _modo,
        bonus: _bonus,
        resolvidos: 0,
        escolhido: (_modo == "vantagem") ? 0 : 21
    };
    var _callback_teste = method(_dados_duplos, function(_valor) {
        escolhido = (modo == "vantagem") ? max(escolhido, _valor) : min(escolhido, _valor);
        resolvidos += 1;
        if (resolvidos < 2) return;
        var _final = clamp(escolhido + bonus, 1, 20);
        mostrar_feedback(string_upper(modo) + ": " + string(_final), atacante.x, atacante.y - 42,
            (modo == "vantagem") ? c_lime : make_color_rgb(190, 95, 255), 45);
        processar_resultado_acerto(_final, atacante, defensor, tipo_ataque, escolhido);
    });

    for (var _i_teste = 0; _i_teste < 2; _i_teste++) {
        var _valor_teste = irandom_range(1, 20);
        var _offset_teste = (_i_teste == 0) ? -55 : 55;
        rolar_dado_visual(_atacante.x + _offset_golpe * 0.22, _atacante.y,
            _defensor.x + _offset_golpe + _offset_teste, _defensor.y,
            20, _valor_teste, _callback_teste, 0,
            _atraso_golpe + ((_i_teste == 0) ? 0 : irandom_range(24, 38)),
            78 + irandom_range(-7, 16), _atacante.dono);
    }
}

// Inicia um combate entre 2 tropas: rola o D20 de acerto (visual) e, quando ele parar,
// decide o resultado em processar_resultado_acerto().
function rolar_combate(_atacante, _defensor, _tipo_ataque, _indice_ataque = 0, _total_ataques = 1) {
    if (abs(_atacante.posicao_atual - _defensor.posicao_atual) > 1
        && (is_struct(_atacante.item_ataque_atual)
            || !tem_habilidade(_atacante, _tipo_ataque == "magica" ? "alcance_magico" : "alcance"))) return;
    if (!tentar_romper_imitacao(_atacante, _defensor)) return;
    registrar_jogada_recente(_atacante.dono, "Ataque declarado", _atacante.lane_atual);
    debug_combate("=== ATAQUE (" + _tipo_ataque + "): " + _atacante.nome_carta + " vs " + _defensor.nome_carta + " ===");

    // Resultado 4 da Loucura: não se defende e o próximo ataque acerta sem D20.
    if (tem_condicao(_defensor, "loucura") && _defensor.loucura_sem_defesa) {
        _defensor.loucura_sem_defesa = false;
        debug_combate(_defensor.nome_carta + " não se defendeu por causa da Loucura.");
        processar_resultado_acerto(11, _atacante, _defensor, _tipo_ataque);
        return;
    }

	iniciar_animacao_ataque(_atacante, _defensor, 8, 14); // cutucada leve no início do ataque

    rolar_teste_acerto_visual(_atacante, _defensor, _tipo_ataque, _indice_ataque, _total_ataques);
}

function rolar_varios_dados(_quantidade, _tamanho_dado) {
    var _total = 0;
    for (var i = 0; i < _quantidade; i++) {
        _total += irandom_range(1, _tamanho_dado);
    }
    return _total;
}

// Lança cada dado separadamente, preserva os resultados individuais e só chama
// o callback final depois que todos pousarem. O atraso e a duração variam para
// parecerem lançamentos físicos independentes.
function rolar_varios_dados_visuais(_origem_x, _origem_y, _destino_x, _destino_y, _quantidade, _tamanho_dado, _callback_final, _modificador_exibido = 0, _atraso_grupo = 0, _dono_rolagem = "") {
    var _qtd = max(1, _quantidade);
    if (_qtd == 1) {
        var _resultado_unico = irandom_range(1, _tamanho_dado);
        var _duracao_unico = 78 + ((_atraso_grupo > 0) ? irandom_range(-8, 18) : 0);
        rolar_dado_visual(_origem_x, _origem_y, _destino_x, _destino_y,
            _tamanho_dado, _resultado_unico, _callback_final, _modificador_exibido,
            _atraso_grupo, _duracao_unico, _dono_rolagem);
        return;
    }

    var _usos_manipulados = 0;
    if (_dono_rolagem == "jogador")
        _usos_manipulados = obj_controlador.dados_manipulados_usos_jogador;
    else if (_dono_rolagem == "inimigo")
        _usos_manipulados = obj_controlador.dados_manipulados_usos_inimigo;

    var _grupo = {
        quantidade: _qtd,
        resolvidos: 0,
        pousados: 0,
        total: 0,
        total_visual: 0,
        resultados: [],
        modificador: _modificador_exibido,
        destino_x: _destino_x,
        destino_y: _destino_y,
        callback_final: _callback_final,
        aguarda_resultado_final: (_usos_manipulados > 0)
    };

    var _espacamento = 110;
    for (var i = 0; i < _qtd; i++) {
        var _offset_x = (i - ((_qtd - 1) / 2)) * _espacamento;
        var _atraso = _atraso_grupo + ((i == 0) ? 0 : i * irandom_range(26, 42));
        var _duracao = 78 + irandom_range(-8, 18);
        var _resultado = irandom_range(1, _tamanho_dado);
        array_push(_grupo.resultados, _resultado);
        _grupo.total_visual += _resultado;
        var _ctx_dado_grupo = { grupo: _grupo, indice: i };
        var _callback_dado = method(_ctx_dado_grupo, function(_resultado_final) {
            grupo.resultados[indice] = _resultado_final;
            grupo.total += _resultado_final;
            grupo.resolvidos += 1;
            if (grupo.resolvidos < grupo.quantidade) return;

            grupo.total_visual = grupo.total;
            if (grupo.aguarda_resultado_final) {
                var _texto_soma_final = "";
                for (var _i_final = 0; _i_final < array_length(grupo.resultados); _i_final++) {
                    if (_i_final > 0) _texto_soma_final += " + ";
                    _texto_soma_final += string(grupo.resultados[_i_final]);
                }
                if (grupo.modificador != 0) {
                    _texto_soma_final += (grupo.modificador > 0 ? " + " : " - ")
                        + string(abs(grupo.modificador));
                }
                _texto_soma_final += " = " + string(grupo.total + grupo.modificador);
                mostrar_feedback(_texto_soma_final, grupo.destino_x, grupo.destino_y + 70, c_yellow, 75);
            }
            var _finalizar = grupo.callback_final;
            if (_finalizar != noone) _finalizar(grupo.total);
        });
        var _dado_grupo = rolar_dado_visual(
            _origem_x + _offset_x * 0.22,
            _origem_y,
            _destino_x + _offset_x,
            _destino_y,
            _tamanho_dado,
            _resultado,
            _callback_dado,
            0,
            _atraso,
            _duracao,
            _dono_rolagem
        );
        _dado_grupo.grupo_soma = _grupo;
        _dado_grupo.grupo_soma_responsavel = (i == _qtd - 1);
    }
}
	
function aplicar_resultado_dano_tropa(_dados, _resultado, _bonus_extra = 0) {
    var _atacante = _dados.atacante;
    var _defensor = _dados.defensor;
    if (!instance_exists(_atacante) || !instance_exists(_defensor)) return;

    var _multiplicador_berserker = (tem_condicao(_atacante, "berserker")) ? 2 : 1;
    var _dano_original = _resultado * _dados.multiplicador_resultado * _multiplicador_berserker + _bonus_extra;
    var _defesa_usada = _dados.ignora_defesa ? 0
        : ((_dados.tipo_ataque == "magica") ? calcular_defesa_magica_total(_defensor) : calcular_defesa_fisica_total(_defensor));
    var _dano_final = _dano_original + _dados.mod_usado + bonus_cemiterio_dano(_atacante);
    _defesa_usada += _dados.ignora_defesa ? 0 : obj_controlador.terreno_bonus_defesa;
    _dano_final = max(0, _dano_final - _defesa_usada);
    evento_partida_aplicar(evento_dano_tropa_criar(_atacante, _defensor,
        _dano_final, _dados.tipo_ataque, _defesa_usada, true, "", c_red, _dados.critico));
}

// Resolve o dano depois do acerto. No crítico, os dados originais podem ser
// duplicados ou o resultado original pode ser multiplicado por dois. Modificadores
// e defesa continuam sendo aplicados uma única vez, depois do dano original.
function resolver_dano_de_acerto(_contexto, _modo_critico = "normal") {
    var _atacante = _contexto.atacante;
    var _defensor = _contexto.defensor;
    if (!instance_exists(_atacante) || !instance_exists(_defensor)
        || _atacante.morrendo || _defensor.morrendo) return;

    var _quantidade = _contexto.qtd_usada;
    var _multiplicador_resultado = 1;
    if (_modo_critico == "dobrar_dados") _quantidade *= 2;
    if (_modo_critico == "dobrar_resultado") _multiplicador_resultado = 2;

    var _bonus_carnica = (_atacante.carnica_estado_proximo_ataque == "bonus");
    if (_bonus_carnica) _atacante.carnica_estado_proximo_ataque = "";
    var _dados_dano = {
        atacante: _atacante,
        defensor: _defensor,
        mod_usado: _contexto.mod_usado,
        tipo_ataque: _contexto.tipo_ataque,
        multiplicador_resultado: _multiplicador_resultado,
        critico: _modo_critico != "normal",
        ignora_defesa: _bonus_carnica,
        bonus_carnica: _bonus_carnica
    };
    var _mod_total_exibido = (_modo_critico == "dobrar_resultado")
        ? 0 : (_contexto.mod_usado + bonus_cemiterio_dano(_atacante));

    rolar_varios_dados_visuais(
        _atacante.x, _atacante.y, _defensor.x, _defensor.y,
        _quantidade, _contexto.dado_usado,
        method(_dados_dano, function(_resultado) {
            if (!instance_exists(atacante) || !instance_exists(defensor)) return;
            if (!bonus_carnica) {
                aplicar_resultado_dano_tropa(self, _resultado, 0);
                return;
            }
            var _resultado_extra = irandom_range(1, 8);
            var _dados_extra = { dados_dano: self, resultado_base: _resultado };
            rolar_dado_visual(atacante.x, atacante.y, defensor.x, defensor.y - 55, 8, _resultado_extra,
                method(_dados_extra, function(_extra) {
                    aplicar_resultado_dano_tropa(dados_dano, resultado_base, _extra);
                }), 0, 0, -1, atacante.dono);
        }),
        _mod_total_exibido,
        0,
        _atacante.dono
    );
}

function abrir_proxima_escolha_critico() {
    if (obj_controlador.ui_modal.critico_escolha_ativa || obj_controlador.rolagens_pendentes > 0) return;
    while (array_length(obj_controlador.ui_modal.criticos_pendentes) > 0) {
        var _contexto = obj_controlador.ui_modal.criticos_pendentes[0];
        array_delete(obj_controlador.ui_modal.criticos_pendentes, 0, 1);
        var _critico_direto = variable_struct_exists(_contexto, "direto") && _contexto.direto;
        if (!instance_exists(_contexto.atacante) || (!_critico_direto && !instance_exists(_contexto.defensor))) continue;
        obj_controlador.ui_modal.critico_contexto = _contexto;
        obj_controlador.ui_modal.critico_escolha_ativa = true;
        obj_controlador.carta_menu_aberto = noone;
        return;
    }
    obj_controlador.ui_modal.critico_contexto = noone;
}

function enfileirar_escolha_critico(_contexto) {
    array_push(obj_controlador.ui_modal.criticos_pendentes, _contexto);
    abrir_proxima_escolha_critico();
}

function resolver_escolha_critico(_modo) {
    if (!obj_controlador.ui_modal.critico_escolha_ativa) return;
    var _contexto = obj_controlador.ui_modal.critico_contexto;
    if (obj_controlador.modo_partida == "online" && is_struct(_contexto)
        && variable_struct_exists(_contexto, "online") && _contexto.online) {
        if (!online_enviar_acao("choose_critical", { choice: _modo })) return;
        obj_controlador.ui_modal.critico_escolha_ativa = false;
        obj_controlador.ui_modal.critico_contexto = noone;
        mostrar_feedback(_modo == "dobrar_dados" ? "CRÍTICO: +DADOS" : "CRÍTICO: RESULTADO ×2",
            _contexto.atacante.x, _contexto.atacante.y - 45, c_yellow, 55);
        return;
    }
    obj_controlador.ui_modal.critico_escolha_ativa = false;
    obj_controlador.ui_modal.critico_contexto = noone;
    if (instance_exists(_contexto.atacante)) {
        mostrar_feedback(_modo == "dobrar_dados" ? "CRÍTICO: +DADOS" : "CRÍTICO: RESULTADO ×2",
            _contexto.atacante.x, _contexto.atacante.y - 45, c_yellow, 55);
    }
    if (is_struct(_contexto) && variable_struct_exists(_contexto, "direto") && _contexto.direto)
        resolver_critico_direto(_contexto, _modo);
    else resolver_dano_de_acerto(_contexto, _modo);
    abrir_proxima_escolha_critico();
}

// A IA prefere a opção estável quando o dano médio já basta e tenta a opção
// mais explosiva quando precisa superar muita vida/defesa.
function ia_escolher_modo_critico(_contexto) {
    var _media_original = _contexto.qtd_usada * ((_contexto.dado_usado + 1) / 2);
    var _defesa = (_contexto.tipo_ataque == "magica") ? _contexto.defensor.defesa_magica : _contexto.defensor.defesa_fisica;
    var _estimativa = _media_original * 2 + _contexto.mod_usado - _defesa;
    return (_estimativa >= _contexto.defensor.vida) ? "dobrar_dados" : "dobrar_resultado";
}

// Contra-ataque compartilhado pelo erro crítico e pelo erro sob Confusão.
function executar_contra_ataque(_atacante, _defensor) {
    if (!instance_exists(_atacante) || !instance_exists(_defensor) || _defensor.dado_dano <= 0) return;
    if (!tropa_pode_agir(_defensor) || !tentar_romper_imitacao(_defensor)) return;
    apresentar_contra_ataque(_defensor);
    var _mod_contra_exibido = _defensor.mod_dano + bonus_cemiterio_dano(_defensor);
    var _dados_contra = { atacante: _atacante, defensor: _defensor };

    rolar_varios_dados_visuais(
        _defensor.x, _defensor.y, _atacante.x, _atacante.y,
        _defensor.qtd_dados_dano, _defensor.dado_dano,
        method(_dados_contra, function(_resultado) {
            if (!instance_exists(atacante) || !instance_exists(defensor)) return;

            var _original_contra = _resultado * ((tem_condicao(defensor, "berserker")) ? 2 : 1);
            var _dano_contra = _original_contra + defensor.mod_dano + bonus_cemiterio_dano(defensor);
            var _defesa_contra = calcular_defesa_fisica_total(atacante) + obj_controlador.terreno_bonus_defesa;
            _dano_contra = max(0, _dano_contra - _defesa_contra);
            atacante.vida -= _dano_contra;
            apresentar_impacto_tropa(defensor, atacante, _dano_contra, _defesa_contra);
            debug_combate(atacante.nome_carta + " tomou " + string(_dano_contra) + " de contra-ataque. Vida: " + string(atacante.vida), [defensor, atacante]);
            if (atacante.vida <= 0) {
                if (tem_habilidade(defensor, "digestao")) defensor.digestao_cadaver_disponivel = true;
                destruir_tropa(atacante);
            }
        }),
        _mod_contra_exibido,
        0,
        _defensor.dono
    );
}

// Regras do D20: 1-10 erra, 1 natural = contra-ataque do defensor, 11-19 acerta,
// 20 natural = crítico com escolha da forma de dobrar o dano original.
function processar_resultado_acerto(_dado_acerto, _atacante, _defensor, _tipo_ataque, _dado_natural = _dado_acerto) {
    if (!instance_exists(_atacante) || !instance_exists(_defensor)
        || _atacante.morrendo || _defensor.morrendo) {
        debug_combate("--> combate cancelado: atacante ou defensor não está mais apto.");
        return;
    }
    debug_combate("D20 natural: " + string(_dado_natural)
        + ((_dado_natural != _dado_acerto) ? " | total: " + string(_dado_acerto) : ""));

    // Roubo reage à declaração do ataque com arma, mesmo quando o golpe erra.
    if (tem_habilidade(_defensor, "roubo") && _atacante.item_ataque_atual != noone) {
        tentar_roubo_item(_defensor, _atacante, _atacante.item_ataque_atual);
    }

    // pega o dado/mod/quantidade certos conforme o tipo de ataque
    var _usando_item_ataque = (_tipo_ataque == "fisica" && is_struct(_atacante.item_ataque_atual)
        && _atacante.item_ataque_atual.dado > 0);
    var _dado_usado = _usando_item_ataque ? _atacante.item_ataque_atual.dado
        : ((_tipo_ataque == "magica") ? _atacante.dado_dano_magico : _atacante.dado_dano);
    var _mod_usado = _usando_item_ataque ? modificador_item_ataque(_atacante, _atacante.item_ataque_atual)
        : ((_tipo_ataque == "magica") ? _atacante.mod_dano_magico : _atacante.mod_dano);
    var _qtd_usada = _usando_item_ataque ? 1
        : ((_tipo_ataque == "magica") ? _atacante.qtd_dados_dano_magico : _atacante.qtd_dados_dano);

    if (_dado_acerto <= 10 && _atacante.carnica_estado_proximo_ataque == "bonus")
        _atacante.carnica_estado_proximo_ataque = "";
    if (_dado_acerto <= 10 || _dado_natural == 1)
        registrar_trajeto_erro(_atacante, _defensor, _dado_natural == 1 ? "Erro crítico" : "Errou · " + string(_dado_acerto));
    if (_dado_natural == 1) {
        registrar_jogada_recente(_atacante.dono, "Erro crítico", _atacante.lane_atual);
        debug_combate("Erro crítico! Defensor vai contra-atacar.");
        executar_contra_ataque(_atacante, _defensor);
        return;
    }

    if (_dado_acerto <= 10) {
        registrar_jogada_recente(_atacante.dono, "Ataque errou", _atacante.lane_atual);
        debug_combate("Errou o ataque (1-10).");
        if (tem_condicao(_atacante, "confusao")) {
            debug_combate("Confusão concedeu um contra-ataque ao defensor.");
            executar_contra_ataque(_atacante, _defensor);
        }
        return;
    }

    debug_combate("Acertou! Vai rolar dano...");

    var _alvo_real = _defensor;
    if (_dado_natural == 20 && tem_habilidade(_atacante, "tiro_burro")) {
        var _todas_tropas = [];
        with (obj_carta) {
            if (travada && !morrendo) array_push(_todas_tropas, id);
        }
        if (array_length(_todas_tropas) > 0) {
            _alvo_real = _todas_tropas[irandom(array_length(_todas_tropas) - 1)];
            debug_combate("TIRO BURRO! A bala perdida atinge " + _alvo_real.nome_carta + " ao invés do alvo original!");
        }
    }

    var _contexto_dano = {
        atacante: _atacante,
        defensor: _alvo_real,
        tipo_ataque: _tipo_ataque,
        dado_usado: _dado_usado,
        mod_usado: _mod_usado,
        qtd_usada: _qtd_usada
    };

    if (_dado_natural == 20) {
        debug_combate("ACERTO CRÍTICO! Escolhendo como dobrar o dano original.");
        if (_atacante.dono == "jogador") {
            enfileirar_escolha_critico(_contexto_dano);
        } else {
            var _modo_ia = ia_escolher_modo_critico(_contexto_dano);
            mostrar_feedback(_modo_ia == "dobrar_dados" ? "CRÍTICO: +DADOS" : "CRÍTICO: RESULTADO ×2",
                _atacante.x, _atacante.y - 45, c_yellow, 55);
            resolver_dano_de_acerto(_contexto_dano, _modo_ia);
        }
        return;
    }

    resolver_dano_de_acerto(_contexto_dano, "normal");
}

function tem_maquina_ima_na_fileira(_dono, _lane) {
    var _achou = false;
    with (obj_construcao) {
        if (dono == _dono && lane_atual == _lane && efeito_construcao == "maquina_ima") {
            _achou = true;
            break;
        }
    }
    return _achou;
}

function descartar_itens_da_tropa(_itens, _dono, _preservar_indice = -1) {
    for (var i = 0; i < array_length(_itens); i++) {
        if (i == _preservar_indice) continue;
        var _item = _itens[i];
        if (_item.funcao != noone) registrar_descarte_dados(_item.funcao(), _dono);
    }
}

function processar_maquina_ima_na_morte(_carta) {
    var _itens = _carta.itens_equipados;
    if (array_length(_itens) <= 0) return false;
    if (!tem_maquina_ima_na_fileira(_carta.dono, _carta.lane_atual)) return false;

    if (_carta.dono == "jogador") {
        array_push(obj_controlador.maquina_ima_pendencias,
            { itens: _itens, x: _carta.x, y: _carta.y, dono: _carta.dono });
    } else {
        var _melhor = 0;
        var _melhor_valor = -999999;
        for (var i = 0; i < array_length(_itens); i++) {
            var _item = _itens[i];
            var _valor = _item.bonus_dano * 2 + _item.bonus_defesa * 2
                + (_item.dado > 0 ? ((_item.dado + 1) / 2 + modificador_item_ataque(_carta, _item)) : 0);
            if (_valor > _melhor_valor) { _melhor_valor = _valor; _melhor = i; }
        }
        if (_itens[_melhor].funcao != noone) array_push(obj_controlador.mao_inimigo, _itens[_melhor].funcao);
        descartar_itens_da_tropa(_itens, _carta.dono, _melhor);
        mostrar_feedback("ITEM RECUPERADO", _carta.x, _carta.y - 45, c_aqua, 55);
    }
    return true;
}

function resolver_escolha_maquina_ima(_indice) {
    if (!obj_controlador.ui_modal.maquina_ima_escolha_ativa || !is_struct(obj_controlador.ui_modal.maquina_ima_escolha_atual)) return;
    var _evento = obj_controlador.ui_modal.maquina_ima_escolha_atual;
    if (_indice < 0 || _indice >= array_length(_evento.itens)) return;
    var _item = _evento.itens[_indice];
    if (variable_struct_exists(_evento, "online") && _evento.online) {
        online_enviar_acao("choose_magnet", { index: variable_struct_exists(_item, "online_index") ? _item.online_index : _indice });
    } else {
        if (_item.funcao != noone) comprar_carta_do_deck_por_funcao(_item.funcao, _evento.x, _evento.y, _evento.dono);
        descartar_itens_da_tropa(_evento.itens, _evento.dono, _indice);
    }
    obj_controlador.ui_modal.maquina_ima_escolha_ativa = false;
    obj_controlador.ui_modal.maquina_ima_escolha_atual = noone;
    mostrar_feedback("ITEM RECUPERADO", _evento.x, _evento.y - 45, c_aqua, 55);
}

function destruir_tropa(_carta, _por_inimigo = true) {
    if (!instance_exists(_carta) || _carta.morrendo) return;
    if (_carta.tipo_morte_visual == "normal") {
        if (tem_condicao(_carta, "queimado")) _carta.tipo_morte_visual = "fogo";
        else if (tem_condicao(_carta, "envenenado") || tem_condicao(_carta, "apodrecer")) _carta.tipo_morte_visual = "veneno";
    }
    debug_combate(_carta.nome_carta + " foi derrotada e enviada ao cemitério.");
    aplicar_efeitos_morte(_carta, _por_inimigo);

    // A Máquina Imã da mesma fileira recupera um equipamento; os demais são descartados.
    var _maquina_recuperou = processar_maquina_ima_na_morte(_carta);
    if (!_maquina_recuperou) descartar_itens_da_tropa(_carta.itens_equipados, _carta.dono);
    _carta.itens_equipados = [];
    _carta.item_ataque_atual = noone;

    if (_carta.selo_abissal) {
        mandar_para_abismo(_carta.nome_carta, _carta.dono);
    } else {
        var _controle = instance_find(obj_controlador, 0);
        if (_carta.dono == "jogador") {
            array_push(_controle.cemiterio_jogador, _carta.nome_carta);
        } else {
            array_push(_controle.cemiterio_inimigo, _carta.nome_carta);
        }
    }

    // limpa o slot do morto ANTES da mitose, pra ela poder reocupá-lo depois
    var _slot_da_carta = _carta.slot_atual;
    if (_slot_da_carta != noone) {
        _slot_da_carta.ocupado = false;
        _slot_da_carta.carta_atual = noone;
    }

    if (tem_habilidade(_carta, "mitose") && _carta.funcao_mitose != noone) {
        executar_mitose(_carta);
    }

    if (obj_controlador.carta_menu_aberto == _carta) obj_controlador.carta_menu_aberto = noone;
    if (obj_controlador.tropa_selecionada == _carta) obj_controlador.tropa_selecionada = noone;
    _carta.morrendo = true;
    _carta.morte_timer = _carta.morte_duracao;
    _carta.condicoes = [];
    sincronizar_condicao_principal(_carta);
}

// Registra cartas da mão abstrata da IA, que não possuem uma instância visual.
function registrar_descarte_dados(_dados, _dono) {
    if (variable_struct_exists(_dados, "selo_abissal") && _dados.selo_abissal) {
        mandar_para_abismo(_dados.nome, _dono);
        return;
    }
    var _destino = (_dono == "jogador") ? obj_controlador.descarte_jogador : obj_controlador.descarte_inimigo;
    array_push(_destino, {
        nome: _dados.nome,
        categoria: _dados.categoria,
        sprite: variable_struct_exists(_dados, "sprite_carta") && _dados.sprite_carta != noone ? _dados.sprite_carta : spr_carta_placeholder,
        descricao: "Carta usada durante a partida."
    });
}

// Itens e magias consumidos vão para o descarte; tropas derrotadas usam o cemitério.
function registrar_descarte(_carta) {
    if (!instance_exists(_carta)) return;
    registrar_ultima_carta_jogada(_carta.funcao_dados_origem, _carta.dono);
    if (_carta.selo_abissal) {
        mandar_para_abismo(_carta.nome_carta, _carta.dono);
        return;
    }
    var _destino = (_carta.dono == "jogador") ? obj_controlador.descarte_jogador : obj_controlador.descarte_inimigo;
    array_push(_destino, {
        nome: _carta.nome_carta,
        categoria: _carta.categoria,
        sprite: _carta.sprite_index,
        descricao: descricao_carta_preview(_carta)
    });
    if (_carta.dono == "jogador") obj_controlador.descarte_jogador = _destino;
    else obj_controlador.descarte_inimigo = _destino;
    // Apenas uma cópia visual: a carta e as regras do descarte já foram resolvidas.
    if (_carta.dono == "jogador" && instance_exists(obj_descarte)) {
        var _cesto = instance_find(obj_descarte, 0);
        array_push(_cesto.cartas_caindo, {sprite: _carta.sprite_index,
            x: _carta.x, y: _carta.y, escala: abs(_carta.image_xscale),
            angulo: _carta.rotacao_atual + _carta.arrasto_rotacao, tempo: 0});
    }
    debug_combate(_carta.nome_carta + " foi para o descarte.");
}

function consumir_carta_de_funcao(_funcao, _dono) {
    if (_dono == "jogador") {
        for (var i = 0; i < array_length(obj_controlador.mao); i++) {
            var _carta_mao = obj_controlador.mao[i];
            if (instance_exists(_carta_mao) && _carta_mao.funcao_dados_origem == _funcao) {
                array_delete(obj_controlador.mao, i, 1);
                instance_destroy(_carta_mao);
                organizar_mao();
                return true;
            }
        }
        var _indice_deck = array_get_index(obj_controlador.monte, _funcao);
        if (_indice_deck >= 0) { array_delete(obj_controlador.monte, _indice_deck, 1); return true; }
    } else {
        var _indice_mao = array_get_index(obj_controlador.mao_inimigo, _funcao);
        if (_indice_mao >= 0) { array_delete(obj_controlador.mao_inimigo, _indice_mao, 1); return true; }
        var _indice_deck_ia = array_get_index(obj_controlador.monte_inimigo, _funcao);
        if (_indice_deck_ia >= 0) { array_delete(obj_controlador.monte_inimigo, _indice_deck_ia, 1); return true; }
    }
    return false;
}

function slots_adjacentes_livres(_slot) {
    var _slots = [];
    var _candidatos = [
        buscar_slot(_slot.lane, _slot.posicao - 1),
        buscar_slot(_slot.lane, _slot.posicao + 1),
        buscar_slot(_slot.lane - 1, _slot.posicao),
        buscar_slot(_slot.lane + 1, _slot.posicao)
    ];
    for (var i = 0; i < array_length(_candidatos); i++) {
        if (_candidatos[i] != noone && !_candidatos[i].ocupado
            && array_get_index(_slots, _candidatos[i]) < 0) array_push(_slots, _candidatos[i]);
    }
    return _slots;
}

function executar_mitose(_carta) {
    var _slot_morte = _carta.slot_atual;
    var _funcao_filhote = _carta.funcao_mitose;
    if (_slot_morte == noone || _funcao_filhote == noone) return;
    if (!consumir_carta_de_funcao(_funcao_filhote, _carta.dono)) {
        debug_combate("Mitose não encontrou um Slimet na mão ou no baralho.");
        return;
    }

    var _dados_filhote = _funcao_filhote();
    criar_tropa_no_slot(_dados_filhote, _slot_morte, _carta.dono);
    var _slots_livres = slots_adjacentes_livres(_slot_morte);

    if (array_length(_slots_livres) > 0 && consumir_carta_de_funcao(_funcao_filhote, _carta.dono)) {
        if (_carta.dono == "jogador") {
            obj_controlador.ui_modal.mitose_selecao_ativa = true;
            obj_controlador.ui_modal.mitose_dados_pendentes = _dados_filhote;
            obj_controlador.ui_modal.mitose_funcao_pendente = _funcao_filhote;
            obj_controlador.ui_modal.mitose_dono_pendente = _carta.dono;
            obj_controlador.ui_modal.mitose_slots_pendentes = _slots_livres;
        } else {
            criar_tropa_no_slot(_dados_filhote, _slots_livres[irandom(array_length(_slots_livres) - 1)], "inimigo");
        }
    }
    mostrar_feedback("MITOSE", _slot_morte.x, _slot_morte.y - 40, c_lime, 55);
}

// Helper genérico: cria uma tropa direto num slot do campo (usado pela Mitose e pode reaproveitar na IA depois)
function criar_tropa_no_slot(_dados, _slot, _dono) {
    var _carta = instance_create_layer(_slot.x, _slot.y, "Instances", obj_carta);
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
	_carta.atk_pos_x = variable_struct_exists(_dados, "atk_pos_x") ? _dados.atk_pos_x : 0.12;
	_carta.atk_pos_y = variable_struct_exists(_dados, "atk_pos_y") ? _dados.atk_pos_y : 0.90;
	_carta.atk_magico_pos_x = variable_struct_exists(_dados, "atk_magico_pos_x") ? _dados.atk_magico_pos_x : 0.37;
	_carta.atk_magico_pos_y = variable_struct_exists(_dados, "atk_magico_pos_y") ? _dados.atk_magico_pos_y : 0.90;
	_carta.def_pos_x = variable_struct_exists(_dados, "def_pos_x") ? _dados.def_pos_x : 0.62;
	_carta.def_pos_y = variable_struct_exists(_dados, "def_pos_y") ? _dados.def_pos_y : 0.90;
	_carta.def_magico_pos_x = variable_struct_exists(_dados, "def_magico_pos_x") ? _dados.def_magico_pos_x : 0.87;
	_carta.def_magico_pos_y = variable_struct_exists(_dados, "def_magico_pos_y") ? _dados.def_magico_pos_y : 0.90;
	_carta.int_pos_x = variable_struct_exists(_dados, "int_pos_x") ? _dados.int_pos_x : 0.88;
	_carta.int_pos_y = variable_struct_exists(_dados, "int_pos_y") ? _dados.int_pos_y : 0.07;
	_carta.mochila_pos_x = variable_struct_exists(_dados, "mochila_pos_x") ? _dados.mochila_pos_x : 0.91;
	_carta.mochila_pos_y = variable_struct_exists(_dados, "mochila_pos_y") ? _dados.mochila_pos_y : 0.185;	

    _carta.esta_na_mao = false;
    _carta.travada = true;
    _carta.depth = -100;
    _carta.dono = _dono;
    _carta.lane_atual = _slot.lane;
    _carta.posicao_atual = _slot.posicao;
    _carta.destino_x = _slot.x;
    _carta.destino_y = _slot.y;
    _carta.slot_atual = _slot;

    _slot.ocupado = true;
    _slot.carta_atual = _carta.id;
    return _carta;
}
#endregion

#region Condições especiais (queimado, veneno, paralisado, etc.)
function obter_config_condicao(_tipo) {
    static _estados = {
        queimado: { nome: "Queimado", sprite: spr_fogo, cor: make_color_rgb(245,173,110) },
        envenenado: { nome: "Envenenado", sprite: spr_veneno, cor: make_color_rgb(176,207,146) },
        congelado: { nome: "Congelado", sprite: spr_congelado, cor: make_color_rgb(171,216,230) },
        eletrocutado: { nome: "Eletrocutado", sprite: spr_eletrocutado, cor: make_color_rgb(242,218,151) },
        paralisado: { nome: "Paralisado", sprite: -1, cor: make_color_rgb(234,207,143) },
        confusao: { nome: "Confusão", sprite: -1, cor: make_color_rgb(211,176,231) },
        adormecido: { nome: "Adormecido", sprite: -1, cor: make_color_rgb(184,196,231) },
        berserker: { nome: "Berserker", sprite: -1, cor: make_color_rgb(239,164,122) },
        loucura: { nome: "Loucura", sprite: -1, cor: make_color_rgb(224,165,197) },
        sangrando: { nome: "Sangrando", sprite: -1, cor: make_color_rgb(245,156,149) },
        corrosao: { nome: "Corrosão", sprite: -1, cor: make_color_rgb(184,211,138) },
        apodrecer: { nome: "Apodrecer", sprite: -1, cor: make_color_rgb(174,186,132) },
        regeneracao: { nome: "Regeneração", sprite: -1, cor: make_color_rgb(172,218,176) }
    };
    if (variable_struct_exists(_estados,_tipo)) return variable_struct_get(_estados,_tipo);
    return { nome: string(_tipo), sprite: -1, cor: c_white };
}

// Cada tipo possui duração e dano próprios; os campos antigos espelham o primeiro.
function obter_condicao(_carta, _tipo) {
    if (!variable_instance_exists(_carta, "condicoes")) return noone;
    for (var i = 0; i < array_length(_carta.condicoes); i++)
        if (_carta.condicoes[i].tipo == _tipo) return _carta.condicoes[i];
    return noone;
}

function tem_condicao(_carta, _tipo) {
    return obter_condicao(_carta, _tipo) != noone;
}

function sincronizar_condicao_principal(_carta) {
    var _primeira = array_length(_carta.condicoes) > 0 ? _carta.condicoes[0] : noone;
    _carta.condicao = _primeira == noone ? noone : _primeira.tipo;
    _carta.condicao_turnos_restantes = _primeira == noone ? 0 : _primeira.turnos;
    _carta.condicao_dano_por_turno = _primeira == noone ? 0 : _primeira.dano;
}

function remover_condicao(_carta, _tipo) {
    if (tem_condicao(_carta, _tipo)) debug_combate(_carta.nome_carta + " deixou de estar " + _tipo + ".");
    for (var i = array_length(_carta.condicoes) - 1; i >= 0; i--)
        if (_carta.condicoes[i].tipo == _tipo) array_delete(_carta.condicoes, i, 1);
    sincronizar_condicao_principal(_carta);
}

function aplicar_condicao(_carta, _tipo, _turnos, _dano_por_turno, _disparar_armadilhas = true, _atraso_visual = 0) {
    if (!instance_exists(_carta) || _carta.object_index != obj_carta) return false;
    if (_tipo == "queimado" && _carta.imunidade_queimado_turnos > 0) return false;
    if (_tipo == "paralisado") _turnos = 2;
    var _estado = obter_condicao(_carta, _tipo);
    if (_estado == noone) {
        array_push(_carta.condicoes, { tipo: _tipo, turnos: _turnos, dano: _dano_por_turno });
    } else {
        // Reaplicar não duplica o tipo; renova a duração sem encurtá-la.
        _estado.turnos = (_estado.turnos < 0 || _turnos < 0) ? -1 : max(_estado.turnos, _turnos);
        _estado.dano = max(_estado.dano, _dano_por_turno);
    }
    sincronizar_condicao_principal(_carta);
    _carta.efeito_visual_tipo = _tipo;
    _carta.efeito_timer = 18 + _atraso_visual;
    debug_combate(_carta.nome_carta + " recebeu " + _tipo + (_turnos < 0 ? " (sem duração fixa)." : " por " + string(_turnos) + " turno(s)."));
    if (_tipo == "loucura" && _disparar_armadilhas) ativar_loucura_mutua(_carta);
    return true;
}

function aplicar_envenenado(_carta) {
    return aplicar_condicao(_carta, "envenenado", -1, 1); // -1 = dura até morrer
}

function aplicar_congelado(_carta) {
    return aplicar_condicao(_carta, "congelado", 1, 0); // sem dano, só trava 1 turno
}

function aplicar_confusao(_carta) {
    return aplicar_condicao(_carta, "confusao", 1, 0);
}

function aplicar_adormecido(_carta) {
    return aplicar_condicao(_carta, "adormecido", -1, 0);
}

function aplicar_berserker(_carta, _turnos = -1) {
    return aplicar_condicao(_carta, "berserker", _turnos, 0);
}

// Ponto único para cartas futuras aplicarem condições por chave de dados.
function aplicar_condicao_por_chave(_carta, _chave) {
    switch (_chave) {
        case "queimado": return aplicar_condicao(_carta, "queimado", 3, 2);
        case "veneno": case "envenenado": return aplicar_envenenado(_carta);
        case "paralisado": return aplicar_condicao(_carta, "paralisado", 2, 0);
        case "gelo": case "congelado": return aplicar_congelado(_carta);
        case "choque": case "eletrocutado": aplicar_eletrocutado(_carta); return true;
        case "confusao": return aplicar_confusao(_carta);
        case "adormecido": case "adormecer": return aplicar_adormecido(_carta);
        case "berserker": return aplicar_berserker(_carta);
        case "loucura": return aplicar_condicao(_carta, "loucura", -1, 0);
        case "corrosao": case "aplicar_corrosao": aplicar_corrosao(_carta); return true;
        case "apodrecer": return aplicar_apodrecer(_carta);
        case "regeneracao": return aplicar_regeneracao(_carta);
        case "sangrando": return aplicar_sangramento(_carta);
    }
    return false;
}

// Golpes no mesmo turno ou no turno ofensivo imediatamente seguinte acumulam.
function aplicar_sangramento(_carta) {
    var _estado = obter_condicao(_carta, "sangrando");
    if (_estado != noone) {
        if (_carta.sangramento_janela_consecutiva || _carta.sangramento_atingido_neste_ciclo)
            _estado.turnos += 1;
        else _estado.turnos = max(1, _estado.turnos);
    } else {
        aplicar_condicao(_carta, "sangrando", _carta.sangramento_janela_consecutiva ? 2 : 1, 3);
    }
    _carta.efeito_visual_tipo = "sangrando";
    _carta.efeito_timer = 18;
    _carta.sangramento_janela_consecutiva = true;
    _carta.sangramento_atingido_neste_ciclo = true;
    sincronizar_condicao_principal(_carta);
    return true;
}

// Eletrocutado é diferente das outras: causa dano instantâneo + joga moeda pra decidir
// se paralisa. Ao completar 6 choques seguidos, a condição vira Loucura.
function aplicar_eletrocutado(_carta) {
    _carta.vida -= 2;
    aplicar_flash_dano(_carta);
    mostrar_dano_tropa(_carta, 2);
    debug_combate(_carta.nome_carta + " foi eletrocutada e tomou 2 de dano.");
    if (_carta.vida <= 0) { destruir_tropa(_carta); return true; }

    _carta.vezes_eletrocutado_seguidas += 1;
    _carta.eletrocutado_neste_ciclo = true;
    var _ctx_choque = { carta: _carta };
    jogar_moeda_visual(_carta.x, _carta.y, _carta.x, _carta.y - 45, method(_ctx_choque, function(_moeda) {
        if (!instance_exists(carta)) return;
        if (carta.vezes_eletrocutado_seguidas >= 6) {
            aplicar_condicao(carta, "loucura", -1, 0);
            carta.vezes_eletrocutado_seguidas = 0;
            mostrar_feedback("LOUCURA", carta.x, carta.y - 45, make_color_rgb(210,45,190), 55);
        } else if (_moeda == 1) {
            aplicar_condicao(carta, "paralisado", 2, 0);
            mostrar_feedback("CARA: PARALISADA", carta.x, carta.y - 45, c_yellow, 45);
        } else {
            aplicar_condicao(carta, "eletrocutado", 1, 0);
            mostrar_feedback("COROA", carta.x, carta.y - 45, c_white, 35);
        }
    }));
    return true;
}

function processar_loucura(_carta) {
    _carta.loucura_sem_defesa = false;
    // Loucura substitui as ações normais da tropa neste turno.
    _carta.atacou_este_turno = true;
    _carta.moveu_este_turno = true;
    _carta.habilidade_usada_este_turno = true;
    var _resultado = irandom_range(1, 4);
    debug_combate(_carta.nome_carta + " está em LOUCURA: resultado " + string(_resultado) + ".");

    if (_resultado == 1) {
        var _dano = rolar_varios_dados(_carta.qtd_dados_dano, _carta.dado_dano) + _carta.mod_dano;
        _carta.vida -= max(0, _dano);
        if (_carta.vida <= 0) destruir_tropa(_carta, false);
    } else if (_resultado == 2) {
        var _alvos_aliados = [];
        with (obj_slot_batalha) {
            if (lane == _carta.lane_atual && abs(posicao - _carta.posicao_atual) == 1 && ocupado && carta_atual.dono == _carta.dono) {
                array_push(_alvos_aliados, carta_atual);
            }
        }
        if (array_length(_alvos_aliados) > 0) {
            var _alvo = _alvos_aliados[irandom(array_length(_alvos_aliados) - 1)];
            var _dano = rolar_varios_dados(_carta.qtd_dados_dano, _carta.dado_dano) + _carta.mod_dano;
            _alvo.vida -= max(0, _dano - calcular_defesa_fisica_total(_alvo));
            if (_alvo.vida <= 0) destruir_tropa(_alvo, false);
        }
    } else if (_resultado == 3) {
        if (_carta.posicao_atual == posicao_entrada(_carta.dono)) {
            var _ctx_loucura = { dono_castelo: _carta.dono, origem: _carta.nome_carta };
            rolar_dano_direto_visual(_carta, "fisica", method(_ctx_loucura, function(_dano_loucura) {
                causar_dano_castelo(dono_castelo, _dano_loucura, origem);
            }));
        } else {
            mover_tropa(_carta, -1);
        }
    } else {
        _carta.loucura_sem_defesa = true;
    }
}

// Corrosão: 3 turnos fixos, dano decrescente (3 → 2 → 1). O decremento já existe em processar_condicoes.
function aplicar_corrosao(_carta) {
    aplicar_condicao(_carta, "corrosao", 3, 3);
}

// O resultado único do D4 define tanto a duração quanto o valor por turno.
function aplicar_apodrecer(_carta) {
    if (!instance_exists(_carta)) return false;
    var _resultado = irandom_range(1, 4);
    var _ctx = { carta: _carta };
    rolar_dado_visual(_carta.x, _carta.y, _carta.x, _carta.y - 45, 4, _resultado,
        method(_ctx, function(_valor) {
            if (!instance_exists(carta)) return;
            if (aplicar_condicao(carta, "apodrecer", _valor, _valor)) carta.condicao_valor_sorteado = _valor;
        }), 0, 0, -1, _carta.dono);
    return true;
}

function aplicar_regeneracao(_carta) {
    if (!instance_exists(_carta)) return false;
    var _resultado = irandom_range(1, 4);
    var _ctx = { carta: _carta };
    rolar_dado_visual(_carta.x, _carta.y, _carta.x, _carta.y - 45, 4, _resultado,
        method(_ctx, function(_valor) {
            if (!instance_exists(carta)) return;
            if (aplicar_condicao(carta, "regeneracao", _valor, _valor)) carta.condicao_valor_sorteado = _valor;
        }), 0, 0, -1, _carta.dono);
    return true;
}

// Condições incapacitantes bloqueiam todas as ações manuais da tropa.
function tropa_pode_agir(_carta) {
    return (!tem_condicao(_carta, "paralisado")
        && !tem_condicao(_carta, "congelado")
        && !tem_condicao(_carta, "adormecido")
        && !tem_condicao(_carta, "loucura"));
}

function tropa_pode_usar_habilidade(_carta) {
    return (!tem_condicao(_carta, "paralisado")
        && !tem_condicao(_carta, "adormecido")
        && !tem_condicao(_carta, "loucura"));
}

// Processa o efeito de todas as condições de um lado (dano/cura), no início do turno dele.
function processar_condicoes(_dono) {
    with (obj_carta) {
        if (dono != _dono || !travada || morrendo) continue;
        if (sombra_cooldown > 0) {
            sombra_cooldown -= 1;
            if (sombra_cooldown == 1) sombra_ativa = false;
        }
        var _dano_total = 0;
        var _cura_total = 0;
        for (var i = 0; i < array_length(condicoes); i++) {
            var _estado = condicoes[i];
            switch (_estado.tipo) {
                case "queimado": case "envenenado": case "corrosao":
                case "apodrecer": case "sangrando": _dano_total += _estado.dano; break;
                case "regeneracao": _cura_total += _estado.dano; break;
            }
            if (_estado.tipo == "corrosao") _estado.dano = max(1, _estado.dano - 1);
        }
        // Dano e cura do mesmo início de turno são somados antes de resolver a morte.
        var _vida_antes_condicoes = vida;
        vida = min(vida_maxima, vida - _dano_total + _cura_total);
        if (_dano_total > 0 || _cura_total > 0) debug_combate(nome_carta + ": condições causaram "
            + string(_dano_total) + " de dano e " + string(_cura_total) + " de cura. Vida: "
            + string(_vida_antes_condicoes) + " -> " + string(vida) + ".");
        if (_dano_total > 0) { aplicar_flash_dano(id, 12); mostrar_dano_tropa(id, _dano_total); }
        if (_cura_total > 0) mostrar_feedback("+" + string(_cura_total), x, y - 40, c_lime, 38);
        sincronizar_condicao_principal(id);
        if (vida <= 0) { destruir_tropa(id, false); continue; }
        if (tem_condicao(id, "adormecido")) {
            var _ctx_sono = { carta: id };
            jogar_moeda_visual(x, y, x, y - 45, method(_ctx_sono, function(_resultado) {
                if (!instance_exists(carta)) return;
                if (_resultado == 1) remover_condicao(carta, "adormecido");
                mostrar_feedback(_resultado == 1 ? "ACORDOU" : "CONTINUA DORMINDO",
                    carta.x, carta.y - 45, _resultado == 1 ? c_aqua : c_blue, 45);
                if (_resultado == 1 && tem_condicao(carta, "loucura")
                    && !tem_condicao(carta, "paralisado") && !tem_condicao(carta, "congelado")) processar_loucura(carta);
            }));
        }
        if (tem_condicao(id, "loucura") && !tem_condicao(id, "adormecido")
            && !tem_condicao(id, "paralisado") && !tem_condicao(id, "congelado")) processar_loucura(id);
    }
}

// Desconta 1 turno de duração das condições.
// Roda DEPOIS das ações daquele lado (senão a tropa nunca chega a ficar bloqueada de verdade).
function expirar_condicoes(_dono) {
    with (obj_carta) {
        if (dono != _dono) continue;

        if (imunidade_queimado_turnos > 0) imunidade_queimado_turnos -= 1;
        if (sangramento_atingido_neste_ciclo) sangramento_janela_consecutiva = true;
        else sangramento_janela_consecutiva = false;
        sangramento_atingido_neste_ciclo = false;

        // Se passou um ciclo inteiro sem novo choque, a sequência foi interrompida.
        if (!eletrocutado_neste_ciclo) vezes_eletrocutado_seguidas = 0;
        eletrocutado_neste_ciclo = false;

        for (var i = array_length(condicoes) - 1; i >= 0; i--) {
            var _estado = condicoes[i];
            if (_estado.turnos > 0) {
                _estado.turnos -= 1;
                if (_estado.turnos <= 0) {
                    debug_combate(nome_carta + ": " + _estado.tipo + " terminou.");
                    if (_estado.tipo == "queimado") imunidade_queimado_turnos = 1;
                    array_delete(condicoes, i, 1);
                }
            }
        }
        sincronizar_condicao_principal(id);
    }
}
#endregion

#region Habilidades especiais das tropas
function obter_nome_exibicao_habilidade(_chave) {
    switch (_chave) {
        case "golpe_duplo": return "Golpe Duplo";
        case "sombra_translucida": return "Sombra Translúcida";
        case "ferida_exposta": return "Ferida Exposta";
        case "imitacao": return "Imitação";
        case "visao_do_veu": return "Visão do Véu";
        case "digestao": return "Digestão";
        case "carnica_frenetica": return "Carniça Frenética";
    }
    return "Habilidade";
}

// Texto usado na prévia ampliada. Centraliza as explicações das regras que já
// estão implementadas, para que cartas novas também recebam informações úteis.
function texto_custo_exibicao(_custo) {
    if (_custo == noone) return "Sem custo";

    var _lista = is_array(_custo) ? _custo : [_custo];
    var _texto = "";
    for (var i = 0; i < array_length(_lista); i++) {
        var _item = _lista[i];
        if (i > 0) _texto += " + ";
        _texto += string(_item.quantidade) + " " + nome_recurso_exibicao(_item.tipo, _item.quantidade);
    }
    return _texto;
}

function descricao_habilidade(_chave) {
    switch (_chave) {
        case "alcance": return "Alcance: permite atacar com o dano físico original a até 2 casas.";
        case "alcance_magico": return "Alcance mágico: permite atacar com o dano mágico original a até 2 casas.";
        case "voar": return "Voar: atravessa tropas terrestres e ignora armadilhas de solo. Só pode ser atacada por tropas com Voar ou Alcance/Alcance mágico.";
        case "golpe_duplo": return "Golpe Duplo: realiza dois ataques com o ataque original da tropa.";
        case "mitose": return "Mitose: ao morrer, gera duas tropas menores quando houver espaço.";
        case "imitacao": return "Imitação: disputa 1D20 + inteligência com o inimigo à frente. Se vencer, bloqueia seus ataques e permite contra-atacar. Cada tentativa de ataque exige novo teste para romper o bloqueio. Uma ativação por turno, antes de atacar. Ao perder o reteste contra o Mimic, o inimigo recebe um contra-ataque.";
        case "sombra_translucida": return "Sombra Translúcida: custa 2 Mana. Fica invisível por 1 turno, impedindo ser alvo de ataques; depois precisa de 1 turno de recarga.";
        case "visao_do_veu": return "Visão do Véu: uso único. Revela a mão inimiga; escolha destruir uma armadilha ou proteger esta tropa de uma armadilha direcionada a ela.";
        case "olhar_vazio": return "Olhar Vazio: quando uma tropa inimiga fica à frente pela primeira vez, ela testa 1D20 uma única vez na partida; se falhar, fica paralisada por 2 turnos.";
        case "tiro_burro": return "Tiro Burro: em um acerto crítico, uma tropa aleatória em campo recebe o disparo, podendo ser aliada.";
        case "digestao": return "Digestão: devora uma tropa que matou ou uma tropa adjacente, aliada ou inimiga, com menos de 4 de vida.";
        case "roubo": return "Roubo: ao ser atacada com um equipamento, rola 1D10. Com 10, rouba e equipa o item se houver espaço na mochila.";
        case "carnica_frenetica": return "Carniça Frenética: paga 2 Sangues e joga uma moeda para alterar o próximo ataque.";
        case "ferida_exposta": return "Ferida Exposta: joga uma moeda para tentar causar Sangramento com o dano original.";
    }
    return _chave;
}

function categoria_exibicao(_categoria) {
    switch (_categoria) {
        case "tropa": return "Tropa";
        case "recurso": return "Recurso";
        case "construcao": return "Construção";
        case "armadilha": return "Armadilha";
        case "item_equipavel": return "Item equipável";
        case "item_consumivel": return "Item consumível";
        case "magica": return "Magia";
        case "terreno": return "Terreno";
        case "bencao": return "Bênção";
        case "maldicao": return "Maldição";
    }
    return _categoria;
}

function descricao_efeito_preview(_carta) {
    switch (_carta.efeito_tipo) {
        case "bola_fogo": return "Causa " + string(_carta.dado_efeito) + " de dano e pode queimar o alvo.";
        case "veneno": return "Envenena a tropa alvo, causando dano ao longo dos turnos.";
        case "gelo": return "Congela a tropa alvo e limita suas ações.";
        case "choque": return "Eletrocuta a tropa alvo; choques repetidos podem causar Loucura.";
        case "comprar_cartas": return "Compra " + string(_carta.quantidade_efeito) + " cartas do seu deck.";
        case "revirar_sangue": return "Desvira um recurso de Sangue usado.";
        case "buscar_sangue": return "Obtém um recurso de Sangue.";
        case "buscar_mana": return "Obtém um recurso de Mana.";
        case "aplicar_corrosao": return "Aplica Corrosão, com dano decrescente por 3 turnos.";
        case "aumentar_intelig": return "Concede +" + string(_carta.quantidade_efeito) + " de Inteligência a uma tropa aliada.";
        case "dados_manipulados": return "Joga D4 e permite trocar as próximas 3 rolagens próprias pelo valor fixado.";
        case "refracao_temporal": return "Transforma-se na última carta não-tropa que você jogou; construção copiada tem metade da vida.";
        case "eutanasia": return "Destrói uma tropa com 5 ou menos de vida.";
        case "bloqueio_recurso": return "Impede usar ou retirar o recurso escolhido durante 3 turnos do dono.";
        case "loucura_mutua": return "Quando uma tropa sua recebe Loucura, uma tropa inimiga da fileira também recebe.";
        case "raizes_espinhosas": return "Cancela o movimento de uma tropa terrestre com menos de 10 de vida e a envenena.";
        case "destrocos": return "Quando uma construção sua é destruída, causa 1D4 às tropas inimigas da fileira.";
    }
    return "Use o efeito da carta em um alvo válido.";
}

function descricao_carta_preview(_carta) {
    var _texto = "TIPO: " + categoria_exibicao(_carta.categoria) + "\nCUSTO: " + texto_custo_exibicao(_carta.custo);
    if (_carta.object_index == obj_carta && _carta.esta_na_mao && lado_controlado_localmente(_carta.dono))
        _texto += "\n\nDISPONIBILIDADE: " + disponibilidade_carta_mao(_carta).motivo;

    if (_carta.categoria == "tropa") {
        _texto += "\n\nITENS EQUIPADOS (" + string(array_length(_carta.itens_equipados)) + "):";
        if (array_length(_carta.itens_equipados) == 0) _texto += "\nNenhum item equipado.";
        for (var _eq = 0; _eq < array_length(_carta.itens_equipados); _eq++) {
            var _item = _carta.itens_equipados[_eq];
            _texto += "\n• " + _item.nome;
            if (_item.dado > 0) _texto += " — ataque D" + string(_item.dado);
            if (_item.bonus_dano != 0) _texto += " | dano +" + string(_item.bonus_dano);
            if (_item.bonus_defesa != 0) _texto += " | defesa +" + string(_item.bonus_defesa);
        }
        if (_carta.travada) {
            _texto += "\n\nAÇÕES DA TROPA:";
            _texto += "\nAtaque: " + (!tropa_pode_agir(_carta) ? "bloqueado por condição"
                : (primeiro_turno_do_lado(_carta.dono) ? "bloqueado no 1º turno"
                : (_carta.atacou_este_turno ? "já usado" : "disponível")));
            _texto += "\nMovimento: " + (!tropa_pode_agir(_carta) ? "bloqueado por condição"
                : (_carta.turnos_no_campo < 1 ? "a partir do próximo turno"
                : (_carta.moveu_este_turno ? "já usado" : "disponível")));
            _texto += "\nAção de item: " + (_carta.troca_item_usada_este_turno ? "já usada" : "disponível");
            if (_carta.sombra_cooldown > 0)
                _texto += "\nSombra Translúcida: " + (_carta.sombra_ativa ? "invisível; depois recarrega" : "recarregando por 1 turno");
            if (_carta.iludido_por_imitacao) _texto += "\nImitação: novo teste de inteligência a cada tentativa de ataque.";
        }
        if (array_length(_carta.condicoes) > 0) {
            _texto += "\n\nCONDIÇÕES ATIVAS:";
            for (var _ci = 0; _ci < array_length(_carta.condicoes); _ci++) {
                var _estado = _carta.condicoes[_ci];
                _texto += "\n" + obter_config_condicao(_estado.tipo).nome + " (" + duracao_condicao_exibida(_estado.turnos) + ")";
            }
        }
        if (array_length(_carta.habilidades) > 0) {
            _texto += "\n\nHABILIDADES:";
            for (var i = 0; i < array_length(_carta.habilidades); i++) {
                _texto += "\n• " + descricao_habilidade(_carta.habilidades[i]);
            }
        }
        if (_carta.funcao_evolucao != noone) {
            var _dados_evolucao = _carta.funcao_evolucao();
            _texto += "\n\nEVOLUÇÃO: após sobreviver 1 turno, pode evoluir para " + _dados_evolucao.nome + ".";
        }
        return _texto;
    }

    switch (_carta.categoria) {
        case "recurso": _texto += "\n\nColoque no seu campo de recursos. Recursos virados pagam cartas e voltam no próximo turno."; break;
        case "construcao":
            if (_carta.efeito_construcao == "maquina_ima")
                _texto += "\n\nQuando uma tropa aliada da fileira morrer, escolha um item dela para devolver à mão.";
            else if (_carta.efeito_construcao == "artilharia")
                _texto += "\n\nNo início do turno do dono, dispara " + string(_carta.dado_efeito) + " contra uma tropa inimiga da fileira.";
            else if (_carta.efeito_construcao == "hemodrenario")
                _texto += "\n\nUma vez por turno, vira um Sangue inimigo e desvira um recurso aliado.";
            else _texto += "\n\nOcupa uma fileira e protege o castelo antes do dano direto.";
        break;
        case "armadilha": _texto += "\n\n" + descricao_efeito_preview(_carta); break;
        case "item_equipavel":
            _texto += "\nINTELIGÊNCIA NECESSÁRIA: " + string(_carta.requisito_inteligencia_item)
                + "\nA tropa pode equipar ou remover apenas 1 item por turno.";
            if (_carta.efeito_item == "grimorio_iniciante")
                _texto += "\n\nUma vez por turno, paga 1 Mana para usar Raio (1D4 mágico), Escudo Arcano (+2 DEF mágica) ou Curazinha (+1 vida).";
            else _texto += "\n\nEquipe em uma tropa aliada. Bônus: +" + string(_carta.bonus_mod_dano_item) + " dano e +" + string(_carta.bonus_defesa_item) + " defesa.";
        break;
        case "item_consumivel": _texto += "\n\n" + descricao_efeito_preview(_carta) + " É consumido depois do uso."; break;
        case "magica": _texto += "\n\n" + descricao_efeito_preview(_carta) + " Magias possuem limite por turno."; break;
        case "terreno":
            if (_carta.efeito_terreno == "planicies_profanas") _texto += "\n\nReduz em 1 o custo de Mana de todas as tropas enquanto estiver ativo.";
            else if (_carta.efeito_terreno == "cemiterio") _texto += "\n\nNo início de cada turno, 20% de chance de esconder as tropas adversárias até o fim dele. Bloqueia consultar detalhes, mas permite atacar os espaços ocupados.";
            else _texto += "\n\nAltera regras ou atributos do campo enquanto estiver ativo.";
        break;
        case "bencao": _texto += "\n\nEfeito positivo permanente para seu lado da partida: " + string(_carta.efeito_passivo) + "."; break;
        case "maldicao": _texto += "\n\nEfeito negativo permanente aplicado ao lado escolhido: " + string(_carta.efeito_passivo) + "."; break;
    }
    return _texto;
}
	
function tem_habilidade(_carta, _chave) {
    return array_get_index(_carta.habilidades, _chave) != -1;
}

// Só essas contam como "usar no menu" -- as outras (alcance, voar, olhar_vazio, tiro_burro)
// são passivas e são checadas direto no combate/movimento, sem precisar de clique.
function habilidades_ativas(_carta) {
    var _ativas = ["golpe_duplo", "sombra_translucida", "ferida_exposta", "imitacao", "visao_do_veu", "digestao", "carnica_frenetica"];
    var _resultado = [];
    for (var i = 0; i < array_length(_carta.habilidades); i++)
        if (array_get_index(_ativas, _carta.habilidades[i]) != -1) array_push(_resultado, _carta.habilidades[i]);
    return _resultado;
}

function tem_habilidade_ativa(_carta) {
    var _ativas = habilidades_ativas(_carta);
    return array_length(_ativas) > 0 ? _ativas[0] : noone;
}

// Despacha pra função específica de cada habilidade, baseado no código salvo na carta.
function usar_habilidade(_carta, _habilidade = noone) {
    if (!instance_exists(_carta) || !_carta.travada || _carta.morrendo || _carta.habilidade_usada_este_turno) return;
    if (_habilidade == noone) _habilidade = tem_habilidade_ativa(_carta);
    if (array_get_index(habilidades_ativas(_carta), _habilidade) < 0) return;
    if (!tropa_pode_usar_habilidade(_carta)) {
        if (_carta.dono == "jogador") mostrar_aviso_regra("Esta condição impede usar habilidades", _carta.x, _carta.y);
        return;
    }
    _carta.visual_habilidade_chave = _habilidade;
    switch (_habilidade) {
        case "golpe_duplo": habilidade_golpe_duplo(_carta); break;
        case "sombra_translucida": habilidade_sombra_translucida(_carta); break;
        case "ferida_exposta": habilidade_ferida_exposta(_carta); break;
        case "imitacao": habilidade_imitacao(_carta); break;
        case "visao_do_veu": habilidade_visao_do_veu(_carta); break;
        case "digestao": habilidade_digestao(_carta); break;
        case "carnica_frenetica": habilidade_carnica_frenetica(_carta); break;
    }
}

// Golpe Duplo: ataca duas vezes seguidas no mesmo turno.
function habilidade_golpe_duplo(_carta) {
    if (primeiro_turno_do_lado(_carta.dono) || !tropa_pode_agir(_carta)) return;
    if (_carta.atacou_este_turno) {
        debug_combate("Golpe Duplo: já atacou esse turno, não pode usar.");
        if (_carta.dono == "jogador") mostrar_aviso_regra("Esta tropa já atacou neste turno", _carta.x, _carta.y);
        return;
    }

    debug_combate(_carta.nome_carta + " usa GOLPE DUPLO!");
    _carta.item_ataque_atual = noone;

    var _tipo = (_carta.dado_dano_magico > 0 && _carta.dado_dano == 0) ? "magica" : "fisica";
    var _ataque_iniciado = processar_combate_tropa(_carta, _tipo, 0, 2);
    if (!_ataque_iniciado) return;
    processar_combate_tropa(_carta, _tipo, 1, 2);

    _carta.atacou_este_turno = true;
    _carta.habilidade_usada_este_turno = true;
}

// Sombra Translúcida: fica invisível (não pode ser mirada) por 1 turno. Custa 2 mana,
// e depois de usar precisa de 1 turno extra de recarga antes de poder usar de novo.
function habilidade_sombra_translucida(_carta) {
    if (_carta.sombra_cooldown > 0) {
        debug_combate("Sombra Translúcida ainda recarregando (" + string(_carta.sombra_cooldown) + " turnos).");
        if (_carta.dono == "jogador") mostrar_aviso_regra("Sombra recarregando por " + string(_carta.sombra_cooldown) + " turno(s)", _carta.x, _carta.y);
        return;
    }

    var _custo_mana = { tipo: "mana", quantidade: 2 };
    if (!pode_pagar_custo(_custo_mana, _carta.dono)) {
        debug_combate("Sem mana suficiente pra Sombra Translúcida.");
        return;
    }
    pagar_custo(_custo_mana, _carta.dono, "", _carta);

    _carta.sombra_ativa = true;
    _carta.sombra_cooldown = 2; // 1 turno ativo + 1 turno de recarga
    _carta.habilidade_usada_este_turno = true;

    debug_combate(_carta.nome_carta + " fica INVISÍVEL por 1 turno!");

    var _texto_flutuante = instance_create_layer(_carta.x, _carta.y - _carta.sprite_height/2, "Instances", obj_texto_flutuante);
    _texto_flutuante.texto = "INVISÍVEL";
    _texto_flutuante.cor_texto = c_aqua;
}

// Ferida Exposta: joga moeda contra a tropa na frente; se der cara, causa dano e Sangrando.
function habilidade_ferida_exposta(_carta) {
    if (_carta.atacou_este_turno || primeiro_turno_do_lado(_carta.dono) || !tropa_pode_agir(_carta)) return;
    if (!_carta.travada || _carta.slot_atual == noone) return;

    var _slot = _carta.slot_atual;
    var _lado_defensor = (_carta.dono == "jogador") ? "inimigo" : "jogador";
    var _sentido = direcao_avanco(_carta.dono);
    var _proxima_posicao = _slot.posicao + _sentido;
    var _slot_alvo = buscar_slot(_slot.lane, _proxima_posicao);

    if (_slot_alvo == noone || !_slot_alvo.ocupado || _slot_alvo.carta_atual.dono != _lado_defensor) {
        debug_combate("Ferida Exposta: sem alvo na frente.");
        if (_carta.dono == "jogador") mostrar_aviso_regra("Ferida Exposta precisa de um inimigo à frente", _carta.x, _carta.y);
        return;
    }

    var _alvo = _slot_alvo.carta_atual;
    if (_alvo.sombra_ativa || (tem_habilidade(_alvo, "voar") && !tem_habilidade(_carta, "voar")
        && !tem_habilidade(_carta, "alcance") && !tem_habilidade(_carta, "alcance_magico"))) return;
    _carta.habilidade_usada_este_turno = true;
    _carta.atacou_este_turno = true;
    if (!tentar_romper_imitacao(_carta, _alvo)) return;
    var _dados_ferida = { atacante: _carta, alvo: _alvo };

    jogar_moeda_visual(_carta.x, obj_controlador.mao_y, _alvo.x, _alvo.y - _alvo.sprite_height/2 - 20, method(_dados_ferida, function(_resultado) {
        if (!instance_exists(atacante) || !instance_exists(alvo)) return;

        if (_resultado == 1) { // cara
            var _dano = rolar_varios_dados(atacante.qtd_dados_dano, atacante.dado_dano_base);
            alvo.vida -= _dano;
            ligar_efeito_alvo(atacante,alvo,c_red);
            aplicar_sangramento(alvo);

            debug_combate(alvo.nome_carta + " ficou SANGRANDO pela Ferida Exposta!");

            if (alvo.vida <= 0) destruir_tropa(alvo);
        } else {
            debug_combate("Ferida Exposta: coroa, nada aconteceu.");
            mostrar_feedback("SEM EFEITO", alvo.x, alvo.y - 35, c_silver, 40);
        }
    }));
}
	
function habilidade_imitacao(_carta) {
    if (_carta.habilidade_usada_este_turno || _carta.atacou_este_turno) return;
    if (!_carta.travada || _carta.slot_atual == noone) return;
    var _slot = _carta.slot_atual;
    var _lado_defensor = (_carta.dono == "jogador") ? "inimigo" : "jogador";
    var _sentido = direcao_avanco(_carta.dono);
    var _slot_alvo = buscar_slot(_slot.lane, _slot.posicao + _sentido);

    if (_slot_alvo == noone || !_slot_alvo.ocupado || _slot_alvo.carta_atual.dono != _lado_defensor) {
        debug_combate("Imitação: sem tropa inimiga na frente pra enganar.");
        if (_carta.dono == "jogador") mostrar_aviso_regra("Imitação precisa de um inimigo à frente", _carta.x, _carta.y);
        return;
    }

    var _alvo = _slot_alvo.carta_atual;
    _carta.habilidade_usada_este_turno = true;

    var _rolagem_imitacao = irandom_range(1, 20) + _carta.nivel_inteligencia;
    var _rolagem_defensor = irandom_range(1, 20) + _alvo.nivel_inteligencia;

    apresentar_teste_imitacao(_carta, _alvo, _rolagem_imitacao, _rolagem_defensor);
    debug_combate(_carta.nome_carta + " usa IMITAÇÃO! (" + string(_rolagem_imitacao) + " vs " + string(_rolagem_defensor) + ")");

    if (_rolagem_imitacao > _rolagem_defensor) {
        _alvo.iludido_por_imitacao = true;
        _alvo.imitacao_origem = _carta;
        debug_combate(_alvo.nome_carta + " foi enganada e precisa vencer um novo teste para atacar!");
        mostrar_feedback("DISFARÇADO DE BAÚ", _carta.x, _carta.y - 45, c_aqua, 65);
    } else {
        debug_combate("A tropa inimiga não caiu no truque.");
        mostrar_feedback("FALHOU", _alvo.x, _alvo.y - 35, c_silver, 40);
    }
}

function usos_maximos_digestao(_carta) {
    return max(0, floor(_carta.vida_maxima / 10));
}

function alvo_valido_digestao(_origem, _alvo) {
    if (!instance_exists(_origem) || !instance_exists(_alvo) || _alvo.morrendo) return false;
    if (!_alvo.travada || _alvo.categoria != "tropa" || _alvo.vida <= 0 || _alvo.vida >= 4) return false;
    return abs(_alvo.lane_atual - _origem.lane_atual) + abs(_alvo.posicao_atual - _origem.posicao_atual) == 1;
}

function aplicar_beneficio_digestao(_carta) {
    _carta.digestao_usos += 1;
    _carta.digestao_cadaver_disponivel = false;
    _carta.vida_maxima += 1;
    aplicar_regeneracao(_carta);
    _carta.habilidade_usada_este_turno = true;
    mostrar_feedback("DIGESTÃO: VIDA MÁX. +1", _carta.x, _carta.y - 45, c_lime, 60);
}

function resolver_digestao(_carta, _alvo = noone) {
    if (!instance_exists(_carta) || _carta.digestao_usos >= usos_maximos_digestao(_carta)) return false;
    if (_carta.digestao_cadaver_disponivel) {
        aplicar_beneficio_digestao(_carta);
        return true;
    }
    if (!alvo_valido_digestao(_carta, _alvo)) return false;
    ligar_efeito_alvo(_alvo,_carta,c_lime);
    destruir_tropa(_alvo, _alvo.dono != _carta.dono);
    aplicar_beneficio_digestao(_carta);
    return true;
}

function habilidade_digestao(_carta) {
    if (_carta.digestao_usos >= usos_maximos_digestao(_carta)) {
        mostrar_aviso_regra("Digestão sem usos disponíveis", _carta.x, _carta.y);
        return;
    }
    if (_carta.digestao_cadaver_disponivel) {
        resolver_digestao(_carta);
        return;
    }

    var _alvos = [];
    with (obj_carta) {
        if (alvo_valido_digestao(_carta, id)) array_push(_alvos, id);
    }
    if (array_length(_alvos) <= 0) {
        mostrar_aviso_regra("Digestão precisa de alvo adjacente com menos de 4 de vida", _carta.x, _carta.y);
        return;
    }
    if (_carta.dono == "inimigo") {
        resolver_digestao(_carta, _alvos[0]);
        return;
    }
    obj_controlador.ui_modal.digestao_selecao_ativa = true;
    obj_controlador.ui_modal.digestao_origem = _carta;
    obj_controlador.carta_menu_aberto = noone;
    obj_controlador.tropa_selecionada = _carta;
}

function habilidade_carnica_frenetica(_carta) {
    if (_carta.carnica_estado_proximo_ataque != "") {
        mostrar_aviso_regra("Carniça Frenética já está preparada", _carta.x, _carta.y);
        return;
    }
    var _custo = { tipo: "sangue", quantidade: 2 };
    if (!pode_pagar_custo(_custo, _carta.dono)) {
        mostrar_aviso_regra("Carniça Frenética exige 2 Sangues", _carta.x, _carta.y);
        return;
    }
    pagar_custo(_custo, _carta.dono, "", _carta);
    _carta.habilidade_usada_este_turno = true;
    var _dados_carnica = { carta: _carta };
    jogar_moeda_visual(_carta.x, _carta.y, _carta.x, _carta.y - 48, method(_dados_carnica, function(_resultado) {
        if (!instance_exists(carta)) return;
        carta.carnica_estado_proximo_ataque = (_resultado == 1) ? "bonus" : "autoataque";
        mostrar_feedback((_resultado == 1) ? "CARA: +1D8 E IGNORA DEFESA" : "COROA: RISCO DE AUTOATAQUE",
            carta.x, carta.y - 45, (_resultado == 1) ? c_lime : c_red, 65);
    }));
}

// Visão do Véu abre uma escolha real para o jogador; a IA decide automaticamente.
function resolver_visao_veu_escolha(_indice_opcao) {
    if (!obj_controlador.ui_modal.visao_veu_ativa || !instance_exists(obj_controlador.ui_modal.visao_veu_origem)) return;
    var _carta = obj_controlador.ui_modal.visao_veu_origem;
    if (obj_controlador.modo_partida == "online") {
        var _payload_veu = { cardId: _carta.online_instance_id, ability: "visao_do_veu",
            choice: (_indice_opcao < 0) ? "protect" : "destroy" };
        if (_indice_opcao >= 0 && _indice_opcao < array_length(obj_controlador.ui_modal.visao_veu_opcoes))
            _payload_veu.trapId = obj_controlador.ui_modal.visao_veu_opcoes[_indice_opcao].online_instance_id;
        online_enviar_acao("use_ability", _payload_veu);
        obj_controlador.ui_modal.visao_veu_ativa = false;
        obj_controlador.ui_modal.visao_veu_origem = noone;
        obj_controlador.ui_modal.visao_veu_opcoes = [];
        return;
    }
    if (_indice_opcao < 0) {
        _carta.imune_armadilha = true;
        _carta.imune_armadilha_usos = 1;
        mostrar_feedback("PROTEGIDA DA PRÓXIMA ARMADILHA", _carta.x, _carta.y - 45, c_aqua, 60);
    } else if (_indice_opcao < array_length(obj_controlador.ui_modal.visao_veu_opcoes)) {
        var _opcao = obj_controlador.ui_modal.visao_veu_opcoes[_indice_opcao];
        if (_opcao.armadilha) {
            var _pos = array_get_index(obj_controlador.mao_inimigo, _opcao.funcao);
            if (_pos >= 0) {
                var _dados = obj_controlador.mao_inimigo[_pos]();
                registrar_descarte_dados(_dados, "inimigo");
                array_delete(obj_controlador.mao_inimigo, _pos, 1);
                mostrar_feedback("ARMADILHA DESTRUÍDA", _carta.x, _carta.y - 45, c_yellow, 60);
            }
        }
    }
    obj_controlador.ui_modal.visao_veu_ativa = false;
    obj_controlador.ui_modal.visao_veu_origem = noone;
    obj_controlador.ui_modal.visao_veu_opcoes = [];
}

// Revela a mão e permite destruir uma armadilha escolhida ou proteger a tropa
// contra a próxima armadilha. A IA usa a mesma regra e prioriza destruir.
function habilidade_visao_do_veu(_carta) {
    if (_carta.visao_do_veu_usada) {
        mostrar_aviso_regra("Visão do Véu já foi usada", _carta.x, _carta.y);
        return;
    }
    _carta.visao_do_veu_usada = true;
    _carta.habilidade_usada_este_turno = true;
    if (_carta.dono == "inimigo") {
        var _armadilha = noone;
        with (obj_carta) if (esta_na_mao && dono == "jogador" && categoria == "armadilha") { _armadilha = id; break; }
        if (instance_exists(_armadilha)) {
            var _pos_mao = array_get_index(obj_controlador.mao, _armadilha);
            if (_pos_mao >= 0) array_delete(obj_controlador.mao, _pos_mao, 1);
            registrar_descarte(_armadilha);
            instance_destroy(_armadilha);
            organizar_mao();
        } else {
            _carta.imune_armadilha = true;
            _carta.imune_armadilha_usos = 1;
        }
        return;
    }
    obj_controlador.ui_modal.visao_veu_opcoes = [];
    var _mao_revelada = obj_controlador.mao_inimigo;
    for (var i = 0; i < array_length(_mao_revelada); i++) {
        var _funcao = _mao_revelada[i];
        var _dados = _funcao();
        array_push(obj_controlador.ui_modal.visao_veu_opcoes, { nome: _dados.nome, funcao: _funcao, armadilha: _dados.categoria == "armadilha" });
    }
    obj_controlador.ui_modal.visao_veu_origem = _carta;
    obj_controlador.visao_veu_revelacao_timer = 0;
    obj_controlador.ui_modal.visao_veu_ativa = true;
    obj_controlador.carta_menu_aberto = noone;
}

function verificar_olhar_vazio(_carta) {
    if (_carta.testado_olhar_vazio) return;
    if (_carta.slot_atual == noone) return;

    var _lado_oponente = (_carta.dono == "jogador") ? "inimigo" : "jogador";
    var _sentido = direcao_avanco(_carta.dono);
    var _slot_frente = buscar_slot(_carta.slot_atual.lane, _carta.slot_atual.posicao + _sentido);

    if (_slot_frente == noone || !_slot_frente.ocupado) return;
    var _oponente = _slot_frente.carta_atual;
    if (_oponente.dono != _lado_oponente) return;
    if (!tem_habilidade(_oponente, "olhar_vazio")) return;

    _carta.testado_olhar_vazio = true;
    var _rolagem = irandom_range(1, 20);
    debug_combate(_carta.nome_carta + " encara o Olhar Vazio de " + _oponente.nome_carta + "... rolou " + string(_rolagem));

    if (_rolagem <= 10) {
        aplicar_condicao(_carta, "paralisado", 2, 0);
        debug_combate(_carta.nome_carta + " ficou PARALISADO pelo Olhar Vazio!");
        mostrar_feedback("PARALISADO", _carta.x, _carta.y - 35, c_aqua, 45);
    }
}
#endregion

#region Habilidades especiais das construções
function usar_habilidade_hemodrenario(_construcao) {
    if (!instance_exists(_construcao) || _construcao.habilidade_usada_este_turno) return false;
    var _inimigo = (_construcao.dono == "jogador") ? "inimigo" : "jogador";
    var _sangue_inimigo = noone;
    var _recurso_proprio = noone;
    with (obj_recurso) {
        if (dono == _inimigo && tipo == "sangue" && !virado && bloqueado_turnos <= 0
            && _sangue_inimigo == noone) _sangue_inimigo = id;
        if (dono == _construcao.dono && virado && bloqueado_turnos <= 0
            && _recurso_proprio == noone) _recurso_proprio = id;
    }
    if (_sangue_inimigo == noone || _recurso_proprio == noone) {
        if (_construcao.dono == "jogador") mostrar_aviso_regra("Hemodrenário precisa de Sangue inimigo livre e recurso próprio gasto", _construcao.x, _construcao.y);
        return false;
    }
    _sangue_inimigo.virado = true;
    _recurso_proprio.virado = false;
    _construcao.habilidade_usada_este_turno = true;
    mostrar_feedback("DRENOU SANGUE", _construcao.x, _construcao.y - 35, c_red, 55);
    return true;
}

function processar_construcoes_inicio_turno(_dono) {
    with (obj_construcao) {
        if (dono != _dono || efeito_construcao != "artilharia" || dado_efeito <= 0) continue;
        var _alvo = noone;
        var _melhor_distancia = 999;
        with (obj_carta) {
            if (!travada || dono == _dono || lane_atual != other.lane_atual) continue;
            var _distancia = abs(posicao_atual - posicao_entrada(_dono));
            if (_distancia < _melhor_distancia) { _melhor_distancia = _distancia; _alvo = id; }
        }
        if (_alvo != noone) {
            var _ctx_torre = { alvo: _alvo, torre: id };
            var _resultado_torre = irandom_range(1, dado_efeito);
            rolar_dado_visual(x, y, _alvo.x, _alvo.y - 35, dado_efeito, _resultado_torre,
                method(_ctx_torre, function(_dano) {
                    if (!instance_exists(alvo)) return;
                    alvo.vida -= _dano;
                    aplicar_flash_dano(alvo);
                    mostrar_dano_tropa(alvo, _dano);
                    mostrar_feedback("ARTILHARIA", torre.x, torre.y - 35, c_yellow, 45);
                    if (alvo.vida <= 0) destruir_tropa(alvo);
                }), 0, 0, -1, dono);
        }
    }
}
#endregion

// Toda tentativa de ataque, inclusive contra castelo e contra-ataque, retesta.
function tentar_romper_imitacao(_carta, _alvo = noone) {
    if (!_carta.iludido_por_imitacao) return true;
    var _origem = _carta.imitacao_origem;
    if (!instance_exists(_origem) || _origem.morrendo) {
        _carta.iludido_por_imitacao = false;
        return true;
    }
    var _teste_inimigo = irandom_range(1, 20) + _carta.nivel_inteligencia;
    var _teste_origem = irandom_range(1, 20) + _origem.nivel_inteligencia;
    var _liberou = _teste_inimigo >= _teste_origem;
    _carta.iludido_por_imitacao = !_liberou;
    var _contra = (!_liberou && _alvo == _origem);
    apresentar_teste_imitacao(_origem, _carta, _teste_origem, _teste_inimigo, _contra);
    mostrar_feedback(_liberou ? "IMITAÇÃO SUPERADA" : "ATAQUE BLOQUEADO: IMITAÇÃO",
        _carta.x, _carta.y - 45, _liberou ? c_aqua : c_yellow, 65);
    debug_combate(_carta.nome_carta + ": teste de inteligência " + string(_teste_inimigo) + " contra "
        + _origem.nome_carta + " (" + string(_teste_origem) + "). " + (_liberou ? "Bloqueio rompido." : "Ataque impedido."));
    return _liberou;
}
