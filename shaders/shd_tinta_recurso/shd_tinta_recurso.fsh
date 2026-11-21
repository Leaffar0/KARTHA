varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main() {
    vec4 papel = texture2D(gm_BaseTexture, v_vTexcoord);
    float tinta = 1.0 - smoothstep(0.08, 0.92, papel.r);
    gl_FragColor = vec4(v_vColour.rgb, v_vColour.a * tinta * papel.a);
}
