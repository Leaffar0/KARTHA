#region Soltar carta e aplicar efeito por categoria
if (arrastando && mouse_check_button_released(mb_left)) {
    arrastando = false;
    
    if (obj_controlador.vida_jogador <= 0 || obj_controlador.vida_inimigo <= 0) {
        x = origem_x; y = origem_y;
        esta_na_mao = true;
        exit;
    }
    
    if (obj_controlador.turno != "jogador") {
	    x = origem_x; y = origem_y;
	    esta_na_mao = true;
	    exit;
	}
	
	if (dono == "jogador" && obj_controlador.primeiro_turno_jogador && categoria_bloqueada_primeiro_turno(categoria)) {
	    debug_combate("Primeiro turno: não pode usar " + categoria + " ainda.");
	    x = origem_x; y = origem_y;
	    esta_na_mao = true;
    exit;
}
	
    if (categoria == "tropa") {
        // --- código de soltar tropa que já existe, sem mudar nada ---
        var _slot_mais_perto = noone;
        var _menor_distancia = 9999;
        var _distancia_maxima = global.CARTA_LARGURA * 0.7;
        
        with (obj_slot_batalha) {
            var _dist = point_distance(x, y, other.x, other.y);
            if (posicao == posicao_entrada("jogador") && !ocupado && _dist < _distancia_maxima && _dist < _menor_distancia) {
                _menor_distancia = _dist;
                _slot_mais_perto = id;
            }
        }
        
        if (_slot_mais_perto != noone && obj_controlador.cartas_jogadas_no_turno < obj_controlador.max_cartas_por_turno && pode_pagar_custo(custo, "jogador")) {
            _slot_mais_perto.ocupado = true;
            _slot_mais_perto.carta_atual = id;
            slot_atual = _slot_mais_perto;
            audio_play_sound(snd_colocar,1,0,.5,0,random_range(.5,2))
            lane_atual = _slot_mais_perto.lane;
            posicao_atual = _slot_mais_perto.posicao;
            dono = "jogador";
            pagar_custo(custo, "jogador");

            esta_na_mao = false;
            travada = true;
            depth = 0;
            rotacao_atual = 0;
            escala_atual = 1;
            y_offset_atual = 0;

            // Mantém a carta visível até o slot, em vez de teletransportá-la ao soltar.
            iniciar_pulo_tropa(id, _slot_mais_perto.x, _slot_mais_perto.y, true);
			
            
            obj_controlador.cartas_jogadas_no_turno += 1;
            
            var _index = array_get_index(obj_controlador.mao, id);
            if (_index != -1) {
                array_delete(obj_controlador.mao, _index, 1);
                organizar_mao();
            }
        } else {
            x = origem_x; y = origem_y;
            esta_na_mao = true;
        }
        
    } else if (categoria == "recurso") {
        // --- novo: soltar carta de recurso ---
        var _slot_recurso_perto = noone;
        var _menor_distancia = 9999;
        var _distancia_maxima = global.CARTA_LARGURA * 0.7;
        
        with (obj_slot_recurso) {
            var _dist = point_distance(x, y, other.x, other.y);
            if (dono == "jogador" && !ocupado && _dist < _distancia_maxima && _dist < _menor_distancia) {
                _menor_distancia = _dist;
                _slot_recurso_perto = id;
            }
        }
        
        if (_slot_recurso_perto != noone && !obj_controlador.recurso_colocado_no_turno) {
            var _resultado = colocar_recurso(tipo_recurso, "jogador", x, y, _slot_recurso_perto);
            
            if (_resultado == "colocado") {
                var _index = array_get_index(obj_controlador.mao, id);
                if (_index != -1) {
                    array_delete(obj_controlador.mao, _index, 1);
                    organizar_mao();
                }
                instance_destroy(id); // a carta "vira" o recurso, ela mesma some
            } else {
                x = origem_x; y = origem_y;
                esta_na_mao = true;
            }
        } else {
            x = origem_x; y = origem_y;
            esta_na_mao = true;
        }
    } else if (categoria == "construcao") {
    var _slot_construcao_perto = noone;
    var _menor_distancia = 9999;
    var _distancia_maxima = global.CARTA_LARGURA * 0.7;
    
    with (obj_slot_construcao) {
        var _dist = point_distance(x, y, other.x, other.y);
        if (!ocupado && _dist < _distancia_maxima && _dist < _menor_distancia) {
            _menor_distancia = _dist;
            _slot_construcao_perto = id;
        }
    }
    
    if (_slot_construcao_perto != noone && pode_pagar_custo(custo, "jogador")) {
        pagar_custo(custo, "jogador");
        
        var _construcao = instance_create_layer(_slot_construcao_perto.x, _slot_construcao_perto.y, "Instances", obj_construcao);
        _construcao.nome_construcao = nome_carta;
        _construcao.vida = vida;
        _construcao.vida_maxima = vida;
        _construcao.dono = "jogador";
        _construcao.lane_atual = _slot_construcao_perto.lane;
        _construcao.slot_atual = _slot_construcao_perto;
		_construcao.tem_habilidade_construcao = (nome_carta == "Hemodrenário");
        
        _slot_construcao_perto.ocupado = true;
        _slot_construcao_perto.construcao_atual = _construcao.id;
        
        var _index = array_get_index(obj_controlador.mao, id);
        if (_index != -1) {
            array_delete(obj_controlador.mao, _index, 1);
            organizar_mao();
        }
        instance_destroy(id);
    } else {
        x = origem_x; y = origem_y;
        esta_na_mao = true;
    }
	
	} else if (categoria == "magica") {
    var _alvo_mais_perto = noone;
    var _menor_distancia = 9999;
    var _distancia_maxima = 60;
    
    with (obj_carta) {
        if (id == other.id) continue; // não pode mirar em si mesma
        if (!travada) continue; // só mira tropas que já estão no campo
        
        var _dist = point_distance(x, y, other.x, other.y);
        if (_dist < _distancia_maxima && _dist < _menor_distancia) {
            _menor_distancia = _dist;
            _alvo_mais_perto = id;
        }
    }
    
    if (_alvo_mais_perto != noone && pode_pagar_custo(custo, "jogador")) {
        pagar_custo(custo, "jogador");
        switch (efeito_tipo) {
			case "bola_fogo":
        aplicar_efeito_bola_fogo(_alvo_mais_perto, dado_efeito, chance_queimar);
        break;
			case "veneno":
        aplicar_condicao(_alvo_mais_perto, "envenenado", -1, 1);
        break;
			case "gelo":
        aplicar_condicao(_alvo_mais_perto, "congelado", 1, 0);
        break;
			case "choque":
        aplicar_condicao(_alvo_mais_perto, "eletrocutado",1,0);
        break;
}
        
        var _index = array_get_index(obj_controlador.mao, id);
        if (_index != -1) {
            array_delete(obj_controlador.mao, _index, 1);
            organizar_mao();
        }
        instance_destroy(id);
    } else {
        x = origem_x; y = origem_y;
        esta_na_mao = true;
    }
	} else if (categoria == "item_equipavel") {
    var _alvo = noone;
    var _menor_distancia = 9999;
    
    with (obj_carta) {
        if (id == other.id) continue;
        if (!travada || dono != "jogador") continue; // só equipa em tropa sua
        if (tem_item_equipado) continue; // já tem item, não aceita outro
        
        var _dist = point_distance(x, y, other.x, other.y);
        if (_dist < 60 && _dist < _menor_distancia) {
            _menor_distancia = _dist;
            _alvo = id;
        }
    }
    
    if (_alvo != noone && pode_pagar_custo(custo, "jogador")) {
        pagar_custo(custo, "jogador");
        
        _alvo.mod_dano += bonus_mod_dano_item;
        _alvo.defesa_fisica += bonus_defesa_item;
        _alvo.tem_item_equipado = true;
        
        var _index = array_get_index(obj_controlador.mao, id);
        if (_index != -1) {
            array_delete(obj_controlador.mao, _index, 1);
            organizar_mao();
        }
        instance_destroy(id);
    } else {
        x = origem_x; y = origem_y;
        esta_na_mao = true;
    }
    
} else if (categoria == "item_consumivel") {
    var _alvo = noone;
    var _menor_distancia = 9999;
    
    with (obj_carta) {
        if (id == other.id) continue;
        if (!travada || dono != "jogador") continue;
        
        var _dist = point_distance(x, y, other.x, other.y);
        if (_dist < 60 && _dist < _menor_distancia) {
            _menor_distancia = _dist;
            _alvo = id;
        }
    }
    
    if (_alvo != noone && pode_pagar_custo(custo, "jogador")) {
        pagar_custo(custo, "jogador");
        _alvo.vida = min(_alvo.vida + cura_item, _alvo.vida_maxima);
        
        var _index = array_get_index(obj_controlador.mao, id);
        if (_index != -1) {
            array_delete(obj_controlador.mao, _index, 1);
            organizar_mao();
        }
        instance_destroy(id);
    } else {
        x = origem_x; y = origem_y;
        esta_na_mao = true;
    }
	
	} else if (categoria == "armadilha") {
	    var _alvo = noone;
	    var _menor_distancia = 9999;
    
	    with (obj_carta) {
	        if (id == other.id) continue;
	        if (!travada) continue;
        
	        var _dist = point_distance(x, y, other.x, other.y);
	        if (_dist < 60 && _dist < _menor_distancia) {
	            _menor_distancia = _dist;
	            _alvo = id;
	        }
	    }
    
	    if (_alvo != noone && pode_pagar_custo(custo, "jogador")) {
	        pagar_custo(custo, "jogador");
        
	        var _dano = irandom_range(1, dado_efeito);
	        _alvo.vida -= _dano;
	        aplicar_condicao(_alvo, "sangrando", 1, 3);
        
	        if (_alvo.vida <= 0) destruir_tropa(_alvo);
        
	        var _index = array_get_index(obj_controlador.mao, id);
	        if (_index != -1) {
	            array_delete(obj_controlador.mao, _index, 1);
	            organizar_mao();
	        }
	        instance_destroy(id);
	    } else {
	        x = origem_x; y = origem_y;
	        esta_na_mao = true;
	    }
	} else if (categoria == "terreno") {
	    var _distancia_arrastada = point_distance(x, y, arrastar_inicio_x, arrastar_inicio_y);
    
	    if (_distancia_arrastada > 80 && pode_pagar_custo(custo, "jogador")) {
	        pagar_custo(custo, "jogador");
        
	        with (obj_slot_terreno) {
	            if (ocupado && terreno_atual != noone) {
	                instance_destroy(terreno_atual);
	            }
	        }
        
	        obj_controlador.terreno_bonus_defesa = bonus_defesa_global;
        
	        var _index = array_get_index(obj_controlador.mao, id);
	        if (_index != -1) {
	            array_delete(obj_controlador.mao, _index, 1);
	            organizar_mao();
	        }
	        instance_destroy(id);
	    } else {
	        x = origem_x; y = origem_y;
	        esta_na_mao = true;
	    }
	} else if (categoria == "bencao" || categoria == "maldicao") {
    var _distancia_arrastada = point_distance(x, y, arrastar_inicio_x, arrastar_inicio_y);
    
    if (_distancia_arrastada > 80 && pode_pagar_custo(custo, "jogador")) {
        var _sucesso = (categoria == "bencao") ? adicionar_bencao("jogador", efeito_passivo) : adicionar_maldicao("jogador", efeito_passivo);
        
        if (_sucesso) {
            pagar_custo(custo, "jogador");
            
            var _index = array_get_index(obj_controlador.mao, id);
            if (_index != -1) {
                array_delete(obj_controlador.mao, _index, 1);
                organizar_mao();
            }
            instance_destroy(id);
        } else {
            debug_combate("Já tem " + string(obj_controlador.max_bencaos_maldicoes) + " " + categoria + "s ativas!");
            x = origem_x; y = origem_y;
            esta_na_mao = true;
        }
    } else {
        x = origem_x; y = origem_y;
        esta_na_mao = true;
    }
}
}
#endregion

