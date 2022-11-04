#pragma language glsl3

uniform sampler2D u_input_tex;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
	vec2 uv = texture_coords;
	ivec2 size = textureSize(u_input_tex, 0);
	if (size.x > size.y) {
		uv.y = (uv.y - 0.5) *  (size.x / size.y) + 0.5;
	} else {
		uv.x = (uv.x - 0.5) *  (size.y / size.x) + 0.5;
	}
	float alpha = Texel(u_input_tex, uv).a;
	return vec4(texture_coords.x * alpha, texture_coords.y * alpha, 0.0, 1.0);
}
