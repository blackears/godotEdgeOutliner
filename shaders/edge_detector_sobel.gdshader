// Edge Detector with Sobel kernel
//
// Created by Mark McKay 2025
//
//Reference
//https://github.com/KodyJKing/hello-threejs/blob/main/src/RenderPixelatedPass.ts
//https://godotshaders.com/shader/simple-sobel-filter/

shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D norm_rough_texture : hint_normal_roughness_texture;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 background_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float normals_weight = .5;
uniform float depth_weight = .01;

uniform int kernel_radius:hint_range(1, 100, 1) = 1;
uniform float normal_cutoff = .5;
uniform float normal_cutoff_radius:hint_range(0, 100, .001) = .1;

void vertex() {
	//Reposition 2x2 quad at origin to cover viewport
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float sobel_kernel_x(ivec2 pos) {
	//https://stackoverflow.com/questions/9567882/sobel-filter-kernel-of-large-size
	return float(pos.x) / float(pos.x * pos.x + pos.y * pos.y);
}

float sobel_kernel_y(ivec2 pos) {
	//https://stackoverflow.com/questions/9567882/sobel-filter-kernel-of-large-size
	return float(pos.y) / float(pos.x * pos.x + pos.y * pos.y);
}

void fragment() {
//	vec3 normal = texelFetch(norm_rough_texture, ivec2(SCREEN_UV * VIEWPORT_SIZE) + ivec2(1, 0), 0).rgb * 2.0 - 1.0;
	
	vec3 normal_dx_sum = vec3(0, 0, 0);
	vec3 normal_dy_sum = vec3(0, 0, 0);
	float kernel_abs_sum = 0.0;
	for (int j = -kernel_radius; j <= kernel_radius; ++j)
		for (int i = -kernel_radius; i <= kernel_radius; ++i)
		{
			if (i == 0 && j == 0)
				continue;
			
			ivec2 offset_co = ivec2(i, j);
			float kx = sobel_kernel_x(offset_co);
			float ky = sobel_kernel_y(offset_co);
			kernel_abs_sum += abs(kx);
		
			vec3 normal = texelFetch(norm_rough_texture, 
				ivec2(SCREEN_UV * VIEWPORT_SIZE) + offset_co, 0).rgb * 2.0 - 1.0;
			normal_dx_sum += normal * kx;
			normal_dy_sum += normal * ky;
		}
	
	float normal_mask = (length(normal_dx_sum) + length(normal_dy_sum)) / kernel_abs_sum;
//	ALBEDO = mix(background_color, line_color, smoothstep(normal_mask, normal_cutoff_min, normal_cutoff_max)).rgb;
//	vec4 final_col = mix(background_color, line_color, normal_mask);
	vec4 final_col = mix(background_color, line_color, 
		smoothstep(normal_cutoff - normal_cutoff_radius, normal_cutoff + normal_cutoff_radius, normal_mask));
	ALBEDO = final_col.rgb;
	ALPHA = final_col.a;
	
//	ALBEDO = normal;
//	ALBEDO = normal_dx_sum + normal_dy_sum * 1.0;
//	ALBEDO = (length(normal_dx_sum) + length(normal_dy_sum)) / kernel_abs_sum * vec3(1, 1, 1);
	
	
//	ALBEDO = 100.0 * normal_dy_sum / weight_sum;
//	ALBEDO = 100.0 * normal_dx_sum / weight_sum;
//	ALBEDO = vec3(1, 1, 1) * length(normal_dx_sum);
//	ALBEDO = vec3(1, 1, 1) * sobel_kernel_x(ivec2(1, 1));
	
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
