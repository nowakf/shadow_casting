vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
	vec2 uv = texture_coords;
	return vec4(uv * ceil(Texel(tex, uv).a), 0.0, 1.0);
}

