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
}
#endregion

#region Tabuleiro — grade e posições
// Grade central da room: 3 lanes (colunas) por 5 posições (linhas).
// posicao: 0 = base inimiga, 1 = retaguarda inimiga, 2 = MEIO (centro, onde o combate acontece),
//          3 = retaguarda do jogador, 4 = base do jogador.
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
    return 2; // o MEIO — onde as tropas param de andar sozinhas e começam a atacar
}

function direcao_avanco(_dono) {
    return (_dono == "jogador") ? -1 : 1;
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
				{ tipo: "osso", quantidade: 1 }],
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

function lista_bencaos(_dono) {
    return (_dono == "jogador") ? obj_controlador.bencaos_jogador : obj_controlador.bencaos_inimigo;
}

function lista_maldicoes(_dono) {
    return (_dono == "jogador") ? obj_controlador.maldicoes_jogador : obj_controlador.maldicoes_inimigo;
}

function adicionar_bencao(_dono, _efeito) {
    var _lista = lista_bencaos(_dono);
    if (array_length(_lista) >= obj_controlador.max_bencaos_maldicoes) return false;
    array_push(_lista, _efeito);
    return true;
}

function adicionar_maldicao(_dono, _efeito) {
    var _lista = lista_maldicoes(_dono);
    if (array_length(_lista) >= obj_controlador.max_bencaos_maldicoes) return false;
    array_push(_lista, _efeito);
    return true;
}

// chamada toda vez que uma tropa morre, ANTES de ser destruída de verdade
function aplicar_efeitos_morte(_carta, _por_inimigo) {
    var _dono = _carta.dono;
    var _bencaos = lista_bencaos(_dono);
    
    for (var i = 0; i < array_length(_bencaos); i++) {
        if (_bencaos[i] == "cura_ao_morrer") {
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
            if (_maldicoes[i] == "perde_vida_ao_morrer") {
                if (_dono == "jogador") {
                    obj_controlador.vida_jogador -= 1;
                } else {
                    obj_controlador.vida_inimigo -= 1;
                }
                debug_combate("Maldição da Perda causou 1 de dano!");
            }
        }
    }
}
#endregion

#region Deck — montar, embaralhar, comprar
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

