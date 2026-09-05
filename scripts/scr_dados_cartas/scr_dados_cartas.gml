// =============================================================================
// KARTHA — script principal
// Todas as funções globais do jogo, organizadas por assunto.
// Use o painel de navegação de #region do GameMaker (ou Ctrl+clique no nome
// de uma região na lista de funções) pra pular direto pro trecho que precisa.
// =============================================================================

#region Debug / Configuração
// Liga/desliga os logs de rastreamento de combate (rolagens, dano, habilidades).
// Deixe true enquanto ainda estiver ajustando balanceamento/bugs;
// mude pra false quando quiser um console limpo pra jogar de verdade.
// (o valor inicial é definido no Create Event do obj_controlador)
function debug_combate(_msg) {
    if (global.DEBUG_COMBATE) {
        show_debug_message(_msg);
    }

    // Histórico curto e visível na partida, independente do console de debug.
    if (instance_exists(obj_controlador)) {
        var _controle = instance_find(obj_controlador, 0);
        if (!variable_instance_exists(_controle, "historico_combate") || !is_array(_controle.historico_combate)) {
            _controle.historico_combate = [];
        }
        if (!variable_instance_exists(_controle, "max_historico_combate") || _controle.max_historico_combate < 15) {
            _controle.max_historico_combate = 15;
        }
        array_push(_controle.historico_combate, _msg);
        while (array_length(_controle.historico_combate) > _controle.max_historico_combate) {
            _controle.historico_combate = array_delete(_controle.historico_combate, 0, 1);
        }
    }
}
#endregion

#region Tabuleiro — grade e posições
// Grade central da room: 3 lanes (colunas) por 5 posições (linhas).
// posicao: 0 = base inimiga, 1 = assalto do jogador, 2 = MEIO (centro do combate),
//          3 = assalto do inimigo, 4 = base do jogador.
// Identifica lane/posicao de cada obj_slot_batalha automaticamente pela posição na room.
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

// Organiza a lane dos slots de construção SEPARADAMENTE por dono (jogador/inimigo).
// Precisa ser por dono porque a numeração não pode se misturar entre os dois lados,
// senão não bate com as lanes do campo de batalha na hora de mirar um ataque.
function ordenar_lane_por_dono(_obj, _dono_alvo) {
    var _lista = [];
    with (_obj) {
        if (dono == _dono_alvo) array_push(_lista, id);
    }

    var _n = array_length(_lista);
    for (var i = 0; i < _n - 1; i++) {
        for (var j = 0; j < _n - i - 1; j++) {
            if (_lista[j].x > _lista[j+1].x) {
                var _temp = _lista[j];
                _lista[j] = _lista[j+1];
                _lista[j+1] = _temp;
            }
        }
    }

    for (var i = 0; i < _n; i++) {
        _lista[i].lane = i;
    }
}

function posicao_entrada(_dono) {
    return (_dono == "jogador") ? 4 : 0;
}

function posicao_ataque() {
    return 2; // o MEIO — tropas podem combater aqui, mas ainda não atingem o castelo
}

function direcao_avanco(_dono) {
    return (_dono == "jogador") ? -1 : 1;
}

// Para causar dano direto ao castelo, a tropa precisa sair do meio e avançar
// mais uma casa. A regra é espelhada para jogador e inimigo.
function posicao_assalto(_dono) {
    return posicao_ataque() + direcao_avanco(_dono);
}

// Cada lado pode manter no máximo uma tropa em cada coluna, independentemente
// da posição em que ela esteja. Tropas morrendo já não bloqueiam a coluna.
function buscar_tropa_na_coluna(_lane, _dono, _ignorar = noone) {
    var _resultado = noone;
    with (obj_carta) {
        if (id != _ignorar && travada && !morrendo && categoria == "tropa"
            && lane_atual == _lane && dono == _dono) {
            _resultado = id;
            break;
        }
    }
    return _resultado;
}

function total_posicoes_batalha() {
    return 5;
}
#endregion

#region Dados das cartas — Tropas
function criar_dados_esquilo() {
    return {
        categoria: "tropa",
        nome: "Esquilo",
        sprite_carta: noone,
		vida: 5, 
        sacrificio: 0, 
        dado_dano: 6, 
        mod_dano: 0,
        dado_dano_magico: 0,
        mod_dano_magico: 0,
        inteligencia: 1,
		mochila: 2,
        defesa_fisica: 0, 
        defesa_magica: 0,
        custo: noone,
        habilidades: [],
		evolucao: criar_dados_esquilo_evoluido
    };
}

function criar_dados_lobo() {
    return {
        categoria: "tropa",
        nome: "Lobo",
        sprite_carta: noone,
		vida: 12, 
        sacrificio: 1, 
        dado_dano: 8, 
        mod_dano: 1,
        dado_dano_magico: 0,
        mod_dano_magico: 0,
        inteligencia: 2,
		mochila: 2,
        defesa_fisica: 1, 
        defesa_magica: 0,
        custo: { tipo: "sangue", quantidade: 1 },
        habilidades: [],
		evolucao: criar_dados_lobo_evoluido
    };
}

function criar_dados_urso() {
    return {
        categoria: "tropa",
        nome: "Urso",
        sprite_carta: noone,
		vida: 14, 
        sacrificio: 2, 
        dado_dano: 12, 
        mod_dano: 2,
        dado_dano_magico: 0,
        mod_dano_magico: 0,
        inteligencia: 2,
		mochila: 3,
        defesa_fisica: 3, 
        defesa_magica: 0,
        custo: { tipo: "ossos", quantidade: 2 },
		habilidades: []
    };
}
	
function criar_dados_esquilo_evoluido() {
    return {
        categoria: "tropa",
        nome: "Esquilo Gigante",
        sprite_carta: noone, // troca quando tiver a arte
		vida: 12, 
        sacrificio: 0, 
        dado_dano: 10, 
        mod_dano: 1,
        dado_dano_magico: 0,
        mod_dano_magico: 0,
        inteligencia: 1,
		mochila: 2,
        defesa_fisica: 1, 
        defesa_magica: 0,
        custo: { tipo: "ossos", quantidade: 1 },
        habilidades: [],
        evolucao: noone // forma final, não evolui mais
    };
}

function criar_dados_lobo_evoluido() {
    return {
        categoria: "tropa",
        nome: "Lobo Alfa",
        sprite_carta: noone,
		vida: 20, 
        sacrificio: 1, 
        dado_dano: 10, 
        mod_dano: 2,
        dado_dano_magico: 0,
        mod_dano_magico: 0,
        inteligencia: 2,
		mochila: 2,
        defesa_fisica: 2, 
        defesa_magica: 0,
        custo: { tipo: "sangue", quantidade: 1 },
        habilidades: ["golpe_duplo"],
        evolucao: noone
    };
}	

function criar_dados_slime() {
    return { categoria: "tropa", 
		nome: "Slime", 
		sprite_carta: spr_carta_slime, 
		vida: 14, 
        sacrificio: 0, 
        dado_dano: 4, 
		qtd_dados_dano: 2,
        mod_dano: 2,
        dado_dano_magico: 0,
        mod_dano_magico: 0,
        inteligencia: 0,
		mochila: 3,
        defesa_fisica: 0, 
        defesa_magica: 0,
		custo: noone, 
		habilidades: ["mitose"], 
		mitose: criar_dados_slimet,
        evolucao: criar_dados_slime_digestao,
		vida_pos_x: 0.11,
		vida_pos_y: 0.06
	};
}

function criar_dados_slimet() {
    return { categoria: "tropa", 
		nome: "Slimet", 
		sprite_carta: spr_carta_slimet, 
		vida: 8, 
        sacrificio: 0, 
        dado_dano: 4, 
        mod_dano: 1,
        dado_dano_magico: 0,
        mod_dano_magico: 0,
        inteligencia: 0,
		mochila: 1,
        defesa_fisica: 0, 
        defesa_magica: 0,
		custo: noone, 
		habilidades: [] };
}
	
function criar_dados_slime_digestao() {
    return {
        categoria: "tropa",
        nome: "Slime Digestão",
        sprite_carta: noone,
        vida: 22,
        sacrificio: 0,
        dado_dano: 12,
        qtd_dados_dano: 1,
        mod_dano: 2,
        dado_dano_magico: 0,
        mod_dano_magico: 0,
        inteligencia: 1,
        mochila: 5,
        defesa_fisica: 2,
        defesa_magica: 0,
        custo: [{ tipo: "ossos", quantidade: 2 }, { tipo: "qualquer", quantidade: 3 }],
        habilidades: ["digestao", "roubo"],
        evolucao: noone
    };
}

// Forma de evolução pronta para ser ligada à futura carta base Zumbi.
function criar_dados_carnica_ambulante() {
    return {
        categoria: "tropa",
        nome: "Carniça Ambulante",
        sprite_carta: noone,
        vida: 18,
        sacrificio: 0,
        dado_dano: 4,
        qtd_dados_dano: 3,
        mod_dano: 0,
        dado_dano_magico: 0,
        mod_dano_magico: 0,
        inteligencia: 2,
        mochila: 0,
        defesa_fisica: 1,
        defesa_magica: 0,
        custo: [{ tipo: "sangue", quantidade: 3 }, { tipo: "ossos", quantidade: 3 }],
        habilidades: ["carnica_frenetica", "ferida_exposta"],
        evolucao: noone
    };
}

function criar_dados_mimic() {
    return { categoria: "tropa", 
		nome: "Mimic", 
		sprite_carta: spr_carta_mimic, 
		vida: 16, 
        sacrificio: 0, 
        dado_dano: 10, 
        mod_dano: 0,
        dado_dano_magico: 4,
        mod_dano_magico: 1,
        inteligencia: 1,
		mochila: 3,
        defesa_fisica: 3, 
        defesa_magica: 0,
		custo: [{ tipo: "sucata", quantidade: 1 },
				{ tipo: "sangue", quantidade: 1}],
		habilidades: ["imitacao"],
		vida_pos_x: 0.11,
		vida_pos_y: 0.06
	};
}
	
function criar_dados_olho_demonio() {
    return { categoria: "tropa", 
		nome: "Olho Demônio", 
		sprite_carta: spr_carta_olho_demonio, 
		vida: 8, 
        sacrificio: 0, 
        dado_dano: 6, 
        mod_dano: 0,
        dado_dano_magico: 6,
        mod_dano_magico: 0,
        inteligencia: 1,
		mochila: 1,
        defesa_fisica: 0, 
        defesa_magica: 0,
		custo: [{ tipo: "mana", quantidade: 1 }, 
				{ tipo: "sangue", quantidade: 1}],
		habilidades: ["alcance_magico", "voar"] };
}
	
function criar_dados_mago_da_sombra() {
    return { categoria: "tropa", 
		nome: "Mago da Sombra", 
		sprite_carta: spr_carta_mago_da_sombra, 
		vida: 20, 
        sacrificio: 0, 
        dado_dano: 12, 
        mod_dano: 0,
        dado_dano_magico: 0,
        mod_dano_magico: 0,
        inteligencia: 2,
		mochila: 2,
        defesa_fisica: 0, 
        defesa_magica: 2,
		custo: { tipo: "mana", quantidade: 2 }, 
		habilidades: ["sombra_translucida"] };
}
	
function criar_dados_gato_mago() {
    return { categoria: "tropa", 
		nome: "Gato Mago", 
		sprite_carta: spr_carta_gato_mago, 
		vida: 15, 
        sacrificio: 0, 
        dado_dano: 4, 
        mod_dano: 1,
        dado_dano_magico: 4,
        mod_dano_magico: 1,
        inteligencia: 3,
		mochila: 2,
        defesa_fisica: 0, 
        defesa_magica: 2,
		custo: [{ tipo: "mana", quantidade: 2 },
				{ tipo: "sangue", quantidade: 1 }],
		habilidades: ["visao_do_veu"],
		def_magico_pos_x: 0.62, 
		def_magico_pos_y: 0.92 };
}
	
function criar_dados_goblin() {
    return { categoria: "tropa", 
		nome: "Goblin", 
		sprite_carta: spr_carta_goblin, 
		vida: 10, 
        sacrificio: 0, 
        dado_dano: 8, 
        mod_dano: 0,
        dado_dano_magico: 0,
        mod_dano_magico: 0,
        inteligencia: 1,
		mochila: 2,
        defesa_fisica: 2, 
        defesa_magica: 0, 
		custo: { tipo: "sangue", quantidade: 2 }, 
		habilidades: ["golpe_duplo"],
		def_pos_x: 0.37, 
		def_pos_y: 0.92 
	};
}
	
function criar_dados_hollow_jack() {
    return { categoria: "tropa", 
        nome: "Hollow Jack", 
        sprite_carta: spr_carta_hollow_jack, 
        vida: 31, 
        sacrificio: 1, 
        dado_dano: 12, 
        mod_dano: 2,
        dado_dano_magico: 8,
        mod_dano_magico: 1,
        inteligencia: 1,
		mochila: 2,
        defesa_fisica: 1, 
        defesa_magica: 2, 
        custo: [{ tipo: "mana", quantidade: 3 }, 
				{ tipo: "ossos", quantidade: 1 }],
        habilidades: ["alcance_magico", "olhar_vazio"]
    };
}
	
function criar_dados_esqueleto() {
    return { categoria: "tropa", 
		nome: "Esqueleto", 
		sprite_carta: spr_carta_esqueleto, 
		vida: 14, 
        sacrificio: 0, 
        dado_dano: 8, 
        mod_dano: 0,
        dado_dano_magico: 0,
        mod_dano_magico: 0,
        inteligencia: 1,
		mochila: 2,
        defesa_fisica: 0, 
        defesa_magica: 0, 
		custo: { tipo: "ossos", quantidade: 1 }, 
		habilidades: [] };
}
	
function criar_dados_shroomilin() {
    return { categoria: "tropa", 
		nome: "Shroomilin", 
		sprite_carta: spr_carta_shroomilin, 
		vida: 10, 
        sacrificio: 0, 
        dado_dano: 4,
		qtd_dados_dano: 2,
        mod_dano: 2,
        dado_dano_magico: 0,
        mod_dano_magico: 0,
        inteligencia: 0,
		mochila: 1,
        defesa_fisica: 2, 
        defesa_magica: 0,
		custo: noone, 
		habilidades: ["tiro_burro"],
		vida_pos_x: 0.11,
		vida_pos_y: 0.06,
		def_pos_x: 0.87, 
		def_pos_y: 0.92
	};
}
	
function desenhar_stat(_carta, _valor, _pos_x, _pos_y, _x, _y_desenho, _rotacao_total, _escala_final, _escala_fallback, _ja_e_texto = false) {
    if (!_ja_e_texto && _valor == 0) return;

    var _texto = _ja_e_texto ? _valor : string(_valor);
    var _offset_x = -_carta.sprite_width/2 + (_carta.sprite_width * _pos_x);
    var _offset_y = -_carta.sprite_height/2 + (_carta.sprite_height * _pos_y);

    var _dist = point_distance(0, 0, _offset_x, _offset_y);
    var _dir = point_direction(0, 0, _offset_x, _offset_y);
    var _stat_x = _x + lengthdir_x(_dist, _dir + _rotacao_total);
    var _stat_y = _y_desenho + lengthdir_y(_dist, _dir + _rotacao_total);

    var _escala_usada = _carta.tem_arte_propria ? _escala_final : _escala_fallback;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_carta.tem_arte_propria ? c_black : c_white);
    draw_text_transformed(_stat_x, _stat_y, _texto, _escala_usada, _escala_usada, _rotacao_total);
    draw_set_color(c_white);
}
	
function desenhar_stat_preview(_carta, _valor, _pos_x, _pos_y, _centro_x, _centro_y, _largura_real, _altura_real, _escala_preview, _escala_stats_preview, _ja_e_texto = false) {
    if (!_ja_e_texto && _valor == 0) return;

    var _texto = _ja_e_texto ? _valor : string(_valor);
    var _offset_x = (-_largura_real/2 + (_largura_real * _pos_x)) * _escala_preview;
    var _offset_y = (-_altura_real/2 + (_altura_real * _pos_y)) * _escala_preview;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_carta.tem_arte_propria ? c_black : c_white);
    draw_text_transformed(_centro_x + _offset_x, _centro_y + _offset_y, _texto, _escala_stats_preview, _escala_stats_preview, 0);
    draw_set_color(c_white);
}
#endregion

#region Dados das cartas — Recursos
function criar_dados_recurso_sangue() {
    return { categoria: "recurso", nome: "Sangue", tipo_recurso: "sangue", sprite_carta: spr_recurso_sangue };
}

function criar_dados_recurso_ossos() {
    return { categoria: "recurso", nome: "Ossos", tipo_recurso: "ossos", sprite_carta: spr_recurso_ossos };
}

function criar_dados_recurso_sucata() {
    return { categoria: "recurso", nome: "Sucata", tipo_recurso: "sucata", sprite_carta: spr_recurso_sucata };
}

function criar_dados_recurso_mana() {
    return { categoria: "recurso", nome: "Mana", tipo_recurso: "mana", sprite_carta: spr_recurso_mana };
}
#endregion

#region Dados das cartas — Construção, Magias, Itens, Armadilha, Terreno
function criar_dados_construcao_torre() {
    return {
        categoria: "construcao",
        nome: "Torre de Vigia",
        sprite_carta: noone,
        vida: 20,
        custo: { tipo: "sucata", quantidade: 1 },
        efeito_construcao: "artilharia",
        dado_efeito: 6
    };
}
	
function criar_dados_construcao_hemodrenario() {
    return {
        categoria: "construcao",
        nome: "Hemodrenário",
        sprite_carta: spr_carta_hemodrenario, // troca quando tiver a arte
        vida: 12,
        custo: [{ tipo: "sangue", quantidade: 1 },
				{ tipo: "sucata", quantidade: 2}],
        efeito_construcao: "hemodrenario"
    };
}

function criar_dados_construcao_maquina_ima() {
    return {
        categoria: "construcao",
        nome: "Máquina Imã",
        sprite_carta: spr_carta_maquina_ima,
        vida: 12,
        custo: { tipo: "sucata", quantidade: 3 },
        efeito_construcao: "maquina_ima"
    };
}

function criar_dados_magica_dados_manipulados() {
    return {
        categoria: "magica",
        nome: "Dados Manipulados",
        sprite_carta: spr_carta_dados_manipulados,
        custo: [{ tipo: "mana", quantidade: 2 }, { tipo: "qualquer", quantidade: 1 }],
        efeito_tipo: "dados_manipulados",
        dado_efeito: 4
    };
}

function criar_dados_magica_refracao_temporal() {
    return { categoria: "magica", nome: "Refração Temporal", sprite_carta: noone,
        custo: noone, efeito_tipo: "refracao_temporal" };
}

function criar_dados_magica_eutanasia() {
    return { categoria: "magica", nome: "Eutanásia", sprite_carta: noone,
        custo: noone, efeito_tipo: "eutanasia" };
}

function criar_dados_magica_bloqueio_recurso() {
    return { categoria: "magica", nome: "Bloqueio de Recurso", sprite_carta: noone,
        custo: noone, efeito_tipo: "bloqueio_recurso" };
}

