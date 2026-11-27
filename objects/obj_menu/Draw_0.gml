// Mesa escura e cartas com entrada escalonada.
draw_set_alpha(1);draw_set_color(make_color_rgb(16,16,16));
draw_rectangle(0,0,room_width,room_height,false);
draw_set_alpha(0.20);draw_set_color(make_color_rgb(62,62,62));
for(var _halo=4;_halo>0;_halo--) draw_ellipse(room_width*0.5-room_width*0.10*_halo,
    room_height*0.43-room_height*0.095*_halo,room_width*0.5+room_width*0.10*_halo,
    room_height*0.43+room_height*0.095*_halo,false);
draw_set_alpha(1);
var _letras="KARTHA";
for(var _i=0;_i<6;_i++) {
    var _c=carta_menu_layout(_i,true,tempo_menu,room_width,room_height);
    desenhar_carta_menu(_c,string_char_at(_letras,_i+1),true,0.35,_i);
}
var _rotulos=["JOGAR","BARALHO","OPÇÕES","SAIR"];
for(var _i=0;_i<4;_i++) {
    var _c=carta_menu_layout(_i,false,tempo_menu,room_width,room_height,menu_hover[_i]);
    desenhar_carta_menu(_c,_rotulos[_i],false,menu_hover[_i],_i);
}
draw_set_font(Fontenil);draw_set_halign(fa_center);draw_set_valign(fa_middle);
if(opcoes_abertas || modo_jogo_aberto || online_aberto || deck_aberto) {
    draw_set_alpha(0.72);draw_set_color(c_black);draw_rectangle(0,0,room_width,room_height,false);
}
draw_set_alpha(1);draw_set_color(c_white);

#region Painel de opções
if (opcoes_abertas) {
    var _opcoes_x = room_width / 2;
    var _opcoes_y = centro_painel_menu(id);
    var _musica_y = _opcoes_y - 35;
    var _efeitos_y = _opcoes_y + 10;
    var _tela_y = _opcoes_y + 55;
    var _interface_y = _opcoes_y + 98;
    var _voltar_y = _opcoes_y + 190;
    desenhar_painel_carta_menu(_opcoes_x-225,_opcoes_y-110,_opcoes_x+225,_opcoes_y+225);
    desenhar_texto_ajustado_ui("OPÇÕES",_opcoes_x,_opcoes_y-75,260,0.72);
    desenhar_conteudo_opcoes_compacto(_opcoes_x,_opcoes_y);

}
#endregion

#region Escolha do modo de partida
if(modo_jogo_aberto) {
    var _cy=centro_painel_menu(id);
    var _cw=carta_modo_menu(0,_cy).w;
    desenhar_painel_carta_menu(room_width/2-(_cw*2+64)/2,_cy-150,room_width/2+(_cw*2+64)/2,_cy+195);
    desenhar_texto_ajustado_ui("ESCOLHA SUA PARTIDA",room_width/2,_cy-115,_cw*2+16,0.86);
    var _nomes=["CONTRA IA","ONLINE"];
    var _sub=["Você contra a máquina","Convide outro jogador"];
    for(var _m=0;_m<array_length(_nomes);_m++) {
        var _c=carta_modo_menu(_m,_cy);
        var _h = menu_por_teclado ? _m == modo_foco : ponto_carta_menu(_c,mouse_x,mouse_y);
        desenhar_carta_menu(_c,_nomes[_m],false,_h?1:0,_m,0.76);
        draw_set_color(c_silver);
        desenhar_texto_ajustado_ui(_sub[_m],_c.x,_c.y+44,_c.w-22,0.40);
    }
    botao_carta_painel(room_width/2-100,_cy+135,room_width/2+100,_cy+175,"VOLTAR");
}
#endregion

