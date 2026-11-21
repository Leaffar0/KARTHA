varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_superficie;

void main() {
    vec4 texel = texture2D(gm_BaseTexture, v_vTexcoord);
    float gray = dot(texel.rgb, vec3(0.299, 0.587, 0.114));
    // Luz difusa sobre o campo; as extremidades voltam ao tom do carvão.
    vec2 pos = (v_superficie - vec2(0.49, 0.46)) * vec2(1.35, 1.0);
    float luz = 1.0 - smoothstep(0.15, 0.80, length(pos));
    float tom = gray * (0.84 + 0.24 * luz) + 0.025 + 0.038 * luz;
    gl_FragColor = vec4(vec3(tom), texel.a) * v_vColour;
}