function criar_dados_magica_bola_fogo() {
    return {
        categoria: "magica",
        nome: "Bola de Fogo",
        sprite_carta: spr_bola_de_fogo,
        custo: { tipo: "mana", quantidade: 2 },
        dado_efeito: 8,       // 1D8 de dano
        chance_queimar: 1     // chance de aplicar queimado (1 = sempre, por enquanto)
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
        sprite_carta: spr_carta_escudo_madeira,
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
	
function criar_dados_item_bau() {
    return {
        categoria: "item_consumivel",
        nome: "Baú",
        sprite_carta: spr_carta_bau,          // importe carta_baú.png com esse nome
        custo: noone,
        efeito_tipo: "comprar_cartas",
        quantidade_efeito: 3
    };
}

function criar_dados_item_frasco_sangue() {
    return {
        categoria: "item_consumivel",
        nome: "Frasco de Sangue",
        sprite_carta: spr_carta_frasco_sangue, // importe carta_frasco_de_sangue.png
        custo: noone,
        efeito_tipo: "revirar_sangue"
    };
}	

function criar_dados_item_sangue_suga() {
    return {
        categoria: "magica",
        nome: "Sangue Suga",
        sprite_carta: spr_carta_sangue_suga,
        custo: noone,
        efeito_tipo: "buscar_sangue"
    };
}

function criar_dados_item_pocao_mana() {
    return {
        categoria: "item_consumivel",
        nome: "Poção de Mãna",
        sprite_carta: spr_carta_pocao_mana,
        custo: noone,
        efeito_tipo: "buscar_mana"
    };
}
	
function criar_dados_item_elmo_ferro() {
    return {
        categoria: "item_equipavel",
        nome: "Elmo de Ferro",
        sprite_carta: spr_carta_elmo_ferro,   // importe carta_ielmo_de_ferro.png
        custo: { tipo: "sucata", quantidade: 1 },
        bonus_mod_dano: 0,
        bonus_defesa: 1
    };
}
	
function criar_dados_item_frasco_acido() {
    return {
        categoria: "item_consumivel",
        nome: "Frasco de Ácido",
        sprite_carta: spr_carta_frasco_acido,   // importe carta_frasco_de_ácido.png
        custo: noone,
        efeito_tipo: "aplicar_corrosao"
    };
}
	
function criar_dados_item_vitamina_cerebro() {
    return {
        categoria: "item_consumivel",
        nome: "Vitamina de Cérebro",
        sprite_carta: spr_carta_vitamina_cerebro,  // importe carta_vitamina_de_cerebro.png
        custo: noone,
        efeito_tipo: "aumentar_intelig",
        quantidade_efeito: 1
    };
}
	
function criar_dados_item_grimorio_iniciante() {
    return {
        categoria: "item_equipavel",
        nome: "Grimório Iniciante",
        sprite_carta: spr_carta_grimorio_iniciante,
        custo: noone,
        requisito_inteligencia: 1,
        bonus_mod_dano: 0,
        bonus_defesa: 0,
        efeito_item: "grimorio_iniciante"
    };
}

function criar_dados_item_espada_quebrada() {
    return {
        categoria: "item_equipavel",
        nome: "Espada Quebrada",
        sprite_carta: spr_carta_espada_quebrada,   // importe carta_espada_quebrada.png
        custo: noone,
        requisito_inteligencia: 1,
        sobrescreve_dado_dano: 8,   // 1d8
        sobrescreve_mod_dano: 0,
        bonus_mod_dano: 0,          // itens sem sobrescrita continuam usando esses (Espada Enferrujada, Elmo)
        bonus_defesa: 0
    };
}

function criar_dados_armadilha_urso() {
    return {
        categoria: "armadilha",
        nome: "Armadilha de Urso",
        sprite_carta: spr_armadilha_de_urso,
        custo: noone,
        dado_efeito: 6,
        qtd_dados_efeito: 2
    };
}

function criar_dados_armadilha_loucura_mutua() {
    return { categoria: "armadilha", nome: "Loucura Mútua", sprite_carta: noone,
        custo: noone, efeito_tipo: "loucura_mutua", dado_efeito: 0, qtd_dados_efeito: 0 };
}

function criar_dados_armadilha_raizes_espinhosas() {
    return { categoria: "armadilha", nome: "Raízes Espinhosas", sprite_carta: noone,
        custo: noone, efeito_tipo: "raizes_espinhosas", dado_efeito: 0, qtd_dados_efeito: 0 };
}

function criar_dados_armadilha_destrocos() {
    return { categoria: "armadilha", nome: "Destroços", sprite_carta: noone,
        custo: noone, efeito_tipo: "destrocos", dado_efeito: 4, qtd_dados_efeito: 1 };
}

function criar_dados_terreno_planicies_profanas() {
    return { categoria: "terreno", nome: "Planícies Profanas", sprite_carta: noone,
        custo: noone, bonus_defesa_global: 0, efeito_terreno: "planicies_profanas" };
}

function criar_dados_terreno_pantano() {
    return {
        categoria: "terreno",
        nome: "Pântano Sombrio",
        sprite_carta: spr_carta_pantano_sombrio,
        custo: { tipo: "ossos", quantidade: 1 },
        bonus_defesa_global: -1 // reduz a defesa de todo mundo (terreno traiçoeiro)
    };
}
	
function criar_dados_terreno_cemiterio() {
    return {
        categoria: "terreno",
        nome: "Cemitério",
        sprite_carta: spr_carta_cemiterio,   // importe cemiterio_carta.png
        custo: { tipo: "ossos", quantidade: 3 },
        bonus_defesa_global: 0,   // esse terreno não usa o bônus genérico, é condicional
        efeito_terreno: "cemiterio"
    };
}
	
// Infere se um slot de batalha é elegível pra colocar armadilha: qualquer posição
// do MEIO (2) pra trás no seu lado (3, 4). O MEIO conta porque é passagem obrigatória
// de qualquer tropa inimiga que avança.
function dono_slot_armadilha(_slot) {
    if (_slot.posicao < posicao_ataque()) return "inimigo"; // posições 0, 1 -- não pode
    return "jogador"; // posições 2 (meio), 3, 4 -- pode colocar armadilha
}

// Cada espaço aceita apenas uma armadilha ativa, independentemente do dono.
function slot_tem_armadilha(_lane, _posicao, _ignorar = noone) {
    var _encontrou = false;
    with (obj_carta) {
        if (id != _ignorar && categoria == "armadilha"
            && armadilha_estado != "" && armadilha_estado != "resolvendo"
            && armadilha_lane == _lane && armadilha_posicao == _posicao) {
            _encontrou = true;
            break;
        }
    }
    return _encontrou;
}

// Remove a armadilha usada do campo/mão e registra seu descarte.
function consumir_armadilha_ativada(_carta_armadilha) {
    if (!instance_exists(_carta_armadilha)) return;

    if (_carta_armadilha.armadilha_visual_id != noone
        && instance_exists(_carta_armadilha.armadilha_visual_id)) {
        instance_destroy(_carta_armadilha.armadilha_visual_id);
    }

    var _index = array_get_index(obj_controlador.mao, _carta_armadilha.id);
    if (_index != -1) {
        array_delete(obj_controlador.mao, _index, 1);
        organizar_mao();
    }

    registrar_descarte(_carta_armadilha);
    instance_destroy(_carta_armadilha);
}

// A ativação continua manual: quando a armadilha fica pronta, o jogador clica nela.
// O dano usa a quantidade de D6 configurada na carta e Sangramento depende da moeda.
function ativar_armadilha(_carta_armadilha) {
    if (!instance_exists(_carta_armadilha)) return;
    if (_carta_armadilha.armadilha_estado != "pronta") return;

    var _slot_vigiado = buscar_slot(_carta_armadilha.armadilha_lane, _carta_armadilha.armadilha_posicao);
    if (_slot_vigiado == noone || !_slot_vigiado.ocupado) return;

    var _alvo = _slot_vigiado.carta_atual;
    if (!instance_exists(_alvo) || _alvo.dono == _carta_armadilha.dono) {
        _carta_armadilha.armadilha_estado = "vigiando";
        return;
    }

    if (_alvo.imune_armadilha || tem_habilidade(_alvo, "voar")) {
        debug_combate(_alvo.nome_carta + " é imune e evitou a " + _carta_armadilha.nome_carta + "!");
        if (_alvo.imune_armadilha && !tem_habilidade(_alvo, "voar")) {
            _alvo.imune_armadilha_usos = max(0, _alvo.imune_armadilha_usos - 1);
            if (_alvo.imune_armadilha_usos <= 0) _alvo.imune_armadilha = false;
            mostrar_aviso_regra("Proteção da Visão do Véu consumida", _alvo.x, _alvo.y);
            // Consome também o marcador visual, liberando o espaço sem deixar uma armadilha fantasma.
            consumir_armadilha_ativada(_carta_armadilha);
        } else {
            mostrar_aviso_regra("Tropas com Voar não ativam esta armadilha", _alvo.x, _alvo.y);
            _carta_armadilha.armadilha_estado = "vigiando";
        }
        return;
    }

    _carta_armadilha.armadilha_estado = "resolvendo";
    _carta_armadilha.visible = false;
    var _index_mao = array_get_index(obj_controlador.mao, _carta_armadilha.id);
    if (_index_mao != -1) {
        array_delete(obj_controlador.mao, _index_mao, 1);
        organizar_mao();
    }

    criar_flash(_alvo.x, _alvo.y, 45);

    var _qtd_dados = max(1, _carta_armadilha.qtd_dados_efeito);
    var _dados_rolagem = {
        armadilha: _carta_armadilha,
        alvo: _alvo,
        quantidade_dados: _qtd_dados,
        dados_resolvidos: 0,
        dano_total: 0
    };

    var _callback_dado = method(_dados_rolagem, function(_resultado) {
        dano_total += _resultado;
        dados_resolvidos += 1;
        if (dados_resolvidos < quantidade_dados) return;

        if (!instance_exists(alvo)) {
            consumir_armadilha_ativada(armadilha);
            return;
        }

        alvo.vida -= dano_total;
        aplicar_flash_dano(alvo);
        mostrar_dano_tropa(alvo, dano_total);
        debug_combate("Armadilha de Urso causou " + string(dano_total) + " de dano com " + string(quantidade_dados) + "D6 em " + alvo.nome_carta + ".");

        if (alvo.vida <= 0) {
            destruir_tropa(alvo);
            consumir_armadilha_ativada(armadilha);
            return;
        }

        var _dados_moeda = { armadilha: armadilha, alvo: alvo };
        jogar_moeda_visual(armadilha.x, armadilha.y, alvo.x, alvo.y - alvo.sprite_height/2 - 20,
            method(_dados_moeda, function(_resultado_moeda) {
                if (instance_exists(alvo)) {
                    if (_resultado_moeda == 1) {
                        var _aplicou = aplicar_sangramento(alvo);
                        mostrar_feedback(_aplicou ? "CARA: SANGRANDO" : "CARA: CONDIÇÃO BLOQUEADA", alvo.x, alvo.y, _aplicou ? c_red : c_gray, 65);
                        debug_combate(_aplicou ? alvo.nome_carta + " ficou SANGRANDO pela Armadilha de Urso!" : "Sangramento bloqueado por outra condição ativa.");
                    } else {
                        mostrar_feedback("COROA: SEM SANGRAMENTO", alvo.x, alvo.y, c_white, 55);
                        debug_combate("Armadilha de Urso: coroa, Sangramento não foi aplicado.");
                    }
                }
                consumir_armadilha_ativada(armadilha);
            })
        );
    });

    for (var i = 0; i < _qtd_dados; i++) {
        var _resultado_dado = irandom_range(1, _carta_armadilha.dado_efeito);
        var _offset_dado = (i - ((_qtd_dados - 1) / 2)) * 110;
        var _atraso_dado = (i == 0) ? 0 : i * irandom_range(8, 15);
        var _duracao_dado = 78 + irandom_range(-8, 18);
        rolar_dado_visual(
            _carta_armadilha.x + _offset_dado * 0.22,
            _carta_armadilha.y,
            _alvo.x + _offset_dado,
            _alvo.y - _alvo.sprite_height/2 - 18,
            _carta_armadilha.dado_efeito,
            _resultado_dado,
            _callback_dado,
            0,
            _atraso_dado,
            _duracao_dado,
            _carta_armadilha.dono
        );
    }
}
function buscar_armadilha_de_gatilho(_dono, _lane, _efeito) {
    var _resultado = noone;
    with (obj_carta) {
        if (categoria == "armadilha" && dono == _dono && armadilha_estado == "vigiando"
            && armadilha_lane == _lane && efeito_tipo == _efeito) {
            _resultado = id;
            break;
        }
    }
    return _resultado;
}

function ativar_raizes_espinhosas_ao_mover(_tropa) {
    if (!instance_exists(_tropa) || _tropa.vida >= 10 || tem_habilidade(_tropa, "voar")) return false;
    var _dono_armadilha = (_tropa.dono == "jogador") ? "inimigo" : "jogador";
    var _armadilha = buscar_armadilha_de_gatilho(_dono_armadilha, _tropa.lane_atual, "raizes_espinhosas");
    if (_armadilha == noone) return false;
    mostrar_feedback("RAÍZES: MOVIMENTO CANCELADO", _tropa.x, _tropa.y - 42, c_lime, 70);
    aplicar_envenenado(_tropa);
    _tropa.moveu_este_turno = true;
    consumir_armadilha_ativada(_armadilha);
    return true;
}

function ativar_loucura_mutua(_tropa_afetada) {
    if (!instance_exists(_tropa_afetada) || _tropa_afetada.lane_atual < 0) return false;
    var _armadilha = buscar_armadilha_de_gatilho(_tropa_afetada.dono, _tropa_afetada.lane_atual, "loucura_mutua");
    if (_armadilha == noone) return false;
    var _alvo = noone;
    var _valor = -1;
    with (obj_carta) {
        if (!travada || dono == _tropa_afetada.dono || lane_atual != _tropa_afetada.lane_atual) continue;
        if (vida > _valor) { _valor = vida; _alvo = id; }
    }
    if (_alvo == noone) return false;
    aplicar_condicao(_alvo, "loucura", -1, 0, false);
    mostrar_feedback("LOUCURA MÚTUA", _alvo.x, _alvo.y - 42, c_purple, 70);
    consumir_armadilha_ativada(_armadilha);
    return true;
}

function ativar_destrocos_construcao(_dono, _lane, _origem_x, _origem_y) {
    var _armadilha = buscar_armadilha_de_gatilho(_dono, _lane, "destrocos");
    if (_armadilha == noone) return false;
    var _alvos = [];
    with (obj_carta) {
        if (travada && dono != _dono && lane_atual == _lane) array_push(_alvos, id);
    }
    consumir_armadilha_ativada(_armadilha);
    for (var i = 0; i < array_length(_alvos); i++) {
        var _alvo = _alvos[i];
        if (!instance_exists(_alvo)) continue;
        var _ctx = { alvo: _alvo };
        var _resultado = irandom_range(1, 4);
        rolar_dado_visual(_origem_x, _origem_y, _alvo.x, _alvo.y - 35, 4, _resultado,
            method(_ctx, function(_dano) {
                if (!instance_exists(alvo)) return;
                alvo.vida -= _dano;
                aplicar_flash_dano(alvo);
                mostrar_dano_tropa(alvo, _dano);
                if (alvo.vida <= 0) destruir_tropa(alvo);
            }), 0, i * 8, -1, _dono);
    }
    mostrar_feedback("DESTROÇOS", _origem_x, _origem_y - 35, c_yellow, 60);
    return true;
}

#endregion

#region Dados das cartas - Bençãos e Maldições
function criar_dados_bencao_vida() {
    return {
        categoria: "bencao",
        nome: "Bênção da Vida",
        sprite_carta: noone,
        custo: noone,
        efeito: "cura_ao_morrer"
    };
}

function criar_dados_maldicao_perda() {
    return {
        categoria: "maldicao",
        nome: "Maldição da Perda",
        sprite_carta: noone,
        custo: noone,
        efeito: "perde_vida_ao_morrer"
    };
}

function criar_dados_bencao_decomposicao() {
    return {
        categoria: "bencao",
        nome: "Bênção da Decomposição",
        sprite_carta: spr_carta_decomposicao,   // importe a arte com esse nome
        custo: noone,
        efeito: "cura_ao_morrer"   // mesmo efeito da Bênção da Vida
    };
}

function criar_dados_maldicao_sangue_por_sangue() {
    return {
        categoria: "maldicao",
        nome: "Sangue por Sangue",
        sprite_carta: spr_carta_sangue_por_sangue,   // importe a arte com esse nome
        custo: noone,
        efeito: "perde_vida_ao_morrer"   // mesmo efeito da Maldição da Perda
    };
}

function lista_bencaos(_dono) {
    return (_dono == "jogador") ? obj_controlador.bencaos_jogador : obj_controlador.bencaos_inimigo;
}

function lista_maldicoes(_dono) {
    return (_dono == "jogador") ? obj_controlador.maldicoes_jogador : obj_controlador.maldicoes_inimigo;
}

function adicionar_bencao(_dono, _efeito, _nome = "", _sprite = noone) {
    var _lista = lista_bencaos(_dono);
    if (array_length(_lista) >= obj_controlador.max_bencaos_maldicoes) return false;
    array_push(_lista, {
        categoria: "bencao",
        efeito: _efeito,
        nome: (_nome == "") ? "Bênção ativa" : _nome,
        sprite: _sprite
    });
    return true;
}

function adicionar_maldicao(_dono, _efeito, _nome = "", _sprite = noone) {
    var _lista = lista_maldicoes(_dono);
    if (array_length(_lista) >= obj_controlador.max_bencaos_maldicoes) return false;
    array_push(_lista, {
        categoria: "maldicao",
        efeito: _efeito,
        nome: (_nome == "") ? "Maldição ativa" : _nome,
        sprite: _sprite
    });
    return true;
}

// chamada toda vez que uma tropa morre, ANTES de ser destruída de verdade
function aplicar_efeitos_morte(_carta, _por_inimigo) {
    var _dono = _carta.dono;
    var _bencaos = lista_bencaos(_dono);
    
    for (var i = 0; i < array_length(_bencaos); i++) {
        var _efeito_bencao = is_struct(_bencaos[i]) ? _bencaos[i].efeito : _bencaos[i];
        if (_efeito_bencao == "cura_ao_morrer") {
            if (_dono == "jogador") {
                obj_controlador.vida_jogador += 1;
            } else {
                obj_controlador.vida_inimigo += 1;
            }
            debug_combate("Bênção da Vida curou 1 ponto!");
        }
    }
    
    // maldições só valem se a tropa morreu PARA o oponente (regra do manual)
    if (_por_inimigo) {
        var _maldicoes = lista_maldicoes(_dono);
        for (var i = 0; i < array_length(_maldicoes); i++) {
            var _efeito_maldicao = is_struct(_maldicoes[i]) ? _maldicoes[i].efeito : _maldicoes[i];
            if (_efeito_maldicao == "perde_vida_ao_morrer") {
                causar_dano_castelo(_dono, 1);
                debug_combate("Maldição da Perda causou 1 de dano!");
            }
        }
    }
}
#endregion

#region Terreno — efeitos condicionais por categoria de nome
// Lista de palavras-chave que classificam uma tropa como "morto-vivo",
// seguindo a convenção descrita no livro de regras (seção 11).
function eh_morto_vivo(_carta) {
    var _categorias_morto_vivo = ["zumbi", "esqueleto", "fantasma", "espirito", "espírito"];
    var _nome_lower = string_lower(_carta.nome_carta);

    for (var i = 0; i < array_length(_categorias_morto_vivo); i++) {
        if (string_pos(_categorias_morto_vivo[i], _nome_lower) > 0) return true;
    }
    return false;
}

// Bônus de defesa que o Cemitério concede a essa carta especificamente (0 se não for morto-vivo ou terreno não ativo).
function bonus_cemiterio_defesa(_carta) {
    if (obj_controlador.terreno_ativo != "cemiterio") return 0;
    return eh_morto_vivo(_carta) ? 1 : 0;
}

// Bônus de dano (físico/mágico) que o Cemitério concede.
function bonus_cemiterio_dano(_carta) {
    if (obj_controlador.terreno_ativo != "cemiterio") return 0;
    return eh_morto_vivo(_carta) ? 1 : 0;
}

// Soma TODOS os modificadores de dano físico que uma tropa recebe agora,
// incluindo o mod_dano base da carta + bônus externos (terreno, etc).
// Centraliza aqui pra o número exibido na carta bater 1:1 com o número usado no combate real.
function calcular_mod_dano_total(_carta) {
    return _carta.mod_dano + bonus_cemiterio_dano(_carta);
}

// Mesma ideia, só que pra defesa física.
function calcular_defesa_fisica_total(_carta) {
    var _bonus_berserker = (_carta.condicao == "berserker") ? 4 : 0;
    return _carta.defesa_fisica + bonus_cemiterio_defesa(_carta) + _bonus_berserker;
}

// Mesma ideia, pra defesa mágica.
function calcular_defesa_magica_total(_carta) {
    return _carta.defesa_magica + bonus_cemiterio_defesa(_carta);
}

// Bônus no D20 de acerto que o Cemitério concede.
function bonus_cemiterio_acerto(_carta) {
    if (obj_controlador.terreno_ativo != "cemiterio") return 0;
    return eh_morto_vivo(_carta) ? 1 : 0;
}
#endregion

#region Deck — montar, embaralhar, comprar
function registrar_ultima_carta_jogada(_funcao, _dono) {
    if (_funcao == noone) return;
    var _dados = _funcao();
    if (_dados.categoria == "tropa" || _dados.nome == "Refração Temporal") return;
    if (_dono == "jogador") obj_controlador.ultima_carta_nao_tropa_jogador = _funcao;
    else obj_controlador.ultima_carta_nao_tropa_inimigo = _funcao;
}

function ultima_carta_jogada(_dono) {
    return (_dono == "jogador") ? obj_controlador.ultima_carta_nao_tropa_jogador
        : obj_controlador.ultima_carta_nao_tropa_inimigo;
}

function bloquear_recurso(_recurso, _turnos = 3) {
    if (!instance_exists(_recurso)) return false;
    _recurso.bloqueado_turnos = max(_recurso.bloqueado_turnos, _turnos);
    _recurso.bloqueio_acabou_de_aplicar = true;
    mostrar_feedback("BLOQUEADO: " + string(_turnos), _recurso.x, _recurso.y - 32, make_color_rgb(175, 95, 235), 60);
    return true;
}

function ativar_dados_manipulados(_dono, _origem_x, _origem_y) {
    var _resultado = irandom_range(1, 4);
    var _ctx = { dono: _dono };
    rolar_dado_visual(_origem_x, _origem_y, _origem_x, _origem_y - 70, 4, _resultado,
        method(_ctx, function(_valor) {
            if (dono == "jogador") {
                obj_controlador.dados_manipulados_valor_jogador = _valor;
                obj_controlador.dados_manipulados_usos_jogador = 3;
            } else {
                obj_controlador.dados_manipulados_valor_inimigo = _valor;
                obj_controlador.dados_manipulados_usos_inimigo = 3;
            }
            mostrar_feedback("DADO FIXADO: " + string(_valor), room_width / 2,
                dono == "jogador" ? obj_controlador.mao_y - 100 : 95, c_aqua, 75);
        }));
}

// Chamado quando um dado próprio termina. Para o jogador, a decisão entra numa
// fila visual; a IA usa o valor guardado apenas quando ele melhora a rolagem.
function entregar_resultado_dado_manipulado(_dono, _tamanho_dado, _resultado, _callback) {
    var _usos = (_dono == "jogador") ? obj_controlador.dados_manipulados_usos_jogador
        : obj_controlador.dados_manipulados_usos_inimigo;
    var _alternativo = (_dono == "jogador") ? obj_controlador.dados_manipulados_valor_jogador
        : obj_controlador.dados_manipulados_valor_inimigo;
    if (_usos <= 0 || _alternativo <= 0 || _alternativo > _tamanho_dado) {
        if (_callback != noone) _callback(_resultado);
        return;
    }

    if (_dono == "jogador") {
        obj_controlador.dados_manipulados_usos_jogador -= 1;
        array_push(obj_controlador.dados_manipulados_escolhas,
            { original: _resultado, alternativo: _alternativo, callback: _callback });
    } else {
        obj_controlador.dados_manipulados_usos_inimigo -= 1;
        if (_callback != noone) _callback(max(_resultado, _alternativo));
        if (_alternativo > _resultado) mostrar_feedback("DADO MANIPULADO", room_width / 2, 100, c_purple, 50);
    }
}

function resolver_escolha_dados_manipulados(_usar_alternativo) {
    if (!obj_controlador.dados_manipulados_escolha_ativa || !is_struct(obj_controlador.dados_manipulados_escolha_atual)) return;
    var _escolha = obj_controlador.dados_manipulados_escolha_atual;
    var _valor = _usar_alternativo ? _escolha.alternativo : _escolha.original;
    obj_controlador.dados_manipulados_escolha_ativa = false;
    obj_controlador.dados_manipulados_escolha_atual = noone;
    if (_escolha.callback != noone) _escolha.callback(_valor);
}

function usar_refracao_temporal(_carta) {
    var _ultima = ultima_carta_jogada(_carta.dono);
    if (_ultima == noone) {
        if (_carta.dono == "jogador") mostrar_aviso_regra("Jogue outra carta antes da Refração Temporal", _carta.x, _carta.y);
        return false;
    }
    var _dados_ultima = _ultima();
    var _nova = comprar_carta_do_deck_por_funcao(_ultima, _carta.x, _carta.y);
    if (instance_exists(_nova) && _nova.categoria == "construcao") _nova.vida = max(1, ceil(_nova.vida * 0.5));
    mostrar_feedback("REFRAÇÃO: " + _dados_ultima.nome, _carta.x, _carta.y - 35, c_aqua, 65);
    return true;
}

function catalogo_cartas() {
    return [
        criar_dados_esquilo, criar_dados_lobo, criar_dados_urso, criar_dados_slime, criar_dados_slimet, criar_dados_mimic,
        criar_dados_olho_demonio, criar_dados_mago_da_sombra, criar_dados_gato_mago, criar_dados_goblin,
        criar_dados_hollow_jack, criar_dados_esqueleto, criar_dados_shroomilin,
        criar_dados_recurso_sangue, criar_dados_recurso_ossos, criar_dados_recurso_sucata, criar_dados_recurso_mana,
        criar_dados_construcao_torre, criar_dados_construcao_hemodrenario, criar_dados_construcao_maquina_ima,
        criar_dados_magica_bola_fogo, criar_dados_magica_veneno, criar_dados_magica_gelo, criar_dados_magica_choque,
        criar_dados_magica_dados_manipulados, criar_dados_magica_refracao_temporal, criar_dados_magica_eutanasia,
        criar_dados_magica_bloqueio_recurso, criar_dados_item_sangue_suga,
        criar_dados_item_espada, criar_dados_item_escudo, criar_dados_item_pocao, criar_dados_item_grimorio_iniciante,
        criar_dados_item_pocao_mana, criar_dados_armadilha_urso, criar_dados_armadilha_loucura_mutua,
        criar_dados_armadilha_raizes_espinhosas, criar_dados_armadilha_destrocos,
        criar_dados_bencao_vida, criar_dados_maldicao_perda, criar_dados_bencao_decomposicao,
        criar_dados_maldicao_sangue_por_sangue, criar_dados_item_bau, criar_dados_item_frasco_sangue,
        criar_dados_item_vitamina_cerebro, criar_dados_item_elmo_ferro, criar_dados_item_frasco_acido,
        criar_dados_terreno_pantano, criar_dados_terreno_cemiterio, criar_dados_terreno_planicies_profanas,
        criar_dados_item_espada_quebrada
    ];
}

function validar_contagens_baralho(_catalogo, _contagens) {
    if (!is_array(_contagens) || array_length(_contagens) != array_length(_catalogo)) return false;
    var _total = 0;
    for (var i = 0; i < array_length(_contagens); i++) {
        if (_contagens[i] < 0 || floor(_contagens[i]) != _contagens[i]) return false;
        _total += _contagens[i];
    }
    return _total == 50;
}

function salvar_contagens_baralho(_contagens) {
    ini_open("kartha_deck.ini");
    ini_write_real("deck", "quantidade_tipos", array_length(_contagens));
    for (var i = 0; i < array_length(_contagens); i++) ini_write_real("deck", "carta_" + string(i), _contagens[i]);
    ini_close();
}

function carregar_contagens_baralho(_quantidade_tipos) {
    if (!file_exists("kartha_deck.ini")) return noone;
    ini_open("kartha_deck.ini");
    var _quantidade_salva = ini_read_real("deck", "quantidade_tipos", -1);
    if (_quantidade_salva != _quantidade_tipos) { ini_close(); return noone; }
    var _contagens = array_create(_quantidade_tipos, 0);
    for (var i = 0; i < _quantidade_tipos; i++) _contagens[i] = max(0, floor(ini_read_real("deck", "carta_" + string(i), 0)));
    ini_close();
    return _contagens;
}

function montar_deck_personalizado(_catalogo, _contagens) {
    var _monte = [];
    for (var i = 0; i < array_length(_catalogo); i++) {
        for (var c = 0; c < _contagens[i]; c++) array_push(_monte, _catalogo[i]);
    }
    return embaralhar_array(_monte);
}

// Executor declarativo para cartas futuras. Uma carta pode fornecer um array
// efeitos com structs {tipo, ...} sem precisar ganhar um novo switch exclusivo.
function executar_efeitos_declarativos(_efeitos, _alvo, _dono) {
    if (!is_array(_efeitos)) return false;
    var _executou = false;
    for (var i = 0; i < array_length(_efeitos); i++) {
        var _efeito = _efeitos[i];
        if (!is_struct(_efeito) || !variable_struct_exists(_efeito, "tipo")) continue;
        switch (_efeito.tipo) {
            case "condicao":
                if (instance_exists(_alvo) && variable_struct_exists(_efeito, "chave"))
                    _executou = aplicar_condicao_por_chave(_alvo, _efeito.chave) || _executou;
                break;
            case "dano":
                if (instance_exists(_alvo) && variable_struct_exists(_efeito, "valor")) {
                    _alvo.vida -= _efeito.valor; mostrar_dano_tropa(_alvo, _efeito.valor); _executou = true;
                    if (_alvo.vida <= 0) destruir_tropa(_alvo);
                }
                break;
            case "cura":
                if (instance_exists(_alvo) && variable_struct_exists(_efeito, "valor")) {
                    _alvo.vida = min(_alvo.vida_maxima, _alvo.vida + _efeito.valor); _executou = true;
                }
                break;
            case "comprar":
                var _qtd = variable_struct_exists(_efeito, "quantidade") ? _efeito.quantidade : 1;
                comprar_varias_cartas(_qtd, _dono); _executou = true;
                break;
            case "recurso":
                if (variable_struct_exists(_efeito, "chave"))
                    _executou = (colocar_recurso(_efeito.chave, _dono) == "colocado") || _executou;
                break;
        }
    }
    return _executou;
}

function embaralhar_array(_array) {
    var _n = array_length(_array);
    for (var i = _n - 1; i > 0; i--) {
        var _j = irandom(i);
        var _temp = _array[i];
        _array[i] = _array[_j];
        _array[_j] = _temp;
    }
    return _array;
}

// Monta o monte de compra com exatamente 50 cartas (regra do manual),
// distribuindo as cópias o mais igual possível entre os tipos do baralho.
function montar_deck() {
    var _monte = [];
    var _total_cartas_desejado = 50;
    var _n_tipos = array_length(baralho);

    var _copias_base = _total_cartas_desejado div _n_tipos;
    var _sobra = _total_cartas_desejado mod _n_tipos;

    for (var i = 0; i < _n_tipos; i++) {
        var _copias = _copias_base + (i < _sobra ? 1 : 0);
        for (var c = 0; c < _copias; c++) {
            array_push(_monte, baralho[i]);
        }
    }

    return embaralhar_array(_monte);
}

// Compra a próxima carta do monte (consumindo ele, igual um baralho físico) e coloca na mão.
function comprar_carta_do_deck(_x_inicial, _y_inicial) {
    if (array_length(obj_controlador.monte) == 0) {
        debug_combate("Monte vazio! Sem cartas pra comprar.");
        return;
    }

    var _funcao_sorteada = obj_controlador.monte[0];
    array_delete(obj_controlador.monte, 0, 1);
    comprar_carta_do_deck_por_funcao(_funcao_sorteada, _x_inicial, _y_inicial);
}

// Procura no monte (baralho de compra) um recurso do tipo pedido, manda pra mão e embaralha o resto.
// Retorna true se achou, false se o deck não tinha esse recurso.
function buscar_recurso_no_deck(_tipo_recurso, _dono) {
    var _monte = (_dono == "jogador") ? obj_controlador.monte : obj_controlador.monte_inimigo;

    var _funcao_alvo = noone;
    switch (_tipo_recurso) {
        case "sangue": _funcao_alvo = criar_dados_recurso_sangue; break;
        case "ossos":  _funcao_alvo = criar_dados_recurso_ossos;  break;
        case "sucata": _funcao_alvo = criar_dados_recurso_sucata; break;
        case "mana":   _funcao_alvo = criar_dados_recurso_mana;   break;
    }
    if (_funcao_alvo == noone) return false;

    var _indice = array_get_index(_monte, _funcao_alvo);
    if (_indice == -1) {
        debug_combate("Busca: nenhum recurso de " + _tipo_recurso + " restou no deck.");
        if (_dono == "jogador") mostrar_aviso_regra("Não há mais " + nome_recurso_exibicao(_tipo_recurso, 1) + " no baralho");
        return false;
    }

    array_delete(_monte, _indice, 1);

    if (_dono == "jogador") {
        comprar_carta_do_deck_por_funcao(_funcao_alvo, obj_deck.x, obj_deck.y);
    } else {
        array_push(obj_controlador.mao_inimigo, _funcao_alvo);
    }

    embaralhar_array(_monte);
    return true;
}

// Mesma lógica de sempre, mas recebe a função da carta já escolhida
// (compra normal E efeitos de busca tipo Sangue Suga usam essa mesma função).
function comprar_carta_do_deck_por_funcao(_funcao_sorteada, _x_inicial, _y_inicial) {
    var _dados = _funcao_sorteada();

    var _carta = instance_create_layer(_x_inicial, _y_inicial, "Instances", obj_carta);
    _carta.nome_carta = _dados.nome;
    _carta.sprite_index = (_dados.sprite_carta != noone) ? _dados.sprite_carta : spr_carta_placeholder;
    _carta.escala_base = global.CARTA_LARGURA / sprite_get_width(_carta.sprite_index);
    _carta.tem_arte_propria = (_dados.sprite_carta != noone);
    _carta.categoria = _dados.categoria;
    _carta.funcao_dados_origem = _funcao_sorteada;
    _carta.dados_carta = _dados;
    _carta.efeitos_declarativos = variable_struct_exists(_dados, "efeitos") ? _dados.efeitos : [];
    _carta.tags = variable_struct_exists(_dados, "tags") ? _dados.tags : [];

    if (_dados.categoria == "tropa") {
        _carta.vida = _dados.vida;
        _carta.vida_maxima = _dados.vida;
        _carta.vida_pos_x = variable_struct_exists(_dados, "vida_pos_x") ? _dados.vida_pos_x : 0.11;
        _carta.vida_pos_y = variable_struct_exists(_dados, "vida_pos_y") ? _dados.vida_pos_y : 0.07;
        _carta.selo_abissal = variable_struct_exists(_dados, "selo_abissal") ? _dados.selo_abissal : false;
        _carta.funcao_evolucao = variable_struct_exists(_dados, "evolucao") ? _dados.evolucao : noone;
        _carta.custo_sacrificio = _dados.sacrificio;
        _carta.dado_dano = _dados.dado_dano;
        _carta.qtd_dados_dano = variable_struct_exists(_dados, "qtd_dados_dano") ? _dados.qtd_dados_dano : 1;
        _carta.qtd_dados_dano_magico = variable_struct_exists(_dados, "qtd_dados_dano_magico") ? _dados.qtd_dados_dano_magico : 1;
        _carta.mod_dano = _dados.mod_dano;
        _carta.defesa_fisica = _dados.defesa_fisica;
        _carta.defesa_magica = _dados.defesa_magica;
        _carta.custo = _dados.custo;
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

        _carta.vida_pos_x = variable_struct_exists(_dados, "vida_pos_x") ? _dados.vida_pos_x : 0.10;
        _carta.vida_pos_y = variable_struct_exists(_dados, "vida_pos_y") ? _dados.vida_pos_y : 0.07;
        _carta.int_pos_x = variable_struct_exists(_dados, "int_pos_x") ? _dados.int_pos_x : 0.91;
        _carta.int_pos_y = variable_struct_exists(_dados, "int_pos_y") ? _dados.int_pos_y : 0.073;
        _carta.mochila_pos_x = variable_struct_exists(_dados, "mochila_pos_x") ? _dados.mochila_pos_x : 0.91;
        _carta.mochila_pos_y = variable_struct_exists(_dados, "mochila_pos_y") ? _dados.mochila_pos_y : 0.185;
        _carta.atk_pos_x = variable_struct_exists(_dados, "atk_pos_x") ? _dados.atk_pos_x : 0.12;
        _carta.atk_pos_y = variable_struct_exists(_dados, "atk_pos_y") ? _dados.atk_pos_y : 0.92;
        _carta.atk_magico_pos_x = variable_struct_exists(_dados, "atk_magico_pos_x") ? _dados.atk_magico_pos_x : 0.37;
        _carta.atk_magico_pos_y = variable_struct_exists(_dados, "atk_magico_pos_y") ? _dados.atk_magico_pos_y : 0.92;
        _carta.def_pos_x = variable_struct_exists(_dados, "def_pos_x") ? _dados.def_pos_x : 0.62;
        _carta.def_pos_y = variable_struct_exists(_dados, "def_pos_y") ? _dados.def_pos_y : 0.92;
        _carta.def_magico_pos_x = variable_struct_exists(_dados, "def_magico_pos_x") ? _dados.def_magico_pos_x : 0.87;
        _carta.def_magico_pos_y = variable_struct_exists(_dados, "def_magico_pos_y") ? _dados.def_magico_pos_y : 0.92;

    } else if (_dados.categoria == "recurso") {
        _carta.tipo_recurso = _dados.tipo_recurso;

    } else if (_dados.categoria == "construcao") {
        _carta.vida = _dados.vida;
        _carta.custo = _dados.custo;
        _carta.efeito_construcao = variable_struct_exists(_dados, "efeito_construcao") ? _dados.efeito_construcao : "";
        _carta.dado_efeito = variable_struct_exists(_dados, "dado_efeito") ? _dados.dado_efeito : 0;

    } else if (_dados.categoria == "item_equipavel") {
	    _carta.custo = _dados.custo;
	    _carta.bonus_mod_dano_item = variable_struct_exists(_dados, "bonus_mod_dano") ? _dados.bonus_mod_dano : 0;
	    _carta.bonus_defesa_item = variable_struct_exists(_dados, "bonus_defesa") ? _dados.bonus_defesa : 0;
	    _carta.requisito_inteligencia_item = variable_struct_exists(_dados, "requisito_inteligencia") ? _dados.requisito_inteligencia : 0;
	    _carta.sobrescreve_dado_dano_item = variable_struct_exists(_dados, "sobrescreve_dado_dano") ? _dados.sobrescreve_dado_dano : 0;
	    _carta.sobrescreve_mod_dano_item = variable_struct_exists(_dados, "sobrescreve_mod_dano") ? _dados.sobrescreve_mod_dano : 0;
        _carta.efeito_item = variable_struct_exists(_dados, "efeito_item") ? _dados.efeito_item : "";

    } else if (_dados.categoria == "item_consumivel") {
	    _carta.custo = _dados.custo;
	    _carta.cura_item = variable_struct_exists(_dados, "cura") ? _dados.cura : 0;
	    _carta.efeito_tipo = variable_struct_exists(_dados, "efeito_tipo") ? _dados.efeito_tipo : "";
	    _carta.quantidade_efeito = variable_struct_exists(_dados, "quantidade_efeito") ? _dados.quantidade_efeito : 0;

    } else if (_dados.categoria == "armadilha") {
        _carta.custo = _dados.custo;
        _carta.efeito_tipo = variable_struct_exists(_dados, "efeito_tipo") ? _dados.efeito_tipo : "armadilha_urso";
        _carta.dado_efeito = _dados.dado_efeito;
        _carta.qtd_dados_efeito = variable_struct_exists(_dados, "qtd_dados_efeito") ? _dados.qtd_dados_efeito : 1;

    } else if (_dados.categoria == "terreno") {
	    _carta.custo = _dados.custo;
	    _carta.bonus_defesa_global = _dados.bonus_defesa_global;
	    _carta.efeito_terreno = variable_struct_exists(_dados, "efeito_terreno") ? _dados.efeito_terreno : "";

    } else if (_dados.categoria == "magica") {
        _carta.custo = _dados.custo;
        _carta.efeito_tipo = variable_struct_exists(_dados, "efeito_tipo") ? _dados.efeito_tipo : "";
        _carta.dado_efeito = variable_struct_exists(_dados, "dado_efeito") ? _dados.dado_efeito : 0;
        _carta.chance_queimar = variable_struct_exists(_dados, "chance_queimar") ? _dados.chance_queimar : 0;

    } else if (_dados.categoria == "bencao" || _dados.categoria == "maldicao") {
        _carta.custo = _dados.custo;
        _carta.efeito_passivo = _dados.efeito;
    }

    // identifica qual magia é pelo nome, pra saber qual efeito aplicar depois
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

    _carta.esta_na_mao = true;
    _carta.compra_animando = true;
    _carta.compra_progresso = 0;
    _carta.compra_origem_x = _x_inicial;
    _carta.compra_origem_y = _y_inicial;
    _carta.depth = -5000;

    array_push(obj_controlador.mao, _carta);
    organizar_mao();

    _carta.x = _x_inicial;
    _carta.y = _y_inicial;
    if (obj_controlador.mao_inicial_comprada) {
        mostrar_feedback("+ CARTA", _x_inicial, _y_inicial, c_aqua, 32);
    }
    return _carta;
}
	
// Compra 1 carta do monte da IA (consumindo ele) e guarda na mão dela.
// A mão da IA fica só como dados (structs), sem cartas visuais na tela.
function comprar_carta_do_deck_ia() {
    if (array_length(obj_controlador.monte_inimigo) == 0) {
        debug_combate("Monte inimigo vazio! IA sem cartas pra comprar.");
        return;
    }

    var _funcao_sorteada = obj_controlador.monte_inimigo[0];
    array_delete(obj_controlador.monte_inimigo, 0, 1);
    array_push(obj_controlador.mao_inimigo, _funcao_sorteada);
}

// Compra a mão inicial do jogador (chamada 1x, no Room Start).
function comprar_mao_inicial() {
    if (obj_controlador.mao_inicial_comprada) return;

    for (var i = 0; i < obj_controlador.quantidade_inicial; i++) {
        if (array_length(obj_controlador.monte) == 0) break;
        comprar_carta_do_deck(obj_deck.x, obj_deck.y);
        var _ultima_carta = obj_controlador.mao[array_length(obj_controlador.mao) - 1];
        if (instance_exists(_ultima_carta)) _ultima_carta.compra_atraso = i * 7;
    }

    obj_controlador.mao_inicial_comprada = true;
}

// Compra N cartas seguidas do monte do lado indicado, parando se o monte acabar.
function comprar_varias_cartas(_quantidade, _dono) {
    for (var i = 0; i < _quantidade; i++) {
        if (_dono == "jogador") {
            if (array_length(obj_controlador.monte) == 0) break;
            comprar_carta_do_deck(obj_deck.x, obj_deck.y);
        } else {
            if (array_length(obj_controlador.monte_inimigo) == 0) break;
            comprar_carta_do_deck_ia();
        }
    }
}

// Desvira 1 recurso de um tipo específico já virado (gasto) de volta pro estado disponível.
// Retorna true se achou um pra reverter, false se não tinha nenhum virado.
function revirar_recurso(_tipo, _dono) {
    var _revirado = false;
    with (obj_recurso) {
        if (!_revirado && dono == _dono && tipo == _tipo && virado) {
            virado = false;
            _revirado = true;
        }
    }
    return _revirado;
}

// Compra a mão inicial da IA (chamada 1x, no Room Start).
function comprar_mao_inicial_ia() {
    if (obj_controlador.mao_inimigo_inicial_comprada) return;

    for (var i = 0; i < obj_controlador.quantidade_inicial; i++) {
        if (array_length(obj_controlador.monte_inimigo) == 0) break;
        comprar_carta_do_deck_ia();
    }

    obj_controlador.mao_inimigo_inicial_comprada = true;
}
#endregion

#region Mão — leque, arco e scroll horizontal
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

        // guarda a posição "base" do leque; o scroll horizontal é somado a isso depois, no Step da carta
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

function mouse_na_faixa_da_mao(_mouse_y) {
    return _mouse_y >= obj_controlador.mao_y - global.CARTA_ALTURA * 0.55;
}

// Reorganiza a mão pela posição horizontal do cursor. A carta continua no
// array durante o arraste, então as vizinhas já abrem espaço e animam até a
// nova posição antes mesmo de o jogador soltá-la.
function reordenar_carta_na_mao(_carta, _mouse_x) {
    if (!instance_exists(_carta)) return false;
    var _indice_antigo = array_get_index(obj_controlador.mao, _carta);
    if (_indice_antigo < 0) return false;

    array_delete(obj_controlador.mao, _indice_antigo, 1);
    var _novo_indice = array_length(obj_controlador.mao);
    for (var i = 0; i < array_length(obj_controlador.mao); i++) {
        var _outra = obj_controlador.mao[i];
        if (instance_exists(_outra) && _mouse_x < _outra.mao_base_x + obj_controlador.mao_scroll_offset) {
            _novo_indice = i;
            break;
        }
    }
    array_insert(obj_controlador.mao, _novo_indice, _carta);
    if (_novo_indice != _indice_antigo) organizar_mao();
    if (_carta.arrastando) {
        _carta.esta_na_mao = false;
        _carta.depth = -100000;
    }
    return _novo_indice != _indice_antigo;
}
#endregion

#region Movimento das tropas
function iniciar_pulo_tropa(_carta, _novo_x, _novo_y, _entrada_no_campo = false) {
    _carta.pulando = true;
    _carta.pulo_origem_x = _carta.x;
    _carta.pulo_origem_y = _carta.y;
    _carta.pulo_destino_x = _novo_x;
    _carta.pulo_destino_y = _novo_y;
    _carta.pulo_progresso = 0;
	// Na entrada, começa no tamanho da mão e encolhe suavemente até a escala do campo
	_carta.pulo_escala_origem = _entrada_no_campo ? (1 / _carta.escala_no_campo) : 1;
	_carta.escala_animacao = _carta.pulo_escala_origem;
	_carta.pulo_poeira_ao_pousar = true;
    _carta.impacto_colocacao_timer = 0;
}

// Move uma tropa 1 casa na direção dela. Retorna uma string dizendo o que aconteceu:
// "movido", "ja_no_assalto", "fora_do_tabuleiro", "invalido", "bloqueado" (aliado no caminho)
// ou "ataque_necessario" (tem inimigo na frente, precisa atacar em vez de mover).
function mover_tropa(_carta, _direcao) {
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
        if (_ocupante.dono == _carta.dono) {
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
                    _nova_posicao = _posicao_apos_voo;
                } else {
                    return "ataque_necessario";
                }
            } else {
            return "ataque_necessario";
            }
        }
    }

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
    _carta.posicao_atual = _nova_posicao;
    _carta.defendendo_castelo = false;

    iniciar_pulo_tropa(_carta, _slot_destino.x, _slot_destino.y);

	verificar_olhar_vazio(_carta);

    debug_combate(_carta.nome_carta + " avançou na fileira " + string(_carta.lane_atual + 1) + ".");

    return "movido";
}

