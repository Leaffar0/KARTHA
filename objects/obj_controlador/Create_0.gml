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
turno = "preparacao";
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
anuncio_turno_timer = 0;
anuncio_turno_duracao = 75;
onda_turno_timer = 0;
onda_turno_duracao = 42;
visao_veu_revelacao_timer = 0;
animacoes_item = [];
fim_animacao_timer = 0;
fim_animacao_duracao = 90;

// A partida só começa depois que os dois lados disputarem a iniciativa no D20.
disputa_inicial_estado = "preparando_dado";
disputa_inicial_resultado_jogador = -1;
disputa_inicial_resultado_inimigo = -1;
disputa_inicial_timer = 18;
dado_iniciativa_id = noone;
disputa_inicial_primeiro_escolhido = "";
disputa_inicial_vencedor = "";
partida_iniciada = false;

// Críticos do jogador abrem uma escolha. A fila também cobre dois críticos
// quase simultâneos, como pode acontecer durante Golpe Duplo.
critico_escolha_ativa = false;
criticos_pendentes = [];
critico_contexto = noone;
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
digestao_selecao_ativa = false;
digestao_origem = noone;
visao_veu_ativa = false;
visao_veu_origem = noone;
visao_veu_opcoes = [];
troca_item_selecao_ativa = false;
troca_item_origem = noone;
recurso_retirado_no_turno = false;
recurso_retirado_no_turno_inimigo = false;
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
confirmacao_recurso_ativa = false;
recurso_pendente_retirada = noone;
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
    { titulo: "QUEM COMEÇA", texto: "No início, pegue o D20 sobre a mesa, mova e solte para arremessá-lo. O inimigo joga o dele automaticamente. Em caso de empate, arremesse novamente. Quem vencer escolhe qual lado começa; depois, clique no deck para receber sua mão e iniciar a partida." },
    { titulo: "SEU TURNO", texto: "Compre cartas, coloque até um recurso e jogue suas cartas pagando o custo indicado. Recursos usados ficam virados até o próximo turno." },
    { titulo: "TROPAS E MOVIMENTO", texto: "Cada jogador pode ter no máximo 1 tropa em cada coluna. Se tentar colocar outra na mesma coluna, a carta volta para a mão e aparece o aviso COLUNA OCUPADA. Uma tropa recém-colocada só pode se mover no próximo turno dela." },
    { titulo: "COMBATE E CASTELO", texto: "Chegar ao centro não permite atingir o castelo. No centro, a tropa combate inimigos à frente; para atacar uma construção, o castelo ou a vida adversária, precisa avançar mais uma casa até a posição de assalto. Em um 20 natural, escolha entre dobrar os dados originais ou dobrar o resultado deles; modificadores são aplicados depois." },
    { titulo: "BOLA DE FOGO", texto: "Arraste a Bola de Fogo sobre uma tropa inimiga, construção inimiga ou sobre o marcador CASTELO. Ela joga seu D8 após o impacto. Somente tropas podem receber Queimado." },
    { titulo: "AÇÕES E EVOLUÇÃO", texto: "Clique numa tropa no campo para atacar, mover, usar habilidade, evoluir ou defender. Evoluções exigem que a tropa tenha sobrevivido pelo menos um turno." },
    { titulo: "EFEITOS ATIVOS", texto: "Cada lado pode manter até 2 bênçãos e 2 maldições. Elas aparecem em quatro espaços próprios do tabuleiro: dourado para bênção e vermelho para maldição. Passe o mouse sobre uma carta ativa para ler seu efeito." },
    { titulo: "CONDIÇÕES", texto: "Uma tropa só mantém uma condição por vez. Confusão dá desvantagem e permite contra-ataque em qualquer erro; Adormecer joga uma moeda no início do turno; Berserker dobra apenas o dano original, dá vantagem e +4 DEF. Apodrecer e Regeneração jogam um único D4, que define duração e valor por turno." },
    { titulo: "ITENS E RECURSOS", texto: "No menu de uma tropa equipada, você pode devolver o último item à mão ou transferi-lo para uma tropa aliada com espaço. Cada tropa envolvida troca no máximo uma vez por turno. Clique com o botão direito em um recurso para devolvê-lo à mão; só 1 recurso pode ser retirado por turno." },
    { titulo: "HABILIDADES ESPECIAIS", texto: "Digestão escolhe uma tropa adjacente com menos de 4 de vida ou usa a vítima recém-abatida. Roubo joga D10 quando a tropa é atacada por uma arma: no 10, toma o item se houver espaço. Carniça Frenética paga 2 Sangues e prepara o próximo ataque. Visão do Véu revela a mão inimiga e oferece duas escolhas." },
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
