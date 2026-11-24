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
    if (_cinza) {
        shader_set(shd_mesa_cinza);
        shader_set_uniform_f(shader_get_uniform(shd_mesa_cinza, "u_area"), _x, _y, _w, _h);
    }
    var _soma = 0;
    for (var _i = 0; _i < 4; _i++) {
        var _peso = _ambiente.pesos[_i];
        if (_peso <= 0) continue;
        _soma += _peso;
        // Alpha composto mantém o brilho constante no meio da transição.
        draw_sprite_stretched_ext(spr_mesa_madeira, _i, _x, _y, _w, _h, make_color_rgb(221, 215, 207), _peso/_soma);
    }
    if (_cinza) shader_reset();
}

// Coordenadas relativas ao recorte do couro, para alinhar os dois bolsões de
// madeira exposta tanto na sala quanto no laboratório. A base de cada peça fica na tábua.
function mesa_desenhar_aderecos(_ambiente, _x, _y, _w, _h) {
    static _grupos = [
        [],
        [[0,137,154,45], [1,160,157,32], [0,578,392,46], [1,598,394,30], [1,509,526,38]],
        [[3,148,154,33], [2,578,392,44], [3,600,395,25], [2,517,527,29]],
        [[4,145,155,50], [5,577,390,34], [4,595,394,38], [4,510,526,42]]
    ];
    var _sx = _w/690, _sy = _h/580;
    var _sw = sprite_get_width(spr_aderecos_terreno), _sh = sprite_get_height(spr_aderecos_terreno);
    var _cor = draw_get_color(), _alpha = draw_get_alpha();
    var _suavizar = shader_is_compiled(shd_aderecos_madeira);
    static _u_uv = shader_get_uniform(shd_aderecos_madeira,"u_uv");
    static _u_passo = shader_get_uniform(shd_aderecos_madeira,"u_passo");
    for (var _terreno=1; _terreno<array_length(_grupos); _terreno++) {
        var _peso = _ambiente.pesos[_terreno];
        if (_peso < 0.008) continue;
        var _pecas = _grupos[_terreno];
        for (var i=0; i<array_length(_pecas); i++) {
            var _peca = _pecas[i];
            var _atraso = (i mod 3)*0.09;
            var _p = clamp((_peso-_atraso)/(1-_atraso),0,1);
            if (_p <= 0) continue;
            var _base_x = _x+_peca[1]*_sx, _base_y = _y+_peca[2]*_sy;
            var _largura = _peca[3], _esc = _largura/_sw;
            var _fenda = _largura*_sx*0.61*min(1,_p*3);

            // A fenda abre antes de a silhueta passar pela superfície.
            draw_set_alpha(0.28*_alpha*min(1,_p*3));
            draw_set_color(make_color_rgb(26,23,22));
            draw_triangle(_base_x-_fenda,_base_y+2*_sy,_base_x-_fenda*0.16,_base_y-2*_sy,
                _base_x+_fenda*0.75,_base_y,false);
            draw_line_width(_base_x,_base_y,_base_x+_fenda,_base_y-1.5*_sy,max(1,_sy));
            draw_set_color(make_color_rgb(108,95,77));
            draw_line(_base_x-_fenda*0.75,_base_y+2*_sy,_base_x-_fenda*0.15,_base_y+_sy);

            // Somente a parte já emersa fica acima da fenda. A pedra mantém a forma.
            var _recorte = max(1,ceil(_sh*_p));
            var _ex = _esc*_sx, _ey = _esc*_sy;
            var _ang = _terreno == 1 ? sin(_ambiente.tempo*1.4+i*1.9)*2*min(1,fator_efeitos_visuais()) : 0;
            var _meia_w = _sw*_ex*0.5, _altura = _recorte*_ey;
            var _ox = _base_x-_meia_w*dcos(_ang)-_altura*dsin(_ang);
            var _oy = _base_y+_meia_w*dsin(_ang)-_altura*dcos(_ang);
            draw_set_alpha(1);
            var _tinta = make_color_rgb(218,213,204);
            if (_suavizar) {
                shader_set(shd_aderecos_madeira);
                var _textura = sprite_get_texture(spr_aderecos_terreno,_peca[0]);
                var _uv = sprite_get_uvs(spr_aderecos_terreno,_peca[0]);
                shader_set_uniform_f(_u_uv,_uv[0],_uv[1],_uv[2],_uv[3]);
                shader_set_uniform_f(_u_passo,3.2*texture_get_texel_width(_textura),3.2*texture_get_texel_height(_textura));
            }
            draw_sprite_general(spr_aderecos_terreno,_peca[0],0,0,_sw,_recorte,
                _ox,_oy,_ex,_ey,_ang,_tinta,_tinta,_tinta,_tinta,0.82*_alpha*min(1,_p*2.4));
            if (_suavizar) shader_reset();
        }
    }
    draw_set_color(_cor);
    draw_set_alpha(_alpha);
}