// Move todas as tropas de um lado que ainda não chegaram à posição de assalto.
function mover_tropas_automatico(_dono) {
    with (obj_carta) {
        if (dono == _dono && travada && turnos_no_campo >= 1 && posicao_atual != posicao_assalto(_dono) && tropa_pode_agir(id)) {
            mover_tropa(id, 1);
        }
    }
}
#endregion

#region Combate — dados, dano e resolução
function iniciar_animacao_ataque(_carta, _alvo = noone, _intensidade = 10, _duracao = 15) {
    if (!instance_exists(_carta)) return;

    var _dir_x = 0;
    var _dir_y = -1;

    if (_alvo != noone && instance_exists(_alvo)) {
        _dir_x = _alvo.x - _carta.x;
        _dir_y = _alvo.y - _carta.y;
        var _dist = point_distance(0, 0, _dir_x, _dir_y);
        if (_dist > 0) {
            _dir_x /= _dist;
            _dir_y /= _dist;
        }
    }

    // reseta pra não ficar "grudado" caso um ataque anterior tenha sido interrompido
    _carta.ataque_offset_x = 0;
    _carta.ataque_offset_y = 0;
    _carta.ataque_elevacao = 0;
    _carta.ataque_escala_extra = 0;

    var _tempo_impulso  = max(4, round(_duracao * 0.4));
    var _tempo_golpe    = max(3, round(_duracao * 0.3));
    var _tempo_retorno  = max(8, round(_duracao * 1.1));

    var _elevacao_impulso = _intensidade * 0.55;
    var _escala_impulso = clamp(_intensidade * 0.012, 0.05, 0.22);

    // guarda os parâmetros NA CARTA (não em locais/struct), porque o callback
    // precisa rodar com self = carta (o tween() usa x/y/depth implícitos do self)
    _carta.ataque_calc_dir_x = _dir_x;
    _carta.ataque_calc_dir_y = _dir_y;
    _carta.ataque_calc_intensidade = _intensidade;
    _carta.ataque_calc_tempo_golpe = _tempo_golpe;
    _carta.ataque_calc_tempo_retorno = _tempo_retorno;

    // FASE 1 — Impulso: sobe e incha um pouco, se preparando pro golpe
    tween(_carta, "ataque_elevacao", _elevacao_impulso, tween_animation.quad_out, _tempo_impulso,
        method(_carta, function() {
            if (!instance_exists(self)) return;

            // FASE 2 — Golpe: dispara rápido na direção do alvo
            tween(self, "ataque_offset_x", ataque_calc_dir_x * ataque_calc_intensidade, tween_animation.circ_out, ataque_calc_tempo_golpe);
            tween(self, "ataque_offset_y", ataque_calc_dir_y * ataque_calc_intensidade, tween_animation.circ_out, ataque_calc_tempo_golpe,
                method(self, function() {
                    if (!instance_exists(self)) return;

                    // FASE 3 — Retorno: volta com uma leve quicada
                    tween(self, "ataque_offset_x", 0, tween_animation.back_out, ataque_calc_tempo_retorno);
                    tween(self, "ataque_offset_y", 0, tween_animation.back_out, ataque_calc_tempo_retorno);
                    tween(self, "ataque_elevacao", 0, tween_animation.back_out, ataque_calc_tempo_retorno);
                })
            );
        })
    );

    tween(_carta, "ataque_escala_extra", _escala_impulso, tween_animation.quad_out, _tempo_impulso,
        method(_carta, function() {
            if (!instance_exists(self)) return;
            tween(self, "ataque_escala_extra", 0, tween_animation.back_out, ataque_calc_tempo_retorno);
        })
    );
}

// Faz a carta piscar vermelho por um instante (feedback de dano recebido).
function aplicar_flash_dano(_carta, _duracao = 18, _origem = noone, _defesa = 0) {
    if (!instance_exists(_carta)) return;
    _carta.dano_flash_timer = _duracao;
    _carta.defesa_impacto_timer = _carta.defesa_impacto_duracao;
    if (instance_exists(_origem)) {
        var _direcao = point_direction(_origem.x, _origem.y, _carta.x, _carta.y);
        _carta.recuo_dano_x = lengthdir_x(9, _direcao);
        _carta.recuo_dano_y = lengthdir_y(9, _direcao);
    }
}

// Número de dano sobre a tropa, desenhado pelo HUD acima de todas as cartas.
function mostrar_dano_tropa(_carta, _dano) {
    if (!instance_exists(_carta) || _dano <= 0) return;
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
    if (_atacante.condicao == "berserker") _original *= 2;
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
        _fisico = (_carta.item_ataque_atual.dado + 1) / 2 + _carta.item_ataque_atual.modificador;
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
    var _modificador = _usando_item ? _carta.item_ataque_atual.modificador : ((_tipo_ataque == "magica") ? _carta.mod_dano_magico : _carta.mod_dano);

    var _dano_original = 0;
    for (var i = 0; i < _quantidade; i++) {
        _dano_original += irandom_range(1, _dado);
    }
    if (_carta.condicao == "berserker") _dano_original *= 2;
    return max(0, _dano_original + _modificador);
}

