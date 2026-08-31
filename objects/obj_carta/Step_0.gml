#region Morte visual
// A regra já foi resolvida e o slot está livre; aqui só termina a animação.
if (morrendo) {
    morte_timer -= 1;
    if (morte_timer <= 0) instance_destroy();
    exit;
}
#endregion

#region Armadilha vigiando: detecta gatilho e faz a carta balançar na mão
if (armadilha_estado == "vigiando" || armadilha_estado == "pronta") {
    var _slot_vigiado = buscar_slot(armadilha_lane, armadilha_posicao);
    var _tem_tropa_em_cima = (_slot_vigiado != noone && _slot_vigiado.ocupado && instance_exists(_slot_vigiado.carta_atual));

    armadilha_estado = _tem_tropa_em_cima ? "pronta" : "vigiando";

    if (armadilha_estado == "pronta" && esta_na_mao && !arrastando) {
        armadilha_balanco_timer += 0.25;
        var _balanco = sin(armadilha_balanco_timer) * 6;
        rotacao_atual = _balanco; // reaproveita a rotação que a carta já usa na mão
    } else {
        armadilha_balanco_timer = 0;
    }
}
#endregion

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

    // Descarte manual: solte uma carta da mão sobre a pilha de descarte.
    var _pilha_descarte = instance_find(obj_descarte, 0);
    if (_pilha_descarte != noone
        && point_in_rectangle(x, y, _pilha_descarte.x - 20, _pilha_descarte.y - 20,
            _pilha_descarte.x + _pilha_descarte.sprite_width + 20, _pilha_descarte.y + _pilha_descarte.sprite_height + 20)) {
        obj_controlador.confirmacao_descarte_ativa = true;
        obj_controlador.carta_pendente_descarte = id;
        exit;
    }
	
	if (dono == "jogador" && obj_controlador.primeiro_turno_jogador && categoria_bloqueada_primeiro_turno(categoria)) {
	    debug_combate("Primeiro turno: não pode usar " + categoria + " ainda.");
	    mostrar_aviso_regra("Não pode usar " + categoria + " no primeiro turno", x, y);
	    x = origem_x; y = origem_y;
	    esta_na_mao = true;
    exit;
}

    if ((categoria == "item_equipavel" || categoria == "item_consumivel") && obj_controlador.itens_usados_este_turno >= 3) {
        debug_combate("Limite de 3 itens por turno atingido.");
        mostrar_aviso_regra("Limite de 3 itens por turno", x, y);
        x = origem_x; y = origem_y;
        esta_na_mao = true;
        exit;
    }

    if (categoria == "magica" && obj_controlador.magias_usadas_este_turno >= 2) {
        mostrar_aviso_regra("Limite de 2 magias por turno", x, y);
        x = origem_x; y = origem_y; esta_na_mao = true;
        exit;
    }
    if (categoria == "construcao" && obj_controlador.construcoes_jogadas_este_turno >= 1) {
        mostrar_aviso_regra("Limite de 1 construção por turno", x, y);
        x = origem_x; y = origem_y; esta_na_mao = true;
        exit;
    }
    if (categoria == "terreno" && obj_controlador.terrenos_jogados_este_turno >= 1) {
        mostrar_aviso_regra("Limite de 1 terreno por turno", x, y);
        x = origem_x; y = origem_y; esta_na_mao = true;
        exit;
    }
	
    if (categoria == "tropa") {
        // --- código de soltar tropa que já existe, sem mudar nada ---
		depth = -100;
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
    
    if (_slot_construcao_perto != noone && obj_controlador.construcoes_jogadas_este_turno < 1 && pode_pagar_custo(custo, "jogador")) {
        pagar_custo(custo, "jogador");
        obj_controlador.construcoes_jogadas_este_turno += 1;
        
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
        mostrar_feedback("USADA", x, y, c_gray, 30);
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
    
    if (_alvo_mais_perto != noone && obj_controlador.magias_usadas_este_turno < 2 && pode_pagar_custo(custo, "jogador")) {
        pagar_custo(custo, "jogador");
        obj_controlador.magias_usadas_este_turno += 1;
        switch (efeito_tipo) {
			case "bola_fogo":
        lancar_bola_de_fogo(_alvo_mais_perto, dado_efeito, chance_queimar);
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
        registrar_descarte(id);
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
	        if (!travada || dono != "jogador") continue;
	        if (mochila <= 0) continue; // mochila cheia, não aceita mais itens
	        if (nivel_inteligencia < other.requisito_inteligencia_item) continue; // não atende ao requisito
        
	        var _dist = point_distance(x, y, other.x, other.y);
	        if (_dist < 60 && _dist < _menor_distancia) {
	            _menor_distancia = _dist;
	            _alvo = id;
	        }
	    }
    
	    if (_alvo != noone && pode_pagar_custo(custo, "jogador")) {
	        pagar_custo(custo, "jogador");
            obj_controlador.itens_usados_este_turno += 1;
        
	        if (sobrescreve_dado_dano_item > 0) {
	            // Arma alternativa: reescreve o ataque físico da tropa (ex: Espada Quebrada)
	            _alvo.dado_dano = sobrescreve_dado_dano_item;
	            _alvo.mod_dano = sobrescreve_mod_dano_item;
	            debug_combate(_alvo.nome_carta + " equipou " + nome_carta + " e agora ataca com 1D" + string(sobrescreve_dado_dano_item) + "!");
	        } else {
	            // Item comum: só soma bônus (Espada Enferrujada, Elmo de Ferro, etc)
	            _alvo.mod_dano += bonus_mod_dano_item;
	            _alvo.defesa_fisica += bonus_defesa_item;
	        }
        
	        _alvo.mochila -= 1;
        
	        var _index = array_get_index(obj_controlador.mao, id);
	        if (_index != -1) {
	            array_delete(obj_controlador.mao, _index, 1);
	            organizar_mao();
	        }
	        mostrar_feedback("USADA", x, y, c_gray, 30);
        registrar_descarte(id);
	        instance_destroy(id);
	    } else {
	        x = origem_x; y = origem_y;
	        esta_na_mao = true;
	    }
    
} else if (categoria == "item_consumivel") {
    if (string_pos("buscar_", efeito_tipo) == 1) {
        // --- Sangue Suga, Poção de Mãna (já existente) ---
        var _distancia_arrastada = point_distance(x, y, arrastar_inicio_x, arrastar_inicio_y);
        var _tipo_buscado = string_delete(efeito_tipo, 1, string_length("buscar_"));

        if (_distancia_arrastada > 80 && pode_pagar_custo(custo, "jogador")) {
            if (buscar_recurso_no_deck(_tipo_buscado, "jogador")) {
                pagar_custo(custo, "jogador");
                obj_controlador.itens_usados_este_turno += 1;
                var _index = array_get_index(obj_controlador.mao, id);
                if (_index != -1) {
                    array_delete(obj_controlador.mao, _index, 1);
                    organizar_mao();
                }
                mostrar_feedback("USADA", x, y, c_gray, 30);
                registrar_descarte(id);
                instance_destroy(id);
            } else {
                x = origem_x; y = origem_y;
                esta_na_mao = true;
            }
        } else {
            x = origem_x; y = origem_y;
            esta_na_mao = true;
        }

    } else if (efeito_tipo == "comprar_cartas") {
        // --- Baú ---
        var _distancia_arrastada = point_distance(x, y, arrastar_inicio_x, arrastar_inicio_y);

        if (_distancia_arrastada > 80 && pode_pagar_custo(custo, "jogador")) {
            pagar_custo(custo, "jogador");
            obj_controlador.itens_usados_este_turno += 1;
            comprar_varias_cartas(quantidade_efeito, "jogador");

            var _index = array_get_index(obj_controlador.mao, id);
            if (_index != -1) {
                array_delete(obj_controlador.mao, _index, 1);
                organizar_mao();
            }
            mostrar_feedback("USADA", x, y, c_gray, 30);
            registrar_descarte(id);
            instance_destroy(id);
        } else {
            x = origem_x; y = origem_y;
            esta_na_mao = true;
        }

	    } else if (efeito_tipo == "aplicar_corrosao") {
        // --- Frasco de Ácido: mira em qualquer tropa (aliada ou inimiga) ---
        var _alvo = noone;
        var _menor_distancia = 9999;

        with (obj_carta) {
            if (id == other.id) continue; // não mira em si mesma
            if (!travada) continue; // só tropas já em campo

            var _dist = point_distance(x, y, other.x, other.y);
            if (_dist < 60 && _dist < _menor_distancia) {
                _menor_distancia = _dist;
                _alvo = id;
            }
        }

        if (_alvo != noone && pode_pagar_custo(custo, "jogador")) {
            pagar_custo(custo, "jogador");
            obj_controlador.itens_usados_este_turno += 1;
            aplicar_corrosao(_alvo);

            var _index = array_get_index(obj_controlador.mao, id);
            if (_index != -1) {
                array_delete(obj_controlador.mao, _index, 1);
                organizar_mao();
            }
            mostrar_feedback("USADA", x, y, c_gray, 30);
            registrar_descarte(id);
            instance_destroy(id);
        } else {
            x = origem_x; y = origem_y;
            esta_na_mao = true;
        }

    } else if (efeito_tipo == "revirar_sangue") {
        // --- Frasco de Sangue ---
        var _distancia_arrastada = point_distance(x, y, arrastar_inicio_x, arrastar_inicio_y);

        if (_distancia_arrastada > 80 && pode_pagar_custo(custo, "jogador")) {
            if (revirar_recurso("sangue", "jogador")) {
                pagar_custo(custo, "jogador");
                obj_controlador.itens_usados_este_turno += 1;
                var _index = array_get_index(obj_controlador.mao, id);
                if (_index != -1) {
                    array_delete(obj_controlador.mao, _index, 1);
                    organizar_mao();
                }
                mostrar_feedback("USADA", x, y, c_gray, 30);
                registrar_descarte(id);
                instance_destroy(id);
            } else {
                debug_combate("Frasco de Sangue: nenhum sangue virado pra reverter.");
                x = origem_x; y = origem_y;
                esta_na_mao = true;
            }
        } else {
            x = origem_x; y = origem_y;
            esta_na_mao = true;
        }

       } else {
        // --- mira numa tropa: cura (Poção) ou buff de inteligência (Vitamina) ---
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
            obj_controlador.itens_usados_este_turno += 1;

            if (efeito_tipo == "aumentar_intelig") {
                _alvo.nivel_inteligencia += quantidade_efeito;
                debug_combate(_alvo.nome_carta + " ganhou +" + string(quantidade_efeito) + " de inteligência!");
                mostrar_feedback("INT +" + string(quantidade_efeito), _alvo.x, _alvo.y - _alvo.sprite_height * 0.45, c_aqua, 45);
            } else {
                var _cura_real = min(cura_item, _alvo.vida_maxima - _alvo.vida);
                _alvo.vida += _cura_real;
                if (_cura_real > 0) mostrar_feedback("+" + string(_cura_real), _alvo.x, _alvo.y - _alvo.sprite_height * 0.45, c_lime, 45);
            }

            var _index = array_get_index(obj_controlador.mao, id);
            if (_index != -1) {
                array_delete(obj_controlador.mao, _index, 1);
                organizar_mao();
            }
            mostrar_feedback("USADA", x, y, c_gray, 30);
            registrar_descarte(id);
            instance_destroy(id);
        } else {
            x = origem_x; y = origem_y;
            esta_na_mao = true;
        }
    }
	
	} else if (categoria == "armadilha") {
    // Arrasta pra um slot de batalha SEU, da posição 2 (meio) pra trás (3, 4).
    var _slot_armadilha = noone;
    var _menor_distancia = 9999;
    var _distancia_maxima = global.CARTA_LARGURA * 0.7;

	   with (obj_slot_batalha) {
	    if (dono_slot_armadilha(id) != "jogador") continue;
	    if (posicao < posicao_ataque()) continue; // bloqueia só posições 0 e 1 (lado inimigo)

	    var _dist = point_distance(x, y, other.x, other.y);
	    if (_dist < _distancia_maxima && _dist < _menor_distancia) {
	        _menor_distancia = _dist;
	        _slot_armadilha = id;
	    }
	}

    if (_slot_armadilha != noone && pode_pagar_custo(custo, "jogador")) {
        pagar_custo(custo, "jogador");

        armadilha_lane = _slot_armadilha.lane;
        armadilha_posicao = _slot_armadilha.posicao;
        armadilha_estado = "vigiando";

        // Efeito visual de "esconder a armadilha" no slot -- reaproveita o objeto de terreno
        // ativo só pelo visual de "cair e assentar no chão", sem afetar regras.
     var _visual_armadilha = instance_create_layer(x, y, "Instances", obj_terreno_ativo);
		_visual_armadilha.sprite_index = sprite_index;
		_visual_armadilha.escala_base = (global.CARTA_LARGURA * 0.6) / sprite_get_width(sprite_index);
		_visual_armadilha.destino_x = _slot_armadilha.x;
		_visual_armadilha.destino_y = _slot_armadilha.y;
		_visual_armadilha.origem_x = x;
		_visual_armadilha.origem_y = y;
		_visual_armadilha.angulo_final = 0;
		_visual_armadilha.entrada_duracao = 20;
		_visual_armadilha.depth = 50;
		_visual_armadilha.alpha_visual = 0.5;

		armadilha_visual_id = _visual_armadilha.id; // guarda referência pra poder destruir depois

        debug_combate(nome_carta + " foi escondida na lane " + string(armadilha_lane) + ", posição " + string(armadilha_posicao) + ".");

        // Volta pra mão como "ativa" -- não é destruída, some do campo e reaparece na mão
        esta_na_mao = true;
        travada = false;
        x = origem_x;
        y = origem_y;
    } else {
        x = origem_x; y = origem_y;
        esta_na_mao = true;
    }

	} else if (categoria == "terreno") {
    var _distancia_arrastada = point_distance(x, y, arrastar_inicio_x, arrastar_inicio_y);

    if (_distancia_arrastada > 80 && obj_controlador.terrenos_jogados_este_turno < 1 && pode_pagar_custo(custo, "jogador")) {
        pagar_custo(custo, "jogador");
        obj_controlador.terrenos_jogados_este_turno += 1;

        var _slot_terreno_destino = noone;
        with (obj_slot_terreno) {
            _slot_terreno_destino = id;
            if (ocupado && terreno_atual != noone && instance_exists(terreno_atual)) {
                instance_destroy(terreno_atual);
            }
        }

        obj_controlador.terreno_bonus_defesa = bonus_defesa_global;
        obj_controlador.terreno_ativo = efeito_terreno;

       if (_slot_terreno_destino != noone) {
		    var _terreno_visual = instance_create_layer(x, y, "Instances", obj_terreno_ativo);
		    _terreno_visual.sprite_index = sprite_index;

		    _terreno_visual.escala_base = global.TERRENO_LARGURA_ALVO / sprite_get_height(sprite_index);

		    _terreno_visual.destino_x = _slot_terreno_destino.x;
		    _terreno_visual.destino_y = _slot_terreno_destino.y;
		    _terreno_visual.origem_x = x;
		    _terreno_visual.origem_y = y;

		    _slot_terreno_destino.ocupado = true;
		    _slot_terreno_destino.terreno_atual = _terreno_visual.id;
		}

        // Anúncio dramático na tela
        obj_controlador.terreno_anuncio_texto = string_upper(nome_carta);
        obj_controlador.terreno_anuncio_timer = obj_controlador.terreno_anuncio_duracao;

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
            iniciar_animacao_bencao_maldicao(categoria, nome_carta);
            
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

#region Efeito de voo (só tropas com Voar, e só enquanto estão travadas em campo)
if (travada && categoria == "tropa" && tem_habilidade(id, "voar")) {
    voo_timer += 0.008; // velocidade geral do ciclo completo -- ajuste pra mais rápido/lento

    var _duracao_subida = 0.10; // fração do ciclo gasta subindo -- menor = batida mais seca e rápida
    var _progresso_ciclo = frac(voo_timer); // sempre entre 0 e 1, reinicia a cada volta

    var _onda_voo;
    if (_progresso_ciclo < _duracao_subida) {
        // SOBE RÁPIDO: dispara do chão e desacelera perto do topo, como o impulso de uma batida
        var _p = _progresso_ciclo / _duracao_subida;
        _onda_voo = 1 - power(1 - _p, 2);
	} else {
	    // DESCE DEVAGAR: sai devagar do topo e vai ganhando velocidade aos poucos
	    var _p = (_progresso_ciclo - _duracao_subida) / (1 - _duracao_subida);
	    _onda_voo = 1 - (_p * _p); // agora começa lento (perto do topo) e acelera no fim
	}

    escala_voo = 1 + _onda_voo * 0.10; // intensidade do efeito -- ajuste esse 0.06
} else {
    escala_voo = 1;
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
