//Based on
//https://github.com/KodyJKing/hello-threejs/blob/main/src/RenderPixelatedPass.ts
//https://godotshaders.com/shader/simple-sobel-filter/


shader_type spatial;
// Prevent the quad from being affected by lighting and fog. This also improves performance.
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D norm_rough_texture : hint_normal_roughness_texture;

//// x direction kernel
//const mat3 kx = mat3(
	//vec3(-1, 0, 1),
	//vec3(-2, 0, 2),
	//vec3(-1, 0, 1)
//);
//
//// y direction kernel
//const mat3 ky = mat3(
	//vec3(-1, -2, -1),
	//vec3(0, 0, 0),
	//vec3(1, 2, 1)
//);

// x direction kernel
const float kx[] = {
	-1.0, 0.0, 1.0,
	-2.0, 0.0, 2.0,
	-1.0, 0.0, 1.0
};

// y direction kernel
const float ky[] = {
	-1.0, -2.0, -1.0,
	0.0, 0.0, 0.0,
	1.0, 2.0, 1.0
};

//float get_depth(vec2 uv) {
	//float depth = texture(depth_texture, uv).x;
//
	//vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	//vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	//view.xyz /= view.w;
	//float linear_depth = -view.z;
	//
//}
vec2 pixel_to_screen_uv(vec2 viewport_size, vec2 pixel) {
	return vec2(pixel.x / viewport_size.x, pixel.y / viewport_size.y);
}

float lum(vec4 color) {
	vec4 weights = vec4(.2126, .7152, .0722, .0);
	return dot(color, weights);
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;

//#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
//vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
//#else
//vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
//#endif

	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;

	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;

	vec2 pixel_delta = 1.0 / VIEWPORT_SIZE;

	vec2 iuv = vec2(SCREEN_UV.x * VIEWPORT_SIZE.x, SCREEN_UV.y * VIEWPORT_SIZE.y);
	//vec3 neighbour_left = texture(screen_texture, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0, 0))).rgb;
	//vec3 neighbour_right = texture(screen_texture, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0.5, 0))).rgb;
//
	//vec3 neighbour_top = texture(screen_texture, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0, 0.0))).rgb;
	//vec3 neighbour_bottom = texture(screen_texture, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0, 0.5))).rgb;
	float depth_data[9];
	for (int j = 0; j <= 2; ++j)
		for (int i = 0; i <= 2; ++i) {
			vec2 samp_pos = (iuv + vec2(float(i - 1), float(j - 1))) / VIEWPORT_SIZE;

			float depth = texture(depth_texture, samp_pos).x;
			vec3 ndc = vec3(samp_pos * 2.0 - 1.0, depth);

			vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
			view.xyz /= view.w;
			float linear_depth = -view.z;
			depth_data[j * 3 + i] = linear_depth;
			}

	float dx = 0.0, dy = 0.0;
	for (int i = 0; i < 9; ++i)
		dx += kx[i] * depth_data[i];
	for (int i = 0; i < 9; ++i)
		dy += ky[i] * depth_data[i];

	float sobel = dx * dx + dy * dy;
//	ALBEDO.rgb = vec3(1, 1, 1) * sobel / 100000.0;
	ALBEDO.rgb = vec3(1, 1, 1) * (sobel > .5 ? 1.0 : 0.0);

//	ALBEDO.rgb = texture(screen_texture, SCREEN_UV).rgb;

	// Visualize linear depth
//	ALBEDO.rgb = vec3(fract(linear_depth));

	// Visualize world coordinates
	//ALBEDO.rgb = fract(world_position).xyz;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