// Versão visual do dano direto. Mantém grupos de Golpe Duplo afastados e
// entrega ao callback o total dos dados já somado ao modificador.
function rolar_dano_direto_visual(_carta, _tipo_ataque, _callback_final, _indice_ataque = 0, _total_ataques = 1) {
    var _usando_item = (_tipo_ataque == "fisica" && is_struct(_carta.item_ataque_atual) && _carta.item_ataque_atual.dado > 0);
    var _dado = _usando_item ? _carta.item_ataque_atual.dado : ((_tipo_ataque == "magica") ? _carta.dado_dano_magico : _carta.dado_dano);
    var _quantidade = _usando_item ? 1 : ((_tipo_ataque == "magica") ? _carta.qtd_dados_dano_magico : _carta.qtd_dados_dano);
    var _modificador = _usando_item ? _carta.item_ataque_atual.modificador : ((_tipo_ataque == "magica") ? _carta.mod_dano_magico : _carta.mod_dano);
    var _offset_grupo = (_indice_ataque - ((_total_ataques - 1) / 2)) * 250;
    var _atraso_grupo = (_indice_ataque == 0) ? 0 : _indice_ataque * irandom_range(10, 16);

    var _bonus_carnica = (_carta.carnica_estado_proximo_ataque == "bonus");
    if (_bonus_carnica) _carta.carnica_estado_proximo_ataque = "";
    var _dados_diretos = {
        callback_final: _callback_final,
        carta: _carta,
        modificador: _modificador,
        multiplicador_original: (_carta.condicao == "berserker") ? 2 : 1,
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
function causar_dano_castelo(_dono, _dano) {
    if (_dano <= 0) return;
    var _controle = instance_find(obj_controlador, 0);
    if (_controle == noone) return;
    // Também cobre uma partida que ficou aberta durante a atualização do código.
    if (!variable_instance_exists(_controle, "fila_dano_castelo") || !is_array(_controle.fila_dano_castelo)) {
        _controle.fila_dano_castelo = [];
    }
    array_push(_controle.fila_dano_castelo, { dono: _dono, valor: _dano });
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
        _controle.fila_dano_castelo = array_delete(_controle.fila_dano_castelo, 0, 1);
        _controle.dano_castelo_ativo = true;
        _controle.dano_castelo_dono = _evento.dono;
        _controle.dano_castelo_valor = _evento.valor;
        _controle.dano_castelo_timer = _controle.dano_castelo_duracao;
        _controle.dano_castelo_aplicado = false;
    }

    if (!_controle.dano_castelo_ativo) return;

    _controle.dano_castelo_timer -= 1;
    // Os últimos 15 frames são o impacto: a vida diminui exatamente aqui.
    if (!_controle.dano_castelo_aplicado && _controle.dano_castelo_timer <= 15) {
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
    var _multiplicador = (_carta.condicao == "berserker") ? 2 : 1;
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

			if (_atacante.iludido_por_imitacao) {
			    _atacante.iludido_por_imitacao = false;
			    debug_combate(_atacante.nome_carta + " está iludida e não atacou.");
			    continue; 
			}


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
                _atacante.atacou_este_turno = true;
				rolar_combate(_atacante, _slot_alvo.carta_atual, _tipo_escolhido);

            } else if (posicao == posicao_assalto(_lado_atacante)) {
                _atacante.atacou_este_turno = true;
                // Dano direto só é permitido depois de avançar uma casa além do meio.
                var _construcao_alvo = _tem_alcance ? buscar_construcao(lane, _lado_defensor) : noone;

                if (_construcao_alvo != noone) {
                    var _tipo_construcao = ia_escolher_tipo_ataque_direto(_atacante);
                    var _dados_construcao = { alvo: _construcao_alvo };
                    rolar_dano_direto_visual(_atacante, _tipo_construcao,
                        method(_dados_construcao, function(_dano_construcao) {
                            if (!instance_exists(alvo)) return;
                            alvo.vida -= _dano_construcao;
                            mostrar_feedback("-" + string(_dano_construcao), alvo.x, alvo.y, c_red, 45);
                            if (alvo.vida <= 0) destruir_construcao(alvo);
                        })
                    );
                } else {
                    var _defensor_castelo = buscar_defensor_castelo(lane, _lado_defensor);
                    if (_defensor_castelo != noone) {
                        debug_combate(_defensor_castelo.nome_carta + " defende o castelo!");
                        rolar_combate(_atacante, _defensor_castelo, ia_escolher_tipo_ataque(_atacante, _defensor_castelo));
                    } else {
                        var _tipo_direto = ia_escolher_tipo_ataque_direto(_atacante);
                        var _dados_castelo = { lado_defensor: _lado_defensor };
                        rolar_dano_direto_visual(_atacante, _tipo_direto,
                            method(_dados_castelo, function(_dano_direto) {
                                causar_dano_castelo(lado_defensor, _dano_direto);
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
    if (!instance_exists(_carta) || !_carta.travada || _carta.slot_atual == noone) return false;

    var _slot = _carta.slot_atual;
    var _lado_atacante = _carta.dono;
    var _lado_defensor = (_lado_atacante == "jogador") ? "inimigo" : "jogador";
    var _sentido = direcao_avanco(_lado_atacante);

    if (_carta.iludido_por_imitacao) {
        _carta.iludido_por_imitacao = false;
        debug_combate(_carta.nome_carta + " está iludida e não atacou.");
        return true;
    }
    if (resolver_autoataque_carnica(_carta)) return true;

    var _tem_alcance = tem_habilidade(_carta, "alcance") || tem_habilidade(_carta, "alcance_magico");
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
        && (!tem_habilidade(_slot_alvo.carta_atual, "voar") || tem_habilidade(_carta, "voar") || _tem_alcance);

    if (_pode_mirar_alvo) {
        rolar_combate(_carta, _slot_alvo.carta_atual, _tipo_ataque, _indice_ataque, _total_ataques);
        return true;
    } else if (_slot.posicao == posicao_assalto(_lado_atacante)) {
        var _construcao_alvo = _tem_alcance ? buscar_construcao(_slot.lane, _lado_defensor) : noone;
        var _dado_usado = (_tipo_ataque == "magica") ? _carta.dado_dano_magico : _carta.dado_dano;
        var _mod_usado = (_tipo_ataque == "magica") ? _carta.mod_dano_magico : _carta.mod_dano;

        if (_construcao_alvo != noone) {
            var _dados_construcao = { alvo: _construcao_alvo };
            rolar_dano_direto_visual(_carta, _tipo_ataque,
                method(_dados_construcao, function(_dano_construcao) {
                    if (!instance_exists(alvo)) return;
                    alvo.vida -= _dano_construcao;
                    mostrar_feedback("-" + string(_dano_construcao), alvo.x, alvo.y, c_red, 45);
                    if (alvo.vida <= 0) destruir_construcao(alvo);
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
                var _dados_castelo = { lado_defensor: _lado_defensor };
                rolar_dano_direto_visual(_carta, _tipo_ataque,
                    method(_dados_castelo, function(_dano_direto) {
                        causar_dano_castelo(lado_defensor, _dano_direto);
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
    var _modo = (_atacante.condicao == "berserker") ? "vantagem"
        : ((_atacante.condicao == "confusao") ? "desvantagem" : "normal");
    var _bonus = bonus_cemiterio_acerto(_atacante);
    var _offset_golpe = (_indice_ataque - ((_total_ataques - 1) / 2)) * 110;
    var _atraso_golpe = (_indice_ataque == 0) ? 0 : _indice_ataque * irandom_range(9, 15);

    if (_modo == "normal") {
        var _resultado = clamp(irandom_range(1, 20) + _bonus, 1, 20);
        var _dados_normais = { atacante: _atacante, defensor: _defensor, tipo_ataque: _tipo_ataque };
        rolar_dado_visual(_atacante.x + _offset_golpe * 0.22, _atacante.y,
            _defensor.x + _offset_golpe, _defensor.y, 20, _resultado,
            method(_dados_normais, function(_valor) {
                processar_resultado_acerto(_valor, atacante, defensor, tipo_ataque);
            }), 0, _atraso_golpe, 78 + ((_total_ataques > 1) ? irandom_range(-7, 16) : 0), _atacante.dono);
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
        processar_resultado_acerto(_final, atacante, defensor, tipo_ataque);
    });

    for (var _i_teste = 0; _i_teste < 2; _i_teste++) {
        var _valor_teste = irandom_range(1, 20);
        var _offset_teste = (_i_teste == 0) ? -55 : 55;
        rolar_dado_visual(_atacante.x + _offset_golpe * 0.22, _atacante.y,
            _defensor.x + _offset_golpe + _offset_teste, _defensor.y,
            20, _valor_teste, _callback_teste, 0,
            _atraso_golpe + ((_i_teste == 0) ? 0 : irandom_range(8, 14)),
            78 + irandom_range(-7, 16), _atacante.dono);
    }
}

// Inicia um combate entre 2 tropas: rola o D20 de acerto (visual) e, quando ele parar,
// decide o resultado em processar_resultado_acerto().
function rolar_combate(_atacante, _defensor, _tipo_ataque, _indice_ataque = 0, _total_ataques = 1) {
    debug_combate("=== ATAQUE (" + _tipo_ataque + "): " + _atacante.nome_carta + " vs " + _defensor.nome_carta + " ===");

    // Resultado 4 da Loucura: não se defende e o próximo ataque acerta sem D20.
    if (_defensor.condicao == "loucura" && _defensor.loucura_sem_defesa) {
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
        callback_final: _callback_final
    };
    var _callback_dado = method(_grupo, function(_resultado) {
        total += _resultado;
        resolvidos += 1;
        if (resolvidos < quantidade) return;
        var _finalizar = callback_final;
        _finalizar(total);
    });

    var _espacamento = 110;
    for (var i = 0; i < _qtd; i++) {
        var _offset_x = (i - ((_qtd - 1) / 2)) * _espacamento;
        var _atraso = _atraso_grupo + ((i == 0) ? 0 : i * irandom_range(8, 15));
        var _duracao = 78 + irandom_range(-8, 18);
        var _resultado = irandom_range(1, _tamanho_dado);
        array_push(_grupo.resultados, _resultado);
        _grupo.total_visual += _resultado;
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

    iniciar_animacao_ataque(_atacante, _defensor, 18, 18);
    var _multiplicador_berserker = (_atacante.condicao == "berserker") ? 2 : 1;
    var _dano_original = _resultado * _dados.multiplicador_resultado * _multiplicador_berserker + _bonus_extra;
    var _defesa_usada = _dados.ignora_defesa ? 0
        : ((_dados.tipo_ataque == "magica") ? calcular_defesa_magica_total(_defensor) : calcular_defesa_fisica_total(_defensor));
    aplicar_flash_dano(_defensor, 18, _atacante, _defesa_usada);
    var _dano_final = _dano_original + _dados.mod_usado + bonus_cemiterio_dano(_atacante);
    _dano_final = max(0, _dano_final - _defesa_usada - (_dados.ignora_defesa ? 0 : obj_controlador.terreno_bonus_defesa));
    _defensor.vida -= _dano_final;
    mostrar_dano_tropa(_defensor, _dano_final);
    debug_combate(_defensor.nome_carta + " tomou " + string(_dano_final) + " de dano " + _dados.tipo_ataque + "! Vida agora: " + string(_defensor.vida));

    if (_defensor.vida <= 0) {
        if (tem_habilidade(_atacante, "digestao")) _atacante.digestao_cadaver_disponivel = true;
        _defensor.tipo_morte_visual = (_dados.tipo_ataque == "magica") ? "magica" : "fisica";
        destruir_tropa(_defensor);
    }
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
    if (obj_controlador.critico_escolha_ativa || obj_controlador.rolagens_pendentes > 0) return;
    while (array_length(obj_controlador.criticos_pendentes) > 0) {
        var _contexto = obj_controlador.criticos_pendentes[0];
        array_delete(obj_controlador.criticos_pendentes, 0, 1);
        if (!instance_exists(_contexto.atacante) || !instance_exists(_contexto.defensor)) continue;
        obj_controlador.critico_contexto = _contexto;
        obj_controlador.critico_escolha_ativa = true;
        obj_controlador.carta_menu_aberto = noone;
        return;
    }
    obj_controlador.critico_contexto = noone;
}

function enfileirar_escolha_critico(_contexto) {
    array_push(obj_controlador.criticos_pendentes, _contexto);
    abrir_proxima_escolha_critico();
}

function resolver_escolha_critico(_modo) {
    if (!obj_controlador.critico_escolha_ativa) return;
    var _contexto = obj_controlador.critico_contexto;
    obj_controlador.critico_escolha_ativa = false;
    obj_controlador.critico_contexto = noone;
    if (instance_exists(_contexto.atacante)) {
        mostrar_feedback(_modo == "dobrar_dados" ? "CRÍTICO: +DADOS" : "CRÍTICO: RESULTADO ×2",
            _contexto.atacante.x, _contexto.atacante.y - 45, c_yellow, 55);
    }
    resolver_dano_de_acerto(_contexto, _modo);
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
    var _mod_contra_exibido = _defensor.mod_dano + bonus_cemiterio_dano(_defensor);
    var _dados_contra = { atacante: _atacante, defensor: _defensor };

    rolar_varios_dados_visuais(
        _defensor.x, _defensor.y, _atacante.x, _atacante.y,
        _defensor.qtd_dados_dano, _defensor.dado_dano,
        method(_dados_contra, function(_resultado) {
            if (!instance_exists(atacante) || !instance_exists(defensor)) return;
            iniciar_animacao_ataque(defensor, atacante, 18, 18);
            aplicar_flash_dano(atacante);

            var _original_contra = _resultado * ((defensor.condicao == "berserker") ? 2 : 1);
            var _dano_contra = _original_contra + defensor.mod_dano + bonus_cemiterio_dano(defensor);
            _dano_contra = max(0, _dano_contra - calcular_defesa_fisica_total(atacante)
                - obj_controlador.terreno_bonus_defesa);
            atacante.vida -= _dano_contra;
            mostrar_dano_tropa(atacante, _dano_contra);
            debug_combate(atacante.nome_carta + " tomou " + string(_dano_contra) + " de contra-ataque. Vida: " + string(atacante.vida));
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
function processar_resultado_acerto(_dado_acerto, _atacante, _defensor, _tipo_ataque) {
    if (!instance_exists(_atacante) || !instance_exists(_defensor)
        || _atacante.morrendo || _defensor.morrendo) {
        debug_combate("--> combate cancelado: atacante ou defensor não está mais apto.");
        return;
    }
    debug_combate("D20 rolou: " + string(_dado_acerto));

    // Roubo reage à declaração do ataque com arma, mesmo quando o golpe erra.
    if (tem_habilidade(_defensor, "roubo") && _atacante.item_ataque_atual != noone) {
        tentar_roubo_item(_defensor, _atacante, _atacante.item_ataque_atual);
    }

    // pega o dado/mod/quantidade certos conforme o tipo de ataque
    var _usando_item_ataque = (_tipo_ataque == "fisica" && is_struct(_atacante.item_ataque_atual)
        && _atacante.item_ataque_atual.dado > 0);
    var _dado_usado = _usando_item_ataque ? _atacante.item_ataque_atual.dado
        : ((_tipo_ataque == "magica") ? _atacante.dado_dano_magico : _atacante.dado_dano);
    var _mod_usado = _usando_item_ataque ? _atacante.item_ataque_atual.modificador
        : ((_tipo_ataque == "magica") ? _atacante.mod_dano_magico : _atacante.mod_dano);
    var _qtd_usada = _usando_item_ataque ? 1
        : ((_tipo_ataque == "magica") ? _atacante.qtd_dados_dano_magico : _atacante.qtd_dados_dano);

    if (_dado_acerto == 1) {
        debug_combate("Erro crítico! Defensor vai contra-atacar.");
        executar_contra_ataque(_atacante, _defensor);
        return;
    }

    if (_dado_acerto <= 10) {
        debug_combate("Errou o ataque (1-10).");
        if (_atacante.condicao == "confusao") {
            debug_combate("Confusão concedeu um contra-ataque ao defensor.");
            executar_contra_ataque(_atacante, _defensor);
        }
        return;
    }

    debug_combate("Acertou! Vai rolar dano...");

    var _alvo_real = _defensor;
    if (_dado_acerto == 20 && tem_habilidade(_atacante, "tiro_burro")) {
        var _todas_tropas = [];
        with (obj_carta) {
            if (travada) array_push(_todas_tropas, id);
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

    if (_dado_acerto == 20) {
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
                + (_item.dado > 0 ? ((_item.dado + 1) / 2 + _item.modificador) : 0);
            if (_valor > _melhor_valor) { _melhor_valor = _valor; _melhor = i; }
        }
        if (_itens[_melhor].funcao != noone) array_push(obj_controlador.mao_inimigo, _itens[_melhor].funcao);
        descartar_itens_da_tropa(_itens, _carta.dono, _melhor);
        mostrar_feedback("ITEM RECUPERADO", _carta.x, _carta.y - 45, c_aqua, 55);
    }
    return true;
}

function resolver_escolha_maquina_ima(_indice) {
    if (!obj_controlador.maquina_ima_escolha_ativa || !is_struct(obj_controlador.maquina_ima_escolha_atual)) return;
    var _evento = obj_controlador.maquina_ima_escolha_atual;
    if (_indice < 0 || _indice >= array_length(_evento.itens)) return;
    var _item = _evento.itens[_indice];
    if (_item.funcao != noone) comprar_carta_do_deck_por_funcao(_item.funcao, _evento.x, _evento.y);
    descartar_itens_da_tropa(_evento.itens, _evento.dono, _indice);
    obj_controlador.maquina_ima_escolha_ativa = false;
    obj_controlador.maquina_ima_escolha_atual = noone;
    mostrar_feedback("ITEM RECUPERADO", _evento.x, _evento.y - 45, c_aqua, 55);
}

function destruir_tropa(_carta, _por_inimigo = true) {
    if (!instance_exists(_carta) || _carta.morrendo) return;
    if (_carta.tipo_morte_visual == "normal") {
        if (_carta.condicao == "queimado") _carta.tipo_morte_visual = "fogo";
        else if (_carta.condicao == "envenenado" || _carta.condicao == "apodrecer") _carta.tipo_morte_visual = "veneno";
    }
    debug_combate(_carta.nome_carta + " foi derrotada e enviada ao cemitério.");
    aplicar_efeitos_morte(_carta, _por_inimigo);

    // A Máquina Imã da mesma fileira recupera um equipamento; os demais são descartados.
    var _maquina_recuperou = processar_maquina_ima_na_morte(_carta);
    if (!_maquina_recuperou) descartar_itens_da_tropa(_carta.itens_equipados, _carta.dono);
    _carta.itens_equipados = [];
    _carta.item_ataque_atual = noone;

    if (_carta.selo_abissal) {
        mandar_para_abismo(_carta.nome_carta);
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
    _carta.condicao = noone;
}

// Registra cartas da mão abstrata da IA, que não possuem uma instância visual.
function registrar_descarte_dados(_dados, _dono) {
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
    var _destino = (_carta.dono == "jogador") ? obj_controlador.descarte_jogador : obj_controlador.descarte_inimigo;
    array_push(_destino, {
        nome: _carta.nome_carta,
        categoria: _carta.categoria,
        sprite: _carta.sprite_index,
        descricao: descricao_carta_preview(_carta)
    });
    if (_carta.dono == "jogador") obj_controlador.descarte_jogador = _destino;
    else obj_controlador.descarte_inimigo = _destino;
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
            obj_controlador.mitose_selecao_ativa = true;
            obj_controlador.mitose_dados_pendentes = _dados_filhote;
            obj_controlador.mitose_funcao_pendente = _funcao_filhote;
            obj_controlador.mitose_slots_pendentes = _slots_livres;
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

#region Dado visual (D20 / dado de dano)
// Cria um dado animado que desliza do atacante até o defensor, gira, e para no valor
// já decidido (_resultado_final). Quando termina, chama _funcao_callback com o resultado.
function rolar_dado_visual(_x, _y, _destino_x, _destino_y, _tamanho_dado, _resultado_final, _funcao_callback, _modificador_exibido = 0, _atraso_inicio = 0, _tempo_total = -1, _dono_rolagem = "") {
    var _dado = instance_create_layer(_x, _y, "Instances", obj_dado);
    obj_controlador.rolagens_pendentes += 1;

    _dado.tamanho_dado = _tamanho_dado;
    _dado.valor_final = _resultado_final;
    _dado.modificador_exibido = _modificador_exibido;
    _dado.destino_x = _destino_x;
    _dado.destino_y = _destino_y;
    _dado.atraso_inicio = max(0, _atraso_inicio);
    _dado.image_alpha = (_dado.atraso_inicio > 0) ? 0 : 1;
    if (_tempo_total > 0) _dado.tempo_total_giro = _tempo_total;
    _dado.girando = true;
    _dado.tempo_girando = 0;
    if (_funcao_callback != noone && _dono_rolagem != "") {
        var _ctx_manipulado = { dono: _dono_rolagem, tamanho: _tamanho_dado, callback_real: _funcao_callback };
        _dado.callback = method(_ctx_manipulado, function(_valor_visual) {
            entregar_resultado_dado_manipulado(dono, tamanho, _valor_visual, callback_real);
        });
    } else {
        _dado.callback = _funcao_callback;
    }
    return _dado;
}
#endregion

#region Moeda visual (cara ou coroa)
// Mesmo princípio do dado: desliza, gira, para num resultado já sorteado, e chama o callback.
function jogar_moeda_visual(_origem_x, _origem_y, _destino_x, _destino_y, _funcao_callback) {
    var _resultado = irandom(1);

    var _moeda = instance_create_layer(_origem_x, _origem_y, "Instances", obj_moeda);
    _moeda.resultado_final = _resultado;
    _moeda.pos_inicial_x = _origem_x;
    _moeda.pos_inicial_y = _origem_y;
    _moeda.destino_x = _destino_x;
    _moeda.destino_y = _destino_y;
    _moeda.escala_moeda = global.MOEDA_LARGURA / sprite_get_width(_moeda.sprite_index);
    _moeda.desvio_lateral_moeda = choose(-1, 1) * irandom_range(6, 14);
    _moeda.girando = true;
    _moeda.tempo_girando = 0;
    _moeda.callback = _funcao_callback;

    _moeda.som_volume = 0.4;

	_moeda.som_arremesso = audio_play_sound(
	    snd_moeda_arremesso,
	    1,
	    0,
	    _moeda.som_volume,
	    0,
	    random_range(.95, 1.05)
	);

    obj_controlador.rolagens_pendentes += 1;
    debug_combate("+1 pendente (moeda id=" + string(_moeda.id) + "). Total: " + string(obj_controlador.rolagens_pendentes));
}
#endregion

#region Turnos — fluxo do jogador e da IA
function preparar_dado_disputa_inicial() {
    if (obj_controlador.rolagens_pendentes > 0) return;
    if (instance_exists(obj_controlador.dado_iniciativa_id)) instance_destroy(obj_controlador.dado_iniciativa_id);

    var _dado = instance_create_layer(room_width * 0.50, room_height * 0.68, "Instances", obj_dado);
    _dado.tamanho_dado = 20;
    _dado.valor_final = -1;
    _dado.interativo_iniciativa = true;
    _dado.ocultar_resultado_ate_rolar = true;
    _dado.girando = false;
    _dado.escala_base_dado = 3.25;
    _dado.image_xscale = _dado.escala_base_dado;
    _dado.image_yscale = _dado.escala_base_dado;
    _dado.iniciativa_mesa_x = _dado.x;
    _dado.iniciativa_mesa_y = _dado.y;
    obj_controlador.dado_iniciativa_id = _dado;
    obj_controlador.disputa_inicial_estado = "aguardando_arremesso";
}

// Chamado pelo próprio D20 quando o jogador realmente o arrasta e solta.
function lancar_dado_disputa_inicial(_dado, _velocidade_arremesso) {
    if (!instance_exists(_dado) || obj_controlador.disputa_inicial_estado != "aguardando_arremesso") return;

    obj_controlador.disputa_inicial_estado = "rolando";
    obj_controlador.disputa_inicial_resultado_jogador = -1;
    obj_controlador.disputa_inicial_resultado_inimigo = -1;

    var _resultado_jogador = irandom_range(1, 20);
    var _resultado_inimigo = irandom_range(1, 20);
    var _controle_jogador = { controle: instance_find(obj_controlador, 0) };
    var _controle_inimigo = { controle: instance_find(obj_controlador, 0) };
    // O seu dado continua na direção do gesto; o da IA escolhe outro pouso a cada disputa.
    var _margem_dado = 58;
    var _destino_jogador_x = clamp(_dado.x + _dado.iniciativa_velocidade_x * 7,
        _margem_dado, room_width - _margem_dado);
    var _destino_jogador_y = clamp(_dado.y + _dado.iniciativa_velocidade_y * 7,
        90, room_height - 135);
    var _destino_ia_x = random_range(room_width * 0.18, room_width * 0.82);
    var _destino_ia_y = random_range(room_height * 0.14, room_height * 0.46);
    for (var _tentativa_ia = 0; _tentativa_ia < 6; _tentativa_ia++) {
        if (point_distance(_destino_jogador_x, _destino_jogador_y, _destino_ia_x, _destino_ia_y) >= 145) break;
        _destino_ia_x = random_range(room_width * 0.18, room_width * 0.82);
        _destino_ia_y = random_range(room_height * 0.14, room_height * 0.46);
    }

    _dado.interativo_iniciativa = false;
    _dado.ocultar_resultado_ate_rolar = false;
    _dado.tamanho_dado = 20;
    _dado.valor_final = _resultado_jogador;
    _dado.modificador_exibido = 0;
    _dado.rotulo_resultado = "";
    _dado.cor_resultado = c_white;
    _dado.escala_texto_resultado = 1.22;
    _dado.offset_texto_resultado = 2;
    _dado.pos_inicial_x = _dado.x;
    _dado.pos_inicial_y = _dado.y;
    _dado.destino_x = _destino_jogador_x;
    _dado.destino_y = _destino_jogador_y;
    _dado.depth = -2000;
    _dado.altura_maxima_dado = 75 + min(55, _velocidade_arremesso * 3);
    _dado.tempo_total_giro = clamp(round(82 - _velocidade_arremesso * 1.5), 50, 82);
    _dado.tempo_girando = 0;
    _dado.girando = true;
    _dado.callback = method(_controle_jogador, function(_resultado) {
        if (!instance_exists(controle)) return;
        controle.disputa_inicial_resultado_jogador = _resultado;
        if (controle.disputa_inicial_resultado_inimigo >= 0) {
            controle.disputa_inicial_estado = "resultado";
            controle.disputa_inicial_timer = 55;
        }
    });
    obj_controlador.rolagens_pendentes += 1;

    var _dado_ia = rolar_dado_visual(random_range(room_width * 0.32, room_width * 0.68), 55, _destino_ia_x, _destino_ia_y,
        20, _resultado_inimigo, method(_controle_inimigo, function(_resultado) {
            if (!instance_exists(controle)) return;
            controle.disputa_inicial_resultado_inimigo = _resultado;
            if (controle.disputa_inicial_resultado_jogador >= 0) {
                controle.disputa_inicial_estado = "resultado";
                controle.disputa_inicial_timer = 55;
            }
        }), 0, irandom_range(8, 15), 78 + irandom_range(-5, 12));
    _dado_ia.rotulo_resultado = "";
    _dado_ia.cor_resultado = c_white;
    _dado_ia.escala_texto_resultado = 1.22;
    _dado_ia.offset_texto_resultado = 2;
}

// Compatibilidade com chamadas antigas: agora apenas coloca o D20 sobre a mesa.
function rolar_disputa_inicial() {
    preparar_dado_disputa_inicial();
}

function finalizar_disputa_inicial(_primeiro) {
    if (!obj_controlador.mao_inicial_comprada) {
        obj_controlador.disputa_inicial_primeiro_escolhido = _primeiro;
        obj_controlador.disputa_inicial_estado = "aguardando_deck";
        obj_controlador.disputa_inicial_vencedor = "";
        mostrar_feedback((_primeiro == "jogador") ? "VOCÊ COMEÇA — COMPRE SUA MÃO" : "INIMIGO COMEÇA — COMPRE SUA MÃO",
            obj_deck.x, obj_deck.y - 55, (_primeiro == "jogador") ? c_aqua : c_red, 80);
        return;
    }

    obj_controlador.disputa_inicial_estado = "concluida";
    obj_controlador.disputa_inicial_vencedor = "";
    obj_controlador.partida_iniciada = true;
    debug_combate((_primeiro == "jogador" ? "Jogador" : "Inimigo") + " foi escolhido para começar a partida.");

    if (_primeiro == "jogador") {
        obj_controlador.turno = "jogador";
        anunciar_turno("jogador");
    } else {
        iniciar_turno_inimigo(false);
    }
}

function passar_turno_jogador() {
    if (obj_controlador.turno != "jogador") return;
    if (obj_controlador.rolagens_pendentes > 0 || obj_controlador.critico_escolha_ativa
        || array_length(obj_controlador.criticos_pendentes) > 0) return;

    obj_controlador.carta_menu_aberto = noone;
    obj_controlador.primeiro_turno_jogador = false;
    // Condições temporárias do jogador expiram somente após ele ter a chance de agir.
    expirar_condicoes("jogador");

    iniciar_turno_inimigo();
}

function anunciar_turno(_dono) {
    obj_controlador.onda_turno_timer = obj_controlador.onda_turno_duracao;
    obj_controlador.anuncio_turno_texto = (_dono == "jogador") ? "SEU TURNO" : "TURNO DO INIMIGO";
    obj_controlador.anuncio_turno_timer = obj_controlador.anuncio_turno_duracao;
}

function iniciar_turno_inimigo(_comprar_no_inicio = true) {
    obj_controlador.turno = "inimigo";
    anunciar_turno("inimigo");

    obj_controlador.itens_usados_este_turno = 0;
    obj_controlador.magias_usadas_este_turno = 0;
    obj_controlador.construcoes_jogadas_este_turno = 0;
    obj_controlador.terrenos_jogados_este_turno = 0;

	reiniciar_acoes_tropas("inimigo");

    processar_condicoes("inimigo");
    desvirar_recursos("inimigo");
    processar_construcoes_inicio_turno("inimigo");
    if (_comprar_no_inicio) comprar_carta_do_deck_ia();

    obj_controlador.ia_ativa = true;
    obj_controlador.ia_etapa = 0;
    obj_controlador.ia_tempo_espera = 45;
    obj_controlador.ia_texto_acao = "intenção: planejar o campo";
}

// Executa uma ação por vez. As pausas deixam claros os movimentos da IA,
// mas o texto é genérico para a mão inimiga continuar secreta.
function processar_turno_ia() {
    if (!obj_controlador.ia_ativa) return;
    if (obj_controlador.rolagens_pendentes > 0) {
        obj_controlador.ia_texto_acao = "resolvendo efeitos...";
        return;
    }
    if (ia_ativar_armadilhas_prontas()) {
        obj_controlador.ia_texto_acao = "ativando uma armadilha...";
        obj_controlador.ia_tempo_espera = 35;
        return;
    }
    if (obj_controlador.ia_tempo_espera > 0) {
        obj_controlador.ia_tempo_espera--;
        return;
    }

    switch (obj_controlador.ia_etapa) {
        case 0:
            obj_controlador.ia_texto_acao = "intenção: preparar recursos e efeitos";
            ia_jogar_recursos();
            ia_jogar_bencaos_maldicoes();
            obj_controlador.ia_etapa = 1;
            obj_controlador.ia_tempo_espera = 55;
        break;
        case 1:
            obj_controlador.ia_texto_acao = "intenção: controlar o campo";
            ia_jogar_construcao();
            ia_usar_construcoes();
            ia_jogar_terreno();
            obj_controlador.ia_etapa = 2;
            obj_controlador.ia_tempo_espera = 55;
        break;
        case 2:
            obj_controlador.ia_texto_acao = "intenção: convocar uma tropa";
            ia_jogar_cartas();
            obj_controlador.ia_etapa = 3;
            obj_controlador.ia_tempo_espera = 65;
        break;
        case 3:
            obj_controlador.ia_texto_acao = "intenção: usar itens e preparar defesas";
            ia_jogar_itens();
            ia_preparar_armadilha();
            obj_controlador.ia_etapa = 4;
            obj_controlador.ia_tempo_espera = 60;
        break;
        case 4:
            obj_controlador.ia_texto_acao = "intenção: evoluir e usar habilidades";
            ia_evoluir_tropa();
            ia_usar_grimorios();
            ia_usar_habilidades_tropas();
            obj_controlador.ia_etapa = 5;
            obj_controlador.ia_tempo_espera = 55;
        break;
        case 5:
            obj_controlador.ia_texto_acao = "intenção: avançar tropas";
            mover_tropas_automatico("inimigo");
            ia_configurar_defesa_castelo();
            obj_controlador.ia_etapa = 6;
            obj_controlador.ia_tempo_espera = 70;
        break;
        case 6:
            obj_controlador.ia_texto_acao = "intenção: escolher magias e alvos";
            if (ia_jogar_magias()) {
                obj_controlador.ia_tempo_espera = 45;
            } else {
                obj_controlador.ia_etapa = 7;
                obj_controlador.ia_tempo_espera = 35;
            }
        break;
        case 7:
            obj_controlador.ia_texto_acao = "intenção: atacar";
            if (!obj_controlador.primeiro_turno_inimigo) processar_combate("inimigo");
            obj_controlador.ia_etapa = 8;
            obj_controlador.ia_tempo_espera = 45;
        break;
        case 8:
            expirar_condicoes("inimigo");
            obj_controlador.primeiro_turno_inimigo = false;
            obj_controlador.ia_ativa = false;
            obj_controlador.ia_texto_acao = "";
            obj_controlador.turno = "jogador";
            obj_controlador.turnos_completos += 1;
            anunciar_turno("jogador");

            reiniciar_acoes_tropas("jogador");
            processar_condicoes("jogador");
            desvirar_recursos("jogador");
            processar_construcoes_inicio_turno("jogador");
            if (instance_exists(obj_deck) && array_length(obj_controlador.monte) > 0) {
                comprar_carta_do_deck(obj_deck.x, obj_deck.y);
            }
            obj_controlador.itens_usados_este_turno = 0;
            obj_controlador.magias_usadas_este_turno = 0;
            obj_controlador.construcoes_jogadas_este_turno = 0;
            obj_controlador.terrenos_jogados_este_turno = 0;
            obj_controlador.cartas_jogadas_no_turno = 0;
        break;
    }
}

function reiniciar_acoes_tropas(_lado) {
    with (obj_carta) {
        if (dono == _lado && travada) {
            moveu_este_turno = false;
            atacou_este_turno = false;
            habilidade_usada_este_turno = false;
            troca_item_usada_este_turno = false;
            grimorio_usado_este_turno = false;
            if (grimorio_escudo_ativo) {
                defesa_magica = max(0, defesa_magica - 2);
                grimorio_escudo_ativo = false;
            }
            turnos_no_campo += 1;
        }
    }

    with (obj_construcao) {
        if (dono == _lado) {
            habilidade_usada_este_turno = false;
        }
    }

    if (_lado == "jogador") {
        obj_controlador.evolucoes_jogador_este_turno = 0;
    } else {
        obj_controlador.evolucoes_inimigo_este_turno = 0;
    }
}
#endregion

#region IA — jogar cartas, recursos e construções
// A IA guarda a mão em structs, então avalia a força da tropa antes de criá-la.
function ia_valor_tropa_dados(_dados) {
    var _qtd_fisica = variable_struct_exists(_dados, "qtd_dados_dano") ? _dados.qtd_dados_dano : 1;
    var _qtd_magica = variable_struct_exists(_dados, "qtd_dados_dano_magico") ? _dados.qtd_dados_dano_magico : 1;
    var _fisico = _qtd_fisica * ((_dados.dado_dano + 1) / 2) + _dados.mod_dano;
    var _magico = _qtd_magica * ((_dados.dado_dano_magico + 1) / 2) + _dados.mod_dano_magico;
    var _habilidades = variable_struct_exists(_dados, "habilidades") ? array_length(_dados.habilidades) : 0;
    return _dados.vida * 0.45 + max(_fisico, _magico) * 1.8 + _dados.defesa_fisica + _dados.defesa_magica + _habilidades * 2;
}

// O Hemodrenário gera Sangue ao ver uma tropa inimiga morrer na própria fileira.
function ia_escolher_indice_tropa() {
    var _melhor_indice = -1;
    var _melhor_valor = -999999;

    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _dados = obj_controlador.mao_inimigo[i]();
        if (_dados.categoria != "tropa" || !pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;

        var _valor = ia_valor_tropa_dados(_dados);
        if (_valor > _melhor_valor) {
            _melhor_valor = _valor;
            _melhor_indice = i;
        }
    }
    return _melhor_indice;
}

// Escolhe a faixa com um alvo mais próximo/vulnerável e evita bloquear a própria tropa.
function ia_escolher_slot_entrada() {
    var _melhor_slot = noone;
    var _melhor_pontuacao = -999999;

    with (obj_slot_batalha) {
        if (posicao != posicao_entrada("inimigo") || ocupado) continue;
        if (buscar_tropa_na_coluna(lane, "inimigo") != noone) continue;

        var _pontuacao = 8;
        var _bloqueio = buscar_slot(lane, 1);
        if (_bloqueio != noone && _bloqueio.ocupado && _bloqueio.carta_atual.dono == "inimigo") {
            _pontuacao -= 1000;
        }

        // Quanto mais perto do centro estiver a ameaça do jogador, maior a prioridade.
        for (var _pos = posicao_ataque(); _pos < total_posicoes_batalha(); _pos++) {
            var _slot_jogador = buscar_slot(lane, _pos);
            if (_slot_jogador == noone || !_slot_jogador.ocupado) continue;
            var _alvo = _slot_jogador.carta_atual;
            if (_alvo.dono != "jogador") continue;

            _pontuacao += (total_posicoes_batalha() - _pos) * 12;
            _pontuacao += ia_poder_ataque(_alvo) * 2;
            _pontuacao += (_alvo.vida_maxima - _alvo.vida) * 1.5;
            break;
        }

        if (_pontuacao > _melhor_pontuacao) {
            _melhor_pontuacao = _pontuacao;
            _melhor_slot = id;
        }
    }
    return _melhor_slot;
}

function ia_pontuacao_alvo_magia(_dados, _alvo) {
    var _pontuacao = ia_poder_ataque(_alvo) * 5 + (_alvo.vida_maxima - _alvo.vida);
    switch (_dados.nome) {
        case "Bola de Fogo":
            var _dano_medio = (_dados.dado_efeito + 1) / 2;
            if (_alvo.vida <= _dano_medio) _pontuacao += 100;
            _pontuacao += (_alvo.vida_maxima - _alvo.vida) * 2;
        break;
        case "Veneno Mortal":
            _pontuacao += _alvo.vida_maxima * 2;
            if (_alvo.condicao == "envenenado") _pontuacao -= 1000;
        break;
        case "Congelante":
            if (_alvo.condicao == "congelado" || _alvo.condicao == "paralisado") _pontuacao -= 1000;
        break;
        case "Choque Elétrico":
            if (_alvo.condicao == "paralisado") _pontuacao -= 1000;
        break;
    }
    return _pontuacao;
}

function ia_escolher_alvo_magia(_dados) {
    var _escolha = { tipo: "", alvo: noone, dono_castelo: "", pontuacao: -999999 };

    if (_dados.nome == "Dados Manipulados") return { tipo: "propria", alvo: noone, dono_castelo: "", pontuacao: 85 };
    if (_dados.nome == "Sangue Suga") return { tipo: "propria", alvo: noone, dono_castelo: "", pontuacao: 70 };
    if (_dados.nome == "Refração Temporal" && ultima_carta_jogada("inimigo") != noone)
        return { tipo: "propria", alvo: noone, dono_castelo: "", pontuacao: 75 };
    if (_dados.nome == "Bloqueio de Recurso") {
        with (obj_recurso) {
            if (dono != "jogador" || bloqueado_turnos > 0) continue;
            var _p = virado ? 35 : 90;
            if (_p > _escolha.pontuacao) {
                _escolha.tipo = "recurso"; _escolha.alvo = id; _escolha.pontuacao = _p;
            }
        }
        return _escolha;
    }

    with (obj_carta) {
        if (!travada || dono != "jogador" || sombra_ativa) continue;
        if (_dados.nome == "Eutanásia" && vida > 5) continue;
        var _pontuacao = ia_pontuacao_alvo_magia(_dados, id);
        if (_dados.nome == "Eutanásia") _pontuacao += 500;
        if (_pontuacao > _escolha.pontuacao) {
            _escolha.tipo = "tropa";
            _escolha.alvo = id;
            _escolha.pontuacao = _pontuacao;
        }
    }

    if (_dados.nome == "Bola de Fogo") {
        var _media = (_dados.dado_efeito + 1) / 2;
        with (obj_construcao) {
            if (dono != "jogador") continue;
            var _pontuacao_construcao = 45 + (vida_maxima - vida) * 3;
            if (vida <= _media) _pontuacao_construcao += 120;
            if (nome_construcao == "Hemodrenário") _pontuacao_construcao += 35;
            if (_pontuacao_construcao > _escolha.pontuacao) {
                _escolha.tipo = "construcao";
                _escolha.alvo = id;
                _escolha.pontuacao = _pontuacao_construcao;
            }
        }

        var _pontuacao_castelo = 70 + (20 - obj_controlador.vida_jogador) * 4;
        if (obj_controlador.vida_jogador <= _dados.dado_efeito) _pontuacao_castelo += 1000;
        if (_pontuacao_castelo > _escolha.pontuacao) {
            _escolha.tipo = "castelo";
            _escolha.alvo = noone;
            _escolha.dono_castelo = "jogador";
            _escolha.pontuacao = _pontuacao_castelo;
        }
    }
    return _escolha;
}

// Usa no máximo uma magia por turno e considera tropas, construções e castelo
// quando a carta escolhida for Bola de Fogo.
function ia_jogar_magias() {
    if (obj_controlador.primeiro_turno_inimigo || obj_controlador.magias_usadas_este_turno >= 2) return false;

    var _melhor_indice = -1;
    var _melhor_escolha = noone;
    var _melhor_pontuacao = -999999;
    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _dados = obj_controlador.mao_inimigo[i]();
        if (_dados.categoria != "magica" || !pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;
        var _escolha = ia_escolher_alvo_magia(_dados);
        if (_escolha.tipo == "" || _escolha.pontuacao <= _melhor_pontuacao) continue;
        _melhor_pontuacao = _escolha.pontuacao;
        _melhor_indice = i;
        _melhor_escolha = _escolha;
    }
    if (_melhor_indice == -1 || !is_struct(_melhor_escolha)) return false;

    var _funcao_magia = obj_controlador.mao_inimigo[_melhor_indice];
    var _magia = _funcao_magia();
    pagar_custo(_magia.custo, "inimigo", _magia.categoria);
    array_delete(obj_controlador.mao_inimigo, _melhor_indice, 1);
    registrar_descarte_dados(_magia, "inimigo");
    registrar_ultima_carta_jogada(_funcao_magia, "inimigo");

    switch (_magia.nome) {
        case "Bola de Fogo":
            lancar_bola_de_fogo(_melhor_escolha.alvo, _magia.dado_efeito, _magia.chance_queimar,
                _melhor_escolha.tipo, _melhor_escolha.dono_castelo, "inimigo");
        break;
        case "Veneno Mortal": aplicar_envenenado(_melhor_escolha.alvo); break;
        case "Congelante": aplicar_congelado(_melhor_escolha.alvo); break;
        case "Choque Elétrico": aplicar_eletrocutado(_melhor_escolha.alvo); break;
        case "Eutanásia": destruir_tropa(_melhor_escolha.alvo, true); break;
        case "Bloqueio de Recurso": bloquear_recurso(_melhor_escolha.alvo, 3); break;
        case "Sangue Suga": buscar_recurso_no_deck("sangue", "inimigo"); break;
        case "Dados Manipulados": ativar_dados_manipulados("inimigo", room_width / 2, 90); break;
        case "Refração Temporal":
            var _ultima_ia = ultima_carta_jogada("inimigo");
            if (_ultima_ia != noone) {
                var _ctx_refracao = { base: _ultima_ia };
                array_push(obj_controlador.mao_inimigo, method(_ctx_refracao, function() {
                    var _copia = base();
                    if (_copia.categoria == "construcao") _copia.vida = max(1, ceil(_copia.vida * 0.5));
                    return _copia;
                }));
            }
        break;
        default:
            if (variable_struct_exists(_magia, "efeito_tipo")) aplicar_condicao_por_chave(_melhor_escolha.alvo, _magia.efeito_tipo);
        break;
    }

    var _nome_alvo = "efeito próprio";
    if (_melhor_escolha.tipo == "castelo") _nome_alvo = "castelo do jogador";
    else if (_melhor_escolha.tipo == "construcao") _nome_alvo = _melhor_escolha.alvo.nome_construcao;
    else if (_melhor_escolha.tipo == "tropa")
        _nome_alvo = instance_exists(_melhor_escolha.alvo) ? _melhor_escolha.alvo.nome_carta : "tropa";
    else if (_melhor_escolha.tipo == "recurso") _nome_alvo = "recurso do jogador";
    obj_controlador.magias_usadas_este_turno += 1;
    debug_combate("IA usou " + _magia.nome + " em " + _nome_alvo + ".");
    return true;
}

function ia_valor_tropa_campo(_carta) {
    return _carta.vida * 0.45 + ia_poder_ataque(_carta) * 1.8 + _carta.defesa_fisica + _carta.defesa_magica;
}

// Evolui só uma tropa por turno, dando prioridade à transformação que mais fortalece o campo.
function ia_evoluir_tropa() {
    if (!evolucoes_disponiveis("inimigo")) return;

    var _melhor_tropa = noone;
    var _melhor_ganho = 0;

    with (obj_carta) {
        if (!travada || dono != "inimigo" || funcao_evolucao == noone || turnos_no_campo < 1) continue;
        var _dados_evolucao = funcao_evolucao();
        if (!pode_pagar_custo(_dados_evolucao.custo, "inimigo")) continue;

        var _ganho = ia_valor_tropa_dados(_dados_evolucao) - ia_valor_tropa_campo(id);
        if (_ganho > _melhor_ganho) {
            _melhor_ganho = _ganho;
            _melhor_tropa = id;
        }
    }

    if (_melhor_tropa != noone) {
        debug_combate("IA evolui " + _melhor_tropa.nome_carta + " (ganho tático: " + string(round(_melhor_ganho)) + ").");
        evoluir_tropa(_melhor_tropa);
    }
}

// Retorna uma tropa do jogador que a carta inimiga consegue atingir neste momento.
function ia_alvo_atingivel(_carta) {
    if (!instance_exists(_carta) || _carta.slot_atual == noone) return noone;

    var _slot = _carta.slot_atual;
    var _sentido = direcao_avanco(_carta.dono);
    var _slot_alvo = buscar_slot(_slot.lane, _slot.posicao + _sentido);
    var _tem_alcance = tem_habilidade(_carta, "alcance") || tem_habilidade(_carta, "alcance_magico");

    if ((_slot_alvo == noone || !_slot_alvo.ocupado) && _tem_alcance) {
        var _slot_longe = buscar_slot(_slot.lane, _slot.posicao + _sentido * 2);
        if (_slot_longe != noone && _slot_longe.ocupado) _slot_alvo = _slot_longe;
    }

    if (_slot_alvo == noone || !_slot_alvo.ocupado) return noone;
    var _alvo = _slot_alvo.carta_atual;
    if (_alvo.dono != "jogador" || _alvo.sombra_ativa) return noone;
    if (tem_habilidade(_alvo, "voar") && !tem_habilidade(_carta, "voar") && !_tem_alcance) return noone;
    return _alvo;
}

// Verifica se uma tropa do jogador pode ameaçar esta carta no próximo ataque.
function ia_tropa_ameacada(_carta) {
    if (_carta.slot_atual == noone) return false;
    var _slot = _carta.slot_atual;
    var _sentido_jogador = direcao_avanco("jogador");

    for (var _distancia = 1; _distancia <= 2; _distancia++) {
        var _slot_inimigo = buscar_slot(_slot.lane, _slot.posicao - _sentido_jogador * _distancia);
        if (_slot_inimigo == noone || !_slot_inimigo.ocupado) continue;
        var _ameaca = _slot_inimigo.carta_atual;
        if (_ameaca.dono != "jogador") continue;
        if (_distancia == 2 && !tem_habilidade(_ameaca, "alcance") && !tem_habilidade(_ameaca, "alcance_magico")) continue;
        if (ia_poder_ataque(_ameaca) >= _carta.vida * 0.5) return true;
    }
    return false;
}

// Decide se uma tropa na base deve interceptar ataques ao castelo. A IA protege
// o castelo quando ele já sofreu dano ou quando a tropa sobreviveria a um golpe médio.
function ia_configurar_defesa_castelo() {
    with (obj_carta) {
        if (!travada || dono != "inimigo") continue;
        if (posicao_atual != posicao_entrada("inimigo")) {
            defendendo_castelo = false;
            continue;
        }
        defendendo_castelo = obj_controlador.vida_inimigo <= 15 || vida >= 6;
    }
}

// Habilidades são usadas apenas quando têm impacto imediato ou proteção concreta.
function ia_usar_habilidades_tropas() {
    if (obj_controlador.primeiro_turno_inimigo) return;

    with (obj_carta) {
        if (!travada || dono != "inimigo" || habilidade_usada_este_turno) continue;

        var _habilidade = tem_habilidade_ativa(id);
        switch (_habilidade) {
            case "golpe_duplo":
                if (!atacou_este_turno && (ia_alvo_atingivel(id) != noone || posicao_atual == posicao_assalto("inimigo"))) {
                    usar_habilidade(id);
                }
            break;
            case "ferida_exposta":
            case "imitacao":
                // Essas duas habilidades exigem uma tropa imediatamente à frente.
                var _slot_frente = buscar_slot(lane_atual, posicao_atual + direcao_avanco("inimigo"));
                if (_slot_frente != noone && _slot_frente.ocupado && _slot_frente.carta_atual.dono == "jogador") {
                    usar_habilidade(id);
                }
            break;
            case "sombra_translucida":
                var _custo_sombra = { tipo: "mana", quantidade: 2 };
                if (sombra_cooldown <= 0 && ia_tropa_ameacada(id) && pode_pagar_custo(_custo_sombra, "inimigo")) {
                    usar_habilidade(id);
                }
            break;
            case "visao_do_veu":
                if (!visao_do_veu_usada) usar_habilidade(id);
            break;
            case "digestao":
                if (digestao_usos < usos_maximos_digestao(id)) {
                    if (digestao_cadaver_disponivel) usar_habilidade(id);
                    else {
                        var _pode_digerir = false;
                        with (obj_carta) if (alvo_valido_digestao(other.id, id)) { _pode_digerir = true; break; }
                        if (_pode_digerir) usar_habilidade(id);
                    }
                }
            break;
            case "carnica_frenetica":
                if (carnica_estado_proximo_ataque == "" && pode_pagar_custo({ tipo: "sangue", quantidade: 2 }, "inimigo")) usar_habilidade(id);
            break;
        }
    }
}

function ia_consumir_carta_da_mao(_indice, _dados, _funcao) {
    pagar_custo(_dados.custo, "inimigo", _dados.categoria);
    array_delete(obj_controlador.mao_inimigo, _indice, 1);
    registrar_descarte_dados(_dados, "inimigo");
    registrar_ultima_carta_jogada(_funcao, "inimigo");
}

function ia_jogar_bencaos_maldicoes() {
    for (var i = array_length(obj_controlador.mao_inimigo) - 1; i >= 0; i--) {
        var _funcao_efeito_ia = obj_controlador.mao_inimigo[i];
        var _dados = _funcao_efeito_ia();
        if ((_dados.categoria != "bencao" && _dados.categoria != "maldicao")
            || !pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;
        var _sucesso = (_dados.categoria == "bencao")
            ? adicionar_bencao("inimigo", _dados.efeito, _dados.nome, _dados.sprite_carta)
            : adicionar_maldicao("inimigo", _dados.efeito, _dados.nome, _dados.sprite_carta);
        if (!_sucesso) continue;
        pagar_custo(_dados.custo, "inimigo", _dados.categoria);
        array_delete(obj_controlador.mao_inimigo, i, 1);
        registrar_ultima_carta_jogada(_funcao_efeito_ia, "inimigo");
        iniciar_animacao_bencao_maldicao(_dados.categoria, _dados.nome);
        debug_combate("IA ativou " + _dados.nome + ".");
    }
}

function ia_jogar_terreno() {
    if (obj_controlador.primeiro_turno_inimigo || obj_controlador.terrenos_jogados_este_turno >= 1) return;
    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _funcao_terreno_ia = obj_controlador.mao_inimigo[i];
        var _dados = _funcao_terreno_ia();
        if (_dados.categoria != "terreno" || !pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;

        pagar_custo(_dados.custo, "inimigo", _dados.categoria);
        array_delete(obj_controlador.mao_inimigo, i, 1);
        registrar_ultima_carta_jogada(_funcao_terreno_ia, "inimigo");
        obj_controlador.terrenos_jogados_este_turno += 1;
        obj_controlador.terreno_bonus_defesa = _dados.bonus_defesa_global;
        obj_controlador.terreno_ativo = variable_struct_exists(_dados, "efeito_terreno") ? _dados.efeito_terreno : "";
        obj_controlador.terreno_anuncio_texto = string_upper(_dados.nome);
        obj_controlador.terreno_anuncio_timer = obj_controlador.terreno_anuncio_duracao;

        var _slot_terreno = instance_find(obj_slot_terreno, 0);
        if (_slot_terreno != noone) {
            if (_slot_terreno.ocupado && instance_exists(_slot_terreno.terreno_atual)) instance_destroy(_slot_terreno.terreno_atual);
            var _visual = instance_create_layer(room_width / 2, 20, "Instances", obj_terreno_ativo);
            _visual.sprite_index = (_dados.sprite_carta != noone) ? _dados.sprite_carta : spr_carta_placeholder;
            _visual.escala_base = global.TERRENO_LARGURA_ALVO / sprite_get_height(_visual.sprite_index);
            _visual.destino_x = _slot_terreno.x;
            _visual.destino_y = _slot_terreno.y;
            _visual.origem_x = room_width / 2;
            _visual.origem_y = 20;
            _slot_terreno.ocupado = true;
            _slot_terreno.terreno_atual = _visual.id;
        }
        debug_combate("IA colocou o terreno " + _dados.nome + ".");
        return;
    }
}

function ia_melhor_tropa_propria(_exigir_mochila = false, _inteligencia_minima = -999) {
    var _melhor = noone;
    var _valor = -999999;
    with (obj_carta) {
        if (!travada || dono != "inimigo") continue;
        if (_exigir_mochila && (mochila <= 0 || troca_item_usada_este_turno)) continue;
        if (nivel_inteligencia < _inteligencia_minima) continue;
        var _pontuacao = ia_valor_tropa_campo(id);
        if (_pontuacao > _valor) {
            _valor = _pontuacao;
            _melhor = id;
        }
    }
    return _melhor;
}

function ia_melhor_tropa_ferida() {
    var _melhor = noone;
    var _vida_faltando = 0;
    with (obj_carta) {
        if (!travada || dono != "inimigo") continue;
        var _faltando = vida_maxima - vida;
        if (_faltando > _vida_faltando) {
            _vida_faltando = _faltando;
            _melhor = id;
        }
    }
    return _melhor;
}

function ia_melhor_alvo_corrosao() {
    var _melhor = noone;
    var _valor = -999999;
    with (obj_carta) {
        if (!travada || dono != "jogador" || condicao != noone) continue;
        var _pontuacao = ia_valor_tropa_campo(id);
        if (_pontuacao > _valor) {
            _valor = _pontuacao;
            _melhor = id;
        }
    }
    return _melhor;
}

function ia_jogar_itens() {
    if (obj_controlador.primeiro_turno_inimigo) return;
    var _usos = 0;
    while (_usos < 3) {
        var _usou = false;
        for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
            var _funcao_item_ia = obj_controlador.mao_inimigo[i];
            var _dados = _funcao_item_ia();
            if ((_dados.categoria != "item_equipavel" && _dados.categoria != "item_consumivel")
                || !pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;

            if (_dados.categoria == "item_equipavel") {
                var _requisito = variable_struct_exists(_dados, "requisito_inteligencia") ? _dados.requisito_inteligencia : 0;
                var _alvo_equipar = ia_melhor_tropa_propria(true, _requisito);
                if (_alvo_equipar == noone) continue;
                var _item_ia = criar_dados_item_equipado(_dados.nome,
                    variable_struct_exists(_dados, "sprite_carta") ? _dados.sprite_carta : spr_carta_placeholder,
                    _funcao_item_ia,
                    variable_struct_exists(_dados, "bonus_mod_dano") ? _dados.bonus_mod_dano : 0,
                    variable_struct_exists(_dados, "bonus_defesa") ? _dados.bonus_defesa : 0,
                    variable_struct_exists(_dados, "sobrescreve_dado_dano") ? _dados.sobrescreve_dado_dano : 0,
                    variable_struct_exists(_dados, "sobrescreve_mod_dano") ? _dados.sobrescreve_mod_dano : 0,
                    variable_struct_exists(_dados, "efeito_item") ? _dados.efeito_item : "");
                equipar_item_dados(_alvo_equipar, _item_ia);
                _alvo_equipar.troca_item_usada_este_turno = true;
                pagar_custo(_dados.custo, "inimigo", _dados.categoria);
                array_delete(obj_controlador.mao_inimigo, i, 1);
                registrar_ultima_carta_jogada(_funcao_item_ia, "inimigo");
                debug_combate("IA equipou " + _dados.nome + " em " + _alvo_equipar.nome_carta + ".");
                _usou = true;
            } else {
                var _efeito = variable_struct_exists(_dados, "efeito_tipo") ? _dados.efeito_tipo : "cura";
                var _executou = false;
                if (string_pos("buscar_", _efeito) == 1) {
                    var _tipo_recurso = string_delete(_efeito, 1, string_length("buscar_"));
                    _executou = buscar_recurso_no_deck(_tipo_recurso, "inimigo");
                } else if (_efeito == "comprar_cartas") {
                    comprar_varias_cartas(_dados.quantidade_efeito, "inimigo");
                    _executou = true;
                } else if (_efeito == "aplicar_corrosao") {
                    var _alvo_corrosao = ia_melhor_alvo_corrosao();
                    if (_alvo_corrosao != noone) {
                        aplicar_corrosao(_alvo_corrosao);
                        _executou = true;
                    }
                } else if (_efeito == "revirar_sangue") {
                    _executou = revirar_recurso("sangue", "inimigo");
                } else if (_efeito == "aumentar_intelig") {
                    var _alvo_inteligencia = ia_melhor_tropa_propria();
                    if (_alvo_inteligencia != noone) {
                        _alvo_inteligencia.nivel_inteligencia += _dados.quantidade_efeito;
                        _executou = true;
                    }
                } else {
                    var _alvo_cura = ia_melhor_tropa_ferida();
                    if (_alvo_cura != noone) {
                        _alvo_cura.vida = min(_alvo_cura.vida_maxima, _alvo_cura.vida + _dados.cura);
                        _executou = true;
                    }
                }
                if (!_executou) continue;
                ia_consumir_carta_da_mao(i, _dados, _funcao_item_ia);
                debug_combate("IA usou " + _dados.nome + ".");
                _usou = true;
            }

            if (_usou) {
                _usos += 1;
                obj_controlador.itens_usados_este_turno += 1;
                break;
            }
        }
        if (!_usou) break;
    }
}

function ia_slot_tem_armadilha(_lane, _posicao) {
    return slot_tem_armadilha(_lane, _posicao);
}

function ia_preparar_armadilha() {
    var _indice = -1;
    var _dados = noone;
    var _funcao_armadilha = noone;
    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _teste = obj_controlador.mao_inimigo[i]();
        if (_teste.categoria == "armadilha" && pode_pagar_custo(_teste.custo, "inimigo")) {
            _indice = i;
            _dados = _teste;
            _funcao_armadilha = obj_controlador.mao_inimigo[i];
            break;
        }
    }
    if (_indice == -1) return;

    var _slot_escolhido = noone;
    var _melhor_pontuacao = -999999;
    with (obj_slot_batalha) {
        if (posicao > posicao_ataque() || ia_slot_tem_armadilha(lane, posicao)) continue;
        var _lane_armadilha = lane;
        var _posicao_armadilha = posicao;
        var _pontuacao = 5 - _posicao_armadilha;
        with (obj_carta) {
            if (travada && dono == "jogador" && lane_atual == _lane_armadilha) {
                _pontuacao += 30 - abs(posicao_atual - _posicao_armadilha) * 5;
            }
        }
        if (_pontuacao > _melhor_pontuacao) {
            _melhor_pontuacao = _pontuacao;
            _slot_escolhido = id;
        }
    }
    if (_slot_escolhido == noone) return;

    pagar_custo(_dados.custo, "inimigo", _dados.categoria);
    array_delete(obj_controlador.mao_inimigo, _indice, 1);
    registrar_ultima_carta_jogada(_funcao_armadilha, "inimigo");
    var _armadilha = instance_create_layer(_slot_escolhido.x, _slot_escolhido.y, "Instances", obj_carta);
    _armadilha.nome_carta = _dados.nome;
    _armadilha.categoria = "armadilha";
    _armadilha.dono = "inimigo";
    _armadilha.sprite_index = (_dados.sprite_carta != noone) ? _dados.sprite_carta : spr_carta_placeholder;
    _armadilha.dado_efeito = _dados.dado_efeito;
    _armadilha.qtd_dados_efeito = variable_struct_exists(_dados, "qtd_dados_efeito") ? _dados.qtd_dados_efeito : 1;
    _armadilha.efeito_tipo = variable_struct_exists(_dados, "efeito_tipo") ? _dados.efeito_tipo : "armadilha_urso";
    _armadilha.armadilha_lane = _slot_escolhido.lane;
    _armadilha.armadilha_posicao = _slot_escolhido.posicao;
    _armadilha.armadilha_estado = "vigiando";
    _armadilha.esta_na_mao = false;
    _armadilha.travada = false;
    _armadilha.visible = false;
    debug_combate("IA preparou uma armadilha oculta.");
}

function ia_ativar_armadilhas_prontas() {
    if (obj_controlador.rolagens_pendentes > 0) return false;
    var _pronta = noone;
    with (obj_carta) {
        if (categoria == "armadilha" && dono == "inimigo" && armadilha_estado == "pronta") {
            _pronta = id;
            break;
        }
    }
    if (_pronta == noone) return false;
    ativar_armadilha(_pronta);
    return true;
}

function ia_jogar_cartas() {
    var _indice_mao_escolhido = ia_escolher_indice_tropa();
    var _slot_escolhido = ia_escolher_slot_entrada();
    if (_indice_mao_escolhido == -1 || _slot_escolhido == noone) return;

    var _cartas_jogadas = 0;
    var _max_cartas = 1;
	 
    with (obj_slot_batalha) {
        if (_cartas_jogadas >= _max_cartas) continue;
		if (id != _slot_escolhido) continue;

        if (posicao == posicao_entrada("inimigo") && !ocupado
            && buscar_tropa_na_coluna(lane, "inimigo") == noone) {
            if (array_length(obj_controlador.mao_inimigo) > 0) {

                var _indice_mao = _indice_mao_escolhido;
                var _funcao_sorteada = obj_controlador.mao_inimigo[_indice_mao];
                var _dados = _funcao_sorteada();

				if (_dados.categoria == "bencao") {
				    if (adicionar_bencao("inimigo", _dados.efeito, _dados.nome, _dados.sprite_carta)) {
				        array_delete(obj_controlador.mao_inimigo, _indice_mao, 1);
				    }
				    continue;
				}
				if (_dados.categoria == "maldicao") {
				    if (adicionar_maldicao("inimigo", _dados.efeito, _dados.nome, _dados.sprite_carta)) {
				        array_delete(obj_controlador.mao_inimigo, _indice_mao, 1);
				    }
				    continue;
				}
				if (_dados.categoria != "tropa") continue;
				if (!pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;

                pagar_custo(_dados.custo, "inimigo", _dados.categoria);
                array_delete(obj_controlador.mao_inimigo, _indice_mao, 1);

                var _carta = instance_create_layer(x, y, "Instances", obj_carta);
                _carta.nome_carta = _dados.nome;
                _carta.sprite_index = (_dados.sprite_carta != noone) ? _dados.sprite_carta : spr_carta_placeholder;
                _carta.escala_base = global.CARTA_LARGURA / sprite_get_width(_carta.sprite_index);
                _carta.tem_arte_propria = (_dados.sprite_carta != noone);
                _carta.categoria = _dados.categoria;
                _carta.vida = _dados.vida;
                _carta.vida_maxima = _dados.vida;
				_carta.vida_pos_x = variable_struct_exists(_dados, "vida_pos_x") ? _dados.vida_pos_x : 0.11;
				_carta.vida_pos_y = variable_struct_exists(_dados, "vida_pos_y") ? _dados.vida_pos_y : 0.07;
				_carta.selo_abissal = variable_struct_exists(_dados, "selo_abissal") ? _dados.selo_abissal : false;
				_carta.funcao_evolucao = variable_struct_exists(_dados, "evolucao") ? _dados.evolucao : noone;
                _carta.custo_sacrificio = _dados.sacrificio;
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

				_carta.vida_pos_x = variable_struct_exists(_dados, "vida_pos_x") ? _dados.vida_pos_x : 0.10;
				_carta.vida_pos_y = variable_struct_exists(_dados, "vida_pos_y") ? _dados.vida_pos_y : 0.07;
				_carta.int_pos_x = variable_struct_exists(_dados, "int_pos_x") ? _dados.int_pos_x : 0.91;
				_carta.int_pos_y = variable_struct_exists(_dados, "int_pos_y") ? _dados.int_pos_y : 0.073;
				_carta.mochila_pos_x = variable_struct_exists(_dados, "mochila_pos_x") ? _dados.mochila_pos_x : 0.91;
				_carta.mochila_pos_y = variable_struct_exists(_dados, "mochila_pos_y") ? _dados.mochila_pos_y : 0.185;
				_carta.atk_pos_x = variable_struct_exists(_dados, "atk_pos_x") ? _dados.atk_pos_x : 0.12;
				_carta.atk_pos_y = variable_struct_exists(_dados, "atk_pos_y") ? _dados.atk_pos_y : 0.92;
				_carta.atk_magico_pos_x = variable_struct_exists(_dados, "atk_magico_pos_x") ? _dados.atk_magico_pos_x : 0.37;
				_carta.atk_magico_pos_y = variable_struct_exists(_dados, "atk_magico_pos_y") ? _dados.atk_magico_pos_y : 0.92;
				_carta.def_pos_x = variable_struct_exists(_dados, "def_pos_x") ? _dados.def_pos_x : 0.62;
				_carta.def_pos_y = variable_struct_exists(_dados, "def_pos_y") ? _dados.def_pos_y : 0.92;
				_carta.def_magico_pos_x = variable_struct_exists(_dados, "def_magico_pos_x") ? _dados.def_magico_pos_x : 0.87;
				_carta.def_magico_pos_y = variable_struct_exists(_dados, "def_magico_pos_y") ? _dados.def_magico_pos_y : 0.92;

                _carta.esta_na_mao = false;
                _carta.travada = true;
                _carta.depth = -100;
                _carta.dono = "inimigo";
                _carta.lane_atual = lane;
                _carta.posicao_atual = posicao;
                _carta.destino_x = x;
                _carta.destino_y = y;
                _carta.slot_atual = id;

                ocupado = true;
                carta_atual = _carta.id;

                _carta.x = room_width / 2;
                _carta.y = -global.CARTA_ALTURA;
                iniciar_pulo_tropa(_carta, x, y, true);

                _cartas_jogadas += 1;
				
				audio_play_sound(snd_colocar,1,0,.5,0,random_range(.5,2))
            }
        }
			
    }
}

function ia_jogar_recursos() {
    // filtra na mão da IA só as cartas de recurso disponíveis
    var _indices_recurso = [];
    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _dados_teste = obj_controlador.mao_inimigo[i]();
        if (_dados_teste.categoria == "recurso") {
            array_push(_indices_recurso, i);
        }
    }

    if (array_length(_indices_recurso) == 0) {
        debug_combate("IA não tem carta de recurso na mão pra jogar.");
        return;
    }

    // Prefere, entre as opções que ela TEM na mão, o tipo que está em menor quantidade em campo.
    var _tipos = ["sangue", "ossos", "sucata", "mana"];
    var _contagens = [0, 0, 0, 0];

    var _recursos = obj_controlador.recursos_inimigo;
    for (var i = 0; i < array_length(_recursos); i++) {
        var _recurso = _recursos[i];
        if (!instance_exists(_recurso)) continue;
        for (var j = 0; j < array_length(_tipos); j++) {
            if (_recurso.tipo == _tipos[j]) {
                _contagens[j] += 1;
                break;
            }
        }
    }

    var _melhor_indice_mao = _indices_recurso[0];
    var _melhor_contagem = 9999;

    for (var i = 0; i < array_length(_indices_recurso); i++) {
        var _indice_mao = _indices_recurso[i];
        var _dados = obj_controlador.mao_inimigo[_indice_mao]();
        var _tipo_idx = array_get_index(_tipos, _dados.tipo_recurso);
        var _contagem_tipo = (_tipo_idx != -1) ? _contagens[_tipo_idx] : 0;

        if (_contagem_tipo < _melhor_contagem) {
            _melhor_contagem = _contagem_tipo;
            _melhor_indice_mao = _indice_mao;
        }
    }

    var _funcao_recurso_ia = obj_controlador.mao_inimigo[_melhor_indice_mao];
    var _dados_escolhidos = _funcao_recurso_ia();
    // Recurso vem da área oculta da mão inimiga, igual antes.
    var _resultado = colocar_recurso(_dados_escolhidos.tipo_recurso, "inimigo", room_width / 2, -global.CARTA_ALTURA);

    if (_resultado == "colocado") {
        array_delete(obj_controlador.mao_inimigo, _melhor_indice_mao, 1);
        registrar_ultima_carta_jogada(_funcao_recurso_ia, "inimigo");
    }
}

function ia_jogar_construcao() {
    if (obj_controlador.construcoes_jogadas_este_turno >= 1) return;

    // filtra na mão da IA só as cartas de construção disponíveis
    var _indices_construcao = [];
    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _dados_teste = obj_controlador.mao_inimigo[i]();
        if (_dados_teste.categoria == "construcao") {
            array_push(_indices_construcao, i);
        }
    }

    if (array_length(_indices_construcao) == 0) return;

    var _slot_livre = noone;
    with (obj_slot_construcao) {
        if (!ocupado && dono == "inimigo") {
            _slot_livre = id;
            break;
        }
    }

    if (_slot_livre == noone) return;

    // tenta cada construção que ela tem na mão até achar uma que dê pra pagar
    for (var i = 0; i < array_length(_indices_construcao); i++) {
        var _indice_mao = _indices_construcao[i];
        var _funcao_construcao_ia = obj_controlador.mao_inimigo[_indice_mao];
        var _dados = _funcao_construcao_ia();

        if (!pode_pagar_custo(_dados.custo, "inimigo", _dados.categoria)) continue;

        pagar_custo(_dados.custo, "inimigo", _dados.categoria);
        array_delete(obj_controlador.mao_inimigo, _indice_mao, 1);
        registrar_ultima_carta_jogada(_funcao_construcao_ia, "inimigo");

        var _construcao = instance_create_layer(_slot_livre.x, _slot_livre.y, "Instances", obj_construcao);
        _construcao.nome_construcao = _dados.nome;
        _construcao.nome_carta = _dados.nome;
        _construcao.custo = _dados.custo;
        if (variable_struct_exists(_dados, "sprite_carta") && _dados.sprite_carta != noone) {
            _construcao.sprite_index = _dados.sprite_carta;
            _construcao.usa_sprite_carta = true;
            _construcao.tem_arte_propria = true;
            _construcao.escala_visual_base = min((global.CARTA_LARGURA * 0.60) / sprite_get_width(_dados.sprite_carta),
                (global.CARTA_ALTURA * 0.60) / sprite_get_height(_dados.sprite_carta));
            _construcao.image_xscale = _construcao.escala_visual_base;
            _construcao.image_yscale = _construcao.escala_visual_base;
            _construcao.vida_pos_x = clamp((variable_struct_exists(_dados, "vida_pos_x") ? _dados.vida_pos_x : 0.11) + 0.05, 0, 1);
            _construcao.vida_pos_y = clamp((variable_struct_exists(_dados, "vida_pos_y") ? _dados.vida_pos_y : 0.07) + 0.05, 0, 1);
        }
        _construcao.vida = _dados.vida;
        _construcao.vida_maxima = _dados.vida;
        _construcao.dono = "inimigo";
        _construcao.lane_atual = _slot_livre.lane;
        _construcao.slot_atual = _slot_livre;
        _construcao.efeito_construcao = variable_struct_exists(_dados, "efeito_construcao") ? _dados.efeito_construcao : "";
        _construcao.dado_efeito = variable_struct_exists(_dados, "dado_efeito") ? _dados.dado_efeito : 0;
        _construcao.tem_habilidade_construcao = (_construcao.efeito_construcao != "");

        _slot_livre.ocupado = true;
        _slot_livre.construcao_atual = _construcao.id;
        obj_controlador.construcoes_jogadas_este_turno += 1;
        break; // já construiu, para de tentar
    }
}
	
function ia_usar_construcoes() {
    with (obj_construcao) {
        if (dono == "inimigo" && efeito_construcao == "hemodrenario" && !habilidade_usada_este_turno) {
            usar_habilidade_hemodrenario(id);
        }
    }
}
#endregion

#region Recursos — colocar, pagar custo, desvirar
function colocar_recurso(_tipo, _dono, _origem_x = noone, _origem_y = noone, _slot_preferido = noone) {
    var _ja_colocou = (_dono == "jogador") ? obj_controlador.recurso_colocado_no_turno : obj_controlador.recurso_colocado_no_turno_inimigo;
	if (_ja_colocou) {
        if (_dono == "jogador") mostrar_aviso_regra("Você já colocou 1 recurso neste turno", _origem_x, _origem_y);
        return "ja_colocou_no_turno";
    }
	 audio_play_sound(snd_colocar,1,0,.5,0,random_range(.5,2))
    var _slot_livre = _slot_preferido;
    if (_slot_livre == noone || _slot_livre.ocupado || _slot_livre.dono != _dono) {
        _slot_livre = noone;
        with (obj_slot_recurso) {
            if (!ocupado && dono == _dono) {
                _slot_livre = id;
                break;
            }
        }
    }

    if (_slot_livre == noone) {
        if (_dono == "jogador") mostrar_aviso_regra("Área de recursos cheia", _origem_x, _origem_y);
        return "campo_cheio";
    }

    var _x_criacao = (_origem_x == noone) ? _slot_livre.x : _origem_x;
    var _y_criacao = (_origem_y == noone) ? _slot_livre.y : _origem_y;
    var _recurso = instance_create_layer(_x_criacao, _y_criacao, "Instances", obj_recurso);
    _recurso.tipo = _tipo;
    _recurso.virado = false;
    _recurso.dono = _dono;
    _recurso.destino_x = _slot_livre.x;
    _recurso.destino_y = _slot_livre.y;
    _recurso.entrada_origem_x = _x_criacao;
    _recurso.entrada_origem_y = _y_criacao;
    _recurso.entrando_no_campo = (_origem_x != noone && _origem_y != noone);
    _recurso.entrada_progresso = 0;
    _recurso.slot_atual = _slot_livre;

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
        mostrar_feedback("+ " + string_upper(nome_recurso_exibicao(_tipo, 1)), _slot_livre.x, _slot_livre.y, c_lime, 45);
    } else {
        array_push(obj_controlador.recursos_inimigo, _recurso);
        obj_controlador.recurso_colocado_no_turno_inimigo = true;
    }

    debug_combate("" + string_upper(string_copy(_dono, 1, 1)) + string_delete(_dono, 1, 1) + " colocou " + nome_recurso_exibicao(_tipo, 1) + ".");
    return "colocado";
}

function funcao_recurso_por_tipo(_tipo) {
    switch (_tipo) {
        case "sangue": return criar_dados_recurso_sangue;
        case "ossos": return criar_dados_recurso_ossos;
        case "sucata": return criar_dados_recurso_sucata;
        case "mana": return criar_dados_recurso_mana;
    }
    return noone;
}

function retirar_recurso_do_campo(_recurso) {
    if (!instance_exists(_recurso) || _recurso.entrando_no_campo) return false;
    var _ja_retirou = (_recurso.dono == "jogador") ? obj_controlador.recurso_retirado_no_turno : obj_controlador.recurso_retirado_no_turno_inimigo;
    if (_ja_retirou) { if (_recurso.dono == "jogador") mostrar_aviso_regra("Você já retirou 1 recurso neste turno", _recurso.x, _recurso.y); return false; }
    var _lista = (_recurso.dono == "jogador") ? obj_controlador.recursos_jogador : obj_controlador.recursos_inimigo;
    var _indice = array_get_index(_lista, _recurso); if (_indice >= 0) array_delete(_lista, _indice, 1);
    if (_recurso.slot_atual != noone) { _recurso.slot_atual.ocupado = false; _recurso.slot_atual.recurso_atual = noone; }
    if (_recurso.dono == "jogador") {
        obj_controlador.recurso_retirado_no_turno = true;
        var _funcao = funcao_recurso_por_tipo(_recurso.tipo);
        if (_funcao != noone) comprar_carta_do_deck_por_funcao(_funcao, _recurso.x, _recurso.y);
        mostrar_feedback("RECURSO PARA A MÃO", _recurso.x, _recurso.y - 30, c_aqua, 45);
    } else obj_controlador.recurso_retirado_no_turno_inimigo = true;
    instance_destroy(_recurso);
    return true;
}

// função auxiliar (workaround pro "with" não enxergar _custo direto às vezes)
function other_custo_tipo(_custo) {
    return _custo.tipo;
}

// Feedback visual reutilizável para ações negadas por regra ou recurso insuficiente.
function mostrar_aviso_regra(_texto, _x = mouse_x, _y = mouse_y) {
    var _aviso = instance_create_layer(_x, _y - 24, "Instances", obj_texto_flutuante);
    _aviso.texto = _texto;
    _aviso.cor_texto = make_color_rgb(255, 210, 70);
    _aviso.vida_texto_max = 75;
    _aviso.velocidade_subida = 0.55;
}

function iniciar_retorno_carta(_carta) {
    if (!instance_exists(_carta)) return;
    _carta.arrastando = false;
    _carta.esta_na_mao = true;
    _carta.retorno_invalido_timer = _carta.retorno_invalido_duracao;
    _carta.arrasto_velocidade_x *= -0.28;
    _carta.arrasto_velocidade_y *= -0.28;
}

function criar_animacao_item(_sprite, _origem_x, _origem_y, _destino_x, _destino_y, _cor = c_aqua) {
    var _controle = instance_find(obj_controlador, 0);
    if (_controle == noone || _sprite == noone || _sprite < 0) return;
    array_push(_controle.animacoes_item, { sprite: _sprite, origem_x: _origem_x, origem_y: _origem_y,
        destino_x: _destino_x, destino_y: _destino_y, timer: 0, duracao: 34, cor: _cor });
}

function mostrar_feedback(_texto, _x, _y, _cor = c_white, _duracao = 55) {
    var _aviso = instance_create_layer(_x, _y - 24, "Instances", obj_texto_flutuante);
    _aviso.texto = _texto;
    _aviso.cor_texto = _cor;
    _aviso.vida_texto_max = _duracao;
    _aviso.velocidade_subida = 0.45;
    _aviso.oscilacao_intensidade = 1;
}

function nome_recurso_exibicao(_tipo, _quantidade) {
    switch (_tipo) {
        case "sangue": return (_quantidade == 1) ? "Sangue" : "Sangues";
        case "ossos": return (_quantidade == 1) ? "Osso" : "Ossos";
        case "sucata": return "Sucata";
        case "mana": return "Mana";
    }
    return "recurso";
}

// verifica se dá pra pagar um custo, sem gastar ainda
function ajustar_custo_por_terreno(_custo, _categoria) {
    if (_custo == noone) return [];
    var _entrada = is_array(_custo) ? _custo : [_custo];
    var _saida = [];
    for (var i = 0; i < array_length(_entrada); i++) {
        var _quantidade = _entrada[i].quantidade;
        if (_categoria == "tropa" && obj_controlador.terreno_ativo == "planicies_profanas"
            && _entrada[i].tipo == "mana") {
            _quantidade = max(0, _quantidade - 1);
        }
        if (_quantidade > 0) array_push(_saida, { tipo: _entrada[i].tipo, quantidade: _quantidade });
    }
    return _saida;
}

// Reserva recursos específicos primeiro e deixa custos neutros/"qualquer" por
// último, impedindo que a mesma carta de recurso pague duas partes do custo.
function selecionar_recursos_para_custo(_custo, _dono, _categoria = "") {
    var _necessidades = ajustar_custo_por_terreno(_custo, _categoria);
    var _disponiveis = [];
    with (obj_recurso) {
        if (!virado && dono == _dono && bloqueado_turnos <= 0) array_push(_disponiveis, id);
    }
    var _selecionados = [];
    var _faltas = [];

    for (var _passo = 0; _passo < 2; _passo++) {
        for (var i = 0; i < array_length(_necessidades); i++) {
            var _item = _necessidades[i];
            var _eh_neutro = (_item.tipo == "qualquer");
            if ((_passo == 0 && _eh_neutro) || (_passo == 1 && !_eh_neutro)) continue;
            var _pagos = 0;
            for (var j = 0; j < array_length(_disponiveis); j++) {
                var _recurso = _disponiveis[j];
                if (!instance_exists(_recurso) || array_get_index(_selecionados, _recurso) >= 0) continue;
                if (_eh_neutro || _recurso.tipo == _item.tipo) {
                    array_push(_selecionados, _recurso);
                    _pagos += 1;
                    if (_pagos >= _item.quantidade) break;
                }
            }
            if (_pagos < _item.quantidade) {
                var _falta = _item.quantidade - _pagos;
                array_push(_faltas, string(_falta) + " " + nome_recurso_exibicao(_item.tipo, _falta));
            }
        }
    }
    return { sucesso: array_length(_faltas) == 0, recursos: _selecionados, faltas: _faltas };
}

function pode_pagar_custo(_custo, _dono, _categoria = "") {
    if (_custo == noone) return true;
    var _selecao = selecionar_recursos_para_custo(_custo, _dono, _categoria);
    if (!_selecao.sucesso && _dono == "jogador") {
        var _texto = "Falta ";
        for (var i = 0; i < array_length(_selecao.faltas); i++) {
            if (i > 0) _texto += (i == array_length(_selecao.faltas) - 1) ? " e " : ", ";
            _texto += _selecao.faltas[i];
        }
        mostrar_aviso_regra(_texto);
    }
    return _selecao.sucesso;
}

function pagar_custo(_custo, _dono, _categoria = "") {
    if (_custo == noone) return true;
    var _selecao = selecionar_recursos_para_custo(_custo, _dono, _categoria);
    if (!_selecao.sucesso) return false;
    for (var i = 0; i < array_length(_selecao.recursos); i++) {
        if (instance_exists(_selecao.recursos[i])) _selecao.recursos[i].virado = true;
    }
    return true;
}

// desvira todos os recursos de um lado (chamado no início do turno dele)
function desvirar_recursos(_dono) {
    with (obj_recurso) {
        if (dono == _dono) {
            virado = false;
            if (bloqueado_turnos > 0) {
                if (bloqueio_acabou_de_aplicar) bloqueio_acabou_de_aplicar = false;
                else bloqueado_turnos = max(0, bloqueado_turnos - 1);
            }
        }
    }
    if (_dono == "jogador") {
        obj_controlador.recurso_colocado_no_turno = false;
        obj_controlador.recurso_retirado_no_turno = false;
    } else {
        obj_controlador.recurso_colocado_no_turno_inimigo = false;
        obj_controlador.recurso_retirado_no_turno_inimigo = false;
    }
}
#endregion

#region Condições especiais (queimado, veneno, paralisado, etc.)
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
        case "confusao":
            return { cor: make_color_rgb(190, 95, 255), sprite: -1, modo: "meio" };
        case "adormecido":
            return { cor: make_color_rgb(110, 155, 255), sprite: -1, modo: "meio" };
        case "berserker":
            return { cor: make_color_rgb(255, 85, 35), sprite: -1, modo: "meio" };
        case "loucura":
            return { cor: make_color_rgb(210, 45, 190), sprite: -1, modo: "meio" };
        case "sangrando":
            return { cor: c_red, sprite: -1, modo: "meio" };
        case "corrosao":
            return { cor: make_color_rgb(115, 210, 65), sprite: -1, modo: "meio" };
        case "apodrecer":
            return { cor: make_color_rgb(105, 145, 55), sprite: -1, modo: "meio" };
        case "regeneracao":
            return { cor: c_lime, sprite: -1, modo: "meio" };
    }
    return { cor: c_white, sprite: -1, modo: "meio" };
}

// Tenta aplicar uma condição -- só funciona se a tropa não tiver outra condição diferente ativa.
// Já dispara o texto flutuante com a cor certa quando aplica com sucesso.
function aplicar_condicao(_carta, _tipo, _turnos, _dano_por_turno, _disparar_armadilhas = true) {
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

    if (_tipo == "loucura" && _disparar_armadilhas) ativar_loucura_mutua(_carta);
    return true;
}

function aplicar_envenenado(_carta) {
    aplicar_condicao(_carta, "envenenado", -1, 1); // -1 = dura até morrer
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
        case "paralisado": return aplicar_condicao(_carta, "paralisado", 1, 0);
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

// Sangrando é especial: se já está sangrando, ataques seguintes SOMAM turnos ao invés de recusar.
function aplicar_sangramento(_carta) {
    if (_carta.condicao == "sangrando") {
        _carta.condicao_turnos_restantes += 1;
        return true;
    }
    return aplicar_condicao(_carta, "sangrando", 1, 3);
}

// Eletrocutado é diferente das outras: causa dano instantâneo + joga moeda pra decidir
// se paralisa. Ao completar 6 choques seguidos, a condição vira Loucura.
function aplicar_eletrocutado(_carta) {
    _carta.vida -= 2;
    aplicar_flash_dano(_carta);
    mostrar_dano_tropa(_carta, 2);
    debug_combate(_carta.nome_carta + " foi eletrocutada e tomou 2 de dano.");
    if (_carta.vida <= 0) { destruir_tropa(_carta); return; }

    _carta.vezes_eletrocutado_seguidas += 1;
    _carta.eletrocutado_neste_ciclo = true;
    var _ctx_choque = { carta: _carta };
    jogar_moeda_visual(_carta.x, _carta.y, _carta.x, _carta.y - 45, method(_ctx_choque, function(_moeda) {
        if (!instance_exists(carta)) return;
        if (carta.vezes_eletrocutado_seguidas >= 6) {
            carta.condicao = noone;
            aplicar_condicao(carta, "loucura", -1, 0);
            carta.vezes_eletrocutado_seguidas = 0;
            mostrar_feedback("LOUCURA", carta.x, carta.y - 45, make_color_rgb(210,45,190), 55);
        } else if (_moeda == 1) {
            aplicar_condicao(carta, "paralisado", 1, 0);
            mostrar_feedback("CARA: PARALISADA", carta.x, carta.y - 45, c_yellow, 45);
        } else {
            aplicar_condicao(carta, "eletrocutado", 1, 0);
            mostrar_feedback("COROA", carta.x, carta.y - 45, c_white, 35);
        }
    }));
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
            var _ctx_loucura = { dono_castelo: _carta.dono };
            rolar_dano_direto_visual(_carta, "fisica", method(_ctx_loucura, function(_dano_loucura) {
                causar_dano_castelo(dono_castelo, _dano_loucura);
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
    if (!instance_exists(_carta) || _carta.condicao != noone) return false;
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
    if (!instance_exists(_carta) || _carta.condicao != noone) return false;
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
    return (_carta.condicao != "paralisado"
        && _carta.condicao != "congelado"
        && _carta.condicao != "adormecido"
        && _carta.condicao != "loucura");
}

// Processa o efeito de todas as condições de um lado (dano/cura), no início do turno dele.
function processar_condicoes(_dono) {
    with (obj_carta) {
        if (dono != _dono) continue;
        if (condicao == noone) continue;

        if (condicao == "loucura") {
            processar_loucura(id);
            continue;
        }

        if (condicao == "adormecido") {
            var _dados_sono = { carta: id };
            jogar_moeda_visual(x, y, x, y - 45, method(_dados_sono, function(_resultado_sono) {
                if (!instance_exists(carta)) return;
                if (_resultado_sono == 1) {
                    carta.condicao = noone;
                    carta.condicao_turnos_restantes = 0;
                    mostrar_feedback("ACORDOU", carta.x, carta.y - 45, c_aqua, 45);
                    debug_combate(carta.nome_carta + " acordou.");
                } else {
                    mostrar_feedback("CONTINUA DORMINDO", carta.x, carta.y - 45, c_blue, 45);
                }
            }));
            continue;
        }

        switch (condicao) {
            case "queimado":
            case "envenenado":
            case "corrosao":
            case "apodrecer":
            case "sangrando":
                vida -= condicao_dano_por_turno;
                aplicar_flash_dano(id, 12);
                mostrar_dano_tropa(id, condicao_dano_por_turno);
                break;

            case "regeneracao":
                vida = min(vida + condicao_dano_por_turno, vida_maxima);
                mostrar_feedback("+" + string(condicao_dano_por_turno), x, y - sprite_height * 0.45, c_lime, 38);
                break;
        }

        if (vida <= 0) {
		    destruir_tropa(id, false);
		    continue;
		}

        if (condicao == "corrosao" && condicao_dano_por_turno > 1) {
            condicao_dano_por_turno -= 1;
        }
    }
}
	
// Desconta 1 turno de duração das condições e da recarga da Sombra Translúcida.
// Roda DEPOIS das ações daquele lado (senão a tropa nunca chega a ficar bloqueada de verdade).
function expirar_condicoes(_dono) {
    with (obj_carta) {
        if (dono != _dono) continue;

        // Se passou um ciclo inteiro sem novo choque, a sequência foi interrompida.
        if (!eletrocutado_neste_ciclo) vezes_eletrocutado_seguidas = 0;
        eletrocutado_neste_ciclo = false;

        // recarrega/desativa a sombra translúcida com o passar dos turnos
        if (sombra_cooldown > 0) {
            sombra_cooldown -= 1;
            if (sombra_cooldown == 1) {
                sombra_ativa = false; // já passou o turno de invisibilidade, agora só recarregando
            }
        }

        if (condicao == noone) continue;

        if (condicao_turnos_restantes > 0) {
            condicao_turnos_restantes -= 1;

            if (condicao_turnos_restantes <= 0) {
                if (condicao == "queimado") {
                    condicao = "imune_queimado"; // 1 turno de imunidade antes de poder queimar de novo
                    condicao_turnos_restantes = 1;
                } else {
                    condicao = noone;
                    condicao_dano_por_turno = 0;
                }
            }
        }
    }
}
#endregion

#region Magias — efeitos específicos
function obter_posicao_castelo(_dono) {
    var _soma_x = 0;
    var _soma_y = 0;
    var _quantidade = 0;
    with (obj_slot_construcao) {
        if (dono == _dono) {
            _soma_x += x;
            _soma_y += y;
            _quantidade += 1;
        }
    }
    if (_quantidade <= 0) {
        return { x: room_width / 2, y: (_dono == "inimigo") ? 20 : room_height - 20 };
    }
    var _media_x = _soma_x / _quantidade;
    var _media_y = _soma_y / _quantidade;
    return {
        x: _media_x,
        y: (_dono == "inimigo") ? max(18, _media_y - 42) : min(room_height - 18, _media_y + 42)
    };
}

function destruir_construcao(_construcao) {
    if (!instance_exists(_construcao)) return;
    var _dono = _construcao.dono;
    var _lane = _construcao.lane_atual;
    var _origem_x = _construcao.x;
    var _origem_y = _construcao.y;
    if (_construcao.slot_atual != noone) {
        _construcao.slot_atual.ocupado = false;
        _construcao.slot_atual.construcao_atual = noone;
    }
    instance_destroy(_construcao);
    ativar_destrocos_construcao(_dono, _lane, _origem_x, _origem_y);
}

function aplicar_efeito_bola_fogo(_alvo, _dado_efeito, _chance_queimar, _tipo_alvo = "tropa", _dono_castelo = "", _dano_rolado = -1) {
    var _dano = (_dano_rolado >= 0) ? _dano_rolado : irandom_range(1, _dado_efeito);

    if (_tipo_alvo == "castelo") {
        debug_combate("Bola de Fogo causou " + string(_dano) + " de dano ao castelo do " + _dono_castelo + "!");
        causar_dano_castelo(_dono_castelo, _dano);
        return;
    }

    if (!instance_exists(_alvo)) return;
    if (_tipo_alvo == "construcao") {
        debug_combate(_alvo.nome_construcao + " tomou " + string(_dano) + " de Bola de Fogo!");
        _alvo.vida -= _dano;
        mostrar_feedback("-" + string(_dano), _alvo.x, _alvo.y, c_red, 45);
        if (_alvo.vida <= 0) destruir_construcao(_alvo);
        return;
    }

    debug_combate(_alvo.nome_carta + " tomou " + string(_dano) + " de Bola de Fogo!");
    _alvo.vida -= _dano;
    aplicar_flash_dano(_alvo);
    mostrar_dano_tropa(_alvo, _dano);

    if (_alvo.vida <= 0) {
        destruir_tropa(_alvo);
        return;
    }
    if (_chance_queimar <= 0) return;

    var _dados_moeda = { alvo: _alvo };
    var _origem_x = _alvo.x;
    var _origem_y = obj_controlador.mao_y;
    var _escala_visual_alvo = _alvo.escala_base * (_alvo.travada ? _alvo.escala_no_campo : 1);
    var _altura_visual_alvo = global.CARTA_ALTURA * _escala_visual_alvo;
    var _destino_x = _alvo.x;
    var _destino_y = _alvo.y - _altura_visual_alvo/2 - global.MOEDA_LARGURA/2 + 20;

    jogar_moeda_visual(_origem_x, _origem_y, _destino_x, _destino_y, method(_dados_moeda, function(_resultado) {
        if (instance_exists(alvo) && _resultado == 1) aplicar_condicao(alvo, "queimado", 3, 2);
    }));
}

// Aceita tropa, construção ou castelo. O D8 aparece após o impacto e somente
// tropas podem receber a condição Queimado.
function lancar_bola_de_fogo(_alvo, _dado_efeito, _chance_queimar, _tipo_alvo = "tropa", _dono_castelo = "", _dono_lancador = "jogador") {
    if (_tipo_alvo != "castelo" && !instance_exists(_alvo)) return;

    var _posicao_alvo;
    if (_tipo_alvo == "castelo") _posicao_alvo = obter_posicao_castelo(_dono_castelo);
    else _posicao_alvo = { x: _alvo.x, y: _alvo.y };

    var _origem_x = room_width / 2;
    var _origem_y = (_dono_lancador == "jogador") ? obj_controlador.mao_y : 25;
    var _projetil = instance_create_layer(_origem_x, _origem_y, "Instances", obj_bola_fogo_projetil);
    obj_controlador.rolagens_pendentes += 1;
    _projetil.origem_x = _origem_x;
    _projetil.origem_y = _origem_y;
    _projetil.destino_x = _posicao_alvo.x;
    _projetil.destino_y = _posicao_alvo.y;
    _projetil.som_voo = audio_play_sound(snd_bola_fogo_voo, 1, 0, .5, 0, random_range(.95, 1.05));

    var _dados_impacto = {
        alvo: _alvo,
        dado_efeito: _dado_efeito,
        chance_queimar: _chance_queimar,
        tipo_alvo: _tipo_alvo,
        dono_castelo: _dono_castelo,
        dono_lancador: _dono_lancador,
        alvo_x: _posicao_alvo.x,
        alvo_y: _posicao_alvo.y
    };
    _projetil.callback_impacto = method(_dados_impacto, function() {
        obj_controlador.rolagens_pendentes = max(0, obj_controlador.rolagens_pendentes - 1);
        if (tipo_alvo != "castelo" && !instance_exists(alvo)) return;
        var _dados_dano = {
            alvo: alvo,
            dado_efeito: dado_efeito,
            chance_queimar: chance_queimar,
            tipo_alvo: tipo_alvo,
            dono_castelo: dono_castelo
        };
        var _resultado = irandom_range(1, dado_efeito);
        rolar_dado_visual(alvo_x, alvo_y - 45, alvo_x, alvo_y, dado_efeito, _resultado,
            method(_dados_dano, function(_dano) {
                aplicar_efeito_bola_fogo(alvo, dado_efeito, chance_queimar, tipo_alvo, dono_castelo, _dano);
            }), 0, 0, -1, dono_lancador);
    });
}
#endregion

#region Partículas — poeira ao jogar carta
function criar_poeira(_x, _y, _largura) {
    var _quantidade = 10; // quantas partículas por explosão

    for (var i = 0; i < _quantidade; i++) {
        // nasce numa posição aleatória ao longo da base da carta
        var _nasce_x = _x + random_range(-_largura/2, _largura/2);
        var _nasce_y = _y;

        var _particula = instance_create_layer(_nasce_x, _nasce_y, "Instances", obj_particula_poeira);

        // direção: espalha principalmente pros lados e um pouco pra baixo
        _particula.direcao_movimento = random_range(200, 340);
        _particula.velocidade_particula = random_range(1.5, 4);
        _particula.vida_particula = irandom_range(20, 35);
        _particula.vida_particula_max = _particula.vida_particula;
    }
}
	
function criar_flash(_x, _y, _tamanho = 40) {
    var _flash = instance_create_layer(_x, _y, "Instances", obj_flash_efeito);
    _flash.tamanho_flash = _tamanho;
}
#endregion

#region Evolução - Controlar turnos para evolução

function evoluir_tropa(_carta) {
    if (_carta.funcao_evolucao == noone) return;
    if (_carta.turnos_no_campo < 1) {
        debug_combate("Ainda não pode evoluir, precisa sobreviver 1 turno completo.");
        if (_carta.dono == "jogador") mostrar_aviso_regra("A tropa precisa sobreviver 1 turno", _carta.x, _carta.y);
        return;
    }
    if (!evolucoes_disponiveis(_carta.dono)) {
        debug_combate("Já evoluiu uma tropa esse turno.");
        if (_carta.dono == "jogador") mostrar_aviso_regra("Limite de 1 evolução por turno", _carta.x, _carta.y);
        return;
    }
    
    var _dados_evo = _carta.funcao_evolucao();
    
    if (!pode_pagar_custo(_dados_evo.custo, _carta.dono, "tropa")) {
        debug_combate("Sem recurso suficiente pra evoluir.");
        return;
    }
    pagar_custo(_dados_evo.custo, _carta.dono, "tropa");
    
    // transfere o dano já sofrido, não reseta a vida
    var _dano_sofrido = _carta.vida_maxima - _carta.vida;
    
    _carta.nome_carta = _dados_evo.nome;
    _carta.sprite_index = (_dados_evo.sprite_carta != noone) ? _dados_evo.sprite_carta : spr_carta_placeholder;
    _carta.escala_base = global.CARTA_LARGURA / sprite_get_width(_carta.sprite_index);
    _carta.tem_arte_propria = (_dados_evo.sprite_carta != noone);
    _carta.evoluindo = true;
    _carta.evolucao_progresso = 0;
    _carta.escala_evolucao = 1;
    _carta.rotacao_evolucao = 0;
    _carta.cor_evolucao = c_white;
    
    _carta.vida_maxima = _dados_evo.vida;
    _carta.vida = max(1, _dados_evo.vida - _dano_sofrido);
	_carta.vida_pos_x = variable_struct_exists(_dados_evo, "vida_pos_x") ? _dados_evo.vida_pos_x : 0.11;
	_carta.vida_pos_y = variable_struct_exists(_dados_evo, "vida_pos_y") ? _dados_evo.vida_pos_y : 0.07;
    _carta.dado_dano = _dados_evo.dado_dano;
	_carta.qtd_dados_dano = variable_struct_exists(_dados_evo, "qtd_dados_dano") ? _dados_evo.qtd_dados_dano : 1;
	_carta.qtd_dados_dano_magico = variable_struct_exists(_dados_evo, "qtd_dados_dano_magico") ? _dados_evo.qtd_dados_dano_magico : 1;
    _carta.mod_dano = _dados_evo.mod_dano;
    _carta.defesa_fisica = _dados_evo.defesa_fisica;
    _carta.defesa_magica = _dados_evo.defesa_magica;
	_carta.habilidades = variable_struct_exists(_dados_evo, "habilidades") ? _dados_evo.habilidades : [];
    _carta.funcao_evolucao = variable_struct_exists(_dados_evo, "evolucao") ? _dados_evo.evolucao : noone;
	_carta.nivel_inteligencia = variable_struct_exists(_dados_evo, "inteligencia") ? _dados_evo.inteligencia : 1;
	_carta.dado_dano_magico = variable_struct_exists(_dados_evo, "dado_dano_magico") ? _dados_evo.dado_dano_magico : 0;
	_carta.mod_dano_magico = variable_struct_exists(_dados_evo, "mod_dano_magico") ? _dados_evo.mod_dano_magico : 0;
	_carta.mochila_maxima = variable_struct_exists(_dados_evo, "mochila") ? _dados_evo.mochila : 1;
	_carta.dado_dano_base = _carta.dado_dano;
	_carta.mod_dano_base = _carta.mod_dano;
	_carta.defesa_fisica_base = _carta.defesa_fisica;
	recalcular_itens_tropa(_carta);

	_carta.vida_pos_x = variable_struct_exists(_dados_evo, "vida_pos_x") ? _dados_evo.vida_pos_x : 0.10;
	_carta.vida_pos_y = variable_struct_exists(_dados_evo, "vida_pos_y") ? _dados_evo.vida_pos_y : 0.07;
	_carta.atk_pos_x = variable_struct_exists(_dados_evo, "atk_pos_x") ? _dados_evo.atk_pos_x : 0.12;
	_carta.atk_pos_y = variable_struct_exists(_dados_evo, "atk_pos_y") ? _dados_evo.atk_pos_y : 0.92;
	_carta.atk_magico_pos_x = variable_struct_exists(_dados_evo, "atk_magico_pos_x") ? _dados_evo.atk_magico_pos_x : 0.37;
	_carta.atk_magico_pos_y = variable_struct_exists(_dados_evo, "atk_magico_pos_y") ? _dados_evo.atk_magico_pos_y : 0.92;
	_carta.def_pos_x = variable_struct_exists(_dados_evo, "def_pos_x") ? _dados_evo.def_pos_x : 0.62;
	_carta.def_pos_y = variable_struct_exists(_dados_evo, "def_pos_y") ? _dados_evo.def_pos_y : 0.92;
	_carta.def_magico_pos_x = variable_struct_exists(_dados_evo, "def_magico_pos_x") ? _dados_evo.def_magico_pos_x : 0.87;
	_carta.def_magico_pos_y = variable_struct_exists(_dados_evo, "def_magico_pos_y") ? _dados_evo.def_magico_pos_y : 0.92;
	_carta.int_pos_x = variable_struct_exists(_dados_evo, "int_pos_x") ? _dados_evo.int_pos_x : 0.91;
	_carta.int_pos_y = variable_struct_exists(_dados_evo, "int_pos_y") ? _dados_evo.int_pos_y : 0.07;
	_carta.mochila_pos_x = variable_struct_exists(_dados_evo, "mochila_pos_x") ? _dados_evo.mochila_pos_x : 0.91;
	_carta.mochila_pos_y = variable_struct_exists(_dados_evo, "mochila_pos_y") ? _dados_evo.mochila_pos_y : 0.185;
    
    registrar_evolucao(_carta.dono);
    
    debug_combate(_carta.nome_carta + " EVOLUIU!");
    
    var _texto_flutuante = instance_create_layer(_carta.x, _carta.y - _carta.sprite_height/2, "Instances", obj_texto_flutuante);
    _texto_flutuante.texto = "EVOLUIU!";
    _texto_flutuante.cor_texto = c_lime;
}

function evolucoes_disponiveis(_dono) {
    var _usadas = (_dono == "jogador") ? obj_controlador.evolucoes_jogador_este_turno : obj_controlador.evolucoes_inimigo_este_turno;
    return (obj_controlador.max_evolucoes_por_turno - _usadas) > 0;
}

function registrar_evolucao(_dono) {
    if (_dono == "jogador") {
        obj_controlador.evolucoes_jogador_este_turno += 1;
    } else {
        obj_controlador.evolucoes_inimigo_este_turno += 1;
    }
}
#endregion

#region Abismo - Cartas especiais
function mandar_para_abismo(_nome_carta) {
    array_push(obj_controlador.abismo, _nome_carta);
    debug_combate(_nome_carta + " foi engolida pelo ABISMO. Nunca mais volta.");
}

function esta_no_abismo(_nome_carta) {
    return array_get_index(obj_controlador.abismo, _nome_carta) != -1;
}
#endregion

// Equipamentos permanecem ligados à tropa para que cartas futuras possam removê-los,
// transferi-los ou roubá-los sem perder a origem nem acumular bônus incorretos.
function criar_dados_item_equipado(_nome, _sprite, _funcao, _bonus_dano, _bonus_defesa, _dado, _mod, _efeito_item = "") {
    return { nome: _nome, sprite: _sprite, funcao: _funcao, bonus_dano: _bonus_dano,
        bonus_defesa: _bonus_defesa, dado: _dado, modificador: _mod, efeito_item: _efeito_item };
}

function recalcular_itens_tropa(_tropa) {
    if (!instance_exists(_tropa)) return;
    _tropa.dado_dano = _tropa.dado_dano_base;
    _tropa.mod_dano = _tropa.mod_dano_base;
    _tropa.defesa_fisica = _tropa.defesa_fisica_base;
    _tropa.item_ataque_atual = noone;
    for (var i = 0; i < array_length(_tropa.itens_equipados); i++) {
        var _item = _tropa.itens_equipados[i];
        _tropa.defesa_fisica += _item.bonus_defesa;
        if (_item.dado <= 0) _tropa.mod_dano += _item.bonus_dano;
    }
    _tropa.mochila = max(0, _tropa.mochila_maxima - array_length(_tropa.itens_equipados));
}

function melhor_item_ataque(_tropa) {
    var _melhor = noone;
    var _media = _tropa.qtd_dados_dano * ((_tropa.dado_dano + 1) / 2) + _tropa.mod_dano;
    for (var i = 0; i < array_length(_tropa.itens_equipados); i++) {
        var _item = _tropa.itens_equipados[i];
        if (_item.dado > 0 && ((_item.dado + 1) / 2 + _item.modificador) > _media) {
            _media = (_item.dado + 1) / 2 + _item.modificador;
            _melhor = _item;
        }
    }
    return _melhor;
}

function equipar_item_dados(_tropa, _item) {
    if (!instance_exists(_tropa) || _tropa.mochila <= 0) return false;
    array_push(_tropa.itens_equipados, _item);
    recalcular_itens_tropa(_tropa);
    return true;
}

function remover_item_equipado(_tropa, _indice, _voltar_mao = true) {
    if (!instance_exists(_tropa) || _indice < 0 || _indice >= array_length(_tropa.itens_equipados)) return noone;
    var _item = _tropa.itens_equipados[_indice];
    array_delete(_tropa.itens_equipados, _indice, 1);
    recalcular_itens_tropa(_tropa);
    if (_voltar_mao && _tropa.dono == "jogador" && _item.funcao != noone) {
        comprar_carta_do_deck_por_funcao(_item.funcao, _tropa.x, _tropa.y);
    }
    return _item;
}

function transferir_item_equipado(_origem, _destino, _indice) {
    if (!instance_exists(_origem) || !instance_exists(_destino) || _destino.mochila <= 0) return false;
    var _item = remover_item_equipado(_origem, _indice, false);
    if (!is_struct(_item)) return false;
    equipar_item_dados(_destino, _item);
    criar_animacao_item(_item.sprite, _origem.x, _origem.y, _destino.x, _destino.y, c_aqua);
    _origem.troca_item_usada_este_turno = true;
    _destino.troca_item_usada_este_turno = true;
    mostrar_feedback("ITEM TRANSFERIDO", _destino.x, _destino.y - 45, c_aqua, 45);
    return true;
}

function tentar_roubo_item(_ladrao, _vitima, _item_atacante) {
    if (!instance_exists(_ladrao) || !instance_exists(_vitima) || _ladrao.mochila <= 0) return;
    var _indice = array_get_index(_vitima.itens_equipados, _item_atacante);
    if (_indice < 0) return;
    var _ctx = { ladrao: _ladrao, vitima: _vitima, item: _item_atacante };
    var _resultado = irandom_range(1, 10);
    rolar_dado_visual(_vitima.x, _vitima.y, _ladrao.x, _ladrao.y - 45, 10, _resultado, method(_ctx, function(_rolagem) {
        if (!instance_exists(ladrao) || !instance_exists(vitima) || _rolagem != 10 || ladrao.mochila <= 0) return;
        var _pos = array_get_index(vitima.itens_equipados, item);
        if (_pos < 0) return;
        var _roubado = remover_item_equipado(vitima, _pos, false);
        equipar_item_dados(ladrao, _roubado);
        criar_animacao_item(_roubado.sprite, vitima.x, vitima.y, ladrao.x, ladrao.y, c_yellow);
        mostrar_feedback("ROUBOU: " + _roubado.nome, ladrao.x, ladrao.y - 45, c_yellow, 60);
    }), 0, 0, -1, _ladrao.dono);
}

function tropa_tem_item_efeito(_tropa, _efeito) {
    if (!instance_exists(_tropa)) return false;
    for (var i = 0; i < array_length(_tropa.itens_equipados); i++) {
        if (_tropa.itens_equipados[i].efeito_item == _efeito) return true;
    }
    return false;
}

function usar_grimorio_iniciante(_tropa, _magia) {
    if (!instance_exists(_tropa) || _tropa.grimorio_usado_este_turno) return false;
    var _custo = { tipo: "mana", quantidade: 1 };
    if (!pode_pagar_custo(_custo, _tropa.dono, "magica")) {
        if (_tropa.dono == "jogador") mostrar_aviso_regra("O Grimório precisa de 1 Mana", _tropa.x, _tropa.y);
        return false;
    }

    var _alvo = noone;
    if (_magia == "raio") {
        var _inimigo = (_tropa.dono == "jogador") ? "inimigo" : "jogador";
        _alvo = buscar_tropa_na_coluna(_tropa.lane_atual, _inimigo);
        if (_alvo == noone) {
            if (_tropa.dono == "jogador") mostrar_aviso_regra("Não há tropa inimiga nesta fileira", _tropa.x, _tropa.y);
            return false;
        }
    }

    pagar_custo(_custo, _tropa.dono, "magica");
    _tropa.grimorio_usado_este_turno = true;
    if (_magia == "curazinha") {
        _tropa.vida = min(_tropa.vida_maxima, _tropa.vida + 1);
        mostrar_feedback("+1 VIDA", _tropa.x, _tropa.y - 40, c_lime, 45);
    } else if (_magia == "escudo") {
        _tropa.defesa_magica += 2;
        _tropa.grimorio_escudo_ativo = true;
        mostrar_feedback("+2 DEF MÁGICA", _tropa.x, _tropa.y - 40, c_aqua, 55);
    } else {
        var _resultado = irandom_range(1, 4);
        var _ctx = { alvo: _alvo, conjurador: _tropa };
        rolar_dado_visual(_tropa.x, _tropa.y, _alvo.x, _alvo.y - 40, 4, _resultado,
            method(_ctx, function(_valor) {
                if (!instance_exists(alvo)) return;
                var _dano = max(0, _valor - alvo.defesa_magica);
                alvo.vida -= _dano;
                aplicar_flash_dano(alvo);
                mostrar_dano_tropa(alvo, _dano);
                if (alvo.vida <= 0) destruir_tropa(alvo, true);
            }), 0, 0, -1, _tropa.dono);
    }
    return true;
}

function ia_usar_grimorios() {
    with (obj_carta) {
        if (!travada || dono != "inimigo" || grimorio_usado_este_turno
            || !tropa_tem_item_efeito(id, "grimorio_iniciante")) continue;
        var _alvo = buscar_tropa_na_coluna(lane_atual, "jogador");
        if (vida < vida_maxima) usar_grimorio_iniciante(id, "curazinha");
        else if (_alvo != noone) usar_grimorio_iniciante(id, "raio");
        else usar_grimorio_iniciante(id, "escudo");
    }
}

#region Menu de ação (clicar na tropa → Atacar/Mover/Habilidade)
function obter_opcoes_menu(_carta) {
    var _opcoes = [];
    var _pode_atacar = !(_carta.dono == "jogador" && obj_controlador.primeiro_turno_jogador);

    if (!_carta.atacou_este_turno && _pode_atacar) {
        var _tem_fisica = _carta.dado_dano > 0;
        var _tem_magica = _carta.dado_dano_magico > 0;

        if (_tem_fisica && _tem_magica) {
            array_push(_opcoes, "Atacar (Física)");
            array_push(_opcoes, "Atacar (Mágica)");
        } else {
            array_push(_opcoes, "Atacar");
        }
    } else {
        array_push(_opcoes, _carta.atacou_este_turno ? "Atacar [já usado]" : "Atacar [1º turno]");
    }

    if (!_carta.moveu_este_turno) {
        if (_carta.turnos_no_campo < 1) {
            array_push(_opcoes, "Avançar [próximo turno]");
            array_push(_opcoes, "Recuar [próximo turno]");
        } else {
            array_push(_opcoes, _carta.posicao_atual == posicao_assalto(_carta.dono)
                ? "Avançar [posição de assalto]" : "Avançar");
            array_push(_opcoes, _carta.posicao_atual == posicao_entrada(_carta.dono)
                ? "Recuar [posição de base]" : "Recuar");
        }
    } else {
        array_push(_opcoes, "Avançar [movimento já usado]");
        array_push(_opcoes, "Recuar [movimento já usado]");
    }
    if (_carta.dono == "jogador" && _carta.travada && _carta.posicao_atual == posicao_entrada("jogador")) {
        array_push(_opcoes, _carta.defendendo_castelo ? "Parar de Defender" : "Defender Castelo");
    }
    if (tem_habilidade_ativa(_carta) != noone) {
        array_push(_opcoes, _carta.habilidade_usada_este_turno ? "Habilidade [já usada]" : "Habilidade");
    }
    if (tropa_tem_item_efeito(_carta, "grimorio_iniciante")) {
        var _sufixo_grimorio = _carta.grimorio_usado_este_turno ? " [já usado]" : "";
        array_push(_opcoes, "Grimório: Raio" + _sufixo_grimorio);
        array_push(_opcoes, "Grimório: Escudo" + _sufixo_grimorio);
        array_push(_opcoes, "Grimório: Curazinha" + _sufixo_grimorio);
    }
    if (array_length(_carta.itens_equipados) > 0) {
        if (!_carta.atacou_este_turno && _pode_atacar) {
            for (var _ii = 0; _ii < array_length(_carta.itens_equipados); _ii++) {
                if (_carta.itens_equipados[_ii].dado > 0) array_push(_opcoes, "Atacar com " + _carta.itens_equipados[_ii].nome);
            }
        }
        array_push(_opcoes, _carta.troca_item_usada_este_turno ? "Remover Item [já usado]" : "Remover Item");
        array_push(_opcoes, _carta.troca_item_usada_este_turno ? "Transferir Item [já usado]" : "Transferir Item");
    }
    if (_carta.funcao_evolucao != noone) {
        if (_carta.turnos_no_campo < 1) array_push(_opcoes, "Evoluir [sobreviva 1 turno]");
        else if (!evolucoes_disponiveis(_carta.dono)) array_push(_opcoes, "Evoluir [limite atingido]");
        else array_push(_opcoes, "Evoluir");
    }
    return _opcoes;
}

function categoria_bloqueada_primeiro_turno(_categoria) {
    return (_categoria == "item_equipavel" 
         || _categoria == "item_consumivel" 
         || _categoria == "magica" 
         || _categoria == "terreno");
}

function executar_opcao_menu(_carta, _opcao) {
    if (!instance_exists(_carta)) return;
    if (obj_controlador.turno != "jogador") {
        mostrar_aviso_regra("Você pode inspecionar; ações ficam para o seu turno", _carta.x, _carta.y);
        return;
    }
    if (obj_controlador.rolagens_pendentes > 0) {
        mostrar_aviso_regra("Aguarde a rolagem terminar", _carta.x, _carta.y);
        return;
    }
    if (string_pos("[", _opcao) > 0) {
        mostrar_aviso_regra(string_delete(_opcao, 1, string_pos("[", _opcao) - 1), _carta.x, _carta.y);
        return;
    }
    if (string_pos("Atacar com ", _opcao) == 1) {
        var _nome_item_ataque = string_delete(_opcao, 1, string_length("Atacar com "));
        for (var _ia = 0; _ia < array_length(_carta.itens_equipados); _ia++) {
            var _item_ataque = _carta.itens_equipados[_ia];
            if (_item_ataque.nome == _nome_item_ataque && _item_ataque.dado > 0) {
                _carta.item_ataque_atual = _item_ataque;
                _carta.atacou_este_turno = processar_combate_tropa(_carta, "fisica");
                return;
            }
        }
    }
    switch (_opcao) {
        case "Atacar":
            _carta.item_ataque_atual = noone;
            var _tipo = (_carta.dado_dano_magico > 0 && _carta.dado_dano == 0) ? "magica" : "fisica";
            _carta.atacou_este_turno = processar_combate_tropa(_carta, _tipo);
            break;
        case "Atacar (Física)":
            _carta.item_ataque_atual = noone;
            _carta.atacou_este_turno = processar_combate_tropa(_carta, "fisica");
            break;
        case "Atacar (Mágica)":
            _carta.item_ataque_atual = noone;
            _carta.atacou_este_turno = processar_combate_tropa(_carta, "magica");
            break;
        case "Avançar":
        case "Recuar":
            var _direcao_movimento = (_opcao == "Avançar") ? 1 : -1;
            var _resultado = mover_tropa(_carta, _direcao_movimento);
            if (_resultado == "movido") {
                _carta.moveu_este_turno = true;
                mostrar_feedback(_direcao_movimento == 1 ? "AVANÇOU" : "RECUOU",
                    _carta.x, _carta.y - 35, _direcao_movimento == 1 ? c_lime : c_aqua, 38);
            } else if (_resultado == "recem_colocada") {
                mostrar_aviso_regra("A tropa só pode mover no próximo turno", _carta.x, _carta.y);
            } else if (_resultado == "bloqueado") {
                mostrar_aviso_regra("Uma tropa aliada bloqueia o caminho", _carta.x, _carta.y);
            } else if (_resultado == "ataque_necessario") {
                mostrar_aviso_regra("Há um inimigo no caminho", _carta.x, _carta.y);
            } else if (_resultado == "armadilha") {
                mostrar_feedback("PRESA PELAS RAÍZES", _carta.x, _carta.y - 38, c_lime, 55);
            } else {
                mostrar_aviso_regra(_direcao_movimento == 1 ? "Não pode avançar mais" : "Não pode recuar mais",
                    _carta.x, _carta.y);
            }
            break;
        case "Defender Castelo":
            _carta.defendendo_castelo = true;
            debug_combate(_carta.nome_carta + " está defendendo o castelo.");
            mostrar_feedback("DEFENDENDO", _carta.x, _carta.y - 35, c_aqua, 45);
            break;
        case "Parar de Defender":
            _carta.defendendo_castelo = false;
            debug_combate(_carta.nome_carta + " deixou de defender o castelo.");
            mostrar_feedback("DEFESA ENCERRADA", _carta.x, _carta.y - 35, c_silver, 45);
            break;
        case "Habilidade":
            usar_habilidade(_carta);
            break;
        case "Grimório: Raio": usar_grimorio_iniciante(_carta, "raio"); break;
        case "Grimório: Escudo": usar_grimorio_iniciante(_carta, "escudo"); break;
        case "Grimório: Curazinha": usar_grimorio_iniciante(_carta, "curazinha"); break;
        case "Remover Item":
            if (remover_item_equipado(_carta, array_length(_carta.itens_equipados) - 1, true) != noone) {
                _carta.troca_item_usada_este_turno = true;
                mostrar_feedback("ITEM PARA A MÃO", _carta.x, _carta.y - 45, c_aqua, 45);
            }
            break;
        case "Transferir Item":
            obj_controlador.troca_item_selecao_ativa = true;
            obj_controlador.troca_item_origem = _carta;
            obj_controlador.tropa_selecionada = _carta;
            break;
        case "Evoluir":
            evoluir_tropa(_carta);
            break;
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
        case "alcance": return "Alcance: pode atacar uma casa mais distante.";
        case "alcance_magico": return "Alcance mágico: pode mirar inimigos mais distantes.";
        case "voar": return "Voar: atravessa tropas terrestres ao se mover.";
        case "golpe_duplo": return "Golpe Duplo: realiza dois ataques na mesma ação.";
        case "mitose": return "Mitose: ao morrer, gera duas tropas menores quando houver espaço.";
        case "imitacao": return "Imitação: pode confundir ou copiar o comportamento do inimigo.";
        case "sombra_translucida": return "Sombra Translúcida: fica difícil de ser alvo por um tempo.";
        case "visao_do_veu": return "Visão do Véu: revela e interage com efeitos ocultos.";
        case "olhar_vazio": return "Olhar Vazio: aplica seu efeito ao avançar sobre um alvo.";
        case "tiro_burro": return "Tiro Burro: pode atingir alvos de forma imprevisível.";
        case "digestao": return "Digestão: devora uma tropa abatida ou com menos de 4 de vida.";
        case "roubo": return "Roubo: ao ser atacada por um item, tenta roubá-lo com um D10.";
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

    if (_carta.categoria == "tropa") {
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
            if (_carta.efeito_item == "grimorio_iniciante")
                _texto += "\n\nUma vez por turno, paga 1 Mana para usar Raio (1D4 mágico), Escudo Arcano (+2 DEF mágica) ou Curazinha (+1 vida).";
            else _texto += "\n\nEquipe em uma tropa aliada. Bônus: +" + string(_carta.bonus_mod_dano_item) + " dano e +" + string(_carta.bonus_defesa_item) + " defesa.";
        break;
        case "item_consumivel": _texto += "\n\n" + descricao_efeito_preview(_carta) + " É consumido depois do uso."; break;
        case "magica": _texto += "\n\n" + descricao_efeito_preview(_carta) + " Magias possuem limite por turno."; break;
        case "terreno":
            if (_carta.efeito_terreno == "planicies_profanas") _texto += "\n\nReduz em 1 o custo de Mana de todas as tropas enquanto estiver ativo.";
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
function tem_habilidade_ativa(_carta) {
    var _ativas = ["golpe_duplo", "sombra_translucida", "ferida_exposta", "imitacao", "visao_do_veu", "digestao", "carnica_frenetica"];
    for (var i = 0; i < array_length(_carta.habilidades); i++) {
        if (array_get_index(_ativas, _carta.habilidades[i]) != -1) return _carta.habilidades[i];
    }
    return noone;
}

// Despacha pra função específica de cada habilidade, baseado no código salvo na carta.
function usar_habilidade(_carta) {
    switch (tem_habilidade_ativa(_carta)) {
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
    pagar_custo(_custo_mana, _carta.dono);

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
    _carta.habilidade_usada_este_turno = true;

    var _dados_ferida = { atacante: _carta, alvo: _alvo };

    jogar_moeda_visual(_carta.x, obj_controlador.mao_y, _alvo.x, _alvo.y - _alvo.sprite_height/2 - 20, method(_dados_ferida, function(_resultado) {
        if (!instance_exists(atacante) || !instance_exists(alvo)) return;

        if (_resultado == 1) { // cara
            var _dano = irandom_range(1, atacante.dado_dano);
            alvo.vida -= _dano;
            aplicar_condicao(alvo, "sangrando", 1, 3);

            debug_combate(alvo.nome_carta + " ficou SANGRANDO pela Ferida Exposta!");

            if (alvo.vida <= 0) destruir_tropa(alvo);
        } else {
            debug_combate("Ferida Exposta: coroa, nada aconteceu.");
            mostrar_feedback("SEM EFEITO", alvo.x, alvo.y - 35, c_silver, 40);
        }
    }));
}
	
function habilidade_imitacao(_carta) {
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
    // Inteligência zero ou menor permite repetir a habilidade, conforme o livro.
    if (_alvo.nivel_inteligencia > 0) _carta.habilidade_usada_este_turno = true;

    var _rolagem_imitacao = irandom_range(1, 20) + _carta.nivel_inteligencia;
    var _rolagem_defensor = irandom_range(1, 20) + _alvo.nivel_inteligencia;

    debug_combate(_carta.nome_carta + " usa IMITAÇÃO! (" + string(_rolagem_imitacao) + " vs " + string(_rolagem_defensor) + ")");

    if (_rolagem_imitacao > _rolagem_defensor) {
        _alvo.iludido_por_imitacao = true;
        debug_combate(_alvo.nome_carta + " foi enganada e não vai atacar no próximo turno dela!");
        var _tipo_contra = ia_escolher_tipo_ataque(_carta, _alvo);
        rolar_combate(_carta, _alvo, _tipo_contra);
        debug_combate(_carta.nome_carta + " realizou o contra-ataque da Imitação!");
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
    if (!_alvo.travada || _alvo.dono == _origem.dono || _alvo.vida >= 4) return false;
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
    destruir_tropa(_alvo);
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
    obj_controlador.digestao_selecao_ativa = true;
    obj_controlador.digestao_origem = _carta;
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
    pagar_custo(_custo, _carta.dono);
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
    if (!obj_controlador.visao_veu_ativa || !instance_exists(obj_controlador.visao_veu_origem)) return;
    var _carta = obj_controlador.visao_veu_origem;
    if (_indice_opcao < 0) {
        _carta.imune_armadilha = true;
        _carta.imune_armadilha_usos = 1;
        mostrar_feedback("PROTEGIDA DA PRÓXIMA ARMADILHA", _carta.x, _carta.y - 45, c_aqua, 60);
    } else if (_indice_opcao < array_length(obj_controlador.visao_veu_opcoes)) {
        var _opcao = obj_controlador.visao_veu_opcoes[_indice_opcao];
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
    obj_controlador.visao_veu_ativa = false;
    obj_controlador.visao_veu_origem = noone;
    obj_controlador.visao_veu_opcoes = [];
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
    obj_controlador.visao_veu_opcoes = [];
    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _funcao = obj_controlador.mao_inimigo[i];
        var _dados = _funcao();
        array_push(obj_controlador.visao_veu_opcoes, { nome: _dados.nome, funcao: _funcao, armadilha: _dados.categoria == "armadilha" });
    }
    obj_controlador.visao_veu_origem = _carta;
    obj_controlador.visao_veu_revelacao_timer = 0;
    obj_controlador.visao_veu_ativa = true;
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
        aplicar_condicao(_carta, "paralisado", 1, 0);
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
        if (dono == _inimigo && tipo == "sangue" && !virado && _sangue_inimigo == noone) _sangue_inimigo = id;
        if (dono == _construcao.dono && virado && _recurso_proprio == noone) _recurso_proprio = id;
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

#region Livro de Regras
function carregar_livro_regras() {
    var _caminho = working_directory + "livro_regras.json";

    if (!file_exists(_caminho)) {
        show_debug_message("AVISO: livro_regras.json não encontrado em " + _caminho);
        return [];
    }

    var _buffer = buffer_load(_caminho);
    var _conteudo = buffer_read(_buffer, buffer_string);
    buffer_delete(_buffer);

    var _dados = json_parse(_conteudo);
    return _dados;
}

// Reduz a escala do texto aos poucos até a altura final caber no espaço disponível.
// Precisa que a fonte certa já esteja setada (draw_set_font) antes de chamar.
function calcular_escala_texto_ajustada(_texto, _largura_alvo, _altura_alvo, _escala_inicial, _escala_minima) {
    var _escala = _escala_inicial;
    repeat (30) {
        var _largura_wrap = _largura_alvo / _escala;
        var _altura_natural = string_height_ext(_texto, -1, _largura_wrap);
        var _altura_final = _altura_natural * _escala;
        if (_altura_final <= _altura_alvo || _escala <= _escala_minima) break;
        _escala -= 0.01;
    }
    return max(_escala, _escala_minima);
}
	
// Desenha o conteúdo de UMA página (título + corpo + rodapé de parte) numa área retangular.
// Serve tanto pra folha esquerda (estática) quanto pra direita (dentro da matriz de virada),
// já que as duas mostram o mesmo tipo de conteúdo agora.
function desenhar_pagina_do_livro(_pagina, _centro_x, _centro_y, _largura_disponivel, _altura_disponivel) {
    var _margem = _largura_disponivel * 0.1;
    var _largura_texto = _largura_disponivel - (_margem * 2);

    var _altura_titulo_reservada = _altura_disponivel * 0.16;
    var _altura_rodape_reservada = (_pagina.partes > 1) ? (_altura_disponivel * 0.08) : 0;
    var _altura_corpo_disponivel = _altura_disponivel - _altura_titulo_reservada - _altura_rodape_reservada;

    var _escala_titulo = calcular_escala_texto_ajustada(_pagina.titulo, _largura_texto, _altura_titulo_reservada * 0.8, 0.72, 0.42);
    var _escala_corpo = calcular_escala_texto_ajustada(_pagina.corpo, _largura_texto, _altura_corpo_disponivel, 0.58, 0.40);

    var _topo_y = _centro_y - _altura_disponivel/2;
    var _cor_tinta = make_color_rgb(64, 44, 27);
    var _cor_titulo = make_color_rgb(90, 30, 24); // um vermelho-vinho escuro, tipo tinta de destaque

    draw_set_color(_cor_titulo);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text_transformed(_centro_x, _topo_y + (_altura_titulo_reservada * 0.15), _pagina.titulo, _escala_titulo, _escala_titulo, 0);

    draw_set_color(_cor_tinta);
    draw_set_halign(fa_left);
    draw_text_ext_transformed(_centro_x - _largura_texto/2, _topo_y + _altura_titulo_reservada, _pagina.corpo, -1, _largura_texto / _escala_corpo, _escala_corpo, _escala_corpo, 0);

    if (_pagina.partes > 1) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_bottom);
        draw_set_alpha(0.6);
        draw_text_transformed(_centro_x, _centro_y + _altura_disponivel/2, "Parte " + string(_pagina.parte) + " de " + string(_pagina.partes), 0.62, 0.62, 0);
        draw_set_alpha(1);
    }

    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
#endregion

#region Áudio
function carregar_configuracoes() {
    ini_open("kartha_config.ini");
    global.volume_musica = clamp(ini_read_real("audio", "musica", 0.8), 0, 1);
    global.volume_efeitos = clamp(ini_read_real("audio", "efeitos", 0.8), 0, 1);
    var _tela_cheia = ini_read_real("video", "tela_cheia", 0) >= 0.5;
    ini_close();
    if (window_get_fullscreen() != _tela_cheia) window_set_fullscreen(_tela_cheia);
    aplicar_config_audio();
}

function salvar_configuracoes() {
    ini_open("kartha_config.ini");
    ini_write_real("audio", "musica", global.volume_musica);
    ini_write_real("audio", "efeitos", global.volume_efeitos);
    ini_write_real("video", "tela_cheia", window_get_fullscreen() ? 1 : 0);
    ini_close();
}

function aplicar_config_audio() {
    var _musica = variable_global_exists("volume_musica") ? global.volume_musica : 0.8;
    var _efeitos = variable_global_exists("volume_efeitos") ? global.volume_efeitos : 0.8;
    audio_sound_gain(snd_menu, _musica, 0);
    audio_sound_gain(snd_jogo, _musica, 0);
    var _sons_efeito = [snd_bencao, snd_maldicao, snd_bola_fogo_fogo, snd_bola_fogo_impacto, snd_bola_fogo_voo, snd_colocar, snd_moeda_arremesso, snd_moeda_impacto, snd_shuffle];
    for (var i = 0; i < array_length(_sons_efeito); i++) {
        audio_sound_gain(_sons_efeito[i], _efeitos, 0);
    }
}

function tocar_musica(_musica) {
    audio_stop_all();

    if (!audio_is_playing(_musica)) {
        audio_play_sound(_musica, 0, true);
    }
    aplicar_config_audio();
}

// Divide capítulos longos em partes legíveis. Assim o livro não reduz o texto
// até ficar minúsculo só para caber em uma página.
function paginar_livro_regras(_capitulos, _limite_caracteres) {
    var _resultado = [];

    for (var i = 0; i < array_length(_capitulos); i++) {
        var _capitulo = _capitulos[i];
        var _palavras = string_split(_capitulo.corpo, " ");
        var _partes = [];
        var _texto_atual = "";

        for (var j = 0; j < array_length(_palavras); j++) {
            var _palavra = _palavras[j];
            var _candidato = (_texto_atual == "") ? _palavra : (_texto_atual + " " + _palavra);
            if (string_length(_candidato) > _limite_caracteres && _texto_atual != "") {
                array_push(_partes, _texto_atual);
                _texto_atual = _palavra;
            } else {
                _texto_atual = _candidato;
            }
        }
        if (_texto_atual != "") array_push(_partes, _texto_atual);
        if (array_length(_partes) == 0) array_push(_partes, "");

        for (var j = 0; j < array_length(_partes); j++) {
            array_push(_resultado, {
                titulo: _capitulo.titulo,
                corpo: _partes[j],
                parte: j + 1,
                partes: array_length(_partes)
            });
        }
    }
    return _resultado;
}
#endregion

#region Debug — ferramentas de teste
// Procura no baralho inteiro (todas as cartas possíveis do jogo) uma função cujo
// nome bata (parcialmente, sem diferenciar maiúsculas) com o texto digitado.
function debug_buscar_funcao_carta_por_nome(_texto_busca) {
    var _busca_lower = string_lower(_texto_busca);

    for (var i = 0; i < array_length(obj_controlador.baralho); i++) {
        var _funcao = obj_controlador.baralho[i];
        var _dados = _funcao();
        var _nome_lower = string_lower(_dados.nome);

        if (string_pos(_busca_lower, _nome_lower) > 0) {
            return _funcao;
        }
    }
    return noone;
}

// Cria a carta direto na mão do jogador, SEM consumir do monte nem gastar recursos.
// Ideal pra testar uma carta específica sem precisar montar uma run inteira.
function debug_adicionar_carta_a_mao(_texto_busca) {
    var _funcao = debug_buscar_funcao_carta_por_nome(_texto_busca);

    if (_funcao == noone) {
        debug_combate("DEBUG: nenhuma carta encontrada com o nome '" + _texto_busca + "'.");
        return false;
    }

    comprar_carta_do_deck_por_funcao(_funcao, obj_deck.x, obj_deck.y);
    debug_combate("DEBUG: carta adicionada à mão via busca '" + _texto_busca + "'.");
    return true;
}

// Enche todos os tipos de recurso do jogador de uma vez, até o limite de 6 por tipo,
// só pra testar cartas com custo sem precisar juntar recursos manualmente.
function debug_encher_recursos(_dono = "jogador") {
    var _tipos = ["sangue", "ossos", "sucata", "mana"];

    for (var i = 0; i < array_length(_tipos); i++) {
        var _slot_livre = noone;
        with (obj_slot_recurso) {
            if (!ocupado && dono == _dono) {
                _slot_livre = id;
                break;
            }
        }
        if (_slot_livre == noone) break; // campo já cheio

        // ignora o limite de "1 recurso por turno" só pro debug
        var _resultado_antigo = (_dono == "jogador") ? obj_controlador.recurso_colocado_no_turno : obj_controlador.recurso_colocado_no_turno_inimigo;
        if (_dono == "jogador") obj_controlador.recurso_colocado_no_turno = false;
        else obj_controlador.recurso_colocado_no_turno_inimigo = false;

        colocar_recurso(_tipos[i mod array_length(_tipos)], _dono, _slot_livre.x, _slot_livre.y, _slot_livre);

        if (_dono == "jogador") obj_controlador.recurso_colocado_no_turno = _resultado_antigo;
        else obj_controlador.recurso_colocado_no_turno_inimigo = _resultado_antigo;
    }

    debug_combate("DEBUG: recursos do " + _dono + " preenchidos.");
}
#endregion

#region Utilidades matemáticas
// Interpola suavemente entre dois ângulos, sempre pelo caminho mais curto
// (evita o bug clássico de girar 350° quando devia girar só 10°).
function lerp_angulo(_atual, _alvo, _fator) {
    var _diferenca = ((_alvo - _atual + 180) mod 360) - 180;
    return _atual + _diferenca * _fator;
}
#endregion