#region Animação de salto e deslocamento no campo
if (pulando) {
    pulo_progresso += 1 / pulo_duracao;
    
    if (pulo_progresso >= 1) {
        pulo_progresso = 1;
        pulando = false;
    }
    
    // Smoothstep deixa o lerp sair e chegar sem cortes bruscos.
    var _progresso_suave = pulo_progresso * pulo_progresso * (3 - (2 * pulo_progresso));
    x = lerp(pulo_origem_x, pulo_destino_x, _progresso_suave);
    var _y_base = lerp(pulo_origem_y, pulo_destino_y, _progresso_suave);
    
    var _arco = sin(_progresso_suave * pi) * pulo_altura;
    y = _y_base - _arco;

    // Um pequeno aumento e inclinação deixam a carta mais viva durante o voo.
    escala_animacao = lerp(pulo_escala_origem, 1, _progresso_suave) * (1 + sin(_progresso_suave * pi) * 0.07);
    rotacao_animacao = sin(_progresso_suave * pi) * 5 * sign(pulo_destino_x - pulo_origem_x);
    
    destino_x = pulo_destino_x;
    destino_y = pulo_destino_y;

    if (!pulando) {
        escala_animacao = 1;
        rotacao_animacao = 0;
        pulso_pouso_timer = pulso_pouso_duracao;
        if (pulo_poeira_ao_pousar) {
            criar_poeira(x, y + sprite_height / 2, sprite_width);
            pulo_poeira_ao_pousar = false;
        }
    }
    
} else if (travada) {
    x += (destino_x - x) * velocidade_movimento;
    y += (destino_y - y) * velocidade_movimento;
    rotacao_animacao = lerp(rotacao_animacao, 0, 0.2);

    // Pulso curto no pouso para dar sensação de impacto, sem alterar o estado da carta.
    if (pulso_pouso_timer > 0) {
        var _pulso = pulso_pouso_timer / pulso_pouso_duracao;
        escala_animacao = 1 + sin(_pulso * pi) * 0.06;
        pulso_pouso_timer--;
    } else {
        escala_animacao = lerp(escala_animacao, 1, 0.2);
    }
}
#endregion

