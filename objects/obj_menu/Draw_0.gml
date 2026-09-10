#region Movimento do fundo e posicionamento dos botões
var offset_x = sin(tempo_menu) * 8;
var offset_y = cos(tempo_menu * 0.7) * 4;

// Fundo inteiro se mexendo
draw_sprite_stretched(
    spr_menu,
    0,
    offset_x - 20,
    offset_y - 20,
    room_width + 40,
    room_height + 40
);

// Botões acompanham o movimento
var jogar_x = room_width/2 + offset_x;
var jogar_y = room_height - 145 + offset_y;
var opcoes_y = room_height - 95 + offset_y;
var baralho_y = room_height - 195 + offset_y;

var sair_x = room_width/2 + offset_x;
var sair_y = room_height - 45 + offset_y;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(Fontenil);
#endregion

#region Botão Baralho
if (point_in_rectangle(mouse_x, mouse_y, jogar_x - 100, baralho_y - 22, jogar_x + 100, baralho_y + 22)) {
    desenhar_texto_interface(jogar_x, baralho_y, "> BARALHO <");
} else desenhar_texto_interface(jogar_x, baralho_y, "BARALHO");
#endregion

#region Botão Jogar
// Hover JOGAR
if (point_in_rectangle(
    mouse_x, mouse_y,
    jogar_x - 80, jogar_y - 25,
    jogar_x + 80, jogar_y + 25))
{
    desenhar_texto_interface(jogar_x, jogar_y, "> JOGAR <");
}
else
{
    desenhar_texto_interface(jogar_x, jogar_y, "JOGAR");
}
#endregion

#region Botão Opções
if (point_in_rectangle(mouse_x, mouse_y, jogar_x - 90, opcoes_y - 22, jogar_x + 90, opcoes_y + 22)) {
    desenhar_texto_interface(jogar_x, opcoes_y, "> OPÇÕES <");
} else {
    desenhar_texto_interface(jogar_x, opcoes_y, "OPÇÕES");
}
#endregion

#region Botão Sair
// Hover SAIR
if (point_in_rectangle(
    mouse_x, mouse_y,
    sair_x - 80, sair_y - 25,
    sair_x + 80, sair_y + 25))
{
    desenhar_texto_interface(sair_x, sair_y, "> SAIR <");
}
else
{
    desenhar_texto_interface(sair_x, sair_y, "SAIR");
}
#endregion

#region Painel de opções
if (opcoes_abertas) {
    var _opcoes_x = room_width / 2;
    var _opcoes_y = room_height / 2;
    var _musica_y = _opcoes_y - 35;
    var _efeitos_y = _opcoes_y + 10;
    var _tela_y = _opcoes_y + 55;
    var _voltar_y = _opcoes_y + 110;
    draw_set_alpha(0.8);
    draw_set_color(c_black);
    draw_rectangle(_opcoes_x - 210, _opcoes_y - 105, _opcoes_x + 210, _opcoes_y + 150, false);
    draw_set_alpha(1);

    draw_set_color(c_white);
    draw_rectangle(_opcoes_x - 210, _opcoes_y - 105, _opcoes_x + 210, _opcoes_y + 150, true);
    desenhar_texto_interface(_opcoes_x, _opcoes_y - 65, "OPÇÕES");
    desenhar_texto_interface(_opcoes_x - 125, _musica_y, "<");
    desenhar_texto_interface(_opcoes_x + 125, _musica_y, ">");
    desenhar_texto_interface(_opcoes_x, _musica_y, "MÚSICA  " + string(round(global.volume_musica * 100)) + "%");
    desenhar_texto_interface(_opcoes_x - 125, _efeitos_y, "<");
    desenhar_texto_interface(_opcoes_x + 125, _efeitos_y, ">");
    desenhar_texto_interface(_opcoes_x, _efeitos_y, "EFEITOS  " + string(round(global.volume_efeitos * 100)) + "%");
    draw_set_color(c_gray);
    desenhar_texto_interface(_opcoes_x, _tela_y, "TELA CHEIA: " + (window_get_fullscreen() ? "SIM" : "NÃO"));
    draw_set_color(c_white);
    desenhar_texto_interface(_opcoes_x, _voltar_y, "VOLTAR");
}
#endregion

