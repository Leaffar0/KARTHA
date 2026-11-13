// =============================================================================
// KARTHA — cartas
// Dados, baralhos, mão, recursos, magias, evolução e equipamentos.
// =============================================================================

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
        dado_dano: 0,
        mod_dano: 0,
        dado_dano_magico: 12,
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
    return { categoria: "recurso", nome: "Sangue", tipo_recurso: "sangue", valor_recurso: 1, sprite_carta: spr_recurso_sangue };
}

function criar_dados_recurso_ossos() {
    return { categoria: "recurso", nome: "Ossos", tipo_recurso: "ossos", valor_recurso: 1, sprite_carta: spr_recurso_ossos };
}

function criar_dados_recurso_sucata() {
    return { categoria: "recurso", nome: "Sucata", tipo_recurso: "sucata", valor_recurso: 1, sprite_carta: spr_recurso_sucata };
}

function criar_dados_recurso_mana() {
    return { categoria: "recurso", nome: "Mana", tipo_recurso: "mana", valor_recurso: 1, sprite_carta: spr_recurso_mana };
}

// Use esta fábrica para recursos futuros que gerem 2 ou mais unidades.
function criar_dados_recurso_especial(_nome, _tipo, _valor, _sprite) {
    return { categoria: "recurso", nome: _nome, tipo_recurso: _tipo,
        valor_recurso: max(1, floor(_valor)), sprite_carta: _sprite };
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
        custo: noone,
        bonus_mod_dano: 2,
        bonus_defesa: 0
    };
}

