shader_type spatial;
render_mode unshaded;

const float EUCLIDEAN_DISTANCE_THRESHOLD = 0.0005;

uniform float horizon_height = 0.0;

uniform vec2 sky_size = vec2(5.0, 5.0);
uniform sampler2D sky_texture : source_color, filter_nearest;
uniform sampler2D horizon_texture : source_color, repeat_enable, filter_nearest;
uniform bool lock_aspect = false;
uniform float aspect_ratio = 1.3333333;
uniform vec2 fov = vec2(180.0, 90.0);
uniform ivec2 tiling = ivec2(1, 1);
uniform vec2 offset = vec2(0.0, 0.0);

uniform float tilt_force = 1.0;
uniform float tilt_speed = 1.0;
uniform int source_color_count = 15;
uniform float color_speed = 0.2;
uniform sampler2D sky_palette_in : source_color, filter_nearest, repeat_enable;
uniform sampler2D sky_palette_out : source_color, filter_linear, repeat_enable;

varying vec4 BG_COORDS;
varying vec3 world_vertex;
uniform float triplanar_blend_sharpness = 0.5;
varying vec3 triplanar_triplanar_pos;
varying vec3 triplanar_power_normal;
uniform vec3 triplanar_texture_scale = vec3(1.0);

float sawtoothWave(float t, float T) {
    return 2.0 * (mod(t / T, 1.0) - 0.5);
}

vec4 sample_remapped(sampler2D original_texture, vec2 uv) {
    float half_texel_increment = 1.0 / float(source_color_count);

    vec4 color = texture(original_texture, uv);

    for (int i = 0; i < source_color_count; i++) {
        float texel_increment = float(i) / float(source_color_count) + half_texel_increment;
        vec3 source_col = texture(sky_palette_in, vec2(texel_increment, 0.0)).rgb;

        float difference = length(source_col - color.rgb);

        if (abs(difference) < EUCLIDEAN_DISTANCE_THRESHOLD) {
            vec4 target_col = texture(sky_palette_out, vec2(texel_increment, TIME * color_speed));
            return target_col;
        }
    }

    return color;
}

void vertex() {
	world_vertex = VERTEX;

	triplanar_power_normal = pow(abs(NORMAL), vec3(triplanar_blend_sharpness));
    triplanar_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0f)).xyz * triplanar_texture_scale;
    triplanar_power_normal /= dot(triplanar_power_normal, vec3(1.0));
    triplanar_triplanar_pos *= vec3(1.0,-1.0, 1.0);

	//Camera YX rotation per Basis.get_euler source code
	float y = atan(VIEW_MATRIX[0][2], VIEW_MATRIX[2][2]);
	float x = asin(VIEW_MATRIX[1][2]);

	//Map rotation to screen space
	BG_COORDS.xy = vec2(y * -0.5, x) / PI;
	BG_COORDS.y += 0.5;

	BG_COORDS.w = fov.y / 180.0;
	BG_COORDS.z = !lock_aspect ? fov.x / 360.0 : VIEWPORT_SIZE.x / (VIEWPORT_SIZE.y * aspect_ratio) * BG_COORDS.w;

	//Keep background centered vertically when FOV changes
	BG_COORDS.y *= BG_COORDS.w > 1.0 ? 0.0 : 1.0 - BG_COORDS.w;
}

vec4 sample_triplanar(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

void fragment() {
	vec2 uv_offset = vec2(-offset.x, offset.y);
	vec2 uv = (SCREEN_UV + uv_offset) * BG_COORDS.zw + BG_COORDS.xy;
	uv *= vec2(tiling);

	if (world_vertex.y > horizon_height) {
		vec2 offset_wave = vec2((uv.y - 0.5) * 0.001 * sin(TIME * tilt_speed) * tilt_force, 0.0);
		ALBEDO = sample_remapped(sky_texture, uv * sky_size + offset_wave).rgb;
	} else {
		// vec2(world_vertex.x * 0.2, -world_vertex.y + horizon_height) * 0.01;

		ALBEDO = sample_triplanar(
			horizon_texture,
			triplanar_power_normal,
			vec3(
				world_vertex.x * 0.2,
				-world_vertex.y + horizon_height,
				world_vertex.z * 0.2
			) * 0.01
		).rgb;
	}
}