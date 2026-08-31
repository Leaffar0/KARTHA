// =============================================================================
// obj_controlador — Create Event
// Configuração inicial do jogo: tamanhos padrão, baralho, deck, estado de turno.
// =============================================================================

#region Configuração global (tamanhos e debug)
global.CARTA_LARGURA = 80;
global.CARTA_ALTURA = 107;
global.RECURSO_LARGURA = 50;
global.MOEDA_LARGURA = 50;
global.ESCALA_TEXTO_CARTA = 0.60; // baixa esse número pra diminuir TODO texto das cartas sem arte
global.ESCALA_TEXTO_ATK = 0.75; // diminui esse número pra encolher só o texto de ATK/ATK mágico
global.TERRENO_LARGURA_ALVO = 70; // ajuste esse valor até a carta de terreno caber certinho no slot (largura visual JÁ considerando a rotação de -90°)

// true = mostra no console cada rolagem de dado/moeda e resultado de combate.
// Mude pra false quando quiser jogar sem poluir o console.
global.DEBUG_COMBATE = true;


depth = -10000; // desenha o menu de ação por cima de absolutamente tudo
vida_pos_x = 0.11; // pode ser sobrescrito por carta específica
vida_pos_y = 0.07;

randomize(); // garante que os números aleatórios mudam a cada execução do jogo
#endregion

#region Baralho e deck
baralho = [
    criar_dados_esquilo, criar_dados_lobo, criar_dados_urso, criar_dados_slime, criar_dados_mimic, 
	criar_dados_olho_demonio, criar_dados_mago_da_sombra, criar_dados_gato_mago, criar_dados_goblin, criar_dados_hollow_jack, 
	criar_dados_esqueleto, criar_dados_shroomilin,
    criar_dados_recurso_sangue, criar_dados_recurso_ossos, criar_dados_recurso_sucata, criar_dados_recurso_mana,
    criar_dados_construcao_torre,criar_dados_construcao_hemodrenario,
    criar_dados_magica_bola_fogo, criar_dados_magica_veneno, criar_dados_magica_gelo, criar_dados_magica_choque,
    criar_dados_item_espada, criar_dados_item_escudo, criar_dados_item_pocao,
	criar_dados_item_sangue_suga, criar_dados_item_pocao_mana,
    criar_dados_armadilha_urso,
	criar_dados_bencao_vida, criar_dados_maldicao_perda,
	criar_dados_bencao_decomposicao, criar_dados_maldicao_sangue_por_sangue,
	criar_dados_item_bau, criar_dados_item_frasco_sangue,
	criar_dados_item_vitamina_cerebro, criar_dados_item_elmo_ferro,
	criar_dados_item_frasco_acido, criar_dados_terreno_pantano,criar_dados_terreno_cemiterio, criar_dados_item_espada_quebrada
	
];

monte = montar_deck();
monte_inimigo = montar_deck();
quantidade_inicial = 7;;
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

#region Mão do inimigo
mao_inimigo = [];
mao_inimigo_inicial_comprada = false;
#endregion

#region Turno e vida
turno = "jogador";
vida_jogador = 20;
vida_inimigo = 20;
fila_dano_castelo = [];
dano_castelo_ativo = false;
dano_castelo_dono = "";
dano_castelo_valor = 0;
dano_castelo_timer = 0;
dano_castelo_duracao = 45;
dano_castelo_aplicado = false;
dano_castelo_impacto_timer = 0;
cartas_jogadas_no_turno = 0;
max_cartas_por_turno = 1;
itens_usados_este_turno = 0;
magias_usadas_este_turno = 0;
construcoes_jogadas_este_turno = 0;
terrenos_jogados_este_turno = 0;
primeiro_turno_jogador = true;
primeiro_turno_inimigo = true;
turnos_completos = 0;
mao_inicial_comprada = false; // <-- nova trava

