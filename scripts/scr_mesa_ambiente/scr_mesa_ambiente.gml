// Somente apresentação: não modifica terreno, custos, cartas ou estado da partida.
function mesa_ambiente_criar() {
    return {pesos: [1, 0, 0, 0], tempo: 0};
}

function mesa_ambiente_indice(_efeito, _nome) {
    if (_efeito == "planicies_profanas" || _nome == "Planícies Profanas") return 3;
    if (_efeito == "cemiterio" || _nome == "Cemitério") return 2;
    if (_nome == "Pântano Sombrio") return 1;
    return 0;
}

function mesa_ambiente_terreno() {
    var _efeito = "", _nome = "";
    if (instance_exists(obj_controlador)) _efeito = obj_controlador.terreno_ativo;
    // Pântano tem bônus de defesa, mas não possui identificador de efeito.
    // Consulta o slot real, nunca uma carta de terreno ainda na mão.
    var _slot = instance_find(obj_slot_terreno, 0);
    if (_slot != noone && _slot.ocupado && instance_exists(_slot.terreno_atual)) {
        var _dados = _slot.terreno_atual.dados_carta;
        if (is_struct(_dados) && variable_struct_exists(_dados, "nome")) _nome = _dados.nome;
    }
    return mesa_ambiente_indice(_efeito, _nome);
}

function mesa_ambiente_atualizar(_ambiente, _alvo, _segundos) {
    _ambiente.tempo += clamp(_segundos, 0, 0.1);
    _alvo = clamp(floor(_alvo), 0, 3);
    // Mistura contínua inclusive quando o terreno muda durante outra transição.
    // Independente do FPS, sem aleatoriedade que interfira nos dados do jogo.
    var _passo = 1 - exp(-3 * clamp(_segundos, 0, 0.1));
    for (var _i = 0; _i < 4; _i++) {
        _ambiente.pesos[_i] = lerp(_ambiente.pesos[_i], _i == _alvo ? 1 : 0, _passo);
    }
    if (_ambiente.pesos[_alvo] > 0.999) {
        for (var _i = 0; _i < 4; _i++) _ambiente.pesos[_i] = _i == _alvo ? 1 : 0;
    }
}

function mesa_ambiente_atmosfera(_ambiente,_x,_y,_w,_h) {
    var _a=draw_get_alpha(), _cor=draw_get_color();
    var _forca=min(1.15,fator_efeitos_visuais());
    var _nevoa=_ambiente.pesos[2]*_forca;
    var _chuva=_ambiente.pesos[1]*_forca;
    var _t=_ambiente.tempo;
    // Faixas de névoa com bordas transparentes: passam devagar sobre o couro,
    // mas ficam abaixo das cartas e da interface. Sem criar instâncias.
    if(_nevoa>0.005) {
        for(var _n=0;_n<12;_n++) {
            var _larg=_w*(0.34+0.035*(_n mod 3));
            var _cx=_x- _larg + ((_t*(9+_n*1.7)+_n*_w*0.23) mod (_w+_larg*2));
            if((_n mod 2)==1) _cx=_x+_w-(_cx-_x);
            var _base_y=_y+_h*(0.08+_n*0.075)+sin(_t*0.23+_n)*_h*0.018;
            for(var _lado=-1;_lado<=1;_lado+=2) {
                draw_primitive_begin(pr_trianglestrip);
                for(var _i=0;_i<=28;_i++) {
                    var _p=_i/28;
                    var _px=_cx+(_p-0.5)*_larg;
                    var _py=_base_y+sin(_p*pi*2+_t*0.3+_n)*_h*0.012;
                    var _perfil=power(sin(_p*pi),2);
                    var _espessura=_h*(0.032+0.014*sin(_p*pi+_n))*_perfil;
                    draw_vertex_color(_px,_py,make_color_rgb(187,190,193),_nevoa*_perfil*0.19);
                    draw_vertex_color(_px,_py+_lado*_espessura,c_white,0);
                }
                draw_primitive_end();
            }
        }
    }
    // Pingos esparsos, com pausas e uma pequena ondulação ao tocar a mesa.
    // Posições determinísticas não consomem o gerador dos dados da partida.
    if(_chuva>0.005) {
        draw_set_color(make_color_rgb(185,190,192));
        for(var _i=0;_i<5;_i++) {
            var _ciclo=4.7+_i*0.61;
            var _agora=_t+_i*1.13;
            var _fase=_agora mod _ciclo;
            var _volta=floor(_agora/_ciclo);
            var _fx=0.08+0.84*frac(abs(sin(_volta*12.71+_i*37.21+4)*437.13));
            var _fy=0.24+0.56*frac(abs(sin(_volta*7.17+_i*19.81+9)*179.17));
            var _dx=_x+_fx*_w, _dy=_y+_fy*_h;
            if(_fase<0.48) {
                var _p=_fase/0.48;
                var _py=lerp(_y-16,_dy,_p*_p);
                var _px=_dx+12*(1-_p);
                draw_set_alpha(_chuva*0.28*sin(_p*pi*0.8));
                draw_line(_px,_py,_px+1,_py-8-7*_p);
            } else if(_fase<1.03) {
                var _p=(_fase-0.48)/0.55;
                var _r=2+_p*9;
                draw_set_alpha(_chuva*0.23*sqr(1-_p));
                draw_ellipse(_dx-_r,_dy-_r*0.28,_dx+_r,_dy+_r*0.28,true);
                if(_p<0.35) {
                    draw_line(_dx-3,_dy-1,_dx-5,_dy-4);
                    draw_line(_dx+3,_dy-1,_dx+5,_dy-3);
                }
            }
        }
    }
    draw_set_alpha(_a); draw_set_color(_cor);
}

