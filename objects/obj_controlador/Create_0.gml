// =============================================================================
// obj_controlador — Create Event
// Configuração inicial do jogo: tamanhos padrão, baralho, deck, estado de turno.
// =============================================================================

#region Configuração global (tamanhos e debug)
global.CARTA_LARGURA = 80;
global.CARTA_ALTURA = 107;
global.RECURSO_LARGURA = 50;
global.MOEDA_LARGURA = 50;

// true = mostra no console cada rolagem de dado/moeda e resultado de combate.
// Mude pra false quando quiser jogar sem poluir o console.
global.DEBUG_COMBATE = true;

randomize(); // garante que os números aleatórios mudam a cada execução do jogo
#endregion

#region Baralho e deck
baralho = [
    criar_dados_esquilo, criar_dados_lobo, criar_dados_urso,
    criar_dados_recurso_sangue, criar_dados_recurso_ossos, criar_dados_recurso_sucata, criar_dados_recurso_mana,
    criar_dados_construcao_torre,
    criar_dados_magica_bola_fogo, criar_dados_magica_veneno, criar_dados_magica_gelo, criar_dados_magica_choque,
    criar_dados_item_espada, criar_dados_item_escudo, criar_dados_item_pocao,
    criar_dados_armadilha_urso,
    criar_dados_terreno_pantano
];

monte = montar_deck();
quantidade_inicial = 3;
#endregion

#region Mão do jogador
mao = [];
mao_x_centro = room_width / 2;
mao_y = room_height - 100;
espaco_entre_cartas = 90;
hover_atual = noone;
carta_preview = noone;

mao_scroll_offset = 0;
mao_scroll_offset_alvo = 0;
mao_scroll_max = 0;
mao_largura_visivel = 400; // ajuste esse valor pro espaço disponível pra mão na sua tela
#endregion

#region Turno e vida
turno = "jogador";
vida_jogador = 20;
vida_inimigo = 20;
cartas_jogadas_no_turno = 0;
max_cartas_por_turno = 1;
#endregion

#region Recursos
recursos_jogador = [];
recursos_inimigo = [];
max_recursos = 6;
recurso_colocado_no_turno = false;      // 1 recurso por turno, por lado
recurso_colocado_no_turno_inimigo = false;
#endregion

#region Terreno (efeito global no campo de batalha)
terreno_bonus_defesa = 0;
#endregion

#region Dados / rolagens visuais
rolagens_pendentes = 0;
rolagens_pendentes_timer = 0; // watchdog: força reset se ficar travado tempo demais (ver Step)
#endregion

#region Menu de ação (clicar na tropa em campo)
carta_menu_aberto = noone;
menu_escala = 0;
opcao_hover_index = -1;
tooltip_escala = 0;
#endregion

depth = -10000; // desenha o menu de ação por cima de absolutamente tudo