// Coordenadas da peça física; os slots e suas áreas de interação não mudam.
function tabuleiro_couro_desenhar(_ambiente, _x = 248, _y = -26, _w = 690, _h = 580) {
    mesa_desenhar_aderecos(_ambiente,_x,_y,_w,_h);
    draw_sprite_stretched_ext(spr_tabuleiro_couro, 0, _x+3, _y+7, _w, _h, c_black, 0.28);
    var _papel = shader_is_compiled(shd_mesa_cinza);
    if (_papel) {
        shader_set(shd_mesa_cinza);
        shader_set_uniform_f(shader_get_uniform(shd_mesa_cinza, "u_area"), _x, _y, _w, _h);
    }
    draw_sprite_stretched_ext(spr_tabuleiro_couro, 0, _x, _y, _w, _h, c_white, 1);
    if (_papel) shader_reset();
}

function tabuleiro_couro_gravuras(_piscada) {
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
    draw_line(301,449,475,449.5);
    draw_line(680,190,854,190.5);

    // Filetes com pontas em losango delimitam a fileira central pelos dois lados.
    draw_set_color(make_color_rgb(200, 187, 164));
    draw_set_alpha(0.48);
    for (var _j = 0; _j < 2; _j++) {
        var _fy = 218.5 + _j * 69;
        draw_line(491, _fy, 661, _fy);
        for (var _k = 0; _k < 4; _k++) {
            var _fx = 495 + _k * 54;
            draw_triangle(_fx-3, _fy, _fx, _fy-2, _fx+3, _fy, false);
            draw_triangle(_fx-3, _fy, _fx, _fy+2, _fx+3, _fy, false);
        }
    }

    // O mesmo olho do baralho, estampado a seco entre a costura e o terreno.
    draw_set_alpha(1);
    var _fechar = min(1, fator_efeitos_visuais()) * round(sin(_piscada * pi) * 2) * 0.47;
    var _piscar = _fechar > 0 && shader_is_compiled(shd_piscar_selo);
    if (_piscar) {
        static _recorte = shader_get_uniform(shd_piscar_selo, "u_recorte");
        static _pixels = shader_get_uniform(shd_piscar_selo, "u_pixels");
        static _fechamento = shader_get_uniform(shd_piscar_selo, "u_fechamento");
        var _uv = sprite_get_uvs(spr_selo_espinhos, 0);
        shader_set(shd_piscar_selo);
        shader_set_uniform_f(_recorte, _uv[0], _uv[1], _uv[2], _uv[3]);
        shader_set_uniform_f(_pixels, _uv[4], _uv[5], _uv[6] * sprite_get_width(spr_selo_espinhos),
            _uv[7] * sprite_get_height(spr_selo_espinhos));
        shader_set_uniform_f(_fechamento, _fechar);
    }
    draw_sprite_stretched_ext(spr_selo_espinhos, 0, 294, 229, 105, 52, c_black, 0.70);
    draw_sprite_stretched_ext(spr_selo_espinhos, 0, 294, 228, 105, 52, c_white, 0.46);
    if (_piscar) shader_reset();
    var _fonte = draw_get_font(), _ha = draw_get_halign(), _va = draw_get_valign();
    draw_set_font(Fontenil);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_alpha(0.64);
    draw_text_transformed(346.5,286,"K A R T H A",0.32,0.32,0);
    draw_set_font(_fonte);
    draw_set_halign(_ha);
    draw_set_valign(_va);
    draw_set_alpha(1);
    draw_set_color(c_white);
}