// Monta o monte de compra: várias cópias de cada carta do baralho, embaralhadas.
function montar_deck() {
    var _monte = [];
    var _copias_por_carta = 3; // ajuste esse número -- quantas cópias de cada carta entram no deck

    for (var i = 0; i < array_length(baralho); i++) {
        for (var c = 0; c < _copias_por_carta; c++) {
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
		_carta.vida_pos_x = variable_struct_exists(_dados, "vida_pos_x") ? _dados.vida_pos_x : 0.11;
		_carta.vida_pos_y = variable_struct_exists(_dados, "vida_pos_y") ? _dados.vida_pos_y : 0.07;
		_carta.selo_abissal = variable_struct_exists(_dados, "selo_abissal") ? _dados.selo_abissal : false;
		_carta.funcao_evolucao = variable_struct_exists(_dados, "evolucao") ? _dados.evolucao : noone;
        _carta.custo_sacrificio = _dados.sacrificio;
        _carta.dado_dano = _dados.dado_dano;
		_carta.qtd_dados_dano = variable_struct_exists(_dados, "qtd_dados_dano") ? _dados.qtd_dados_dano : 1;
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

    array_push(obj_controlador.mao, _carta);
    organizar_mao();

    _carta.x = _x_inicial;
    _carta.y = _y_inicial;
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
#endregion

#region Movimento das tropas
function iniciar_pulo_tropa(_carta, _novo_x, _novo_y) {
    _carta.pulando = true;
    _carta.pulo_origem_x = _carta.x;
    _carta.pulo_origem_y = _carta.y;
    _carta.pulo_destino_x = _novo_x;
    _carta.pulo_destino_y = _novo_y;
    _carta.pulo_progresso = 0;
}

// Move uma tropa 1 casa na direção dela. Retorna uma string dizendo o que aconteceu:
// "movido", "ja_no_meio", "fora_do_tabuleiro", "invalido", "bloqueado" (aliado no caminho)
// ou "ataque_necessario" (tem inimigo na frente, precisa atacar em vez de mover).
function mover_tropa(_carta, _direcao) {
    if (_carta.posicao_atual == posicao_ataque() && _direcao == 1) {
        return "ja_no_meio"; // ela já chegou no MEIO e fica ali até morrer
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

    iniciar_pulo_tropa(_carta, _slot_destino.x, _slot_destino.y);

	verificar_olhar_vazio(_carta);

    return "movido";
}

// Move todas as tropas de um lado que ainda não chegaram no MEIO (usada no início de cada turno).
function mover_tropas_automatico(_dono) {
    with (obj_carta) {
        if (dono == _dono && travada && posicao_atual != posicao_ataque() && tropa_pode_agir(id)) {
            mover_tropa(id, 1);
        }
    }
}
#endregion

#region Combate — dados, dano e resolução
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

// Processa o ataque de TODAS as tropas de um lado de uma vez (usada pela IA).
// Cadeia de alvo: tropa inimiga na frente > construção na lane > vida direto.
function processar_combate(_lado_atacante) {
    var _lado_defensor = (_lado_atacante == "jogador") ? "inimigo" : "jogador";
    var _sentido = direcao_avanco(_lado_atacante);

    with (obj_slot_batalha) {
        if (ocupado && carta_atual.dono == _lado_atacante && tropa_pode_agir(carta_atual)) {
            var _atacante = carta_atual;
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
			    && (!tem_habilidade(_slot_alvo.carta_atual, "voar") || tem_habilidade(_atacante, "voar") || _tem_alcance);

			if (_pode_mirar_alvo) {
                rolar_combate(_atacante, _slot_alvo.carta_atual);

            } else if (posicao == posicao_ataque()) {
                // só chega aqui se estiver no MEIO e não tiver tropa na frente
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
            // se não estiver no MEIO e não tiver tropa na frente: não faz nada, ela ainda vai avançar sozinha
        }
    }
}

// Versão do combate pra UMA tropa só (usada pelo menu de ação do jogador).
// Mesma cadeia de alvo que processar_combate(), só que pra 1 tropa específica.
function processar_combate_tropa(_carta) {
    if (!instance_exists(_carta) || !_carta.travada || _carta.slot_atual == noone) return;

    var _slot = _carta.slot_atual;
    var _lado_atacante = _carta.dono;
    var _lado_defensor = (_lado_atacante == "jogador") ? "inimigo" : "jogador";
    var _sentido = direcao_avanco(_lado_atacante);

    if (_carta.iludido_por_imitacao) {
        _carta.iludido_por_imitacao = false;
        debug_combate(_carta.nome_carta + " está iludida e não atacou.");
        return;
    }

    var _tem_alcance = tem_habilidade(_carta, "alcance") || tem_habilidade(_carta, "alcance_magico");
    var _proxima_posicao = _slot.posicao + _sentido;
    var _slot_alvo = buscar_slot(_slot.lane, _proxima_posicao);

    if ((_slot_alvo == noone || !_slot_alvo.ocupado) && _tem_alcance) {
        var _slot_longe = buscar_slot(_slot.lane, _slot.posicao + _sentido * 2);
        if (_slot_longe != noone && _slot_longe.ocupado) _slot_alvo = _slot_longe;
    }

    var _pode_mirar_alvo = _slot_alvo != noone && _slot_alvo.ocupado && _slot_alvo.carta_atual.dono == _lado_defensor
        && !_slot_alvo.carta_atual.sombra_ativa
        && (!tem_habilidade(_slot_alvo.carta_atual, "voar") || tem_habilidade(_carta, "voar") || _tem_alcance);

    if (_pode_mirar_alvo) {
        rolar_combate(_carta, _slot_alvo.carta_atual);
    } else if (_slot.posicao == posicao_ataque()) {
        var _construcao_alvo = buscar_construcao(_slot.lane, _lado_defensor);

        if (_construcao_alvo != noone) {
            var _dano_construcao = irandom_range(1, _carta.dado_dano) + _carta.mod_dano;
            _construcao_alvo.vida -= _dano_construcao;

            if (_construcao_alvo.vida <= 0) {
                _construcao_alvo.slot_atual.ocupado = false;
                _construcao_alvo.slot_atual.construcao_atual = noone;
                instance_destroy(_construcao_alvo);
            }
        } else {
            var _dano_direto = irandom_range(1, _carta.dado_dano) + _carta.mod_dano;
            if (_lado_atacante == "jogador") {
                obj_controlador.vida_inimigo -= _dano_direto;
            } else {
                obj_controlador.vida_jogador -= _dano_direto;
            }
        }
    } else {
        debug_combate(_carta.nome_carta + " não tem alvo na frente ainda (precisa avançar mais).");
    }
}

// Inicia um combate entre 2 tropas: rola o D20 de acerto (visual) e, quando ele parar,
// decide o resultado em processar_resultado_acerto().
function rolar_combate(_atacante, _defensor) {
    debug_combate("=== ATAQUE: " + _atacante.nome_carta + " (id=" + string(_atacante.id) + ") vs " + _defensor.nome_carta + " (id=" + string(_defensor.id) + ") ===");

    var _dado_acerto = irandom_range(1, 20);

    var _dados_combate = {
        atacante: _atacante,
        defensor: _defensor
    };

    rolar_dado_visual(_atacante.x, _atacante.y, _defensor.x, _defensor.y, 20, _dado_acerto, method(_dados_combate, function(_resultado) {
        processar_resultado_acerto(_resultado, atacante, defensor);
    }));
}

function rolar_varios_dados(_quantidade, _tamanho_dado) {
    var _total = 0;
    for (var i = 0; i < _quantidade; i++) {
        _total += irandom_range(1, _tamanho_dado);
    }
    return _total;
}
	
// Regras do D20: 1-10 erra, 1 natural = contra-ataque do defensor, 11-19 acerta,
// 20 natural = crítico (rola 2 dados de dano e soma).
function processar_resultado_acerto(_dado_acerto, _atacante, _defensor) {
    if (!instance_exists(_atacante) || !instance_exists(_defensor)) {
        debug_combate("--> combate cancelado: atacante ou defensor não existe mais.");
        return;
    }
    debug_combate("D20 rolou: " + string(_dado_acerto));

    if (_dado_acerto == 1) {
        debug_combate("Erro crítico! Defensor vai contra-atacar.");

        var _dano_contra_dado = rolar_varios_dados(_defensor.qtd_dados_dano, _defensor.dado_dano);

        var _dados_contra = {
            atacante: _atacante,
            defensor: _defensor
        };

        rolar_dado_visual(_defensor.x, _defensor.y, _atacante.x, _atacante.y, _defensor.dado_dano, _dano_contra_dado, method(_dados_contra, function(_resultado) {
            if (!instance_exists(atacante) || !instance_exists(defensor)) return;

            var _dano_contra = _resultado + defensor.mod_dano;
            _dano_contra = max(0, _dano_contra - atacante.defesa_fisica - obj_controlador.terreno_bonus_defesa);
            atacante.vida -= _dano_contra;

            debug_combate(atacante.nome_carta + " tomou " + string(_dano_contra) + " de contra-ataque. Vida: " + string(atacante.vida));

            if (atacante.vida <= 0) {
                destruir_tropa(atacante);
            }
        }));
        return;
    }

    if (_dado_acerto <= 10) {
        debug_combate("Errou o ataque (1-10).");
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

    // crítico dobra a quantidade de dados originais da carta (regra do manual)
	var _num_dados = (_dado_acerto == 20) ? (_atacante.qtd_dados_dano * 2) : _atacante.qtd_dados_dano;
	var _dano_dado = rolar_varios_dados(_num_dados, _atacante.dado_dano);

    var _dados_dano = {
        atacante: _atacante,
        defensor: _alvo_real
    };

    rolar_dado_visual(_atacante.x, _atacante.y, _alvo_real.x, _alvo_real.y, _atacante.dado_dano, _dano_dado, method(_dados_dano, function(_resultado) {
	    if (!instance_exists(atacante) || !instance_exists(defensor)) return;

	    var _dano_final = _resultado + atacante.mod_dano;
	    _dano_final = max(0, _dano_final - defensor.defesa_fisica - obj_controlador.terreno_bonus_defesa);
	    defensor.vida -= _dano_final;

	    debug_combate(defensor.nome_carta + " tomou " + string(_dano_final) + " de dano! Vida agora: " + string(defensor.vida));

	    if (defensor.vida <= 0) {
	        destruir_tropa(defensor);
	    }
	}));
}

function destruir_tropa(_carta, _por_inimigo = true) {
    aplicar_efeitos_morte(_carta, _por_inimigo);

    if (_carta.selo_abissal) {
        mandar_para_abismo(_carta.nome_carta);
    }

    if (tem_habilidade(_carta, "mitose") && _carta.funcao_mitose != noone) {
        executar_mitose(_carta);
    }

    if (_carta.slot_atual != noone) {
        _carta.slot_atual.ocupado = false;
        _carta.slot_atual.carta_atual = noone;
    }
    instance_destroy(_carta);
}

function executar_mitose(_carta) {
    var _slot_morte = _carta.slot_atual;
    if (_slot_morte == noone) return;

    var _dados_filhote = _carta.funcao_mitose();

    criar_tropa_no_slot(_dados_filhote, _slot_morte, _carta.dono);

    var _slot_adjacente = buscar_slot(_slot_morte.lane, _slot_morte.posicao + direcao_avanco(_carta.dono));
    if (_slot_adjacente == noone || _slot_adjacente.ocupado) {
        _slot_adjacente = buscar_slot(_slot_morte.lane, _slot_morte.posicao - direcao_avanco(_carta.dono));
    }
    if (_slot_adjacente != noone && !_slot_adjacente.ocupado) {
        criar_tropa_no_slot(_dados_filhote, _slot_adjacente, _carta.dono);
    }

    debug_combate(_carta.nome_carta + " se dividiu em 2 Slimets pela MITOSE!");
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
    _carta.mod_dano = _dados.mod_dano;
    _carta.defesa_fisica = _dados.defesa_fisica;
    _carta.defesa_magica = _dados.defesa_magica;
    _carta.habilidades = variable_struct_exists(_dados, "habilidades") ? _dados.habilidades : [];
    _carta.funcao_mitose = variable_struct_exists(_dados, "mitose") ? _dados.mitose : noone;
	_carta.nivel_inteligencia = variable_struct_exists(_dados, "inteligencia") ? _dados.inteligencia : 1;
	_carta.dado_dano_magico = variable_struct_exists(_dados, "dado_dano_magico") ? _dados.dado_dano_magico : 0;
	_carta.mod_dano_magico = variable_struct_exists(_dados, "mod_dano_magico") ? _dados.mod_dano_magico : 0;
	_carta.mochila = variable_struct_exists(_dados, "mochila") ? _dados.mochila : 1;

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
    _carta.depth = 0;
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
function rolar_dado_visual(_x, _y, _destino_x, _destino_y, _tamanho_dado, _resultado_final, _funcao_callback) {
    var _dado = instance_create_layer(_x, _y, "Instances", obj_dado);
    obj_controlador.rolagens_pendentes += 1;

    _dado.tamanho_dado = _tamanho_dado;
    _dado.valor_final = _resultado_final;
    _dado.destino_x = _destino_x;
    _dado.destino_y = _destino_y;
    _dado.girando = true;
    _dado.tempo_girando = 0;
    _dado.callback = _funcao_callback;
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
    _moeda.girando = true;
    _moeda.tempo_girando = 0;
    _moeda.callback = _funcao_callback;

    obj_controlador.rolagens_pendentes += 1;
    debug_combate("+1 pendente (moeda id=" + string(_moeda.id) + "). Total: " + string(obj_controlador.rolagens_pendentes));
}
#endregion

#region Turnos — fluxo do jogador e da IA
function passar_turno_jogador() {
    if (obj_controlador.turno != "jogador") return;
    if (obj_controlador.rolagens_pendentes > 0) return;

    obj_controlador.carta_menu_aberto = noone;

    iniciar_turno_inimigo();

    processar_condicoes("jogador");
    desvirar_recursos("jogador");
    if (instance_exists(obj_deck) && array_length(obj_controlador.monte) > 0) {
        comprar_carta_do_deck(obj_deck.x, obj_deck.y);
    }
    reiniciar_acoes_tropas("jogador");
    expirar_condicoes("jogador"); // desconta o turno da tropa só agora, depois dela já ter agido
    obj_controlador.cartas_jogadas_no_turno = 0;
}

function iniciar_turno_inimigo() {
    obj_controlador.turno = "inimigo";

	reiniciar_acoes_tropas("inimigo");

    processar_condicoes("inimigo"); // dano/cura no início do turno dela
    desvirar_recursos("inimigo");
    ia_jogar_recursos();
    ia_jogar_construcao();

    mover_tropas_automatico("inimigo"); // aqui ela ainda está bloqueada, se estiver congelada/paralisada
    ia_jogar_cartas();
    processar_combate("inimigo");

    expirar_condicoes("inimigo"); // só desconta o turno DEPOIS de tudo isso

    obj_controlador.turno = "jogador";
}

function reiniciar_acoes_tropas(_lado) {
    with (obj_carta) {
        if (dono == _lado && travada) {
            moveu_este_turno = false;
            atacou_este_turno = false;
            habilidade_usada_este_turno = false;
            turnos_no_campo += 1;
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
				
				if (_dados.categoria == "bencao") {
				    adicionar_bencao("inimigo", _dados.efeito);
				    continue;
				}
				if (_dados.categoria == "maldicao") {
				    adicionar_maldicao("inimigo", _dados.efeito);
				    continue;
				}
				if (_dados.categoria != "tropa") continue;
				if (!pode_pagar_custo(_dados.custo, "inimigo")) continue;
				


                pagar_custo(_dados.custo, "inimigo");

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
                _carta.mod_dano = _dados.mod_dano;
                _carta.defesa_fisica = _dados.defesa_fisica;
                _carta.defesa_magica = _dados.defesa_magica;
                _carta.habilidades = variable_struct_exists(_dados, "habilidades") ? _dados.habilidades : [];
				_carta.funcao_mitose = variable_struct_exists(_dados, "mitose") ? _dados.mitose : noone;
				_carta.nivel_inteligencia = variable_struct_exists(_dados, "inteligencia") ? _dados.inteligencia : 1;
				_carta.dado_dano_magico = variable_struct_exists(_dados, "dado_dano_magico") ? _dados.dado_dano_magico : 0;
				_carta.mod_dano_magico = variable_struct_exists(_dados, "mod_dano_magico") ? _dados.mod_dano_magico : 0;
				_carta.mochila = variable_struct_exists(_dados, "mochila") ? _dados.mochila : 1;

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
#endregion

#region Recursos — colocar, pagar custo, desvirar
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

// função auxiliar (workaround pro "with" não enxergar _custo direto às vezes)
function other_custo_tipo(_custo) {
    return _custo.tipo;
}

// verifica se dá pra pagar um custo, sem gastar ainda
function pode_pagar_custo(_custo, _dono) {
    if (_custo == noone) return true;

    // aceita tanto o formato antigo (1 struct só) quanto o novo (array de structs)
    var _lista_custos = is_array(_custo) ? _custo : [_custo];

    for (var i = 0; i < array_length(_lista_custos); i++) {
        var _item = _lista_custos[i];
        var _disponiveis = 0;

        with (obj_recurso) {
            if (!virado && dono == _dono && (tipo == other_custo_tipo(_item) || _item.tipo == "qualquer")) {
                _disponiveis += 1;
            }
        }

        if (_disponiveis < _item.quantidade) return false;
    }

    return true;
}

// paga de verdade, virando os recursos usados
function pagar_custo(_custo, _dono) {
    if (_custo == noone) return true;

    var _lista_custos = is_array(_custo) ? _custo : [_custo];
    var _lista_recursos = (_dono == "jogador") ? obj_controlador.recursos_jogador : obj_controlador.recursos_inimigo;

    for (var i = 0; i < array_length(_lista_custos); i++) {
        var _item = _lista_custos[i];
        var _pagos = 0;

        for (var j = 0; j < array_length(_lista_recursos); j++) {
            if (_pagos >= _item.quantidade) break;

            var _recurso = _lista_recursos[j];
            if (instance_exists(_recurso) && !_recurso.virado) {
                if (_item.tipo == "qualquer" || _recurso.tipo == _item.tipo) {
                    _recurso.virado = true;
                    _pagos += 1;
                }
            }
        }

        if (_pagos < _item.quantidade) return false; // não deveria acontecer se pode_pagar_custo já checou antes
    }

    return true;
}

// desvira todos os recursos de um lado (chamado no início do turno dele)
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
    }
    return { cor: c_white, sprite: -1, modo: "meio" };
}

// Tenta aplicar uma condição -- só funciona se a tropa não tiver outra condição diferente ativa.
// Já dispara o texto flutuante com a cor certa quando aplica com sucesso.
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

function aplicar_envenenado(_carta) {
    aplicar_condicao(_carta, "envenenado", -1, 1); // -1 = dura até morrer
}

function aplicar_congelado(_carta) {
    aplicar_condicao(_carta, "congelado", 1, 0); // sem dano, só trava 1 turno
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
// se paralisa. A cada 6 choques seguidos sem descanso, ganharia Loucura (ainda não implementada).
function aplicar_eletrocutado(_carta) {
    _carta.vida -= 2;

    debug_combate(_carta.nome_carta + " foi eletrocutado! Tomou 2 de dano.");

    if (_carta.vida <= 0) {
        destruir_tropa(_carta);
        return;
    }

    _carta.vezes_eletrocutado_seguidas += 1;

    var _moeda = irandom(1); // 0 = coroa, 1 = cara

    if (_moeda == 1) {
        debug_combate(_carta.nome_carta + " tirou CARA! Ficou paralisado.");
        aplicar_condicao(_carta, "paralisado", 1, 0);
    } else {
        debug_combate(_carta.nome_carta + " tirou COROA. Sem paralisia dessa vez.");
        aplicar_condicao(_carta, "eletrocutado", 1, 0);
    }

    if (_carta.vezes_eletrocutado_seguidas >= 6) {
        debug_combate(_carta.nome_carta + " levou choque demais e ganhou LOUCURA! (efeito ainda não implementado)");
        _carta.vezes_eletrocutado_seguidas = 0;
    }
}

// Tropas paralisadas/congeladas não podem agir (mover, atacar, usar habilidade).
function tropa_pode_agir(_carta) {
    return (_carta.condicao != "paralisado" && _carta.condicao != "congelado");
}

// Processa o efeito de todas as condições de um lado (dano/cura), no início do turno dele.
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
		    destruir_tropa(id, false); // morreu por condição, não foi o oponente que causou diretamente
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
function aplicar_efeito_bola_fogo(_alvo, _dado_efeito, _chance_queimar) {
    var _dano = irandom_range(1, _dado_efeito);

    debug_combate(_alvo.nome_carta + " tomou " + string(_dano) + " de Bola de Fogo!");

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
    var _altura_visual_moeda = global.MOEDA_LARGURA; // a moeda é quadrada, largura = altura

    var _destino_x = _alvo.x;
    var _destino_y = _alvo.y - _altura_visual_alvo/2 - (_altura_visual_moeda/2) + 20; // "+20" desce ela um pouco

    jogar_moeda_visual(_origem_x, _origem_y, _destino_x, _destino_y, method(_dados_moeda, function(_resultado) {
        if (!instance_exists(alvo)) return;

        if (_resultado == 1) {
            aplicar_condicao(alvo, "queimado", 3, 2);
        }
    }));
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
#endregion

#region Evolução - Controlar turnos para evolução

function evoluir_tropa(_carta) {
    if (_carta.funcao_evolucao == noone) return;
    if (_carta.turnos_no_campo < 1) {
        debug_combate("Ainda não pode evoluir, precisa sobreviver 1 turno completo.");
        return;
    }
    if (!evolucoes_disponiveis(_carta.dono)) {
        debug_combate("Já evoluiu uma tropa esse turno.");
        return;
    }
    
    var _dados_evo = _carta.funcao_evolucao();
    
    if (!pode_pagar_custo(_dados_evo.custo, _carta.dono)) {
        debug_combate("Sem recurso suficiente pra evoluir.");
        return;
    }
    pagar_custo(_dados_evo.custo, _carta.dono);
    
    // transfere o dano já sofrido, não reseta a vida
    var _dano_sofrido = _carta.vida_maxima - _carta.vida;
    
    _carta.nome_carta = _dados_evo.nome;
    _carta.sprite_index = (_dados_evo.sprite_carta != noone) ? _dados_evo.sprite_carta : spr_carta_placeholder;
    _carta.escala_base = global.CARTA_LARGURA / sprite_get_width(_carta.sprite_index);
    _carta.tem_arte_propria = (_dados_evo.sprite_carta != noone);
    
    _carta.vida_maxima = _dados_evo.vida;
    _carta.vida = max(1, _dados_evo.vida - _dano_sofrido);
	_carta.vida_pos_x = variable_struct_exists(_dados_evo, "vida_pos_x") ? _dados.vida_pos_x : 0.11;
	_carta.vida_pos_y = variable_struct_exists(_dados_evo, "vida_pos_y") ? _dados.vida_pos_y : 0.07;
    _carta.dado_dano = _dados_evo.dado_dano;
	_carta.qtd_dados_dano = variable_struct_exists(_dados_evo, "qtd_dados_dano") ? _dados_evo.qtd_dados_dano : 1;
    _carta.mod_dano = _dados_evo.mod_dano;
    _carta.defesa_fisica = _dados_evo.defesa_fisica;
    _carta.defesa_magica = _dados_evo.defesa_magica;
	_carta.habilidades = variable_struct_exists(_dados_evo, "habilidades") ? _dados_evo.habilidades : [];
    _carta.funcao_evolucao = variable_struct_exists(_dados_evo, "evolucao") ? _dados_evo.evolucao : noone;
	_carta.nivel_inteligencia = variable_struct_exists(_dados_evo, "inteligencia") ? _dados_evo.inteligencia : 1;
	_carta.dado_dano_magico = variable_struct_exists(_dados_evo, "dado_dano_magico") ? _dados_evo.dado_dano_magico : 0;
	_carta.mod_dano_magico = variable_struct_exists(_dados_evo, "mod_dano_magico") ? _dados_evo.mod_dano_magico : 0;
	_carta.mochila = variable_struct_exists(_dados_evo, "mochila") ? _dados_evo.mochila : 1;

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

#region Menu de ação (clicar na tropa → Atacar/Mover/Habilidade)
function obter_opcoes_menu(_carta) {
    var _opcoes = [];
    if (!_carta.atacou_este_turno) array_push(_opcoes, "Atacar");
    if (!_carta.moveu_este_turno) array_push(_opcoes, "Mover");
    if (tem_habilidade_ativa(_carta) != noone && !_carta.habilidade_usada_este_turno) array_push(_opcoes, "Habilidade");
    if (_carta.funcao_evolucao != noone && _carta.turnos_no_campo >= 1 && evolucoes_disponiveis(_carta.dono)) {
        array_push(_opcoes, "Evoluir");
    }
    return _opcoes;
}

function executar_opcao_menu(_carta, _opcao) {
    switch (_opcao) {
        case "Atacar":
            processar_combate_tropa(_carta);
            _carta.atacou_este_turno = true;
            break;
        case "Mover":
            var _resultado = mover_tropa(_carta, 1);
            if (_resultado == "movido") {
                _carta.moveu_este_turno = true;
            }
            break;
        case "Habilidade":
            usar_habilidade(_carta);
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
    }
    return "Habilidade";
}
	
function tem_habilidade(_carta, _chave) {
    return array_get_index(_carta.habilidades, _chave) != -1;
}

// Só essas contam como "usar no menu" -- as outras (alcance, voar, olhar_vazio, tiro_burro)
// são passivas e são checadas direto no combate/movimento, sem precisar de clique.
function tem_habilidade_ativa(_carta) {
    var _ativas = ["golpe_duplo", "sombra_translucida", "ferida_exposta", "imitacao", "visao_do_veu"];
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
    }
}

// Golpe Duplo: ataca duas vezes seguidas no mesmo turno.
function habilidade_golpe_duplo(_carta) {
    if (_carta.atacou_este_turno) {
        debug_combate("Golpe Duplo: já atacou esse turno, não pode usar.");
        return;
    }

    debug_combate(_carta.nome_carta + " usa GOLPE DUPLO!");

    processar_combate_tropa(_carta);
    processar_combate_tropa(_carta);

    _carta.atacou_este_turno = true;
    _carta.habilidade_usada_este_turno = true;
}

// Sombra Translúcida: fica invisível (não pode ser mirada) por 1 turno. Custa 2 mana,
// e depois de usar precisa de 1 turno extra de recarga antes de poder usar de novo.
function habilidade_sombra_translucida(_carta) {
    if (_carta.sombra_cooldown > 0) {
        debug_combate("Sombra Translúcida ainda recarregando (" + string(_carta.sombra_cooldown) + " turnos).");
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
        return;
    }

    var _alvo = _slot_alvo.carta_atual;
    _carta.habilidade_usada_este_turno = true;

    var _rolagem_imitacao = irandom_range(1, 20);
    var _rolagem_defensor = irandom_range(1, 20);

    debug_combate(_carta.nome_carta + " usa IMITAÇÃO! (" + string(_rolagem_imitacao) + " vs " + string(_rolagem_defensor) + ")");

    if (_rolagem_imitacao > _rolagem_defensor) {
        _alvo.iludido_por_imitacao = true;
        debug_combate(_alvo.nome_carta + " foi enganada e não vai atacar no próximo turno dela!");
    } else {
        debug_combate("A tropa inimiga não caiu no truque.");
    }
}

// Simplificado: mostra a mão do oponente no console e torna a tropa imune a armadilhas
// (o jogo ainda não tem uma tela de "escolher carta da mão do oponente" nem sistema de armadilha automática).
function habilidade_visao_do_veu(_carta) {
    if (_carta.visao_do_veu_usada) {
        debug_combate("Visão do Véu já foi usada nessa carta.");
        return;
    }
    _carta.visao_do_veu_usada = true;
    _carta.habilidade_usada_este_turno = true;
    _carta.imune_armadilha = true;

    var _lado_oponente = (_carta.dono == "jogador") ? "inimigo" : "jogador";
    var _nomes = [];
    with (obj_carta) {
        if (dono == _lado_oponente && esta_na_mao) {
            array_push(_nomes, nome_carta);
        }
    }
    debug_combate("VISÃO DO VÉU revela a mão do oponente: " + string(_nomes));
    debug_combate(_carta.nome_carta + " agora é imune a armadilhas.");
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
    }
}
#endregion

#region Áudio
function tocar_musica(_musica) {
    audio_stop_all();

    if (!audio_is_playing(_musica)) {
        audio_play_sound(_musica, 0, true);
    }
}
#endregion