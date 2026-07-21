// Grade central da room: 3 caminhos por 5 posicoes.
// 0 = base inimiga, 1 = retaguarda inimiga, 2 = centro,
// 3 = retaguarda do jogador, 4 = base do jogador.
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

function posicao_entrada(_dono) {
    return (_dono == "jogador") ? 4 : 0;
}

function posicao_ataque() {
    return 2;
}

function direcao_avanco(_dono) {
    return (_dono == "jogador") ? -1 : 1;
}

function total_posicoes_batalha() {
    return 5;
}

function criar_dados_esquilo() {
    return {
        categoria: "tropa",
        nome: "Esquilo",
		sprite_carta: noone,
        vida: 1,
        sacrificio: 0,
        dado_dano: 4,
        mod_dano: 0,
        defesa_fisica: 0,
        defesa_magica: 0,
        custo: noone
    };
}

function criar_dados_lobo() {
    return {
        categoria: "tropa",
        nome: "Lobo",
		sprite_carta: noone,
        vida: 6,
        sacrificio: 1,
        dado_dano: 6,
        mod_dano: 1,
        defesa_fisica: 1,
        defesa_magica: 0,
        custo: { tipo: "sangue", quantidade: 1 }
    };
}
	
function criar_dados_urso() {
    return {
        categoria: "tropa",
        nome: "Urso",
		sprite_carta: noone,
        vida: 10,
        sacrificio: 0,
        dado_dano: 6,
        mod_dano: 0,
        defesa_fisica: 0,
        defesa_magica: 0,
        custo: noone
    };
}

function criar_dados_recurso_sangue() {
    return { categoria: "recurso", nome: "Sangue", tipo_recurso: "sangue", sprite_carta: spr_recurso_sangue, };
}

function criar_dados_recurso_ossos() {
    return { categoria: "recurso", nome: "Ossos", tipo_recurso: "ossos", sprite_carta: spr_recurso_ossos, };
}

function criar_dados_recurso_sucata() {
    return { categoria: "recurso", nome: "Sucata", tipo_recurso: "sucata", sprite_carta: spr_recurso_sucata, };
}

function criar_dados_recurso_mana() {
    return { categoria: "recurso", nome: "Mana", tipo_recurso: "mana", sprite_carta: spr_recurso_mana, };
}
	
function criar_dados_construcao_torre() {
    return {
        categoria: "construcao",
        nome: "Torre de Vigia",
		sprite_carta: noone,
        vida: 5,
        custo: { tipo: "sucata", quantidade: 1 }
    };
}
	
function criar_dados_magica_bola_fogo() {
    return {
        categoria: "magica",
        nome: "Bola de Fogo",
		sprite_carta: spr_bola_de_fogo,
        custo: { tipo: "mana", quantidade: 2 },
        dado_efeito: 8,      // 1D8 de dano
        chance_queimar: 1 // 50% de chance de aplicar queimado
    };
}
	
function criar_dados_magica_veneno() {
    return {
        categoria: "magica",
        nome: "Veneno Mortal",
		sprite_carta: noone,
        custo: { tipo: "mana", quantidade: 1 }
    };
}

function criar_dados_magica_gelo() {
    return {
        categoria: "magica",
        nome: "Congelante",
		sprite_carta: noone,
        custo: { tipo: "mana", quantidade: 1 }
    };
}

function criar_dados_magica_choque() {
    return {
        categoria: "magica",
        nome: "Choque Elétrico",
		sprite_carta: noone,
        custo: { tipo: "mana", quantidade: 1 }
    };
}

function criar_dados_item_espada() {
    return {
        categoria: "item_equipavel",
        nome: "Espada Enferrujada",
		sprite_carta: noone,
        custo: { tipo: "sucata", quantidade: 1 },
        bonus_mod_dano: 2,
        bonus_defesa: 0
    };
}

function criar_dados_item_escudo() {
    return {
        categoria: "item_equipavel",
        nome: "Escudo de Madeira",
		sprite_carta: noone,
        custo: { tipo: "sucata", quantidade: 1 },
        bonus_mod_dano: 0,
        bonus_defesa: 2
    };
}

