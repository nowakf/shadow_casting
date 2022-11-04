uniform sampler2D u_input_tex;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
	vec2 size = love_ScreenSize.xy;
	vec2 uv = texture_coords;
	if (size.x > size.y) {
		uv.y = (uv.y - 0.5) *  (size.x / size.y) + 0.5;
	} else {
		uv.x = (uv.x - 0.5) *  (size.y / size.x) + 0.5;
	}
	vec2 closest_pt = Texel(tex, texture_coords).xy;
	float dist = distance(texture_coords.xy, closest_pt);
	//mod?
	return vec4(vec3(clamp(dist, 0.0, 1.0)), 1.0);
	return Texel(tex, uv);
	
}
