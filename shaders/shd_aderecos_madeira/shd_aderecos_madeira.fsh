varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform vec4 u_uv;
uniform vec2 u_passo;

// Mistura em alfa pré-multiplicado, evitando um halo nas bordas transparentes.
vec4 tinta(vec2 deslocamento) {
    vec2 uv = v_vTexcoord + deslocamento * u_passo;
    if (any(lessThan(uv, u_uv.xy)) || any(greaterThanEqual(uv, u_uv.zw))) return vec4(0.0);
    vec4 c = texture2D(gm_BaseTexture, uv);
    return vec4(c.rgb * c.a, c.a);
}

void main() {
    vec4 c = 4.0 * tinta(vec2(0.0));
    c += 2.0 * (tinta(vec2(-1.0, 0.0)) + tinta(vec2(1.0, 0.0))
              + tinta(vec2(0.0, -1.0)) + tinta(vec2(0.0, 1.0)));
    c += tinta(vec2(-1.0, -1.0)) + tinta(vec2(1.0, -1.0))
       + tinta(vec2(-1.0, 1.0)) + tinta(vec2(1.0, 1.0));
    gl_FragColor = vec4(c.rgb / max(c.a, 0.0001), c.a / 16.0) * v_vColour;
}