#region Lobby online
if (online_aberto) {
    var _online_cx = room_width / 2;
    var _online_cy = centro_painel_menu(id);
    desenhar_painel_carta_menu(_online_cx-285,_online_cy-205,_online_cx+285,_online_cy+205);
    desenhar_texto_interface(_online_cx, _online_cy - 174, "MULTIPLAYER ONLINE");

    var _online_conectado = online_ativo();
    var _online_ocupado = global.online_status == "conectando" || global.online_status == "reconectando";

	   if (!_online_conectado && !_online_ocupado) {
	    draw_set_halign(fa_left);
	    draw_set_color(c_ltgray);
	    draw_set_alpha(0.55);

	    desenhar_texto_interface(_online_cx - 160, _online_cy - 115, "NOME");
	    desenhar_texto_interface(_online_cx - 160, _online_cy - 65, "CÓDIGO DA SALA");
	    desenhar_texto_interface(_online_cx - 160, _online_cy - 15, "SERVIDOR");

	    draw_set_alpha(1);
	    draw_set_halign(fa_center);

        for (var _online_i = 0; _online_i < 3; _online_i++) {
            var _online_y = _online_cy - 105 + _online_i * 50;
            draw_set_color(online_foco == _online_i ? c_aqua : c_white);
            botao_carta_painel(_online_cx - 190, _online_y, _online_cx + 190, _online_y + 36, "");
            if(online_foco==_online_i) {
                draw_set_color(c_aqua);
                draw_rectangle(_online_cx-187,_online_y+3,_online_cx+187,_online_y+33,true);
            }
        }
        draw_set_color(c_white);
        desenhar_texto_ajustado_ui(online_nome_input,_online_cx,_online_cy-87,350,0.55);
        desenhar_texto_ajustado_ui(online_codigo_input==""?"Ctrl+V para colar":online_codigo_input,_online_cx-38,_online_cy-37,285,0.5);
        var _hover_colar_codigo = point_in_rectangle(mouse_x, mouse_y, _online_cx + 125, _online_cy - 55, _online_cx + 190, _online_cy - 19);
        draw_set_color(c_black);
        draw_roundrect(_online_cx + 125, _online_cy - 55, _online_cx + 190, _online_cy - 19, false);
        draw_set_color(_hover_colar_codigo ? c_aqua : c_white);
        botao_carta_painel(_online_cx + 125, _online_cy - 55, _online_cx + 190, _online_cy - 19, "");
        desenhar_texto_ajustado_ui("COLAR",_online_cx+157,_online_cy-37,49,0.42);
        draw_set_color(c_white);
        desenhar_texto_ajustado_ui(online_servidor_input,_online_cx,_online_cy+13,350,0.46);

        var _hover_criar = point_in_rectangle(mouse_x, mouse_y, _online_cx - 190, _online_cy + 55, _online_cx - 10, _online_cy + 101);
        var _hover_entrar = point_in_rectangle(mouse_x, mouse_y, _online_cx + 10, _online_cy + 55, _online_cx + 190, _online_cy + 101);
        draw_set_color(_hover_criar ? c_aqua : c_white);
        botao_carta_painel(_online_cx - 190, _online_cy + 55, _online_cx - 10, _online_cy + 101, "");
        desenhar_texto_interface(_online_cx - 100, _online_cy + 78, "CRIAR SALA");
        draw_set_color(_hover_entrar ? c_aqua : c_white);
        botao_carta_painel(_online_cx + 10, _online_cy + 55, _online_cx + 190, _online_cy + 101, "");
        desenhar_texto_interface(_online_cx + 100, _online_cy + 78, "ENTRAR");
        draw_set_color(c_gray);
        botao_carta_painel(_online_cx-100,_online_cy+130,_online_cx+100,_online_cy+170,"VOLTAR");
    } else if (_online_ocupado && !_online_conectado) {
        draw_set_color(c_aqua);
        desenhar_texto_interface(_online_cx, _online_cy - 10,
            global.online_status == "reconectando" ? "RECONECTANDO..." : "CONECTANDO...");
        draw_set_color(c_ltgray);
        desenhar_texto_interface(_online_cx, _online_cy + 28, "Aguarde o servidor responder");
        botao_carta_painel(_online_cx-100,_online_cy+130,_online_cx+100,_online_cy+170,"CANCELAR");
    } else {
        draw_set_color(c_aqua);
        desenhar_texto_interface(_online_cx, _online_cy - 132, "SALA " + global.net_room_id);
        draw_set_color(c_ltgray);
        desenhar_texto_interface(_online_cx, _online_cy - 102, "Você é " + global.online_nome_jogador);

        if (global.online_fase == "waiting") {
            draw_set_color(c_white);
            desenhar_texto_interface(_online_cx, _online_cy - 35, "AGUARDANDO OUTRO JOGADOR");
            draw_set_color(c_aqua);
            botao_carta_painel(_online_cx - 105, _online_cy + 35, _online_cx + 105, _online_cy + 75, "");
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
            if (global.online_assento >= 0 && global.online_assento < array_length(global.online_iniciativa) && global.online_iniciativa[global.online_assento] < 0) {
                draw_set_color(c_aqua);
                botao_carta_painel(_online_cx - 130, _online_cy + 45, _online_cx + 130, _online_cy + 95, "");
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
                botao_carta_painel(_online_cx - 205, _online_cy + 45, _online_cx - 5, _online_cy + 95, "");
                botao_carta_painel(_online_cx + 5, _online_cy + 45, _online_cx + 205, _online_cy + 95, "");
                desenhar_texto_interface(_online_cx - 105, _online_cy + 70, "EU COMEÇO");
                desenhar_texto_interface(_online_cx + 105, _online_cy + 70, "OPONENTE COMEÇA");
            } else {
                draw_set_color(c_yellow);
                desenhar_texto_interface(_online_cx, _online_cy - 10, "O OPONENTE ESTÁ ESCOLHENDO");
            }
        }
        draw_set_color(c_gray);
        botao_carta_painel(_online_cx-100,_online_cy+140,_online_cx+100,_online_cy+178,"SAIR DA SALA");
    }

    if (global.online_erro != "") {
        draw_set_color(c_red);
        desenhar_texto_interface_ext(_online_cx, _online_cy + 116, global.online_erro, 18, 480);
    }
    draw_set_color(c_white);
}
#endregion