function criar_dados_item_pocao() {
    return {
        categoria: "item_consumivel",
        nome: "Poção de Cura",
		sprite_carta: noone,
        custo: { tipo: "mana", quantidade: 1 },
        cura: 5
    };
}
	
function criar_dados_armadilha_urso() {
    return {
        categoria: "armadilha",
        nome: "Armadilha de Urso",
		sprite_carta: spr_armadilha_de_urso,
        custo: noone,
        dado_efeito: 6
    };
}

function criar_dados_terreno_pantano() {
    return {
        categoria: "terreno",
        nome: "Pântano Sombrio",
		sprite_carta: noone,
        custo: { tipo: "ossos", quantidade: 1 },
        bonus_defesa_global: -1 // reduz a defesa de todo mundo (terreno traiçoeiro)
    };
}

function organizar_mao() {
    var _mao = obj_controlador.mao;
    var _total = array_length(_mao);
    var _espaco = obj_controlador.espaco_entre_cartas;
    var _centro_x = obj_controlador.mao_x_centro;
    var _y = obj_controlador.mao_y;
    
    var _largura_total = (_total - 1) * _espaco;
    var _x_inicial = _centro_x - (_largura_total / 2);
    
    var _angulo_maximo = 10;
    var _altura_arco = 20;
    
    for (var i = 0; i < _total; i++) {
        var _carta = _mao[i];
        var _nova_x = _x_inicial + (i * _espaco);
        
        var _posicao_relativa = 0;
        if (_total > 1) {
            _posicao_relativa = (i / (_total - 1)) - 0.5;
        }
        
        var _deslocamento_y = abs(_posicao_relativa) * abs(_posicao_relativa) * 4 * _altura_arco;
        var _nova_y = _y + _deslocamento_y;
        
        // guarda a posição "base" do leque, sem o scroll ainda
        _carta.mao_base_x = _nova_x;
        _carta.mao_base_y = _nova_y;
        _carta.esta_na_mao = true;
        _carta.depth = _total - i;
        _carta.rotacao_alvo = -_posicao_relativa * (_angulo_maximo * 2);
    }
    
    // calcula quanto dá pra rolar (só rola se a mão for mais larga que o espaço visível)
    obj_controlador.mao_scroll_max = max(0, (_largura_total - obj_controlador.mao_largura_visivel) / 2);
    obj_controlador.mao_scroll_offset_alvo = clamp(obj_controlador.mao_scroll_offset_alvo, -obj_controlador.mao_scroll_max, obj_controlador.mao_scroll_max);
}
	
function comprar_carta_do_deck(_x_inicial, _y_inicial) {
    var _funcoes = obj_controlador.baralho;
    var _funcao_sorteada = _funcoes[irandom(array_length(_funcoes) - 1)];
    var _dados = _funcao_sorteada();
    
    var _carta = instance_create_layer(_x_inicial, _y_inicial, "Instances", obj_carta);
    _carta.nome_carta = _dados.nome;
	_carta.sprite_index = (_dados.sprite_carta != noone) ? _dados.sprite_carta : spr_carta_placeholder;
	_carta.escala_base = global.CARTA_LARGURA / sprite_get_width(_carta.sprite_index);
	_carta.tem_arte_propria = (_dados.sprite_carta != noone);
    _carta.categoria = _dados.categoria;
	
    if (_dados.categoria == "tropa") {
        _carta.vida = _dados.vida;
        _carta.vida_maxima = _dados.vida;
        _carta.custo_sacrificio = _dados.sacrificio;
        _carta.dado_dano = _dados.dado_dano;
        _carta.mod_dano = _dados.mod_dano;
        _carta.defesa_fisica = _dados.defesa_fisica;
        _carta.defesa_magica = _dados.defesa_magica;
        _carta.custo = _dados.custo;
		
    } else if (_dados.categoria == "recurso") {
	    _carta.tipo_recurso = _dados.tipo_recurso;
		
	} else if (_dados.categoria == "construcao") {
	    _carta.vida = _dados.vida;
	    _carta.custo = _dados.custo;
		
	} else if (_dados.categoria == "item_equipavel") {
	    _carta.custo = _dados.custo;
	    _carta.bonus_mod_dano_item = _dados.bonus_mod_dano;
	    _carta.bonus_defesa_item = _dados.bonus_defesa;
	} else if (_dados.categoria == "item_consumivel") {
	    _carta.custo = _dados.custo;
	    _carta.cura_item = _dados.cura;
		
	} else if (_dados.categoria == "armadilha") {
	    _carta.custo = _dados.custo;
	    _carta.dado_efeito = _dados.dado_efeito;
		
	} else if (_dados.categoria == "terreno") {
    _carta.custo = _dados.custo;
    _carta.bonus_defesa_global = _dados.bonus_defesa_global;	
		
	} else if (_dados.categoria == "magica") {
		_carta.custo = _dados.custo;
    
    if (_dados.nome == "Bola de Fogo") {
        _carta.efeito_tipo = "bola_fogo";
        _carta.dado_efeito = _dados.dado_efeito;
        _carta.chance_queimar = _dados.chance_queimar;
    } else if (_dados.nome == "Veneno Mortal") {
        _carta.efeito_tipo = "veneno";
    } else if (_dados.nome == "Congelante") {
        _carta.efeito_tipo = "gelo";
    } else if (_dados.nome == "Choque Elétrico") {
        _carta.efeito_tipo = "choque";
    }
}
    
    _carta.esta_na_mao = true;
    
    array_push(obj_controlador.mao, _carta);
    organizar_mao();
    
    _carta.x = _x_inicial;
    _carta.y = _y_inicial;
    
    if (instance_exists(obj_deck)) {
        obj_deck.quantidade_cartas -= 1;
    }
}

