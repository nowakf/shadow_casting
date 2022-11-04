
float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
	vec2 jittered = texture_coords + vec2(0.01 - random(texture_coords) * 0.02, 0.0);
	return Texel(tex, jittered);
}
