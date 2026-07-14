if (arrastando && mouse_check_button_released(mb_left)) {
    arrastando = false;
    
    if (obj_controlador.vida_jogador <= 0 || obj_controlador.vida_inimigo <= 0) {
        x = origem_x; y = origem_y;
        esta_na_mao = true;
        exit;
    }
    
    if (obj_controlador.turno != "jogador" || obj_controlador.fase != "gerenciamento") {
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
            x = _slot_mais_perto.x;
            y = _slot_mais_perto.y;
            _slot_mais_perto.ocupado = true;
            _slot_mais_perto.carta_atual = id;
            slot_atual = _slot_mais_perto;
            
            lane_atual = _slot_mais_perto.lane;
            posicao_atual = _slot_mais_perto.posicao;
            dono = "jogador";
            pagar_custo(custo, "jogador");
            
			criar_poeira(x, y + sprite_height/2, sprite_width);
			
            origem_x = x; origem_y = y;
            destino_x = x; destino_y = y;
            esta_na_mao = false;
            travada = true;
            depth = 0;
            rotacao_atual = 0;
            escala_atual = 1;
            y_offset_atual = 0;
			
            
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
            if (!ocupado && _dist < _distancia_maxima && _dist < _menor_distancia) {
                _menor_distancia = _dist;
                _slot_recurso_perto = id;
            }
        }
        
        if (_slot_recurso_perto != noone && !obj_controlador.recurso_colocado_no_turno) {
            var _resultado = colocar_recurso(tipo_recurso, "jogador");
            
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
    if (pode_pagar_custo(custo, "jogador")) {
        pagar_custo(custo, "jogador");
        
        // remove o terreno antigo, se tiver
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
}
}

if (pulando) {
    pulo_progresso += 1 / pulo_duracao;
    
    if (pulo_progresso >= 1) {
        pulo_progresso = 1;
        pulando = false;
    }
    
    x = lerp(pulo_origem_x, pulo_destino_x, pulo_progresso);
    var _y_base = lerp(pulo_origem_y, pulo_destino_y, pulo_progresso);
    
    var _arco = sin(pulo_progresso * pi) * pulo_altura;
    y = _y_base - _arco;
    
    destino_x = pulo_destino_x;
    destino_y = pulo_destino_y;
    
} else if (travada) {
    x += (destino_x - x) * velocidade_movimento;
    y += (destino_y - y) * velocidade_movimento;
}

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

if (arrastando) {
    x = mouse_x;
    y = mouse_y;
}