// acha um slot específico pelo lado e coluna
function buscar_slot(_lane, _posicao) {
    var _resultado = noone;
    with (obj_slot_batalha) {
        if (lane == _lane && posicao == _posicao) {
            _resultado = id;
        }
    }
    return _resultado;
}

// processa o ataque de todas as cartas do jogador
function processar_combate(_lado_atacante) {
    var _lado_defensor = (_lado_atacante == "jogador") ? "inimigo" : "jogador";
    var _sentido = direcao_avanco(_lado_atacante);
    
    with (obj_slot_batalha) {
        if (ocupado && carta_atual.dono == _lado_atacante && tropa_pode_agir(carta_atual)) {
            var _atacante = carta_atual;
            var _proxima_posicao = posicao + _sentido;
            var _slot_alvo = buscar_slot(lane, _proxima_posicao);
            
            if (_slot_alvo != noone && _slot_alvo.ocupado && _slot_alvo.carta_atual.dono == _lado_defensor) {
                // tem tropa inimiga na frente, em QUALQUER posição: ataca ela
                rolar_combate(_atacante, _slot_alvo.carta_atual);
                
            } else if (posicao == posicao_ataque()) {
                // só chega aqui se estiver no MEIO E não tiver tropa na frente
                var _construcao_alvo = buscar_construcao(lane, _lado_defensor);
                
                if (_construcao_alvo != noone) {
                    var _dano_construcao = irandom_range(1, _atacante.dado_dano) + _atacante.mod_dano;
                    _construcao_alvo.vida -= _dano_construcao;
                    
                    if (_construcao_alvo.vida <= 0) {
                        _construcao_alvo.slot_atual.ocupado = false;
                        _construcao_alvo.slot_atual.construcao_atual = noone;
                        instance_destroy(_construcao_alvo);
                    }
                } else {
                    var _dano_direto = irandom_range(1, _atacante.dado_dano) + _atacante.mod_dano;
                    if (_lado_atacante == "jogador") {
                        obj_controlador.vida_inimigo -= _dano_direto;
                    } else {
                        obj_controlador.vida_jogador -= _dano_direto;
                    }
                }
            }
            // se não estiver no MEIO e não tiver tropa na frente: não faz nada, ela ainda vai avançar na Fase de Movimento
        }
    }
}

function iniciar_pulo_tropa(_carta, _novo_x, _novo_y) {
    _carta.pulando = true;
    _carta.pulo_origem_x = _carta.x;
    _carta.pulo_origem_y = _carta.y;
    _carta.pulo_destino_x = _novo_x;
    _carta.pulo_destino_y = _novo_y;
    _carta.pulo_progresso = 0;
}	
	
