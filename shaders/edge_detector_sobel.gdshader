// Edge Detector with Sobel kernel
//
// Copyright Mark McKay 2025

// Reference
// https://github.com/KodyJKing/hello-threejs/blob/main/src/RenderPixelatedPass.ts
// https://godotshaders.com/shader/simple-sobel-filter/

// MIT License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable;
uniform sampler2D norm_rough_texture : hint_normal_roughness_texture, repeat_disable;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 background_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);

uniform int detect_type : hint_enum("COMBINED", "NORMAL_ONLY", "DEPTH_ONLY");

uniform bool map_quad_to_viewport = false;
uniform int kernel_radius:hint_range(1, 100, 1) = 1;

uniform float normal_cutoff = .5;
uniform float normal_cutoff_radius:hint_range(0, 10, .001) = .1;

uniform float depth_cutoff = .5;
uniform float depth_cutoff_radius:hint_range(0, 10, .001) = .1;

void vertex() {
	if (map_quad_to_viewport)
		//Reposition 2x2 quad at origin to cover viewport
		POSITION = vec4(-VERTEX.x * 2.0, VERTEX.y * 2.0, 1.0, 1.0);
	else
		//Default model view projection
		POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
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
	float depth_dx_sum = 0.0;
	float depth_dy_sum = 0.0;
	vec3 normal_dx_sum = vec3(0, 0, 0);
	vec3 normal_dy_sum = vec3(0, 0, 0);
	float kernel_abs_sum = 0.0;
	
	for (int j = -kernel_radius; j <= kernel_radius; ++j)
		for (int i = -kernel_radius; i <= kernel_radius; ++i)
		{
			if (i == 0 && j == 0)
				continue;
			
			//Normal
			ivec2 offset_co = ivec2(i, j);
			float kx = sobel_kernel_x(offset_co);
			float ky = sobel_kernel_y(offset_co);
			kernel_abs_sum += abs(kx);
		
			vec3 normal = texelFetch(norm_rough_texture, 
				ivec2(SCREEN_UV * VIEWPORT_SIZE) + offset_co, 0).rgb * 2.0 - 1.0;
			normal_dx_sum += normal * kx;
			normal_dy_sum += normal * ky;
			
			//Depth
			float depth = texelFetch(depth_texture, ivec2(SCREEN_UV * VIEWPORT_SIZE) + offset_co, 0).r;
			vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
			upos.xyz /= upos.w;
			//Position of fragment relative to camera
			vec3 pixel_pos = upos.xyz;
			float linear_depth = -pixel_pos.z;
			
			depth_dx_sum += linear_depth * kx;
			depth_dy_sum += linear_depth * ky;
		}
	
	float normal_mask = (length(normal_dx_sum) + length(normal_dy_sum)) / kernel_abs_sum;
	float depth_mask = sqrt(depth_dx_sum * depth_dx_sum + depth_dy_sum * depth_dy_sum);
	
	if (detect_type == 1) {
		vec4 final_normals_col = mix(background_color, line_color, 
			smoothstep(normal_cutoff - normal_cutoff_radius, normal_cutoff + normal_cutoff_radius, normal_mask));
		ALBEDO = final_normals_col.rgb;
		ALPHA = final_normals_col.a;
	}
	else if (detect_type == 2) {
		vec4 final_depth_col = mix(background_color, line_color, 
			smoothstep(depth_cutoff - depth_cutoff_radius, depth_cutoff + depth_cutoff_radius, depth_mask));
		ALBEDO = final_depth_col.rgb;
		ALPHA = final_depth_col.a;
	}
	else {
		vec4 final_col = mix(background_color, line_color, 
			smoothstep(normal_cutoff - normal_cutoff_radius, normal_cutoff + normal_cutoff_radius, normal_mask) + 
			smoothstep(depth_cutoff - depth_cutoff_radius, depth_cutoff + depth_cutoff_radius, depth_mask)
			);
		ALBEDO = final_col.rgb;
		ALPHA = final_col.a;
	}
	
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