function mesa_ambiente_desenhar(_ambiente, _x, _y, _w, _h) {
    // Apenas o fundo recebe a correção; slots, cartas e HUD mantêm suas cores.
    var _cinza = shader_is_compiled(shd_mesa_cinza);
    if (_cinza) shader_set(shd_mesa_cinza);
    var _soma = 0;
    for (var _i = 0; _i < 4; _i++) {
        var _peso = _ambiente.pesos[_i];
        if (_peso <= 0) continue;
        _soma += _peso;
        // Alpha composto mantém o brilho constante no meio da transição.
        draw_sprite_stretched_ext(spr_mesa_madeira, _i, _x, _y, _w, _h, c_white, _peso/_soma);
    }
    if (_cinza) shader_reset();
}

// Coordenadas da peça física; os slots e suas áreas de interação não mudam.
function tabuleiro_couro_desenhar(_ambiente, _x = 248, _y = -26, _w = 690, _h = 580) {
    draw_sprite_stretched_ext(spr_tabuleiro_couro, 0, _x+3, _y+7, _w, _h, c_black, 0.28);
    var _papel = shader_is_compiled(shd_mesa_cinza);
    if (_papel) shader_set(shd_mesa_cinza);
    draw_sprite_stretched_ext(spr_tabuleiro_couro, 0, _x, _y, _w, _h, c_white, 1);
    if (_papel) shader_reset();

    // Pequenos vestígios de terreno nas bordas, em grafite. Nenhuma partícula
    // cobre cartas e nenhuma chamada aleatória interfere nos dados da partida.
    for (var _lado = 0; _lado < 2; _lado++) {
        var _ex = _x + _w * (_lado == 0 ? 0.055 : 0.945);
        var _ey = _y + _h * (_lado == 0 ? 0.57 : 0.11);
        var _direcao = _lado == 0 ? 1 : -1;
        for (var _i = 0; _i < 5; _i++) {
            var _py = _ey + _i * _h * 0.045;
            var _dx = _direcao * _w * (0.012 + 0.004 * sin(_i*7));
            draw_set_color(make_color_rgb(16,16,16));
            draw_set_alpha(_ambiente.pesos[1]*0.55);
            draw_line_width(_ex,_py,_ex+_dx,_py+8,2);
            draw_line(_ex+_dx,_py+8,_ex+_dx*0.7,_py+18);
            draw_line(_ex+_dx,_py+8,_ex+_dx*2,_py+5);
            draw_set_color(make_color_rgb(160,160,160));
            draw_set_alpha(_ambiente.pesos[2]*0.24);
            for (var _j=0; _j<5; _j++) {
                var _po = _direcao * (3 + _j*3);
                draw_line(_ex+_po,_py+sin(_j*8+_i)*9,_ex+_po+2,_py+sin(_j*8+_i)*9+1);
            }
            draw_set_color(c_black);
            draw_set_alpha(_ambiente.pesos[3]*0.65);
            draw_line(_ex,_py,_ex+_dx*1.5,_py+5);
            draw_line(_ex+_dx*1.5,_py+5,_ex+_dx,_py+9);
            draw_line(_ex+_dx,_py+9,_ex+_dx*2.5,_py+15);
        }
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

function tabuleiro_couro_gravuras() {
    draw_set_color(make_color_rgb(140,140,140));
    draw_set_alpha(0.18);
    // Corredores do campo, entre as molduras, como sulcos feitos à mão.
    for (var _i=0; _i<4; _i++) {
        var _gx = 495 + _i*54;
        draw_line(_gx,16,_gx+0.6,250);
        draw_line(_gx+0.6,250,_gx,496);
    }
    draw_line(496,77,656,77.5);
    draw_line(496,430.5,656,430);
    draw_line(495,287.5,657,288);
    draw_line(301,449,475,449.5);
    draw_line(680,190,854,190.5);

    // Selo gravado em uma área livre, ao lado do terreno.
    draw_set_alpha(0.28);
    draw_line(329,259,352,244);
    draw_line(352,244,375,259);
    draw_line(375,259,352,274);
    draw_line(352,274,329,259);
    draw_ellipse(339,254,365,264,true);
    draw_circle(352,259,3,true);
    var _fonte = draw_get_font(), _ha = draw_get_halign(), _va = draw_get_valign();
    draw_set_font(Fontenil);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(352,288,"K A R T H A",0.32,0.32,0);
    draw_set_font(_fonte);
    draw_set_halign(_ha);
    draw_set_valign(_va);
    draw_set_alpha(1);
    draw_set_color(c_white);
}