function mover_tropa(_carta, _direcao) {
    if (_carta.posicao_atual == posicao_ataque() && _direcao == 1) {
        return "ja_no_meio";
    }
    
    var _sentido = direcao_avanco(_carta.dono);
    var _nova_posicao = _carta.posicao_atual + (_direcao * _sentido);
    
    if (_nova_posicao < 0 || _nova_posicao >= total_posicoes_batalha()) return "fora_do_tabuleiro";
    
    var _slot_destino = buscar_slot(_carta.lane_atual, _nova_posicao);
    if (_slot_destino == noone) return "invalido";
    
    if (_slot_destino.ocupado) {
        var _ocupante = _slot_destino.carta_atual;
        if (_ocupante.dono == _carta.dono) {
            return "bloqueado";
        } else {
            return "ataque_necessario";
        }
    }
    
    _carta.slot_atual.ocupado = false;
    _carta.slot_atual.carta_atual = noone;
    
    _slot_destino.ocupado = true;
    _slot_destino.carta_atual = _carta.id;
    _carta.slot_atual = _slot_destino;
    _carta.posicao_atual = _nova_posicao;
    
    // dispara o pulo animado ao invés de só atualizar destino
    iniciar_pulo_tropa(_carta, _slot_destino.x, _slot_destino.y);
    
    return "movido";
}
	
function ia_jogar_cartas() {
    var _chance_jogar = 0.7;
    var _cartas_jogadas = 0;
    var _max_cartas = 1;
    
    with (obj_slot_batalha) {
        if (_cartas_jogadas >= _max_cartas) continue;
        
        if (posicao == posicao_entrada("inimigo") && !ocupado) {
            if (random(1) < _chance_jogar) {
                var _funcoes = obj_controlador.baralho;
                var _funcao_sorteada = _funcoes[irandom(array_length(_funcoes) - 1)];
                var _dados = _funcao_sorteada();
                
                if (_dados.categoria != "tropa") continue;
                if (!pode_pagar_custo(_dados.custo, "inimigo")) continue;
                
                pagar_custo(_dados.custo, "inimigo");
                
                var _carta = instance_create_layer(x, y, "Instances", obj_carta);
                _carta.nome_carta = _dados.nome;
				_carta.escala_base = global.CARTA_LARGURA / sprite_get_width(_carta.sprite_index);
                _carta.categoria = _dados.categoria;
                _carta.vida = _dados.vida;
                _carta.vida_maxima = _dados.vida;
                _carta.custo_sacrificio = _dados.sacrificio;
                _carta.dado_dano = _dados.dado_dano;
                _carta.mod_dano = _dados.mod_dano;
                _carta.defesa_fisica = _dados.defesa_fisica;
                _carta.defesa_magica = _dados.defesa_magica;
                
                _carta.esta_na_mao = false;
                _carta.travada = true;
                _carta.depth = 0;
                _carta.dono = "inimigo";
                _carta.lane_atual = lane;
                _carta.posicao_atual = posicao;
                _carta.destino_x = x;
                _carta.destino_y = y;
                _carta.slot_atual = id;
                
                ocupado = true;
                carta_atual = _carta.id;
                
                _cartas_jogadas += 1;
            }
        }
    }
}
	
function ia_jogar_recursos() {
    var _tipos = ["sangue", "ossos", "sucata", "mana"];
    var _tipo_sorteado = _tipos[irandom(array_length(_tipos) - 1)];
    colocar_recurso(_tipo_sorteado, "inimigo");
}

function ia_jogar_construcao() {
    if (random(1) > 0.3) return; // 30% de chance de tentar construir por turno
    
    if (!pode_pagar_custo(criar_dados_construcao_torre().custo, "inimigo")) return;
    
    var _slot_livre = noone;
    with (obj_slot_construcao) {
        if (!ocupado && dono == "inimigo") {
            _slot_livre = id;
            break;
        }
    }
    
    if (_slot_livre == noone) return;
    
    var _dados = criar_dados_construcao_torre();
    pagar_custo(_dados.custo, "inimigo");
    
    var _construcao = instance_create_layer(_slot_livre.x, _slot_livre.y, "Instances", obj_construcao);
    _construcao.nome_construcao = _dados.nome;
    _construcao.vida = _dados.vida;
    _construcao.vida_maxima = _dados.vida;
    _construcao.dono = "inimigo";
    _construcao.lane_atual = _slot_livre.lane;
    _construcao.slot_atual = _slot_livre;
    
    _slot_livre.ocupado = true;
    _slot_livre.construcao_atual = _construcao.id;
}
	
