function transicao_sala_ativa() {
    return instance_exists(obj_transicao_sala);
}

function trocar_sala_suave(_destino) {
    if (transicao_sala_ativa()) return;
    var _transicao = instance_create_depth(0, 0, -15000, obj_transicao_sala);
    _transicao.destino = _destino;
}

// Arte geométrica própria da passagem: papel cinza, cantos cortados e selo em tinta.
function transicao_desenhar_carta(_x, _y, _w, _h, _angulo, _alpha, _frente) {
    var _co = dcos(_angulo), _si = dsin(_angulo);
    var _px = [-0.42,0.42,0.5,0.5,0.42,-0.42,-0.5,-0.5];
    var _py = [-0.5,-0.5,-0.45,0.45,0.5,0.5,0.45,-0.45];
    draw_set_alpha(_alpha);
    draw_set_color(_frente ? make_color_rgb(199,199,195) : make_color_rgb(120,122,121));
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(_x, _y);
    for (var _i = 0; _i <= 8; _i++) {
        var _j = _i mod 8, _lx = _px[_j]*_w, _ly = _py[_j]*_h;
        draw_vertex(_x+_lx*_co+_ly*_si, _y-_lx*_si+_ly*_co);
    }
    draw_primitive_end();
    draw_set_color(make_color_rgb(32,33,34));
    for (var _b = 0; _b < 2; _b++) {
        var _esc = _b == 0 ? 1 : 0.84;
        draw_primitive_begin(pr_linestrip);
        for (var _i = 0; _i <= 8; _i++) {
            var _j = _i mod 8, _lx = _px[_j]*_w*_esc, _ly = _py[_j]*_h*_esc;
            draw_vertex(_x+_lx*_co+_ly*_si, _y-_lx*_si+_ly*_co);
        }
        draw_primitive_end();
    }
    // Losango alongado envolvendo um olho: sem letras ou arte do menu.
    draw_primitive_begin(pr_linestrip);
    for (var _i = 0; _i <= 4; _i++) {
        var _lx = dsin(_i*90)*_w*0.31, _ly = -dcos(_i*90)*_h*0.32;
        draw_vertex(_x+_lx*_co+_ly*_si, _y-_lx*_si+_ly*_co);
    }
    draw_primitive_end();
    for (var _lado = -1; _lado <= 1; _lado += 2) {
        draw_primitive_begin(pr_linestrip);
        for (var _i = 0; _i <= 20; _i++) {
            var _t = _i/20, _lx = (_t-0.5)*_w*0.47;
            var _ly = sin(_t*pi)*_lado*_h*0.075;
            draw_vertex(_x+_lx*_co+_ly*_si, _y-_lx*_si+_ly*_co);
        }
        draw_primitive_end();
    }
    draw_circle(_x, _y, _w*0.055, false);
}