#region Flash de dano
if (dano_flash_timer > 0) {
    dano_flash_timer -= 1;
}
#endregion

#region Organização visual da mão e hover
if (esta_na_mao && !arrastando && !travada) {
    
    // recalcula o destino toda vez, somando o scroll horizontal atual
    destino_x = mao_base_x + obj_controlador.mao_scroll_offset;
    destino_y = mao_base_y;
    origem_x = destino_x;
    origem_y = destino_y;
    
    x += (destino_x - x) * velocidade_movimento;
    y += (destino_y - y) * velocidade_movimento;
    
    if (hover_ativo_externo) {
        escala_alvo = 1.25;
        hover_ativo = true;
        y_offset_alvo = -30;
        depth = -1000;
    } else {
        escala_alvo = 1;
        hover_ativo = false;
        y_offset_alvo = 0;
    }
    
    var _rotacao_desejada = hover_ativo ? 0 : rotacao_alvo;
    
    rotacao_atual += (_rotacao_desejada - rotacao_atual) * 0.2;
    escala_atual += (escala_alvo - escala_atual) * 0.2;
    y_offset_atual += (y_offset_alvo - y_offset_atual) * 0.2;
}
#endregion

#region Arrasto ativo
if (arrastando) {
    x = mouse_x;
    y = mouse_y;
}
#endregion

#region Animação de evolução
if (evoluindo) {
    evolucao_progresso += 1 / evolucao_duracao;
    var _progresso_evo = clamp(evolucao_progresso, 0, 1);
    var _suave_evo = _progresso_evo * _progresso_evo * (3 - (2 * _progresso_evo));
    var _energia_evo = sin(_progresso_evo * pi);

    // Um giro fechado em 720° termina visualmente alinhado, sem salto na última imagem.
    rotacao_evolucao = 720 * _suave_evo;
    escala_evolucao = 1 + (_energia_evo * 0.28);
    cor_evolucao = merge_color(c_white, c_aqua, _energia_evo * 0.55);

    if (_progresso_evo >= 1) {
        evoluindo = false;
        rotacao_evolucao = 0;
        escala_evolucao = 1;
        cor_evolucao = c_white;
        pulso_pouso_timer = pulso_pouso_duracao;
    }
}
#endregion