function mover_tropas_automatico(_dono) {
    with (obj_carta) {
        if (dono == _dono && travada && posicao_atual != posicao_ataque() && tropa_pode_agir(id)) {
            mover_tropa(id, 1);
        }
    }
}
	
function rolar_combate(_atacante, _defensor) {
    show_debug_message("=== ATAQUE: " + _atacante.nome_carta + " (id=" + string(_atacante.id) + ") vs " + _defensor.nome_carta + " (id=" + string(_defensor.id) + ") ===");
    
    var _dado_acerto = irandom_range(1, 20);
    
    var _dados_combate = {
        atacante: _atacante,
        defensor: _defensor
    };
    
    rolar_dado_visual(_atacante.x, _atacante.y, _defensor.x, _defensor.y, 20, _dado_acerto, method(_dados_combate, function(_resultado) {
        processar_resultado_acerto(_resultado, atacante, defensor);
    }));
}

function processar_resultado_acerto(_dado_acerto, _atacante, _defensor) {
    if (!instance_exists(_atacante) || !instance_exists(_defensor)) {
        return;
    }
    show_debug_message("D20 rolou: " + string(_dado_acerto));
    if (_dado_acerto == 1) {
        show_debug_message("Erro crítico! Defensor vai contra-atacar.");
        
        var _dano_contra_dado = irandom_range(1, _defensor.dado_dano);
        
        var _dados_contra = {
            atacante: _atacante,
            defensor: _defensor
        };
        
        rolar_dado_visual(_defensor.x, _defensor.y, _atacante.x, _atacante.y, _defensor.dado_dano, _dano_contra_dado, method(_dados_contra, function(_resultado) {
            if (!instance_exists(atacante) || !instance_exists(defensor)) {
                return;
            }
            var _dano_contra = _resultado + defensor.mod_dano;
            _dano_contra = max(0, _dano_contra - atacante.defesa_fisica - obj_controlador.terreno_bonus_defesa);
            atacante.vida -= _dano_contra;
            
            show_debug_message(atacante.nome_carta + " tomou " + string(_dano_contra) + " de contra-ataque. Vida: " + string(atacante.vida));
            
            if (atacante.vida <= 0) {
                destruir_tropa(atacante);
            }
        }));
        return;
    }
    
    if (_dado_acerto <= 10) {
        show_debug_message("Errou o ataque (1-10).");
        return;
    }
    
    show_debug_message("Acertou! Vai rolar dano...");
    
    var _num_dados = (_dado_acerto == 20) ? 2 : 1;
    var _dano_dado = irandom_range(1, _atacante.dado_dano);
    if (_num_dados == 2) {
        _dano_dado += irandom_range(1, _atacante.dado_dano);
    }
    
    var _dados_dano = {
        atacante: _atacante,
        defensor: _defensor
    }
};

function destruir_tropa(_carta) {
    if (_carta.slot_atual != noone) {
        _carta.slot_atual.ocupado = false;
        _carta.slot_atual.carta_atual = noone;
    }
    instance_destroy(_carta);
}
	
function rolar_dado_visual(_x, _y, _destino_x, _destino_y, _tamanho_dado, _resultado_final, _funcao_callback) {
    var _dado = instance_create_layer(_x, _y, "Instances", obj_dado);
    obj_controlador.rolagens_pendentes += 1;
    _dado.tamanho_dado = _tamanho_dado;
    _dado.valor_final = _resultado_final;
    _dado.destino_x = _destino_x;
    _dado.destino_y = _destino_y;
	_dado.pos_inicial_x = _x;
	_dado.pos_inicial_y = _y;
    _dado.girando = true;
    _dado.tempo_girando = 0;
    _dado.callback = _funcao_callback;
}

