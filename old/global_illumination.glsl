#define MAX_RAY_STEPS 32

uniform sampler2D u_distance_data;
uniform sampler2D u_scene_data;


#define LIGHT_COUNT 2
uniform vec2 u_lights[LIGHT_COUNT];

bool raymarch(vec2 origin, vec2 dir, out vec2 hit_pos){
	float current_dist = 0.0;
	for (int i=0; i<MAX_RAY_STEPS; i++) {
		vec2 sample_point = origin + dir * current_dist;
		if (sample_point.x > 1.0 || sample_point.x < 0.0 || sample_point.y > 1.0 || sample_point.y < 0.0) {
			return false;
		}
		float dist_to_surface = Texel(u_distance_data, sample_point).r;
		//anything else to encode here?
		if (dist_to_surface < 0.001f) {
			hit_pos = sample_point;
			return true;
		}
		current_dist += dist_to_surface;
	}
	return false;
}

float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

vec3 cast_rays(vec2 origin) {
	vec3 emission = vec3(0.0);
	for (int i=0; i<LIGHT_COUNT; i++) {
		//float dist = length(origin - u_lights[i]) * 0.05;
		////needs some better jitter on light_pos?
		//vec2 jitter = vec2(dist) - vec2(random(origin), random(-origin)) * 2.0 * dist;
		//vec2 light_pos = u_lights[i]-jitter;
		vec2 light_pos = u_lights[i];
		vec2 ray_dir = normalize(light_pos - origin);
		vec2 hit_pos;
		if (raymarch(origin, ray_dir, hit_pos)) {
			emission += Texel(u_scene_data, hit_pos).rgb;
		}
		//emission += raymarch(origin, ray_dir);
	}
	return emission / float(LIGHT_COUNT);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
	return vec4(cast_rays(texture_coords), 1.0) * Texel(tex, texture_coords);
}
