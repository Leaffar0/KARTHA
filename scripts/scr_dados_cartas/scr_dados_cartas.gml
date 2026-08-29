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
        custo: { tipo: "sucata", quantidade: 1 }
    };
}
	
function criar_dados_construcao_hemodrenario() {
    return {
        categoria: "construcao",
        nome: "Hemodrenário",
        sprite_carta: spr_carta_hemodrenario, // troca quando tiver a arte
        vida: 12,
        custo: [{ tipo: "sangue", quantidade: 1 },
				{ tipo: "sucata", quantidade: 2}]
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
        categoria: "item_consumivel",
        nome: "Sangue Suga",
        sprite_carta: spr_carta_sangue_suga, // troque quando importar a arte
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
        dado_efeito: 6
    };
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

// Ativa uma carta de armadilha que está "pronta" (tropa em cima do slot vigiado agora).
// Genérico: funciona pra qualquer carta armadilha que use dado_efeito (dano + sangrando).
function ativar_armadilha(_carta_armadilha) {
    if (!instance_exists(_carta_armadilha)) return;
    if (_carta_armadilha.armadilha_estado != "pronta") return;

    var _slot_vigiado = buscar_slot(_carta_armadilha.armadilha_lane, _carta_armadilha.armadilha_posicao);
    if (_slot_vigiado == noone || !_slot_vigiado.ocupado) return;

    var _alvo = _slot_vigiado.carta_atual;
    if (!instance_exists(_alvo)) return;

    if (_alvo.imune_armadilha) {
        debug_combate(_alvo.nome_carta + " é imune a armadilhas e evitou a " + _carta_armadilha.nome_carta + "!");
        return;
    }

    criar_flash(_alvo.x, _alvo.y, 45); // <-- flash discreto no momento do disparo

    var _dano = irandom_range(1, _carta_armadilha.dado_efeito);
    _alvo.vida -= _dano;
    aplicar_condicao(_alvo, "sangrando", 1, 3);

    debug_combate(_carta_armadilha.nome_carta + " ativada em " + _alvo.nome_carta + "! " + string(_dano) + " de dano.");

    if (_alvo.vida <= 0) destruir_tropa(_alvo);

    if (_carta_armadilha.armadilha_visual_id != noone && instance_exists(_carta_armadilha.armadilha_visual_id)) {
        instance_destroy(_carta_armadilha.armadilha_visual_id);
    }

    var _index = array_get_index(obj_controlador.mao, _carta_armadilha.id);
    if (_index != -1) {
        array_delete(obj_controlador.mao, _index, 1);
        organizar_mao();
    }
    instance_destroy(_carta_armadilha);
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
        nome: "Decomposição",
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
    return _carta.defesa_fisica + bonus_cemiterio_defesa(_carta);
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
	    _carta.bonus_mod_dano_item = variable_struct_exists(_dados, "bonus_mod_dano") ? _dados.bonus_mod_dano : 0;
	    _carta.bonus_defesa_item = variable_struct_exists(_dados, "bonus_defesa") ? _dados.bonus_defesa : 0;
	    _carta.requisito_inteligencia_item = variable_struct_exists(_dados, "requisito_inteligencia") ? _dados.requisito_inteligencia : 0;
	    _carta.sobrescreve_dado_dano_item = variable_struct_exists(_dados, "sobrescreve_dado_dano") ? _dados.sobrescreve_dado_dano : 0;
	    _carta.sobrescreve_mod_dano_item = variable_struct_exists(_dados, "sobrescreve_mod_dano") ? _dados.sobrescreve_mod_dano : 0;

    } else if (_dados.categoria == "item_consumivel") {
	    _carta.custo = _dados.custo;
	    _carta.cura_item = variable_struct_exists(_dados, "cura") ? _dados.cura : 0;
	    _carta.efeito_tipo = variable_struct_exists(_dados, "efeito_tipo") ? _dados.efeito_tipo : "";
	    _carta.quantidade_efeito = variable_struct_exists(_dados, "quantidade_efeito") ? _dados.quantidade_efeito : 0;

    } else if (_dados.categoria == "armadilha") {
        _carta.custo = _dados.custo;
        _carta.dado_efeito = _dados.dado_efeito;

    } else if (_dados.categoria == "terreno") {
	    _carta.custo = _dados.custo;
	    _carta.bonus_defesa_global = _dados.bonus_defesa_global;
	    _carta.efeito_terreno = variable_struct_exists(_dados, "efeito_terreno") ? _dados.efeito_terreno : "";

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
            // Uma tropa voadora atravessa uma tropa terrestre e pousa na próxima casa livre.
            if (tem_habilidade(_carta, "voar") && !tem_habilidade(_ocupante, "voar")) {
                var _slot_apos_voo = buscar_slot(_carta.lane_atual, _nova_posicao + (_direcao * _sentido));
                if (_slot_apos_voo != noone && !_slot_apos_voo.ocupado) {
                    _slot_destino = _slot_apos_voo;
                    _nova_posicao += _direcao * _sentido;
                } else {
                    return "ataque_necessario";
                }
            } else {
            return "ataque_necessario";
            }
        }
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
function aplicar_flash_dano(_carta, _duracao = 18) {
    if (!instance_exists(_carta)) return;
    _carta.dano_flash_timer = _duracao;
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
    return max(0, _quantidade * ((_dado + 1) / 2) + _modificador + bonus_cemiterio_dano(_atacante) - _defesa - obj_controlador.terreno_bonus_defesa);
}

// Escolhe entre ataque físico e mágico usando o dano médio depois da defesa do alvo.
function ia_escolher_tipo_ataque(_atacante, _defensor) {
    if (_atacante.dado_dano_magico <= 0) return "fisica";
    if (_atacante.dado_dano <= 0) return "magica";

    var _fisico = ia_dano_esperado(_atacante, _defensor, "fisica");
    var _magico = ia_dano_esperado(_atacante, _defensor, "magica");
    return (_magico > _fisico) ? "magica" : "fisica";
}

function ia_poder_ataque(_carta) {
    var _fisico = max(0, _carta.qtd_dados_dano * ((_carta.dado_dano + 1) / 2) + _carta.mod_dano);
    var _magico = max(0, _carta.qtd_dados_dano_magico * ((_carta.dado_dano_magico + 1) / 2) + _carta.mod_dano_magico);
    return max(_fisico, _magico);
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
				var _tipo_escolhido = ia_escolher_tipo_ataque(_atacante, _slot_alvo.carta_atual);

				rolar_combate(_atacante, _slot_alvo.carta_atual, _tipo_escolhido);

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
                    var _defensor_castelo = buscar_defensor_castelo(lane, _lado_defensor);
                    if (_defensor_castelo != noone) {
                        debug_combate(_defensor_castelo.nome_carta + " defende o castelo!");
                        rolar_combate(_atacante, _defensor_castelo, ia_escolher_tipo_ataque(_atacante, _defensor_castelo));
                    } else {
                        var _dano_direto = irandom_range(1, _atacante.dado_dano) + _atacante.mod_dano;
                        if (_lado_atacante == "jogador") {
                            obj_controlador.vida_inimigo -= _dano_direto;
                        } else {
                            obj_controlador.vida_jogador -= _dano_direto;
                        }
                    }
                }
            }
            // se não estiver no MEIO e não tiver tropa na frente: não faz nada, ela ainda vai avançar sozinha
        }
    }
}