function avancar_fase_jogador() {
    if (obj_controlador.turno != "jogador") return;
    if (obj_controlador.rolagens_pendentes > 0) return;

    switch (obj_controlador.fase) {
        case "gerenciamento":
            obj_controlador.fase = "ataque";
            break;

        case "ataque":
		    processar_combate("jogador");
		    obj_controlador.fase = "movimento";
		    break;

        case "movimento":
            iniciar_turno_inimigo();
            break;

       case "compra":
		    processar_condicoes("jogador");
		    desvirar_recursos("jogador");
		    if (instance_exists(obj_deck) && obj_deck.quantidade_cartas > 0) {
		        comprar_carta_do_deck(obj_deck.x, obj_deck.y);
		    }
		    reiniciar_acoes_tropas("jogador");
		    obj_controlador.fase = "gerenciamento";
		    break;
    }
}

function iniciar_turno_inimigo() {
    obj_controlador.turno = "inimigo";
    obj_controlador.fase = "turno_inimigo";
    
    processar_condicoes("inimigo");
    desvirar_recursos("inimigo");
    ia_jogar_recursos();
    ia_jogar_construcao();
    
    mover_tropas_automatico("inimigo");
    ia_jogar_cartas();
    processar_combate("inimigo");
    
    obj_controlador.turno = "jogador";
    obj_controlador.fase = "compra";
    obj_controlador.cartas_jogadas_no_turno = 0;
}

function reiniciar_acoes_tropas(_lado)
{
    with (obj_carta)
    {
        if (dono == _lado && travada)
        {
            moveu_este_turno = false;
        }
    }
}

function colocar_recurso(_tipo, _dono) {
    var _ja_colocou = (_dono == "jogador") ? obj_controlador.recurso_colocado_no_turno : obj_controlador.recurso_colocado_no_turno_inimigo;
    if (_ja_colocou) return "ja_colocou_no_turno";
    
    var _slot_livre = noone;
    with (obj_slot_recurso) {
        if (!ocupado && dono == _dono) {
            _slot_livre = id;
            break;
        }
    }
    
    if (_slot_livre == noone) return "campo_cheio";
    
    var _recurso = instance_create_layer(_slot_livre.x, _slot_livre.y, "Instances", obj_recurso);
    _recurso.tipo = _tipo;
    _recurso.virado = false;
    _recurso.dono = _dono;
    
    switch (_tipo) {
        case "sangue": _recurso.sprite_index = spr_recurso_sangue; break;
        case "ossos": _recurso.sprite_index = spr_recurso_ossos; break;
        case "sucata": _recurso.sprite_index = spr_recurso_sucata; break;
        case "mana": _recurso.sprite_index = spr_recurso_mana; break;
    }
    
	_recurso.escala_recurso = global.RECURSO_LARGURA / sprite_get_width(_recurso.sprite_index);
	
    _slot_livre.ocupado = true;
    _slot_livre.recurso_atual = _recurso.id;
    
    if (_dono == "jogador") {
        array_push(obj_controlador.recursos_jogador, _recurso);
        obj_controlador.recurso_colocado_no_turno = true;
    } else {
        array_push(obj_controlador.recursos_inimigo, _recurso);
        obj_controlador.recurso_colocado_no_turno_inimigo = true;
    }
    
    return "colocado";
}

// verifica se dá pra pagar um custo, sem gastar ainda
function pode_pagar_custo(_custo, _dono) {
    if (_custo == noone) return true;
    
    var _disponiveis = 0;
    with (obj_recurso) {
        if (!virado && dono == _dono && (tipo == other_custo_tipo(_custo) || _custo.tipo == "qualquer")) {
            _disponiveis += 1;
        }
    }
    return _disponiveis >= _custo.quantidade;
}

// função auxiliar (workaround pro "with" não enxergar _custo direto às vezes)
function other_custo_tipo(_custo) {
    return _custo.tipo;
}

// paga de verdade, virando os recursos usados
function pagar_custo(_custo, _dono) {
    if (_custo == noone) return true;
    
    var _lista = (_dono == "jogador") ? obj_controlador.recursos_jogador : obj_controlador.recursos_inimigo;
    var _pagos = 0;
    
    for (var i = 0; i < array_length(_lista); i++) {
        if (_pagos >= _custo.quantidade) break;
        
        var _recurso = _lista[i];
        if (instance_exists(_recurso) && !_recurso.virado) {
            if (_custo.tipo == "qualquer" || _recurso.tipo == _custo.tipo) {
                _recurso.virado = true;
                _pagos += 1;
            }
        }
    }
    
    return _pagos >= _custo.quantidade;
}

