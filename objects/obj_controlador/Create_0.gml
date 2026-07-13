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
    criar_dados_construcao_torre
];
mao = [];

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
//window_set_fullscreen(true);

// garante que a área de desenho acompanha o tamanho real da tela

#region camera antiga
/*display_set_gui_size(display_get_width(), display_get_height());
// tamanho da "janela" visível (menor que a room inteira)
altura_view = 650;
largura_view = 800;

// posição vertical atual da câmera (0 = topo da room)
camera_y = room_height - altura_view; // começa mostrando SEU lado (embaixo)
camera_y_alvo = camera_y;

// cria a câmera
minha_camera = camera_create();
camera_set_view_size(minha_camera, room_width, room_height);
camera_set_view_pos(minha_camera, 0, camera_y);

view_camera[0] = minha_camera;
view_enabled = true;
view_visible[0] = true;*/
#endregion

