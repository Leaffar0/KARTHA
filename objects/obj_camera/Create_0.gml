x = 576;
y = 576;
velocidade_scroll = 60; // distância no tabuleiro por passo da roda do mouse
suavidade_scroll = 0.25;
scroll_ativo = false;
scroll_alvo_y = y;
scroll_mouse_origem_y = window_mouse_get_y();

view_object[0] = noone; // mantém a view sob controle manual (evita o bug de travar)