#region Escolha do modo de partida
if (modo_jogo_aberto) {
    var _modo_cx = room_width / 2;
    var _modo_cy = room_height / 2;
    draw_set_alpha(0.90);
    draw_set_color(c_black);
    draw_roundrect(_modo_cx - 235, _modo_cy - 125, _modo_cx + 235, _modo_cy + 198, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_roundrect(_modo_cx - 235, _modo_cy - 125, _modo_cx + 235, _modo_cy + 198, true);
    desenhar_texto_interface(_modo_cx, _modo_cy - 82, "ESCOLHA O MODO");

    var _hover_ia = point_in_rectangle(mouse_x, mouse_y,
        _modo_cx - 170, _modo_cy - 42, _modo_cx + 170, _modo_cy + 2);
    var _hover_local = point_in_rectangle(mouse_x, mouse_y,
        _modo_cx - 170, _modo_cy + 15, _modo_cx + 170, _modo_cy + 59);
    var _hover_online = point_in_rectangle(mouse_x, mouse_y,
        _modo_cx - 170, _modo_cy + 72, _modo_cx + 170, _modo_cy + 116);
    var _hover_voltar = point_in_rectangle(mouse_x, mouse_y,
        _modo_cx - 100, _modo_cy + 135, _modo_cx + 100, _modo_cy + 175);

    draw_set_color(_hover_ia ? c_yellow : c_white);
    draw_roundrect(_modo_cx - 170, _modo_cy - 42, _modo_cx + 170, _modo_cy + 2, true);
    desenhar_texto_interface(_modo_cx, _modo_cy - 20, "CONTRA IA");
    draw_set_color(_hover_local ? c_yellow : c_white);
    draw_roundrect(_modo_cx - 170, _modo_cy + 15, _modo_cx + 170, _modo_cy + 59, true);
    desenhar_texto_interface(_modo_cx, _modo_cy + 37, "2 JOGADORES LOCAL");
    draw_set_color(_hover_online ? c_aqua : c_white);
    draw_roundrect(_modo_cx - 170, _modo_cy + 72, _modo_cx + 170, _modo_cy + 116, true);
    desenhar_texto_interface(_modo_cx, _modo_cy + 94, "ONLINE (BETA)");
    draw_set_color(_hover_voltar ? c_yellow : c_gray);
    desenhar_texto_interface(_modo_cx, _modo_cy + 155, "VOLTAR");
    draw_set_color(c_white);
}
#endregion

#region Lobby online
if (online_aberto) {
    var _online_cx = room_width / 2;
    var _online_cy = room_height / 2;
    draw_set_alpha(0.94);
    draw_set_color(c_black);
    draw_roundrect(_online_cx - 285, _online_cy - 205, _online_cx + 285, _online_cy + 205, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_roundrect(_online_cx - 285, _online_cy - 205, _online_cx + 285, _online_cy + 205, true);
    desenhar_texto_interface(_online_cx, _online_cy - 174, "MULTIPLAYER ONLINE");

    var _online_conectado = online_ativo();
    var _online_ocupado = global.online_status == "conectando" || global.online_status == "reconectando";

	   if (!_online_conectado && !_online_ocupado) {
	    draw_set_halign(fa_left);
	    draw_set_color(c_ltgray);
	    draw_set_alpha(0.55);

	    desenhar_texto_interface(_online_cx - 160, _online_cy - 105, "NOME");
	    desenhar_texto_interface(_online_cx - 160, _online_cy - 55, "CÓDIGO DA SALA");
	    desenhar_texto_interface(_online_cx - 160, _online_cy - 5, "SERVIDOR");

	    draw_set_alpha(1);
	    draw_set_halign(fa_center);

        for (var _online_i = 0; _online_i < 3; _online_i++) {
            var _online_y = _online_cy - 105 + _online_i * 50;
            draw_set_color(online_foco == _online_i ? c_aqua : c_white);
            draw_roundrect(_online_cx - 190, _online_y, _online_cx + 190, _online_y + 36, true);
        }
        draw_set_color(c_white);
        desenhar_texto_interface(_online_cx, _online_cy - 87, online_nome_input);
        desenhar_texto_interface(_online_cx - 28, _online_cy - 37, online_codigo_input == "" ? "Ctrl+V para colar" : online_codigo_input);
        var _hover_colar_codigo = point_in_rectangle(mouse_x, mouse_y, _online_cx + 125, _online_cy - 55, _online_cx + 190, _online_cy - 19);
        draw_set_color(c_black);
        draw_roundrect(_online_cx + 125, _online_cy - 55, _online_cx + 190, _online_cy - 19, false);
        draw_set_color(_hover_colar_codigo ? c_aqua : c_white);
        draw_roundrect(_online_cx + 125, _online_cy - 55, _online_cx + 190, _online_cy - 19, true);
        desenhar_texto_interface(_online_cx + 157, _online_cy - 37, "COLAR");
        draw_set_color(c_white);
        desenhar_texto_interface(_online_cx, _online_cy + 13, online_servidor_input);

        var _hover_criar = point_in_rectangle(mouse_x, mouse_y, _online_cx - 190, _online_cy + 55, _online_cx - 10, _online_cy + 101);
        var _hover_entrar = point_in_rectangle(mouse_x, mouse_y, _online_cx + 10, _online_cy + 55, _online_cx + 190, _online_cy + 101);
        draw_set_color(_hover_criar ? c_aqua : c_white);
        draw_roundrect(_online_cx - 190, _online_cy + 55, _online_cx - 10, _online_cy + 101, true);
        desenhar_texto_interface(_online_cx - 100, _online_cy + 78, "CRIAR SALA");
        draw_set_color(_hover_entrar ? c_aqua : c_white);
        draw_roundrect(_online_cx + 10, _online_cy + 55, _online_cx + 190, _online_cy + 101, true);
        desenhar_texto_interface(_online_cx + 100, _online_cy + 78, "ENTRAR");
        draw_set_color(c_gray);
        desenhar_texto_interface(_online_cx, _online_cy + 150, "VOLTAR");
    } else if (_online_ocupado && !_online_conectado) {
        draw_set_color(c_aqua);
        desenhar_texto_interface(_online_cx, _online_cy - 10,
            global.online_status == "reconectando" ? "RECONECTANDO..." : "CONECTANDO...");
        draw_set_color(c_ltgray);
        desenhar_texto_interface(_online_cx, _online_cy + 28, "Aguarde o servidor responder");
    } else {
        draw_set_color(c_aqua);
        desenhar_texto_interface(_online_cx, _online_cy - 132, "SALA " + global.net_room_id);
        draw_set_color(c_ltgray);
        desenhar_texto_interface(_online_cx, _online_cy - 102, "Você é " + global.online_nome_jogador);

        if (global.online_fase == "waiting") {
            draw_set_color(c_white);
            desenhar_texto_interface(_online_cx, _online_cy - 35, "AGUARDANDO OUTRO JOGADOR");
            draw_set_color(c_aqua);
            draw_roundrect(_online_cx - 105, _online_cy + 35, _online_cx + 105, _online_cy + 75, true);
            desenhar_texto_interface(_online_cx, _online_cy + 55, online_copiado_timer > 0 ? "CÓDIGO COPIADO" : "COPIAR CÓDIGO");
        } else if (global.online_fase == "initiative") {
            draw_set_color(c_white);
            desenhar_texto_interface(_online_cx, _online_cy - 55, "DISPUTA DE INICIATIVA — D20");
            desenhar_texto_interface(_online_cx - 95, _online_cy - 10,
                global.online_iniciativa[0] < 0 ? "—" : string(global.online_iniciativa[0]));
            desenhar_texto_interface(_online_cx + 95, _online_cy - 10,
                global.online_iniciativa[1] < 0 ? "—" : string(global.online_iniciativa[1]));
            draw_set_color(c_ltgray);
            desenhar_texto_interface(_online_cx - 95, _online_cy + 14, global.online_nomes_assentos[0]);
            desenhar_texto_interface(_online_cx + 95, _online_cy + 14, global.online_nomes_assentos[1]);
            if (global.online_iniciativa[global.online_assento] < 0) {
                draw_set_color(c_aqua);
                draw_roundrect(_online_cx - 130, _online_cy + 45, _online_cx + 130, _online_cy + 95, true);
                desenhar_texto_interface(_online_cx, _online_cy + 70, "JOGAR O D20");
            } else {
                draw_set_color(c_yellow);
                desenhar_texto_interface(_online_cx, _online_cy + 70, "AGUARDANDO A OUTRA JOGADA...");
            }
        } else if (global.online_fase == "choose_first") {
            if (global.online_vencedor_iniciativa == global.online_assento) {
                draw_set_color(c_yellow);
                desenhar_texto_interface(_online_cx, _online_cy - 35, "VOCÊ VENCEU — QUEM COMEÇA?");
                draw_set_color(c_aqua);
                draw_roundrect(_online_cx - 205, _online_cy + 45, _online_cx - 5, _online_cy + 95, true);
                draw_roundrect(_online_cx + 5, _online_cy + 45, _online_cx + 205, _online_cy + 95, true);
                desenhar_texto_interface(_online_cx - 105, _online_cy + 70, "EU COMEÇO");
                desenhar_texto_interface(_online_cx + 105, _online_cy + 70, "OPONENTE COMEÇA");
            } else {
                draw_set_color(c_yellow);
                desenhar_texto_interface(_online_cx, _online_cy - 10, "O OPONENTE ESTÁ ESCOLHENDO");
            }
        }
        draw_set_color(c_gray);
        desenhar_texto_interface(_online_cx, _online_cy + 160, "SAIR DA SALA");
    }

    if (global.online_erro != "") {
        draw_set_color(c_red);
        desenhar_texto_interface_ext(_online_cx, _online_cy + 116, global.online_erro, 18, 480);
    }
    draw_set_color(c_white);
}
#endregion

#region Montagem de baralho
if (deck_aberto) {
    var _deck_cx = room_width / 2;
    var _deck_cy = room_height / 2;
    draw_set_alpha(0.94); draw_set_color(c_black);
    draw_rectangle(_deck_cx - 310, _deck_cy - 205, _deck_cx + 310, _deck_cy + 205, false);
    draw_set_alpha(1); draw_set_color(c_white);
    draw_rectangle(_deck_cx - 310, _deck_cy - 205, _deck_cx + 310, _deck_cy + 205, true);
    desenhar_texto_interface(_deck_cx, _deck_cy - 178, "MONTAGEM DE BARALHO");

    var _total_deck = 0;
    for (var _dt = 0; _dt < array_length(global.deck_contagens); _dt++) _total_deck += global.deck_contagens[_dt];
    draw_set_color(_total_deck == 50 ? c_lime : c_yellow);
    desenhar_texto_interface(_deck_cx, _deck_cy - 150, "CARTAS: " + string(_total_deck) + "/50");

    var _deck_inicio = deck_pagina * deck_por_pagina;
    var _deck_inicio_y = _deck_cy - 115;
    for (var _dr = 0; _dr < deck_por_pagina; _dr++) {
        var _deck_indice = _deck_inicio + _dr;
        if (_deck_indice >= array_length(deck_catalogo_menu)) break;
        var _dados_deck = deck_catalogo_menu[_deck_indice]();
        var _deck_y = _deck_inicio_y + _dr * 31;
        draw_set_halign(fa_left); draw_set_color(c_white);
        desenhar_texto_interface(_deck_cx - 275, _deck_y, _dados_deck.nome);
        draw_set_halign(fa_center);
        draw_rectangle(_deck_cx + 105, _deck_y - 12, _deck_cx + 145, _deck_y + 12, true);
        draw_rectangle(_deck_cx + 190, _deck_y - 12, _deck_cx + 230, _deck_y + 12, true);
        desenhar_texto_interface(_deck_cx + 125, _deck_y, "-");
        desenhar_texto_interface(_deck_cx + 167, _deck_y, string(global.deck_contagens[_deck_indice]));
        desenhar_texto_interface(_deck_cx + 210, _deck_y, "+");
    }
    draw_set_halign(fa_center); draw_set_color(c_white);
    desenhar_texto_interface(_deck_cx - 150, _deck_cy + 167, "< ANTERIOR");
    desenhar_texto_interface(_deck_cx, _deck_cy + 167, "CONCLUIR");
    desenhar_texto_interface(_deck_cx + 150, _deck_cy + 167, "PRÓXIMA >");
    if (deck_aviso_timer > 0) {
        draw_set_color(c_red);
        desenhar_texto_interface(_deck_cx, _deck_cy + 195, "O BARALHO PRECISA TER EXATAMENTE 50 CARTAS");
    }
}
#endregion

draw_set_font(-1);