#region Consulta do baralho
if (deck_aberto) {
    var _deck_cx = room_width / 2;
    var _deck_cy = centro_painel_menu(id);
    desenhar_painel_carta_menu(_deck_cx-310,_deck_cy-215,_deck_cx+310,_deck_cy+220);
    botao_carta_painel(_deck_cx+260,_deck_cy-195,_deck_cx+298,_deck_cy-162,"X");
    var _ficha = is_struct(deck_ficha);
    var _pagina = _ficha ? deck_texto_pagina : deck_pagina;
    var _paginas = _ficha ? array_length(deck_textos) : ceil(array_length(deck_catalogo_menu) / deck_por_pagina);
    if (_pagina > 0) botao_carta_painel(_deck_cx-220,_deck_cy+150,_deck_cx-80,_deck_cy+185,"< Anterior");
    if (_pagina+1 < _paginas) botao_carta_painel(_deck_cx+80,_deck_cy+150,_deck_cx+220,_deck_cy+185,"Próxima >");
    botao_carta_painel(_deck_cx-70,_deck_cy+150,_deck_cx+70,_deck_cy+185,"Voltar");
    if (_paginas > 1) desenhar_texto_interface(_deck_cx, _deck_cy+125, string(_pagina+1)+" / "+string(_paginas),0.48);
    if (_ficha) {
        desenhar_texto_ajustado_ui(deck_ficha.nome_carta, _deck_cx, _deck_cy-174, 482, 0.90);
        var _sprite = deck_ficha.sprite_index;
        var _escala = min(202 / sprite_get_width(_sprite), 249 / sprite_get_height(_sprite));
        desenhar_face_consulta(deck_ficha, _deck_cx-168, _deck_cy-15, _escala, 0, 0, true);
        draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_color(c_white);
        draw_text_transformed(_deck_cx-33, _deck_cy-139, deck_textos[deck_texto_pagina], 0.62, 0.62, 0);
    } else {
        desenhar_texto_interface(_deck_cx, _deck_cy-178, "BARALHO");
        desenhar_texto_interface(_deck_cx, _deck_cy-150, string(array_length(deck_catalogo_menu)*COPIAS_POR_CARTA)+" CARTAS");
        var _inicio = deck_pagina * deck_por_pagina;
        for (var _dr=0; _dr<min(deck_por_pagina,array_length(deck_catalogo_menu)-_inicio); _dr++) {
            var _dados = deck_catalogo_menu[_inicio+_dr]();
            var _y = _deck_cy-115+_dr*31;
            if (_dr == deck_linha) {
                draw_set_color(make_color_rgb(62,60,56));
                draw_roundrect(_deck_cx-280,_y-14,_deck_cx+280,_y+14,false);
            }
            draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_middle);
            desenhar_texto_ajustado_ui(_dados.nome,_deck_cx-270,_y,385,0.58);
            draw_set_halign(fa_center);
            desenhar_texto_interface(_deck_cx+167,_y,"×"+string(COPIAS_POR_CARTA));
        }
    }
    draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top);
}
#endregion

draw_set_font(-1);
