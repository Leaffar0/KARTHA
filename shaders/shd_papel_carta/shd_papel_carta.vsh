attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;
uniform vec4 u_recorte;
varying vec2 v_vTexcoord;
varying vec2 v_papel;
varying vec4 v_vColour;

void main() {
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position, 1.0);
    v_vTexcoord = in_TextureCoord;
    v_papel = (in_TextureCoord - u_recorte.xy) / (u_recorte.zw - u_recorte.xy);
    v_vColour = in_Colour;
}
