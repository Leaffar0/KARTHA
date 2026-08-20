enum tween_animation {
	//Esses são os originais e estão baoms
	back,
	flat,
	elastic,
	bounce,
	ease,
	//Outras opção (não sei se ficaram boras, pode ser interessante olhar as curvas)
	linear,
	sine_in,    sine_out,    sine_inout,
	quad_in,    quad_out,    quad_inout,
	cubic_in,   cubic_out,   cubic_inout,
	quart_in,   quart_out,   quart_inout,
	quint_in,   quint_out,   quint_inout,
	expo_in,    expo_out,    expo_inout,
	circ_in,    circ_out,    circ_inout,
	back_in,    back_out,    back_inout,
	elastic_in, elastic_out, elastic_inout,
	bounce_in,  bounce_out,  bounce_inout
}

function tween(_object, _variable_name, _value, _animation = tween_animation.back, _time = room_speed, _callback = -1){
	static _anim_names = [
		"back", "flat", "elastic", "bounce", "ease",
		"linear",
		"sine_in",    "sine_out",    "sine_inout",
		"quad_in",    "quad_out",    "quad_inout",
		"cubic_in",   "cubic_out",   "cubic_inout",
		"quart_in",   "quart_out",   "quart_inout",
		"quint_in",   "quint_out",   "quint_inout",
		"expo_in",    "expo_out",    "expo_inout",
		"circ_in",    "circ_out",    "circ_inout",
		"back_in",    "back_out",    "back_inout",
		"elastic_in", "elastic_out", "elastic_inout",
		"bounce_in",  "bounce_out",  "bounce_inout"
	];

	var _anim = is_string(_animation) ? _animation : _anim_names[_animation];

	with (obj_tween) {
		if (object == _object && variable_name == _variable_name) {
			if (value == _value) return id;
			instance_destroy();
		}
	}
	if (_object[$ _variable_name] == _value) return noone;

	var _tween = instance_create_depth(_object.x, _object.y, _object.depth, obj_tween, {
			object: _object,
			variable_name: _variable_name,
			value: _value,
			animation: _anim,
			time: _time,
			anim_curve: animcurve_get_channel(tween_curves, _anim),
			callback: _callback
		});

	return _tween;
}