function criar_dados_item_escudo() {
    return {
        categoria: "item_equipavel",
        nome: "Escudo de Madeira",
        sprite_carta: spr_carta_escudo_madeira,
        custo: noone,
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
        custo: noone,
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

    revelar_armadilha_posicionada(_carta_armadilha);
    _carta_armadilha.armadilha_estado = "resolvendo";
    _carta_armadilha.visible = false;
    var _index_mao = array_get_index(obj_controlador.mao, _carta_armadilha.id);
    if (_index_mao != -1) {
        array_delete(obj_controlador.mao, _index_mao, 1);
        organizar_mao();
    }

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

        criar_flash(alvo.x, alvo.y, 32);
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
        var _atraso_dado = 8 + ((i == 0) ? 0 : i * irandom_range(26, 42));
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
    revelar_armadilha_posicionada(_armadilha);
    apresentacao_enfileirar(evento_feedback_criar("RAÍZES: MOVIMENTO CANCELADO",
        _tropa.x, _tropa.y - 42, c_lime, 70), 8);
    aplicar_condicao(_tropa, "envenenado", -1, 1, true, 8);
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
    revelar_armadilha_posicionada(_armadilha);
    aplicar_condicao(_alvo, "loucura", -1, 0, false, 8);
    apresentacao_enfileirar(evento_feedback_criar("LOUCURA MÚTUA", _alvo.x, _alvo.y - 42, c_purple, 70), 8);
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
    revelar_armadilha_posicionada(_armadilha);
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
    if (array_length(lista_bencaos(_dono)) + array_length(lista_maldicoes(_dono)) >= obj_controlador.max_bencaos_maldicoes) return false;
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
    if (array_length(lista_bencaos(_dono)) + array_length(lista_maldicoes(_dono)) >= obj_controlador.max_bencaos_maldicoes) return false;
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
    var _bonus_berserker = (tem_condicao(_carta, "berserker")) ? 4 : 0;
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
    if (!obj_controlador.ui_modal.dados_manipulados_escolha_ativa || !is_struct(obj_controlador.ui_modal.dados_manipulados_escolha_atual)) return;
    var _escolha = obj_controlador.ui_modal.dados_manipulados_escolha_atual;
    var _valor = _usar_alternativo ? _escolha.alternativo : _escolha.original;
    obj_controlador.ui_modal.dados_manipulados_escolha_ativa = false;
    obj_controlador.ui_modal.dados_manipulados_escolha_atual = noone;
    if (variable_struct_exists(_escolha, "online") && _escolha.online) {
        if (online_ativo()) colyseus_send(global.net_room, "choose_manipulated_roll", { useAlternative: _usar_alternativo });
        return;
    }
    if (variable_struct_exists(_escolha, "callback") && _escolha.callback != noone) _escolha.callback(_valor);
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
function executar_efeitos_declarativos(_efeitos, _alvo, _dono, _origem = noone) {
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
                    var _vida_antes_cura = _alvo.vida;
                    _alvo.vida = min(_alvo.vida_maxima, _alvo.vida + _efeito.valor); _executou = true;
                    debug_combate(_alvo.nome_carta + " recuperou " + string(_alvo.vida - _vida_antes_cura) + " de vida.");
                }
                break;
            case "comprar":
                var _qtd = variable_struct_exists(_efeito, "quantidade") ? _efeito.quantidade : 1;
                comprar_varias_cartas(_qtd, _dono); _executou = true;
                break;
            case "recurso":
                if (variable_struct_exists(_efeito, "chave")) {
                    var _valor_recurso_efeito = variable_struct_exists(_efeito, "quantidade") ? _efeito.quantidade : 1;
                    _executou = (colocar_recurso(_efeito.chave, _dono, noone, noone, noone, _valor_recurso_efeito) == "colocado") || _executou;
                }
                break;
            case "vida_maxima":
                if (instance_exists(_alvo) && variable_struct_exists(_efeito, "valor")) {
                    _alvo.vida_maxima = max(1, _alvo.vida_maxima + _efeito.valor);
                    _executou = true;
                }
                break;
            case "destruir":
                if (instance_exists(_alvo)) {
                    var _limite = variable_struct_exists(_efeito, "limite_vida") ? _efeito.limite_vida : 999999;
                    if (_alvo.vida <= _limite) { destruir_tropa(_alvo); _executou = true; }
                }
                break;
        }
    }
    if (_executou) ligar_efeito_alvo(_origem,_alvo,c_aqua);
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
function comprar_carta_do_deck(_x_inicial, _y_inicial, _dono = "jogador") {
    var _monte_compra = (_dono == "jogador") ? obj_controlador.monte : obj_controlador.monte_inimigo;
    if (array_length(_monte_compra) == 0) {
        debug_combate("Monte de " + nome_jogador_lado(_dono) + " vazio! Sem cartas pra comprar.");
        return noone;
    }

    var _funcao_sorteada = _monte_compra[0];
    array_delete(_monte_compra, 0, 1);
    return comprar_carta_do_deck_por_funcao(_funcao_sorteada, _x_inicial, _y_inicial, _dono);
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
        if (_dono == "jogador" || partida_local_ativa()) mostrar_aviso_regra("Não há mais " + nome_recurso_exibicao(_tipo_recurso, 1) + " no baralho");
        return false;
    }

    array_delete(_monte, _indice, 1);

    if (_dono == "jogador" || partida_local_ativa()) {
        comprar_carta_do_deck_por_funcao(_funcao_alvo, obj_deck.x, obj_deck.y, _dono);
    } else {
        array_push(obj_controlador.mao_inimigo, _funcao_alvo);
    }

    embaralhar_array(_monte);
    return true;
}

