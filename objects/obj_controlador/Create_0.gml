randomize(); // garante que os números aleatórios mudam a cada execução

// --- 1. TUDO que o Step usa, primeiro, sem risco de erro ---
baralho = [
    criar_dados_esquilo, 
    criar_dados_lobo,
    criar_dados_urso,
    criar_dados_recurso_sangue,
    criar_dados_recurso_ossos,
    criar_dados_recurso_sucata,
    criar_dados_recurso_mana,
    criar_dados_construcao_torre,
    criar_dados_magica_bola_fogo,
    criar_dados_magica_veneno,
    criar_dados_magica_gelo,
    criar_dados_magica_choque
];

mao = [];

recursos_inimigo = [];
recurso_colocado_no_turno_inimigo = false;
carta_preview = noone;
quantidade_inicial = 3;
mao_x_centro = room_width / 2;
mao_y = room_height - 100;
espaco_entre_cartas = 50;
hover_atual = noone;
vida_jogador = 20;
vida_inimigo = 20;
turno = "jogador";
fase = "gerenciamento";
rolagens_pendentes = 0;
cartas_jogadas_no_turno = 0;
max_cartas_por_turno = 1;
carta_arrastando = noone;
carta_selecionada = noone;
recursos_jogador = [];
max_recursos = 6;
recurso_colocado_no_turno = false; // 1 por turno
