function slot_traco(_x,_y,_sx,_sy,_rot,_x1,_y1,_x2,_y2) {
    var _c=dcos(_rot), _s=dsin(_rot);
    draw_line(_x+_x1*_sx*_c+_y1*_sy*_s,_y-_x1*_sx*_s+_y1*_sy*_c,
        _x+_x2*_sx*_c+_y2*_sy*_s,_y-_x2*_sx*_s+_y2*_sy*_c);
}

function desenhar_slot_gravado(_x,_y,_w,_h,_rot,_cor,_ocupado,_tipo,_hover=0,_pressao=0) {
    var _sx=_w/48, _sy=_h/64;
    var _a=draw_get_alpha(), _c=draw_get_color();
    // Interior translúcido: o próprio couro permanece visível.
    draw_set_color(c_black); draw_set_alpha(_a*(0.10+_pressao*0.12));
    draw_primitive_begin(pr_trianglefan);
    for(var _i=0;_i<4;_i++) {
        var _px=(_i==0||_i==3)?-_w*0.45:_w*0.45;
        var _py=(_i<2)?-_h*0.46:_h*0.46;
        draw_vertex(_x+_px*dcos(_rot)+_py*dsin(_rot),_y-_px*dsin(_rot)+_py*dcos(_rot));
    }
    draw_primitive_end();
    draw_set_alpha(1);
    var _forca=_ocupado?0.45:1;
    // Lábio claro abaixo do sulco escuro: gravado, sem sombra elevada.
    draw_sprite_ext(spr_slot_moldura_v2,0,_x,_y+0.65,
        _w/sprite_get_width(spr_slot_moldura_v2),_h/sprite_get_height(spr_slot_moldura_v2),
        _rot,make_color_rgb(222,211,190),_a*_forca*(0.37+_hover*0.42));
    draw_sprite_ext(spr_slot_gravado,0,_x,_y,
        _w/sprite_get_width(spr_slot_gravado),_h/sprite_get_height(spr_slot_gravado),
        _rot,c_white,_a*_forca*0.92);
    // Cor de categoria restrita a duas pequenas incisões nos cantos.
    draw_set_color(merge_color(make_color_rgb(227,215,190),_cor,0.18));
    draw_set_alpha(_a*_forca*(0.46+_hover*0.48));
    for (var _lado = -1; _lado <= 1; _lado += 2) {
        slot_traco(_x,_y,_sx,_sy,_rot,_lado*20,_lado*23,_lado*20,_lado*27);
        slot_traco(_x,_y,_sx,_sy,_rot,_lado*20,_lado*27,_lado*18,_lado*29);
        slot_traco(_x,_y,_sx,_sy,_rot,_lado*18,_lado*29,_lado*13,_lado*29);
    }
    if (!_ocupado) {
        var _linhas=[];
        switch(_tipo) {
            case "tropa": _linhas=[[-2,4,-2,-5],[-2,-5,0,-8],[0,-8,2,-5],[2,-5,2,4],[-5,4,5,4],[0,4,0,8]]; break;
            case "recurso": _linhas=[[0,-7,5,0],[5,0,0,7],[0,7,-5,0],[-5,0,0,-7],[0,-7,0,7]]; break;
            case "construcao": _linhas=[[-5,7,-5,-6],[-5,-6,-2,-6],[-2,-6,-2,-3],[-2,-3,2,-3],[2,-3,2,-6],[2,-6,5,-6],[5,-6,5,7],[5,7,-5,7]]; break;
            case "terreno": _linhas=[[-8,5,-2,-5],[-2,-5,3,5],[0,0,4,-4],[4,-4,8,5],[-8,5,8,5]]; break;
            case "bencao": _linhas=[[0,-6,4,0],[4,0,0,6],[0,6,-4,0],[-4,0,0,-6],[0,-10,0,-8],[0,8,0,10],[-8,0,-6,0],[6,0,8,0]]; break;
            case "maldicao": _linhas=[[3,-7,-3,-4],[-3,-4,-5,1],[-5,1,-2,6],[-2,6,4,7],[4,7,0,3],[0,3,-1,-1],[-1,-1,3,-7]]; break;
        }
        draw_set_color(make_color_rgb(198,189,171)); draw_set_alpha(_a*(0.41+_hover*0.30));
        for(var _i=0;_i<array_length(_linhas);_i++) {
            var _l=_linhas[_i];
            slot_traco(_x,_y,_sx,_sy,_rot,_l[0],_l[1],_l[2],_l[3]);
        }
    }
    draw_set_alpha(_a); draw_set_color(_c);
}

function atualizar_gravura_slot() {
    var _alvo=false;
    if(instance_exists(obj_tabuleiro)) {
        _alvo=obj_tabuleiro.gravura_pronta
            && abs(x-obj_tabuleiro.gravura_x)<1 && abs(y-obj_tabuleiro.gravura_y)<1;
    }
    gravura_hover=lerp(gravura_hover,_alvo?1:0,1-exp(-12*min(delta_time/1000000,0.1)));
    if(ocupado && !gravura_ocupado_anterior) gravura_pressao=1;
    else gravura_pressao=max(0,gravura_pressao-delta_time/1000000*5);
    gravura_ocupado_anterior=ocupado;
}