// A IA executa o turno em etapas visíveis, sem revelar a mão do oponente.
ia_ativa = false;
ia_etapa = 0;
ia_tempo_espera = 0;
ia_texto_acao = "";
anuncio_turno_texto = "SEU TURNO";
anuncio_turno_timer = 75;
anuncio_turno_duracao = 75;
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
terreno_ativo = "";        // nome do terreno ativo, usado pra efeitos condicionais tipo Cemitério
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
tropa_selecionada = noone;
pausa_ativa = false;
opcoes_pausa_ativa = false;
carregar_configuracoes();
hud_deslocamento_esquerda = 160;
hud_deslocamento_direita = 180;
#endregion

#region Evolução
evolucoes_jogador_este_turno = 0;
evolucoes_inimigo_este_turno = 0;
max_evolucoes_por_turno = 1;
#endregion

#region Bençãos e maldições
bencaos_jogador = [];
maldicoes_jogador = [];
bencaos_inimigo = [];
maldicoes_inimigo = [];
max_bencaos_maldicoes = 2;
#endregion

#region Abismo
abismo = []; // guarda os nomes das cartas que foram parar lá, pra sempre
cemiterio_jogador = []; // descarte lógico; a visualização pode ser adicionada depois
cemiterio_inimigo = [];
descarte_jogador = []; // magias e itens consumidos; a pilha visual será ligada a este array
descarte_inimigo = [];
descarte_aberto = false;
descarte_preview_indice = -1;
confirmacao_descarte_ativa = false;
carta_pendente_descarte = noone;
cemiterio_aberto = false;
historico_aberto = false;
historico_combate = [];
max_historico_combate = 15;
#endregion	

#region Tutorial opcional
tutorial_ativo = false;
tutorial_pagina = 0;
tutorial_paginas = [
    { titulo: "BEM-VINDO A KARTHA", texto: "O objetivo é reduzir a vida do castelo inimigo a zero. Use suas cartas para formar tropas, criar recursos e controlar as três fileiras." },
    { titulo: "SEU TURNO", texto: "Compre cartas, coloque até um recurso e jogue suas cartas pagando o custo indicado. Recursos usados ficam virados até o próximo turno." },
    { titulo: "TROPAS E MOVIMENTO", texto: "Tropas entram na base da sua fileira. Uma tropa recém-colocada só pode se mover no próximo turno dela. Assim, chegar ao centro exige planejamento." },
    { titulo: "COMBATE E CASTELO", texto: "No centro, a tropa ataca inimigos à frente. Sem tropa ou construção na fileira, ela ataca o castelo. Uma tropa na base pode escolher Defender Castelo para interceptar esse dano." },
    { titulo: "AÇÕES E EVOLUÇÃO", texto: "Clique numa tropa no campo para atacar, mover, usar habilidade, evoluir ou defender. Evoluções exigem que a tropa tenha sobrevivido pelo menos um turno." },
    { titulo: "INFORMAÇÕES DA PARTIDA", texto: "Use HISTÓRICO para rever ações recentes e CEMITÉRIO para ver as tropas derrotadas. Você pode abrir este tutorial novamente a qualquer momento pelo botão TUTORIAL ou com F1." }
];
abrir_livro_pendente = variable_global_exists("abrir_livro_menu") && global.abrir_livro_menu;
if (variable_global_exists("abrir_tutorial_menu") && global.abrir_tutorial_menu) {
    tutorial_ativo = true;
    global.abrir_tutorial_menu = false;
}
if (abrir_livro_pendente) global.abrir_livro_menu = false;
#endregion

#region Anúncio de terreno (nome grande na tela)
terreno_anuncio_texto = "";
terreno_anuncio_timer = 0;
terreno_anuncio_duracao = 100; // ~1.6s a 60fps: fade in, hold, fade out
#endregion

#region Animação de bênção e maldição
ritual_texto = "";
ritual_tipo = "";
ritual_timer = 0;
ritual_duracao = 180; // cerca de 3 segundos a 60 FPS
ritual_som = -1;
ritual_fade_final_iniciado = false;
#endregion
