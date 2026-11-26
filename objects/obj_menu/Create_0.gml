carregar_configuracoes();
display_set_gui_size(-1, -1);
tocar_musica(snd_menu);
tempo_menu = 0;
opcoes_abertas = false;
modo_jogo_aberto = false;
online_inicializar();
online_aberto = (online_ativo() && global.online_fase != "playing") || global.online_reabrir_lobby;
global.online_reabrir_lobby = false;
online_foco = 0;
online_nome_input = global.online_nome;
online_codigo_input = "";
online_servidor_input = online_carregar_endpoint();
online_copiado_timer = 0;
deck_aberto = false;
deck_pagina = 0;
deck_por_pagina = 8;
deck_catalogo_menu = catalogo_cartas();

audio_opcoes_anterior=false;

menu_hover=array_create(4,0);
menu_hover_anterior=-1;

painel_menu_abertura=0;
painel_menu_anterior="";
