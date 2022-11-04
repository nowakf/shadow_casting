uniform float u_offset = 0.0;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
	float closest_dist = 99999.0;
	vec2 closest_pos = vec2(0.0);

	for (float x=-1.0; x<=1.0; x++) {
		for (float y=-1.0; y<=1.0; y++) {
			vec2 voffset = texture_coords + vec2(x, y) * u_offset / love_ScreenSize.xy;
			vec2 pos = Texel(tex, voffset).xy;
			float dist = distance(pos, texture_coords);
			if (pos.x != 0.0 && pos.y != 0.0 && dist < closest_dist) {
				closest_dist = dist;
				closest_pos = pos;
			}
		}
	}
	return vec4(closest_pos, 0.0, 1.0);
}
