varying vec2 v_vTexcoord;
varying vec2 v_papel;
varying vec4 v_vColour;
uniform vec4 u_recorte;
uniform vec4 u_pixels;
uniform vec3 u_gesto;

float alcance(vec2 px, vec2 centro, vec2 raio) {
    return 1.0 - smoothstep(0.36, 1.0, length((px - centro) / raio));
}

void main() {
    vec2 uv = v_vTexcoord;
    if (u_gesto.x > 0.5) {
        vec2 px = u_pixels.xy + v_papel * u_pixels.zw;
        float peso;
        if (u_gesto.x < 1.5) {
            peso = alcance(px, vec2(123.5,128.0), vec2(10.0,9.0))
                 + alcance(px, vec2(163.5,128.0), vec2(10.0,9.0))
                 + alcance(px, vec2(146.0,117.0), vec2(8.0,6.0));
        } else {
            peso = alcance(px, vec2(135.0,114.0), vec2(13.0,8.5));
        }
        uv -= u_gesto.yz * peso * (u_recorte.zw - u_recorte.xy) / u_pixels.zw;
    }
    vec4 arte = texture2D(gm_BaseTexture, uv);
    vec2 margem = min(v_papel, 1.0 - v_papel) * vec2(0.75, 1.0);
    float centro = smoothstep(0.0, 0.11, min(margem.x, margem.y));
    // Ondulações largas permanecem estáveis quando a carta gira ou diminui.
    float fibra = sin(v_papel.y * 69.0 + 2.0 * sin(v_papel.x * 11.0));
    vec3 papel = mix(vec3(0.80, 0.75, 0.65), vec3(0.94, 0.92, 0.86), centro) + fibra * 0.008;
    gl_FragColor = vec4(arte.rgb * papel, arte.a) * v_vColour;
}