// desvira todos os recursos (chamado na Fase de Compra)
function desvirar_recursos(_dono) {
    with (obj_recurso) {
        if (dono == _dono) virado = false;
    }
    if (_dono == "jogador") {
        obj_controlador.recurso_colocado_no_turno = false;
    } else {
        obj_controlador.recurso_colocado_no_turno_inimigo = false;
    }
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
	
// tenta aplicar uma condição -- só funciona se a tropa não tiver outra condição diferente ativa
function aplicar_condicao(_carta, _tipo, _turnos, _dano_por_turno) {
    if (_carta.condicao != noone && _carta.condicao != _tipo) {
        return false;
    }
    
    _carta.condicao = _tipo;
    _carta.condicao_turnos_restantes = _turnos;
    _carta.condicao_dano_por_turno = _dano_por_turno;
    _carta.efeito_timer = 0; // reseta a animação do sprite
    
    var _config = obter_config_condicao(_tipo);
    
    var _texto_flutuante = instance_create_layer(_carta.x, _carta.y - _carta.sprite_height/2, "Instances", obj_texto_flutuante);
    _texto_flutuante.texto = string_upper(_tipo);
    _texto_flutuante.cor_texto = _config.cor;
    
    return true;
}
	
function aplicar_eletrocutado(_carta) {
    _carta.vida -= 2;
    
    show_debug_message(_carta.nome_carta + " foi eletrocutado! Tomou 2 de dano.");
    
    if (_carta.vida <= 0) {
        destruir_tropa(_carta);
        return;
    }
    
    _carta.vezes_eletrocutado_seguidas += 1;
    
    var _moeda = irandom(1); // 0 = coroa, 1 = cara
    
    if (_moeda == 1) {
        show_debug_message(_carta.nome_carta + " tirou CARA! Ficou paralisado.");
        aplicar_condicao(_carta, "paralisado", 1, 0);
    } else {
        show_debug_message(_carta.nome_carta + " tirou COROA. Sem paralisia dessa vez.");
        aplicar_condicao(_carta, "eletrocutado", 1, 0);
    }
    
    if (_carta.vezes_eletrocutado_seguidas >= 6) {
        show_debug_message(_carta.nome_carta + " levou choque demais e ganhou LOUCURA!");
        _carta.vezes_eletrocutado_seguidas = 0;
    }
}

function aplicar_envenenado(_carta) {
    aplicar_condicao(_carta, "envenenado", -1, 1); // -1 = dura até morrer
}

function aplicar_congelado(_carta) {
    aplicar_condicao(_carta, "congelado", 1, 0); // sem dano, só trava 1 turno
}

// sangrando é especial: se já está sangrando, ataques seguintes SOMAM turnos ao invés de recusar
function aplicar_sangramento(_carta) {
    if (_carta.condicao == "sangrando") {
        _carta.condicao_turnos_restantes += 1;
        return true;
    }
    return aplicar_condicao(_carta, "sangrando", 1, 3);
}
	
// tropas paralisadas/congeladas não podem agir
function tropa_pode_agir(_carta) {
    return (_carta.condicao != "paralisado" && _carta.condicao != "congelado");
}

// processa o efeito de todas as condições de um lado, no início do turno dele
function processar_condicoes(_dono) {
    with (obj_carta) {
        if (dono != _dono) continue;
        if (condicao == noone) continue;
        
        switch (condicao) {
            case "queimado":
            case "envenenado":
            case "corrosao":
            case "apodrecer":
            case "sangrando":
                vida -= condicao_dano_por_turno;
                break;
            
            case "regeneracao":
                vida = min(vida + condicao_dano_por_turno, vida_maxima);
                break;
        }
        
        if (vida <= 0) {
            destruir_tropa(id);
            continue;
        }
        
        // corrosão diminui o dano a cada turno (3, 2, 1)
        if (condicao == "corrosao" && condicao_dano_por_turno > 1) {
            condicao_dano_por_turno -= 1;
        }
        
        // conta os turnos restantes (se não for infinito)
        if (condicao_turnos_restantes > 0) {
            condicao_turnos_restantes -= 1;
            
            if (condicao_turnos_restantes <= 0) {
                if (condicao == "queimado") {
                    // fica 1 turno imune antes de poder ser queimada de novo
                    condicao = "imune_queimado";
                    condicao_turnos_restantes = 1;
                } else {
                    condicao = noone;
                    condicao_dano_por_turno = 0;
                }
            }
        }
    }
}
	
function criar_poeira(_x, _y, _largura) {
    var _quantidade = 10; // quantas partículas por explosão
    
    for (var i = 0; i < _quantidade; i++) {
        // nasce numa posição aleatória ao longo da base da carta
        var _nasce_x = _x + random_range(-_largura/2, _largura/2);
        var _nasce_y = _y;
        
        var _particula = instance_create_layer(_nasce_x, _nasce_y, "Instances", obj_particula_poeira);
        
        // direção: espalha principalmente pros lados e um pouco pra baixo (60° a 120° = baixo, ou ajuste)
        _particula.direcao_movimento = random_range(200, 340); // ajuste esse range conforme testar
        _particula.velocidade_particula = random_range(1.5, 4);
        _particula.vida_particula = irandom_range(20, 35);
        _particula.vida_particula_max = _particula.vida_particula;
    }
}

function aplicar_efeito_bola_fogo(_alvo, _dado_efeito, _chance_queimar) {
    var _dano = irandom_range(1, _dado_efeito);
    
    show_debug_message(_alvo.nome_carta + " tomou " + string(_dano) + " de Bola de Fogo!");
    
    _alvo.vida -= _dano;
    
    if (_alvo.vida <= 0) {
        destruir_tropa(_alvo);
        return;
    }
    
    var _dados_moeda = { alvo: _alvo };
    
    // origem: perto da sua mão (seu lado da tela) -- destino: em cima do alvo
    var _origem_x = _alvo.x;
    var _origem_y = obj_controlador.mao_y;
    var _escala_visual_alvo = _alvo.escala_base * (_alvo.travada ? _alvo.escala_no_campo : 1);
	var _altura_visual_alvo = global.CARTA_ALTURA * _escala_visual_alvo;
	var _altura_visual_moeda = global.MOEDA_LARGURA; // já que a moeda é quadrada (100x100), largura = altura

	var _destino_x = _alvo.x;
	var _destino_y = _alvo.y - _altura_visual_alvo/2 - (_altura_visual_moeda/2) + 20; // esse "+20" desce ela um pouco
    
    jogar_moeda_visual(_origem_x, _origem_y, _destino_x, _destino_y, method(_dados_moeda, function(_resultado) {
        if (!instance_exists(alvo)) return;
        
        if (_resultado == 1) {
            aplicar_condicao(alvo, "queimado", 3, 2);
        }
    }));
}
	
function obter_config_condicao(_tipo) {
    switch (_tipo) {
        case "queimado":
            return { cor: c_red, sprite: spr_fogo, modo: "meio" };
        case "eletrocutado":
            return { cor: c_yellow, sprite: spr_eletrocutado, modo: "meio" };
        case "envenenado":
            return { cor: c_lime, sprite: spr_veneno, modo: "meio" };
        case "congelado":
            return { cor: c_aqua, sprite: spr_congelado, modo: "envolta" };
    }
    return { cor: c_white, sprite: -1, modo: "meio" };
}
	
function tocar_musica(_musica)
{
    audio_stop_all();

    if (!audio_is_playing(_musica))
    {
        audio_play_sound(_musica, 0, true);
    }
}

function jogar_moeda_visual(_origem_x, _origem_y, _destino_x, _destino_y, _funcao_callback) {
    show_debug_message("jogar_moeda_visual chamada!");
    
    var _resultado = irandom(1);
    
    var _moeda = instance_create_layer(_origem_x, _origem_y, "Instances", obj_moeda);
    _moeda.resultado_final = _resultado;
    _moeda.pos_inicial_x = _origem_x;
    _moeda.pos_inicial_y = _origem_y;
    _moeda.destino_x = _destino_x;
    _moeda.destino_y = _destino_y;
    _moeda.escala_moeda = global.MOEDA_LARGURA / sprite_get_width(_moeda.sprite_index);
    _moeda.girando = true;
    _moeda.tempo_girando = 0;
    _moeda.callback = _funcao_callback;
    
    obj_controlador.rolagens_pendentes += 1;
}