// Versão do combate pra UMA tropa só (usada pelo menu de ação do jogador).
// Mesma cadeia de alvo que processar_combate(), só que pra 1 tropa específica.
function processar_combate_tropa(_carta, _tipo_ataque) {
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
        rolar_combate(_carta, _slot_alvo.carta_atual, _tipo_ataque);
    } else if (_slot.posicao == posicao_ataque()) {
        var _construcao_alvo = buscar_construcao(_slot.lane, _lado_defensor);
        var _dado_usado = (_tipo_ataque == "magica") ? _carta.dado_dano_magico : _carta.dado_dano;
        var _mod_usado = (_tipo_ataque == "magica") ? _carta.mod_dano_magico : _carta.mod_dano;

        if (_construcao_alvo != noone) {
            var _dano_construcao = irandom_range(1, _dado_usado) + _mod_usado;
            _construcao_alvo.vida -= _dano_construcao;

            if (_construcao_alvo.vida <= 0) {
                _construcao_alvo.slot_atual.ocupado = false;
                _construcao_alvo.slot_atual.construcao_atual = noone;
                instance_destroy(_construcao_alvo);
            }
        } else {
            var _defensor_castelo = buscar_defensor_castelo(_slot.lane, _lado_defensor);
            if (_defensor_castelo != noone) {
                debug_combate(_defensor_castelo.nome_carta + " defende o castelo!");
                rolar_combate(_carta, _defensor_castelo, _tipo_ataque);
            } else {
                var _dano_direto = irandom_range(1, _dado_usado) + _mod_usado;
                if (_lado_atacante == "jogador") {
                    obj_controlador.vida_inimigo -= _dano_direto;
                } else {
                    obj_controlador.vida_jogador -= _dano_direto;
                }
            }
        }
    } else {
        debug_combate(_carta.nome_carta + " não tem alvo na frente ainda (precisa avançar mais).");
    }
}

