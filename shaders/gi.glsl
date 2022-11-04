uniform sampler2D u_voronoi_map;
uniform sampler3D u_cloud_map;
#define MAX_RAY_STEPS 64
#define LIGHT_COUNT 1
uniform vec2 u_lights[LIGHT_COUNT];
uniform vec2 sun_dir = vec2(1.0, 0.0);
uniform float u_time = 0.0;

float PHI = 1.61803398874989484830459;
float gold_noise(in vec2 xy, in float seed) {
	return fract(tan(distance(xy*PHI, xy)*seed)*xy.x);
}

vec2 random_vec(in vec2 xy) {
	return vec2(0.5) - vec2(
		gold_noise(xy*1000.0, 0.32213),
		gold_noise(xy*1000.0, 0.83232)
	);
}

float sample_distance(vec2 uv) {
	return clamp(distance(
		uv,
		Texel(u_voronoi_map, uv).xy
	), 0.0, 1.0);
}
float raymarch(float ray_max, vec2 origin, vec2 dir) {
	float current_dist = 0.0;
	for (int i=0; i<MAX_RAY_STEPS; i++) {
		vec2 sample_point = origin + dir * current_dist;
		if (current_dist > ray_max) {
			return 1.0;
		}
		float dist_to_surface = sample_distance(sample_point);
		if (dist_to_surface < 0.001f) {
			return 0.0;
		}
		current_dist += dist_to_surface;
	}
	return 0.0;
}

float cast_rays(vec2 origin) {
	float emission = 0.0;
	float cloud_density = Texel(u_cloud_map, vec3(origin, 0.0)).r;
	for (int i=0; i<LIGHT_COUNT; i++) {
		vec2 jitter = random_vec(origin) * 0.05;
		vec2 light_pos = u_lights[i]  + jitter;
		vec2 diff = light_pos - origin;
		vec2 ray_dir = normalize(diff);
		float ray_len = length(diff);
		float raw = raymarch(ray_len, origin, ray_dir);
		float falloff = pow(1.0 - clamp(ray_len / 5.0, 0.0, 1.0), 15.0);
		emission += raw * 2.0 * (falloff - cloud_density*0.5);
	}
	return clamp(emission, 0.0, 1.0);
}

float diffuse(sampler2D tex, vec2 pos) {
	float acc = 0.0;
	vec2 tx = Texel(tex, pos).ra;
	vec3 normal = normalize(vec3(dFdx(tx.r), dFdy(tx.r), 0.05));
	for (int i=0; i<LIGHT_COUNT; i++) {
		vec3 light_dir = normalize(vec3(
		(pos) -
		(u_lights[i]),
		0.1
		));
		acc += max(0.0, dot(light_dir, normal)) * tx.g;
	}
	return acc;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
	float raycast = cast_rays(texture_coords);
	float diffuse = diffuse(tex, texture_coords);
	float banding = 1.0; //ceil(mod(texture_coords.y, 0.001) - 0.0005);
	return vec4(vec3(0.5 + 0.5 * (raycast + diffuse) * banding), 1.0);
	//return vec4(sample_distance(texture_coords) + u_lights[0].y);
}

