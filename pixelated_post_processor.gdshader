//Based on
//https://github.com/KodyJKing/hello-threejs/blob/main/src/RenderPixelatedPass.ts
//https://godotshaders.com/shader/simple-sobel-filter/


shader_type spatial;
// Prevent the quad from being affected by lighting and fog. This also improves performance.
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D norm_rough_texture : hint_normal_roughness_texture;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 background_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float normals_weight = .5;
uniform float depth_weight = .01;

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

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float edge_weight = 0.0;

	vec2 pixel_delta = 1.0 / VIEWPORT_SIZE;

	vec2 iuv = vec2(SCREEN_UV.x * VIEWPORT_SIZE.x, SCREEN_UV.y * VIEWPORT_SIZE.y);

	//Sample textures
	float depth_data[9];
	vec3 norm_data[9];
	for (int j = 0; j <= 2; ++j)
		for (int i = 0; i <= 2; ++i) {
			vec2 samp_pos = (iuv + vec2(float(i - 1), float(j - 1))) / VIEWPORT_SIZE;

			norm_data[j * 3 + i] = texture(norm_rough_texture, samp_pos).rgb * 2.0 - 1.0;

			float depth = texture(depth_texture, samp_pos).x;
			vec3 ndc = vec3(samp_pos * 2.0 - 1.0, depth);
			vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
			view.xyz /= view.w;
			float linear_depth = -view.z;
			depth_data[j * 3 + i] = linear_depth;
		}

	//Edge detect based on depth differences
	float dx_depth = 0.0, dy_depth = 0.0;
	for (int i = 0; i < 9; ++i)
		dx_depth += kx[i] * depth_data[i];
	for (int i = 0; i < 9; ++i)
		dy_depth += ky[i] * depth_data[i];

	float sobel_depth = sqrt(dx_depth * dx_depth + dy_depth * dy_depth) / 8.0;
	//sobel_depth = log(sobel_depth);

	//Edge detect based on normal variation
	vec3 dx_norm = vec3(0.0, 0.0, 0.0), dy_norm = vec3(0.0, 0.0, 0.0);
	for (int i = 0; i < 9; ++i)
		dx_norm += kx[i] * norm_data[i];
	for (int i = 0; i < 9; ++i)
		dy_norm += ky[i] * norm_data[i];

	float sobel_norm = length(dx_norm * dx_norm + dy_norm * dy_norm) / 8.0;

	edge_weight += sobel_norm * normals_weight  + sobel_depth * depth_weight;
	vec4 final_color = mix(background_color, line_color, smoothstep(0.0, 1.0, edge_weight));
	ALBEDO.rgb = final_color.rgb;
	ALPHA = final_color.a;
	//ALBEDO.rgb = line_color.rgb;
	//ALPHA = line_color.a * clamp(smoothstep(0.0, 1.0, edge_weight), 0.0, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
