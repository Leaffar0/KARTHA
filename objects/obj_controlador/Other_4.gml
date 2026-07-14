// Room Start: identifica a grade pelos slots vermelhos da room.
organizar_grade_batalha();

// descobre a divisão vertical (mesma lógica do campo de batalha: metade de cima = inimigo, de baixo = jogador)
var _todos_y_recurso = [];
with (obj_slot_recurso) {
    if (array_get_index(_todos_y_recurso, y) == -1) array_push(_todos_y_recurso, y);
}
array_sort(_todos_y_recurso, true);

var _meio_recurso = _todos_y_recurso[floor(array_length(_todos_y_recurso) / 2)];

with (obj_slot_recurso) {
    dono = (y >= _meio_recurso) ? "jogador" : "inimigo";
}

var _todos_y_construcao = [];
with (obj_slot_construcao) {
    if (array_get_index(_todos_y_construcao, y) == -1) array_push(_todos_y_construcao, y);
}
array_sort(_todos_y_construcao, true);

var _meio_construcao = _todos_y_construcao[floor(array_length(_todos_y_construcao) / 2)];

with (obj_slot_construcao) {
    dono = (y >= _meio_construcao) ? "jogador" : "inimigo";
}

// organiza a lane das construções SEPARADAMENTE por dono
// (senão a numeração ficava misturada entre jogador e inimigo, não batendo com as lanes do campo de batalha)
function ordenar_lane_por_dono(_obj, _dono_alvo) {
    var _lista = [];
    with (_obj) {
        if (dono == _dono_alvo) array_push(_lista, id);
    }
    
    var _n = array_length(_lista);
    for (var i = 0; i < _n - 1; i++) {
        for (var j = 0; j < _n - i - 1; j++) {
            if (_lista[j].x > _lista[j+1].x) {
                var _temp = _lista[j];
                _lista[j] = _lista[j+1];
                _lista[j+1] = _temp;
            }
        }
    }
    
    for (var i = 0; i < _n; i++) {
        _lista[i].lane = i;
    }
}

ordenar_lane_por_dono(obj_slot_construcao, "jogador");
ordenar_lane_por_dono(obj_slot_construcao, "inimigo");