// Mesma lógica de sempre, mas recebe a função da carta já escolhida
// (compra normal E efeitos de busca tipo Sangue Suga usam essa mesma função).
function comprar_carta_do_deck_por_funcao(_funcao_sorteada, _x_inicial, _y_inicial, _dono = "jogador") {
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
    _carta.alvo_declarativo = variable_struct_exists(_dados, "alvo") ? _dados.alvo : "inimigo";
    _carta.tags = variable_struct_exists(_dados, "tags") ? _dados.tags : [];
    _carta.sinergias = variable_struct_exists(_dados, "sinergias") ? _dados.sinergias : [];

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
        _carta.defesa_magica_base = _carta.defesa_magica;

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
        _carta.valor_recurso = variable_struct_exists(_dados, "valor_recurso") ? max(1, _dados.valor_recurso) : 1;

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

    _carta.dono = _dono;
    _carta.esta_na_mao = true;
    _carta.compra_animando = true;
    _carta.compra_progresso = 0;
    _carta.compra_origem_x = _x_inicial;
    _carta.compra_origem_y = _y_inicial;
    _carta.depth = -5000;

    var _destino_mao_oculta = partida_local_ativa()
        && ((_dono == "jogador" && obj_controlador.turno == "inimigo")
        || (_dono == "inimigo" && obj_controlador.turno != "inimigo"));
    if (_destino_mao_oculta) {
        array_push(obj_controlador.mao_oculta, _carta);
    } else {
        array_push(obj_controlador.mao, _carta);
        organizar_mao();
    }

    _carta.x = _x_inicial;
    _carta.y = _y_inicial;
    if (obj_controlador.mao_inicial_comprada) {
        mostrar_feedback("+ CARTA", _x_inicial, _y_inicial,
            (_dono == "jogador") ? c_aqua : c_red, 32);
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
            if (partida_local_ativa()) comprar_carta_do_deck(obj_deck.x, obj_deck.y, "inimigo");
            else comprar_carta_do_deck_ia();
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

function comprar_mao_inicial_segundo_jogador() {
    if (obj_controlador.mao_inimigo_inicial_comprada) return;

    for (var i = 0; i < obj_controlador.quantidade_inicial; i++) {
        if (array_length(obj_controlador.monte_inimigo) == 0) break;
        var _carta = comprar_carta_do_deck(obj_deck.x, obj_deck.y, "inimigo");
        if (instance_exists(_carta)) _carta.compra_atraso = i * 7;
    }
    obj_controlador.mao_inimigo_inicial_comprada = true;
}

#region Mão — leque, arco e scroll horizontal
function organizar_mao() {
    // Referências de instâncias destruídas nunca devem chegar ao cálculo do leque.
    var _mao_limpa = [];
    for (var _limpar = 0; _limpar < array_length(obj_controlador.mao); _limpar++) {
        var _candidata = obj_controlador.mao[_limpar];
        if (instance_exists(_candidata)) array_push(_mao_limpa, _candidata);
    }
    obj_controlador.mao = _mao_limpa;
    var _mao = obj_controlador.mao;
    var _total = array_length(_mao);
    var _espaco = obj_controlador.espaco_entre_cartas * global.escala_interface;
    var _centro_x = obj_controlador.mao_x_centro;
    var _y = obj_controlador.mao_y;

    var _largura_total = (_total - 1) * _espaco;
    var _x_inicial = _centro_x - (_largura_total / 2);

    var _angulo_maximo = 10;
    var _altura_arco = 20 * global.escala_interface;

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
    obj_controlador.mao_scroll_offset = clamp(obj_controlador.mao_scroll_offset, -obj_controlador.mao_scroll_max, obj_controlador.mao_scroll_max);
}

function mouse_na_faixa_da_mao(_mouse_y) {
    return _mouse_y >= obj_controlador.mao_y - global.CARTA_ALTURA * 0.55 * global.escala_interface;
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
        _carta.depth = -12000;
    }
    return _novo_indice != _indice_antigo;
}
#endregion

#region Recursos — colocar, pagar custo, desvirar
function colocar_recurso(_tipo, _dono, _origem_x = noone, _origem_y = noone, _slot_preferido = noone, _valor = 1, _funcao_origem = noone) {
    var _ja_colocou = (_dono == "jogador") ? obj_controlador.recurso_colocado_no_turno : obj_controlador.recurso_colocado_no_turno_inimigo;
	if (_ja_colocou) {
        if (_dono == "jogador") mostrar_aviso_regra("Você já colocou 1 recurso neste turno", _origem_x, _origem_y);
        return "ja_colocou_no_turno";
    }
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
    _recurso.quantidade = max(1, floor(_valor));
    _recurso.funcao_origem = _funcao_origem;
    _recurso.virado = false;
    _recurso.dono = _dono;
    _recurso.destino_x = _slot_livre.x;
    _recurso.destino_y = _slot_livre.y;
    _recurso.entrada_origem_x = _x_criacao;
    _recurso.entrada_origem_y = _y_criacao;
    _recurso.entrando_no_campo = (_origem_x != noone && _origem_y != noone);
    _recurso.entrada_progresso = 0;
    if (!_recurso.entrando_no_campo) tocar_som_variado("recurso", 0.30);
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
        mostrar_feedback("+ " + string(_recurso.quantidade) + " " + string_upper(nome_recurso_exibicao(_tipo, _recurso.quantidade)), _slot_livre.x, _slot_livre.y, c_lime, 45);
    } else {
        array_push(obj_controlador.recursos_inimigo, _recurso);
        obj_controlador.recurso_colocado_no_turno_inimigo = true;
    }

    debug_combate("" + string_upper(string_copy(_dono, 1, 1)) + string_delete(_dono, 1, 1) + " colocou " + string(_recurso.quantidade) + " " + nome_recurso_exibicao(_tipo, _recurso.quantidade) + ".");
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
    if (obj_controlador.modo_partida == "online") {
        if (!lado_controlado_localmente(_recurso.dono)) return false;
        online_enviar_acao("remove_resource", { resourceId: _recurso.online_instance_id, resourceType: _recurso.tipo });
        return true;
    }
    var _ja_retirou = (_recurso.dono == "jogador") ? obj_controlador.recurso_retirado_no_turno : obj_controlador.recurso_retirado_no_turno_inimigo;
    if (_ja_retirou) { if (_recurso.dono == "jogador") mostrar_aviso_regra("Você já retirou 1 recurso neste turno", _recurso.x, _recurso.y); return false; }
    var _lista = (_recurso.dono == "jogador") ? obj_controlador.recursos_jogador : obj_controlador.recursos_inimigo;
    var _indice = array_get_index(_lista, _recurso); if (_indice >= 0) array_delete(_lista, _indice, 1);
    if (_recurso.slot_atual != noone) { _recurso.slot_atual.ocupado = false; _recurso.slot_atual.recurso_atual = noone; }
    if (_recurso.dono == "jogador") {
        obj_controlador.recurso_retirado_no_turno = true;
        var _funcao = (_recurso.funcao_origem != noone) ? _recurso.funcao_origem : funcao_recurso_por_tipo(_recurso.tipo);
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
    debug_combate("Ação recusada: " + _texto);
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

function criar_animacao_item(_sprite, _origem_x, _origem_y, _destino_x, _destino_y, _cor = c_aqua,
    _tropa = noone, _equipamento = noone, _indice_online = -1, _definicao_online = "") {
    var _controle = instance_find(obj_controlador, 0);
    if (_controle == noone) return;
    if (!sprite_exists(_sprite)) _sprite = spr_carta_placeholder;
    if (is_struct(_equipamento)) _equipamento.visual_em_voo = true;
    if (instance_exists(_tropa)) tocar_som_variado("deslize", 0.38, 1);
    array_push(_controle.animacoes_item, { tipo: "item", sprite: _sprite,
        origem_x: _origem_x, origem_y: _origem_y, destino_x: _destino_x, destino_y: _destino_y,
        timer: 0, duracao: 32, cor: _cor, tropa: _tropa, equipamento: _equipamento,
        indice_online: _indice_online, definicao_online: _definicao_online });
}

function equipamento_online_em_voo(_tropa, _item, _indice) {
    if (!variable_struct_exists(_item, "online_definition_id")) return false;
    var _animacoes = obj_controlador.animacoes_item;
    for (var i = 0; i < array_length(_animacoes); i++) {
        var _anim = _animacoes[i];
        if (_anim.tipo == "item" && _anim.tropa == _tropa && _anim.indice_online == _indice
            && _anim.definicao_online == _item.online_definition_id) return true;
    }
    return false;
}

function revelar_armadilha_visual(_sprite, _x, _y) {
    if (!instance_exists(obj_controlador)) return;
    if (!sprite_exists(_sprite)) _sprite = spr_carta_placeholder;
    array_push(obj_controlador.animacoes_item, { tipo: "armadilha", sprite: _sprite,
        destino_x: _x, destino_y: _y, timer: 0, duracao: 17, tropa: noone, equipamento: noone });
}

function revelar_armadilha_posicionada(_armadilha) {
    var _slot = buscar_slot(_armadilha.armadilha_lane, _armadilha.armadilha_posicao);
    if (_slot == noone) return;
    if (instance_exists(_armadilha.armadilha_visual_id)) _armadilha.armadilha_visual_id.visible = false;
    revelar_armadilha_visual(_armadilha.sprite_index, _slot.x, _slot.y);
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
        if (!virado && dono == _dono && bloqueado_turnos <= 0)
            array_push(_disponiveis, { recurso: id, restante: max(1, quantidade) });
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
                var _entrada_recurso = _disponiveis[j];
                var _recurso = _entrada_recurso.recurso;
                if (!instance_exists(_recurso) || _entrada_recurso.restante <= 0) continue;
                if (_eh_neutro || _recurso.tipo == _item.tipo) {
                    var _usar = min(_entrada_recurso.restante, _item.quantidade - _pagos);
                    _entrada_recurso.restante -= _usar;
                    _pagos += _usar;
                    if (array_get_index(_selecionados, _recurso) < 0) array_push(_selecionados, _recurso);
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
    if (!_selecao.sucesso && (_dono == "jogador" || partida_local_ativa())) {
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
        var _recurso = _selecao.recursos[i];
        if (!instance_exists(_recurso)) continue;
        _recurso.atraso_virada_visual = min(i * 3, 15);
        _recurso.virado = true;
    }
    return true;
}

// desvira todos os recursos de um lado (chamado no início do turno dele)
function desvirar_recursos(_dono) {
    var _desvirou = false;
    with (obj_recurso) {
        if (dono == _dono) {
            _desvirou = _desvirou || virado;
            virado = false;
            if (bloqueado_turnos > 0) {
                if (bloqueio_acabou_de_aplicar) bloqueio_acabou_de_aplicar = false;
                else bloqueado_turnos = max(0, bloqueado_turnos - 1);
            }
        }
    }
    if (_desvirou) audio_play_sound(snd_shuffle, 1, false, 0.15, 0, 1.18);
    if (_dono == "jogador") {
        obj_controlador.recurso_colocado_no_turno = false;
        obj_controlador.recurso_retirado_no_turno = false;
    } else {
        obj_controlador.recurso_colocado_no_turno_inimigo = false;
        obj_controlador.recurso_retirado_no_turno_inimigo = false;
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

#region Evolução - Controlar turnos para evolução

function evoluir_tropa(_carta) {
    if (_carta.funcao_evolucao == noone) return;
    if (tem_condicao(_carta, "adormecido") || tem_condicao(_carta, "loucura")) {
        if (_carta.dono == "jogador") mostrar_aviso_regra("Esta condição impede evoluir", _carta.x, _carta.y);
        return;
    }
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
    
    _carta.evolucao_sprite_anterior = _carta.sprite_index;
    _carta.nome_carta = _dados_evo.nome;
    _carta.tags = variable_struct_exists(_dados_evo, "tags") ? _dados_evo.tags : [];
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
        _carta.defesa_magica_base = _carta.defesa_magica;
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
function mandar_para_abismo(_nome_carta, _dono = "") {
    array_push(obj_controlador.abismo, _nome_carta);
    if (_dono == "jogador") array_push(obj_controlador.abismo_jogador, _nome_carta);
    else if (_dono == "inimigo") array_push(obj_controlador.abismo_inimigo, _nome_carta);
    debug_combate(_nome_carta + " foi engolida pelo ABISMO. Nunca mais volta.");
}

function esta_no_abismo(_nome_carta) {
    return array_get_index(obj_controlador.abismo, _nome_carta) != -1;
}
#endregion

// Equipamentos permanecem ligados à tropa para que cartas futuras possam removê-los,
// transferi-los ou roubá-los sem perder a origem nem acumular bônus incorretos.
function criar_dados_item_equipado(_nome, _sprite, _funcao, _bonus_dano, _bonus_defesa, _dado, _mod, _efeito_item = "", _sinergias = []) {
    return { nome: _nome, sprite: _sprite, funcao: _funcao, bonus_dano: _bonus_dano,
        bonus_defesa: _bonus_defesa, dado: _dado, modificador: _mod,
        efeito_item: _efeito_item, sinergias: _sinergias };
}

// Tags explícitas são preferidas; a busca no nome mantém as convenções do livro.
function carta_tem_tag(_carta, _tag) {
    if (!instance_exists(_carta)) return false;
    var _procurada = string_lower(_tag);
    if (array_get_index(_carta.tags, _procurada) >= 0 || array_get_index(_carta.tags, _tag) >= 0) return true;
    return string_pos(_procurada, string_lower(_carta.nome_carta)) > 0;
}

function bonus_sinergia_item(_item, _tropa, _campo) {
    if (!is_struct(_item) || !variable_struct_exists(_item, "sinergias") || !is_array(_item.sinergias)) return 0;
    var _total = 0;
    for (var _si = 0; _si < array_length(_item.sinergias); _si++) {
        var _sinergia = _item.sinergias[_si];
        if (!is_struct(_sinergia) || !variable_struct_exists(_sinergia, "tag")
            || !carta_tem_tag(_tropa, _sinergia.tag) || !variable_struct_exists(_sinergia, _campo)) continue;
        _total += variable_struct_get(_sinergia, _campo);
    }
    return _total;
}

function modificador_item_ataque(_tropa, _item) {
    return _item.modificador + bonus_sinergia_item(_item, _tropa, "bonus_dano");
}

function recalcular_itens_tropa(_tropa) {
    if (!instance_exists(_tropa)) return;
    _tropa.dado_dano = _tropa.dado_dano_base;
    _tropa.mod_dano = _tropa.mod_dano_base;
    _tropa.defesa_fisica = _tropa.defesa_fisica_base;
    _tropa.item_ataque_atual = noone;
    for (var i = 0; i < array_length(_tropa.itens_equipados); i++) {
        var _item = _tropa.itens_equipados[i];
        _tropa.defesa_fisica += _item.bonus_defesa + bonus_sinergia_item(_item, _tropa, "bonus_defesa");
        if (_item.dado <= 0)
            _tropa.mod_dano += _item.bonus_dano + bonus_sinergia_item(_item, _tropa, "bonus_dano");
    }
    _tropa.mochila = max(0, _tropa.mochila_maxima - array_length(_tropa.itens_equipados));
}

function melhor_item_ataque(_tropa) {
    var _melhor = noone;
    var _media = _tropa.qtd_dados_dano * ((_tropa.dado_dano + 1) / 2) + _tropa.mod_dano;
    for (var i = 0; i < array_length(_tropa.itens_equipados); i++) {
        var _item = _tropa.itens_equipados[i];
        var _bonus_sinergia = bonus_sinergia_item(_item, _tropa, "bonus_dano");
        if (_item.dado > 0 && ((_item.dado + 1) / 2 + _item.modificador + _bonus_sinergia) > _media) {
            _media = (_item.dado + 1) / 2 + _item.modificador + _bonus_sinergia;
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

// Retorna o motivo que já bloqueia a colocação de equipamentos da mão.
function motivo_recusa_equipamento(_tropa, _inteligencia_necessaria) {
    if (tem_condicao(_tropa, "adormecido") || tem_condicao(_tropa, "loucura"))
        return "Esta condição impede equipar itens";
    if (_tropa.troca_item_usada_este_turno)
        return "Esta tropa já usou sua ação de item neste turno";
    if (_tropa.mochila <= 0) return "A mochila desta tropa está cheia";
    if (_tropa.nivel_inteligencia < _inteligencia_necessaria)
        return "Este item exige inteligência " + string(_inteligencia_necessaria)
            + "; a tropa possui " + string(_tropa.nivel_inteligencia);
    return "";
}

function remover_item_equipado(_tropa, _indice, _voltar_mao = true) {
    if (!instance_exists(_tropa) || _indice < 0 || _indice >= array_length(_tropa.itens_equipados)) return noone;
    if (_voltar_mao && (_tropa.troca_item_usada_este_turno || troca_item_do_lado_usada(_tropa.dono))) return noone;
    var _item = _tropa.itens_equipados[_indice];
    if (_voltar_mao && _item.funcao == noone) return noone;
    array_delete(_tropa.itens_equipados, _indice, 1);
    recalcular_itens_tropa(_tropa);
    if (_voltar_mao) {
        comprar_carta_do_deck_por_funcao(_item.funcao, _tropa.x, _tropa.y, _tropa.dono);
        _tropa.troca_item_usada_este_turno = true;
        variable_struct_set(obj_controlador.troca_item_usada_por_lado, _tropa.dono, true);
    }
    return _item;
}

function transferir_item_equipado(_origem, _destino, _indice) {
    if (!instance_exists(_origem) || !instance_exists(_destino) || _destino.mochila <= 0) return false;
    if (_origem == _destino || _origem.dono != _destino.dono
        || _origem.troca_item_usada_este_turno || _destino.troca_item_usada_este_turno
        || troca_item_do_lado_usada(_origem.dono)) return false;
    var _item = remover_item_equipado(_origem, _indice, false);
    if (!is_struct(_item)) return false;
    equipar_item_dados(_destino, _item);
    criar_animacao_item(_item.sprite, _origem.x, _origem.y, _destino.x, _destino.y, c_aqua, _destino, _item);
    _origem.troca_item_usada_este_turno = true;
    _destino.troca_item_usada_este_turno = true;
    variable_struct_set(obj_controlador.troca_item_usada_por_lado, _origem.dono, true);
    mostrar_feedback("ITEM TRANSFERIDO", _destino.x, _destino.y - 45, c_aqua, 45);
    return true;
}

function troca_item_do_lado_usada(_dono) {
    return variable_struct_get(obj_controlador.troca_item_usada_por_lado, _dono);
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
        criar_animacao_item(_roubado.sprite, vitima.x, vitima.y, ladrao.x, ladrao.y, c_yellow, ladrao, _roubado);
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
    if (!tropa_pode_usar_habilidade(_tropa)) {
        if (_tropa.dono == "jogador") mostrar_aviso_regra("Esta condição impede usar o Grimório", _tropa.x, _tropa.y);
        return false;
    }
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


// A animação pertence à carta equipada e usa a mesma posição final da pilha.
function animacao_equipamento_ativo(_tropa, _item, _indice) {
    var _animacoes = obj_controlador.animacoes_item;
    for (var i = 0; i < array_length(_animacoes); i++) {
        var _anim = _animacoes[i];
        if (_anim.tipo != "item" || _anim.tropa != _tropa) continue;
        if (is_struct(_anim.equipamento) && _anim.equipamento == _item) return _anim;
        if (variable_struct_exists(_item, "online_definition_id")
            && _anim.indice_online == _indice && _anim.definicao_online == _item.online_definition_id) return _anim;
    }
    return noone;
}