// Inicia um combate entre 2 tropas: rola o D20 de acerto (visual) e, quando ele parar,
// decide o resultado em processar_resultado_acerto().
function rolar_combate(_atacante, _defensor, _tipo_ataque) {
    debug_combate("=== ATAQUE (" + _tipo_ataque + "): " + _atacante.nome_carta + " vs " + _defensor.nome_carta + " ===");

    // Resultado 4 da Loucura: não se defende e o próximo ataque acerta sem D20.
    if (_defensor.condicao == "loucura" && _defensor.loucura_sem_defesa) {
        _defensor.loucura_sem_defesa = false;
        debug_combate(_defensor.nome_carta + " não se defendeu por causa da Loucura.");
        processar_resultado_acerto(11, _atacante, _defensor, _tipo_ataque);
        return;
    }

	iniciar_animacao_ataque(_atacante, _defensor, 8, 14); // cutucada leve no início do ataque

    var _dado_acerto = irandom_range(1, 20) + bonus_cemiterio_acerto(_atacante);
    _dado_acerto = clamp(_dado_acerto, 1, 20); // não deixa passar de 20 nem virar crítico artificial

    var _dados_combate = {
        atacante: _atacante,
        defensor: _defensor,
        tipo_ataque: _tipo_ataque
    };

    rolar_dado_visual(_atacante.x, _atacante.y, _defensor.x, _defensor.y, 20, _dado_acerto, method(_dados_combate, function(_resultado) {
        processar_resultado_acerto(_resultado, atacante, defensor, tipo_ataque);
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
function processar_resultado_acerto(_dado_acerto, _atacante, _defensor, _tipo_ataque) {
    if (!instance_exists(_atacante) || !instance_exists(_defensor)) {
        debug_combate("--> combate cancelado: atacante ou defensor não existe mais.");
        return;
    }
    debug_combate("D20 rolou: " + string(_dado_acerto));

    // pega o dado/mod/quantidade certos conforme o tipo de ataque
    var _dado_usado = (_tipo_ataque == "magica") ? _atacante.dado_dano_magico : _atacante.dado_dano;
    var _mod_usado = (_tipo_ataque == "magica") ? _atacante.mod_dano_magico : _atacante.mod_dano;
    var _qtd_usada = (_tipo_ataque == "magica") ? _atacante.qtd_dados_dano_magico : _atacante.qtd_dados_dano;

    if (_dado_acerto == 1) {
        debug_combate("Erro crítico! Defensor vai contra-atacar.");

        // contra-ataque sempre usa o ataque físico do defensor (padrão)
        var _dano_contra_dado = rolar_varios_dados(_defensor.qtd_dados_dano, _defensor.dado_dano);
		var _mod_contra_exibido = _defensor.mod_dano + bonus_cemiterio_dano(_defensor);

		var _dados_contra = {
		    atacante: _atacante,
		    defensor: _defensor
		};

		rolar_dado_visual(_defensor.x, _defensor.y, _atacante.x, _atacante.y, _defensor.dado_dano, _dano_contra_dado, method(_dados_contra, function(_resultado) {
            if (!instance_exists(atacante) || !instance_exists(defensor)) return;

			iniciar_animacao_ataque(defensor, atacante, 18, 18);
			aplicar_flash_dano(atacante);

            var _dano_contra = _resultado + defensor.mod_dano + bonus_cemiterio_dano(defensor);
            var _defesa_contra = atacante.defesa_fisica + bonus_cemiterio_defesa(atacante);
            _dano_contra = max(0, _dano_contra - _defesa_contra - obj_controlador.terreno_bonus_defesa);
            atacante.vida -= _dano_contra;

            debug_combate(atacante.nome_carta + " tomou " + string(_dano_contra) + " de contra-ataque. Vida: " + string(atacante.vida));

            if (atacante.vida <= 0) {
                destruir_tropa(atacante);
            }
        }), _mod_contra_exibido);
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

    var _num_dados = (_dado_acerto == 20) ? (_qtd_usada * 2) : _qtd_usada;
	var _dano_dado = rolar_varios_dados(_num_dados, _dado_usado);
	var _mod_total_exibido = _mod_usado + bonus_cemiterio_dano(_atacante);

	var _dados_dano = {
	    atacante: _atacante,
	    defensor: _alvo_real,
	    mod_usado: _mod_usado,
	    tipo_ataque: _tipo_ataque
	};

	rolar_dado_visual(_atacante.x, _atacante.y, _alvo_real.x, _alvo_real.y, _dado_usado, _dano_dado, method(_dados_dano, function(_resultado) {
        if (!instance_exists(atacante) || !instance_exists(defensor)) return;

		iniciar_animacao_ataque(atacante, defensor, 18, 18);
		aplicar_flash_dano(defensor);

        var _defesa_usada = (tipo_ataque == "magica") ? defensor.defesa_magica : defensor.defesa_fisica;
        _defesa_usada += bonus_cemiterio_defesa(defensor);

        var _dano_final = _resultado + mod_usado + bonus_cemiterio_dano(atacante);
        _dano_final = max(0, _dano_final - _defesa_usada - obj_controlador.terreno_bonus_defesa);
        defensor.vida -= _dano_final;

        debug_combate(defensor.nome_carta + " tomou " + string(_dano_final) + " de dano " + tipo_ataque + "! Vida agora: " + string(defensor.vida));

        if (defensor.vida <= 0) {
            destruir_tropa(defensor);
        }
    }), _mod_total_exibido);
}

function destruir_tropa(_carta, _por_inimigo = true) {
    aplicar_efeitos_morte(_carta, _por_inimigo);

    if (_carta.selo_abissal) {
        mandar_para_abismo(_carta.nome_carta);
    } else {
        var _cemiterio = (_carta.dono == "jogador") ? obj_controlador.cemiterio_jogador : obj_controlador.cemiterio_inimigo;
        array_push(_cemiterio, _carta.nome_carta);
        ativar_hemodrenario_ao_morrer(_carta);
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
function rolar_dado_visual(_x, _y, _destino_x, _destino_y, _tamanho_dado, _resultado_final, _funcao_callback, _modificador_exibido = 0) {
    var _dado = instance_create_layer(_x, _y, "Instances", obj_dado);
    obj_controlador.rolagens_pendentes += 1;

    _dado.tamanho_dado = _tamanho_dado;
    _dado.valor_final = _resultado_final;
    _dado.modificador_exibido = _modificador_exibido;
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
function passar_turno_jogador() {
    if (obj_controlador.turno != "jogador") return;
    if (obj_controlador.rolagens_pendentes > 0) return;

    obj_controlador.carta_menu_aberto = noone;
    obj_controlador.primeiro_turno_jogador = false; // <-- adicione aqui

    iniciar_turno_inimigo();
}

function iniciar_turno_inimigo() {
    obj_controlador.turno = "inimigo";

    obj_controlador.itens_usados_este_turno = 0;
    obj_controlador.magias_usadas_este_turno = 0;
    obj_controlador.construcoes_jogadas_este_turno = 0;
    obj_controlador.terrenos_jogados_este_turno = 0;

	reiniciar_acoes_tropas("inimigo");

    processar_condicoes("inimigo");
    desvirar_recursos("inimigo");
    comprar_carta_do_deck_ia();

    obj_controlador.ia_ativa = true;
    obj_controlador.ia_etapa = 0;
    obj_controlador.ia_tempo_espera = 45;
    obj_controlador.ia_texto_acao = "planejando...";
}

// Executa uma ação por vez. As pausas deixam claros os movimentos da IA,
// mas o texto é genérico para a mão inimiga continuar secreta.
function processar_turno_ia() {
    if (!obj_controlador.ia_ativa) return;
    if (obj_controlador.rolagens_pendentes > 0) {
        obj_controlador.ia_texto_acao = "resolvendo o ataque...";
        return;
    }
    if (obj_controlador.ia_tempo_espera > 0) {
        obj_controlador.ia_tempo_espera--;
        return;
    }

    switch (obj_controlador.ia_etapa) {
        case 0:
            obj_controlador.ia_texto_acao = "preparando recursos";
            ia_jogar_recursos();
            obj_controlador.ia_etapa = 1;
            obj_controlador.ia_tempo_espera = 55;
        break;

        case 1:
            obj_controlador.ia_texto_acao = "organizando o campo";
            ia_jogar_construcao();
            ia_usar_construcoes();
            obj_controlador.ia_etapa = 2;
            obj_controlador.ia_tempo_espera = 55;
        break;

        case 2:
            obj_controlador.ia_texto_acao = "movendo tropas";
            mover_tropas_automatico("inimigo");
            obj_controlador.ia_etapa = 3;
            obj_controlador.ia_tempo_espera = 70;
        break;

        case 3:
            obj_controlador.ia_texto_acao = "escolhendo uma carta";
            ia_jogar_cartas();
            obj_controlador.ia_etapa = 4;
            obj_controlador.ia_tempo_espera = 70;
        break;

        case 4:
            obj_controlador.ia_texto_acao = "usando habilidades";
            ia_evoluir_tropa();
            ia_usar_habilidades_tropas();
            obj_controlador.ia_etapa = 5;
            obj_controlador.ia_tempo_espera = 55;
        break;

        case 5:
            obj_controlador.ia_texto_acao = "avaliando alvos";
            ia_jogar_magias();
            obj_controlador.ia_etapa = 6;
            obj_controlador.ia_tempo_espera = 55;
        break;

        case 6:
            obj_controlador.ia_texto_acao = "atacando";
            if (!obj_controlador.primeiro_turno_inimigo) {
                processar_combate("inimigo");
            }
            obj_controlador.ia_etapa = 7;
            obj_controlador.ia_tempo_espera = 45;
        break;

        case 7:
            expirar_condicoes("inimigo");
            obj_controlador.primeiro_turno_inimigo = false;
            obj_controlador.ia_ativa = false;
            obj_controlador.ia_texto_acao = "";
            obj_controlador.turno = "jogador";

            processar_condicoes("jogador");
            desvirar_recursos("jogador");
            if (instance_exists(obj_deck) && array_length(obj_controlador.monte) > 0) {
                comprar_carta_do_deck(obj_deck.x, obj_deck.y);
            }
            reiniciar_acoes_tropas("jogador");
            obj_controlador.itens_usados_este_turno = 0;
            obj_controlador.magias_usadas_este_turno = 0;
            obj_controlador.construcoes_jogadas_este_turno = 0;
            obj_controlador.terrenos_jogados_este_turno = 0;
            expirar_condicoes("jogador");
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
function ativar_hemodrenario_ao_morrer(_tropa_morta) {
    var _dono_beneficiado = (_tropa_morta.dono == "jogador") ? "inimigo" : "jogador";
    with (obj_construcao) {
        if (nome_construcao != "Hemodrenário" || dono != _dono_beneficiado || lane_atual != _tropa_morta.lane_atual) continue;

        // Este recurso é gerado por efeito; não consome a colocação normal do turno.
        var _ja_colocou = (dono == "jogador") ? obj_controlador.recurso_colocado_no_turno : obj_controlador.recurso_colocado_no_turno_inimigo;
        if (dono == "jogador") obj_controlador.recurso_colocado_no_turno = false;
        else obj_controlador.recurso_colocado_no_turno_inimigo = false;
        var _resultado = colocar_recurso("sangue", dono, x, y);
        if (dono == "jogador") obj_controlador.recurso_colocado_no_turno = _ja_colocou;
        else obj_controlador.recurso_colocado_no_turno_inimigo = _ja_colocou;

        if (_resultado == "colocado") debug_combate("HEMODRENÁRIO gerou 1 Sangue após a morte de " + _tropa_morta.nome_carta + ".");
    }
}

function ia_escolher_indice_tropa() {
    var _melhor_indice = -1;
    var _melhor_valor = -999999;

    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _dados = obj_controlador.mao_inimigo[i]();
        if (_dados.categoria != "tropa" || !pode_pagar_custo(_dados.custo, "inimigo")) continue;

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
            if (_alvo.vida <= _dano_medio) _pontuacao += 100; // prioriza eliminação provável
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
    var _melhor_alvo = noone;
    var _melhor_pontuacao = -999999;

    with (obj_carta) {
        if (!travada || dono != "jogador" || sombra_ativa) continue;
        var _pontuacao = ia_pontuacao_alvo_magia(_dados, id);

        if (_pontuacao > _melhor_pontuacao) {
            _melhor_pontuacao = _pontuacao;
            _melhor_alvo = id;
        }
    }
    return _melhor_alvo;
}

// Usa no máximo uma magia por turno, sempre no alvo de maior valor tático.
function ia_jogar_magias() {
    if (obj_controlador.primeiro_turno_inimigo) return;

    var _melhor_indice = -1;
    var _melhor_alvo = noone;
    var _melhor_pontuacao = -999999;

    for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
        var _dados = obj_controlador.mao_inimigo[i]();
        if (_dados.categoria != "magica" || !pode_pagar_custo(_dados.custo, "inimigo")) continue;

        var _alvo = ia_escolher_alvo_magia(_dados);
        if (_alvo == noone) continue;

        var _pontuacao = ia_pontuacao_alvo_magia(_dados, _alvo);
        if (_pontuacao > _melhor_pontuacao) {
            _melhor_pontuacao = _pontuacao;
            _melhor_indice = i;
            _melhor_alvo = _alvo;
        }
    }

    if (_melhor_indice == -1 || !instance_exists(_melhor_alvo)) return;

    var _magia = obj_controlador.mao_inimigo[_melhor_indice]();
    pagar_custo(_magia.custo, "inimigo");
    array_delete(obj_controlador.mao_inimigo, _melhor_indice, 1);

    switch (_magia.nome) {
        case "Bola de Fogo": lancar_bola_de_fogo(_melhor_alvo, _magia.dado_efeito, _magia.chance_queimar); break;
        case "Veneno Mortal": aplicar_condicao(_melhor_alvo, "envenenado", -1, 1); break;
        case "Congelante": aplicar_condicao(_melhor_alvo, "congelado", 1, 0); break;
        case "Choque Elétrico": aplicar_condicao(_melhor_alvo, "eletrocutado", 1, 0); break;
    }

    debug_combate("IA usou " + _magia.nome + " em " + _melhor_alvo.nome_carta + ".");
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

// Habilidades são usadas apenas quando têm impacto imediato ou proteção concreta.
function ia_usar_habilidades_tropas() {
    if (obj_controlador.primeiro_turno_inimigo) return;

    with (obj_carta) {
        if (!travada || dono != "inimigo" || habilidade_usada_este_turno) continue;

        var _habilidade = tem_habilidade_ativa(id);
        switch (_habilidade) {
            case "golpe_duplo":
                if (!atacou_este_turno && (ia_alvo_atingivel(id) != noone || posicao_atual == posicao_ataque())) {
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
        }
    }
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

        if (posicao == posicao_entrada("inimigo") && !ocupado) {
            if (array_length(obj_controlador.mao_inimigo) > 0) {

                var _indice_mao = _indice_mao_escolhido;
                var _funcao_sorteada = obj_controlador.mao_inimigo[_indice_mao];
                var _dados = _funcao_sorteada();

				if (_dados.categoria == "bencao") {
				    if (adicionar_bencao("inimigo", _dados.efeito)) {
				        array_delete(obj_controlador.mao_inimigo, _indice_mao, 1);
				    }
				    continue;
				}
				if (_dados.categoria == "maldicao") {
				    if (adicionar_maldicao("inimigo", _dados.efeito)) {
				        array_delete(obj_controlador.mao_inimigo, _indice_mao, 1);
				    }
				    continue;
				}
				if (_dados.categoria != "tropa") continue;
				if (!pode_pagar_custo(_dados.custo, "inimigo")) continue;

                pagar_custo(_dados.custo, "inimigo");
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

    var _dados_escolhidos = obj_controlador.mao_inimigo[_melhor_indice_mao]();
    // Recurso vem da área oculta da mão inimiga, igual antes.
    var _resultado = colocar_recurso(_dados_escolhidos.tipo_recurso, "inimigo", room_width / 2, -global.CARTA_ALTURA);

    if (_resultado == "colocado") {
        array_delete(obj_controlador.mao_inimigo, _melhor_indice_mao, 1);
    }
}

function ia_jogar_construcao() {
    if (random(1) > 0.3) return; // 30% de chance de tentar construir por turno

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
        var _dados = obj_controlador.mao_inimigo[_indice_mao]();

        if (!pode_pagar_custo(_dados.custo, "inimigo")) continue;

        pagar_custo(_dados.custo, "inimigo");
        array_delete(obj_controlador.mao_inimigo, _indice_mao, 1);

        var _construcao = instance_create_layer(_slot_livre.x, _slot_livre.y, "Instances", obj_construcao);
        _construcao.nome_construcao = _dados.nome;
        _construcao.vida = _dados.vida;
        _construcao.vida_maxima = _dados.vida;
        _construcao.dono = "inimigo";
        _construcao.lane_atual = _slot_livre.lane;
        _construcao.slot_atual = _slot_livre;
        _construcao.tem_habilidade_construcao = (_dados.nome == "Hemodrenário");

        _slot_livre.ocupado = true;
        _slot_livre.construcao_atual = _construcao.id;
        break; // já construiu, para de tentar
    }
}
	
function ia_usar_construcoes() {
    with (obj_construcao) {
        if (dono == "inimigo" && tem_habilidade_construcao && !habilidade_usada_este_turno) {
            if (random(1) < 0.6) { // 60% de chance de usar quando disponível
                usar_habilidade_hemodrenario(id);
            }
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

// Feedback visual reutilizável para ações negadas por regra ou recurso insuficiente.
function mostrar_aviso_regra(_texto, _x = mouse_x, _y = mouse_y) {
    var _aviso = instance_create_layer(_x, _y - 24, "Instances", obj_texto_flutuante);
    _aviso.texto = _texto;
    _aviso.cor_texto = make_color_rgb(255, 210, 70);
    _aviso.vida_texto_max = 75;
    _aviso.velocidade_subida = 0.55;
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

        if (_disponiveis < _item.quantidade) {
            if (_dono == "jogador") {
                var _faltam = _item.quantidade - _disponiveis;
                mostrar_aviso_regra("Falta " + string(_faltam) + " " + nome_recurso_exibicao(_item.tipo, _faltam));
            }
            return false;
        }
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
        _carta.condicao = noone; // Loucura substitui o estado temporário do último choque.
        aplicar_condicao(_carta, "loucura", -1, 0);
        debug_combate(_carta.nome_carta + " levou choque demais e ganhou LOUCURA!");
        _carta.vezes_eletrocutado_seguidas = 0;
    }
}

function processar_loucura(_carta) {
    _carta.loucura_sem_defesa = false;
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
            if (_carta.dono == "jogador") obj_controlador.vida_jogador -= _carta.dado_dano;
            else obj_controlador.vida_inimigo -= _carta.dado_dano;
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

// Apodrecer: duração sorteada por D4 ao aplicar. O DANO de cada turno é resorteado (D4) a cada turno.
function aplicar_apodrecer(_carta) {
    var _turnos = irandom_range(1, 4);
    aplicar_condicao(_carta, "apodrecer", _turnos, irandom_range(1, 4));
}

// Regeneração: mesma lógica do Apodrecer, mas curando em vez de causar dano.
function aplicar_regeneracao(_carta) {
    var _turnos = irandom_range(1, 4);
    aplicar_condicao(_carta, "regeneracao", _turnos, irandom_range(1, 4));
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

        if (condicao == "loucura") {
            processar_loucura(id);
            continue;
        }

        // apodrecer/regeneração: o valor deste turno é resorteado (D4) toda vez
        if (condicao == "apodrecer" || condicao == "regeneracao") {
            condicao_dano_por_turno = irandom_range(1, 4);
        }

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
	
// Dispara a Bola de Fogo de um ponto fixo (meio da tela, embaixo) até o alvo, em arco.
// O dano/queimadura só é aplicado DEPOIS que ela impacta (via callback).
function lancar_bola_de_fogo(_alvo, _dado_efeito, _chance_queimar) {
    if (!instance_exists(_alvo)) return;

    var _origem_x = room_width / 2;
    var _origem_y = obj_controlador.mao_y; // mesma altura da mão do jogador (embaixo)

    var _projetil = instance_create_layer(_origem_x, _origem_y, "Instances", obj_bola_fogo_projetil);
    _projetil.origem_x = _origem_x;
    _projetil.origem_y = _origem_y;
    _projetil.destino_x = _alvo.x;
    _projetil.destino_y = _alvo.y;

    _projetil.som_voo = audio_play_sound(snd_bola_fogo_voo, 1, 0, .5, 0, random_range(.95, 1.05));

    var _dados_impacto = { alvo: _alvo, dado_efeito: _dado_efeito, chance_queimar: _chance_queimar };
    _projetil.callback_impacto = method(_dados_impacto, function() {
        if (!instance_exists(alvo)) return;
        aplicar_efeito_bola_fogo(alvo, dado_efeito, chance_queimar);
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
        return;
    }
    if (!evolucoes_disponiveis(_carta.dono)) {
        debug_combate("Já evoluiu uma tropa esse turno.");
        if (_carta.dono == "jogador") mostrar_aviso_regra("Limite de 1 evolução por turno", _carta.x, _carta.y);
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
    }

    if (!_carta.moveu_este_turno) array_push(_opcoes, "Mover");
    if (_carta.dono == "jogador" && _carta.travada && _carta.posicao_atual == posicao_entrada("jogador")) {
        array_push(_opcoes, _carta.defendendo_castelo ? "Parar de Defender" : "Defender Castelo");
    }
    if (tem_habilidade_ativa(_carta) != noone && !_carta.habilidade_usada_este_turno) array_push(_opcoes, "Habilidade");
    if (_carta.funcao_evolucao != noone && _carta.turnos_no_campo >= 1 && evolucoes_disponiveis(_carta.dono)) {
        array_push(_opcoes, "Evoluir");
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
    switch (_opcao) {
        case "Atacar":
            var _tipo = (_carta.dado_dano_magico > 0 && _carta.dado_dano == 0) ? "magica" : "fisica";
            processar_combate_tropa(_carta, _tipo);
            _carta.atacou_este_turno = true;
            break;
        case "Atacar (Física)":
            processar_combate_tropa(_carta, "fisica");
            _carta.atacou_este_turno = true;
            break;
        case "Atacar (Mágica)":
            processar_combate_tropa(_carta, "magica");
            _carta.atacou_este_turno = true;
            break;
        case "Mover":
            var _resultado = mover_tropa(_carta, 1);
            if (_resultado == "movido") {
                _carta.moveu_este_turno = true;
            }
            break;
        case "Defender Castelo":
            _carta.defendendo_castelo = true;
            debug_combate(_carta.nome_carta + " está defendendo o castelo.");
            break;
        case "Parar de Defender":
            _carta.defendendo_castelo = false;
            debug_combate(_carta.nome_carta + " deixou de defender o castelo.");
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

    var _tipo = (_carta.dado_dano_magico > 0 && _carta.dado_dano == 0) ? "magica" : "fisica";
    processar_combate_tropa(_carta, _tipo);
    processar_combate_tropa(_carta, _tipo);

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
    // A mão do jogador é visível no tabuleiro; sem tela de escolha, destrói a primeira armadilha encontrada.
    var _armadilha_destruida = noone;
    with (obj_carta) {
        if (dono == _lado_oponente && esta_na_mao && categoria == "armadilha") {
            _armadilha_destruida = id;
            break;
        }
    }
    if (_armadilha_destruida != noone) {
        var _indice_armadilha = array_get_index(obj_controlador.mao, _armadilha_destruida);
        if (_indice_armadilha != -1) {
            array_delete(obj_controlador.mao, _indice_armadilha, 1);
            organizar_mao();
        }
        instance_destroy(_armadilha_destruida);
        debug_combate("VISÃO DO VÉU destruiu uma armadilha da mão inimiga.");
    } else if (_lado_oponente == "inimigo") {
        // A mão da IA é guardada como dados, não como instâncias visíveis.
        for (var i = 0; i < array_length(obj_controlador.mao_inimigo); i++) {
            if (obj_controlador.mao_inimigo[i]().categoria == "armadilha") {
                array_delete(obj_controlador.mao_inimigo, i, 1);
                debug_combate("VISÃO DO VÉU destruiu uma armadilha da mão inimiga.");
                break;
            }
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

#region Habilidades especiais das construções
function usar_habilidade_hemodrenario(_construcao) {
    // O efeito é automático e é processado em ativar_hemodrenario_ao_morrer().
    debug_combate("Hemodrenário aguarda uma tropa inimiga morrer em sua fileira.");
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
function tocar_musica(_musica) {
    audio_stop_all();

    if (!audio_is_playing(_musica)) {
        audio_play_sound(_musica, 0, true);
    }
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
