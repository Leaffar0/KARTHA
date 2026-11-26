mesa_ambiente_atualizar(ambiente_mesa, mesa_ambiente_terreno(), delta_time/1000000);
tempo_piscada = min(1, tempo_piscada + min(delta_time / 1000000, 0.1) / 0.34);
if (instance_exists(obj_controlador) && obj_controlador.partida_iniciada
    && obj_controlador.turno != turno_do_selo) {
    turno_do_selo = obj_controlador.turno;
    tempo_piscada = 0;
}

// A prévia só consulta a validação existente; não paga nem joga nenhuma carta.
gravura_pronta=false;
gravura_bases = [];
var _arrasto=instance_exists(obj_controlador)?carta_arrastada_local():noone;
var _efeito_arrasto_pronto=false;
if(instance_exists(_arrasto)) {
    var _previa=estado_previa_arrasto(_arrasto);
    if (_arrasto.categoria == "tropa" && _previa.motivo == "" && _previa.pagamento.sucesso) {
        gravura_bases = _previa.alvos;
    }
    if(_previa.pronta) {
        _efeito_arrasto_pronto=true;
        if(is_struct(_previa.perto)) {
            gravura_x=_previa.perto.x; gravura_y=_previa.perto.y; gravura_pronta=true;
        } else if(_arrasto.categoria=="terreno" && instance_exists(obj_slot_terreno)) {
            gravura_x=obj_slot_terreno.x; gravura_y=obj_slot_terreno.y; gravura_pronta=true;
        }
    }
}

if(instance_exists(obj_controlador)) {
    for(var _i=0;_i<8;_i++) {
        var _lado=_i<4?"jogador":"inimigo";
        var _bencao=(_i mod 4)<2;
        var _lista=_lado=="jogador"
            ? (_bencao?obj_controlador.bencaos_jogador:obj_controlador.maldicoes_jogador)
            : (_bencao?obj_controlador.bencaos_inimigo:obj_controlador.maldicoes_inimigo);
        var _ocupado=(_i mod 2)<array_length(_lista);
        var _destino=false;
        if(_efeito_arrasto_pronto) _destino=_arrasto.dono==_lado
            && _arrasto.categoria==(_bencao?"bencao":"maldicao")
            && (_i mod 2)==array_length(_lista);
        gravura_efeitos_hover[_i]=lerp(gravura_efeitos_hover[_i],_destino?1:0,1-exp(-12*min(delta_time/1000000,0.1)));
        gravura_efeitos_pressao[_i]=(_ocupado && !gravura_efeitos_ocupados[_i])?1:max(0,gravura_efeitos_pressao[_i]-delta_time/1000000*5);
        gravura_efeitos_ocupados[_i]=_ocupado;
    }
}
