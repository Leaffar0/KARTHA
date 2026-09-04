carregar_configuracoes();
tocar_musica(snd_menu);
tempo_menu = 0;
opcoes_abertas = false;
deck_aberto = false;
deck_pagina = 0;
deck_por_pagina = 8;
deck_aviso_timer = 0;
deck_catalogo_menu = catalogo_cartas();
if (!variable_global_exists("deck_contagens")
    || array_length(global.deck_contagens) != array_length(deck_catalogo_menu)) {
    global.deck_contagens = carregar_contagens_baralho(array_length(deck_catalogo_menu));
    if (!validar_contagens_baralho(deck_catalogo_menu, global.deck_contagens)) {
        global.deck_contagens = array_create(array_length(deck_catalogo_menu), 0);
        var _base_deck = 50 div array_length(deck_catalogo_menu);
        var _resto_deck = 50 mod array_length(deck_catalogo_menu);
        for (var _di = 0; _di < array_length(deck_catalogo_menu); _di++)
            global.deck_contagens[_di] = _base_deck + (_di < _resto_deck ? 1 : 0);
    }
}
