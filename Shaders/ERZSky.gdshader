shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_front, diffuse_lambert, specular_schlick_ggx, unshaded;


uniform sampler2D base_texture : source_color, filter_nearest;
uniform bool use_texture = true;
uniform float texture_visibility : hint_range(0.0, 2.0) = 1.0;
uniform float texture_transparency : hint_range(0.0, 1.0) = 0.7;
uniform vec2 texture_scale = vec2(1.0, 1.0);
uniform vec2 texture_offset = vec2(0.0, 0.0);
uniform bool texture_on_top = false; // Текстура поверх эффектов или под ними


uniform vec4 nebula_color1 : source_color = vec4(0.1, 0.2, 0.6, 0.7);
uniform vec4 nebula_color2 : source_color = vec4(0.6, 0.1, 0.5, 0.7);
uniform vec4 nebula_color3 : source_color = vec4(0.1, 0.5, 0.3, 0.7);
uniform vec4 star_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);


uniform float star_density : hint_range(0.0, 1.0) = 0.5;
uniform float nebula_density : hint_range(0.0, 1.0) = 0.3;
uniform float star_size : hint_range(0.1, 5.0) = 1.0;
uniform float nebula_scale : hint_range(0.1, 10.0) = 3.0;


uniform float speed : hint_range(0.0, 2.0) = 0.1;
uniform float time_scale : hint_range(0.1, 5.0) = 1.0;
uniform vec2 scroll_direction = vec2(0.1, 0.2);
uniform bool animate_stars = true;
uniform bool animate_nebula = true;
uniform bool animate_texture = false;
uniform vec2 texture_scroll_direction = vec2(0.05, 0.03);


uniform float emission_strength : hint_range(0.0, 10.0) = 1.0;
uniform float texture_emission : hint_range(0.0, 5.0) = 0.5;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.7;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.3;
uniform float specular_value : hint_range(0.0, 1.0) = 0.5;


uniform bool use_rim_effect = false;
uniform float rim_power : hint_range(0.1, 10.0) = 3.0;
uniform vec4 rim_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform bool use_fresnel = false;
uniform float fresnel_power : hint_range(0.1, 10.0) = 2.0;


uniform int octaves : hint_range(1, 8) = 5;
uniform float persistence : hint_range(0.1, 1.0) = 0.5;
uniform float lacunarity : hint_range(1.0, 4.0) = 2.0;


uniform int texture_blend_mode : hint_range(0, 5) = 5; // 0=Multiply, 1=Add, 2=Overlay, 3=Screen, 4=Normal, 5=Soft Light


uniform bool use_texture_mask = false;
uniform float texture_mask_threshold : hint_range(0.0, 1.0) = 0.5;
uniform bool invert_mask = false;


float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}


float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}


float fbm(vec2 uv) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(frequency * uv);
        amplitude *= persistence;
        frequency *= lacunarity;
    }

    return value;
}


float worley(vec2 uv, float scale) {
    vec2 id = floor(uv * scale);
    vec2 gv = fract(uv * scale);

    float min_dist = 1.0;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 offset = vec2(float(x), float(y));

            float rx = random(id + offset);
            float ry = random(id + offset + vec2(12.345, 67.890));
            vec2 pos = vec2(rx, ry) * 0.5 + 0.25;

            float dist = length(gv - pos - offset);
            min_dist = min(min_dist, dist);
        }
    }

    return min_dist;
}


vec3 blend_overlay(vec3 base, vec3 blend) {
    vec3 result;
    for(int i = 0; i < 3; i++) {
        if(base[i] < 0.5) {
            result[i] = 2.0 * base[i] * blend[i];
        } else {
            result[i] = 1.0 - 2.0 * (1.0 - base[i]) * (1.0 - blend[i]);
        }
    }
    return result;
}


vec3 blend_screen(vec3 base, vec3 blend) {
    return 1.0 - (1.0 - base) * (1.0 - blend);
}


vec3 blend_soft_light(vec3 base, vec3 blend) {
    vec3 result;
    for(int i = 0; i < 3; i++) {
        if(blend[i] < 0.5) {
            result[i] = 2.0 * base[i] * blend[i] + base[i] * base[i] * (1.0 - 2.0 * blend[i]);
        } else {
            result[i] = 2.0 * base[i] * (1.0 - blend[i]) + sqrt(base[i]) * (2.0 * blend[i] - 1.0);
        }
    }
    return result;
}

void fragment() {

    vec2 base_uv = UV;


    vec2 moving_uv = base_uv;
    if (animate_nebula) {
        moving_uv += TIME * speed * scroll_direction;
    }


    vec2 texture_uv = base_uv * texture_scale + texture_offset;
    if (animate_texture) {
        texture_uv += TIME * speed * texture_scroll_direction;
    }
    vec4 texture_color = texture(base_texture, texture_uv);


    float texture_mask = 1.0;
    if (use_texture_mask) {
        texture_mask = fbm(base_uv * 2.0);
        texture_mask = step(texture_mask_threshold, texture_mask);
        if (invert_mask) {
            texture_mask = 1.0 - texture_mask;
        }
    }


    float nebula = fbm(moving_uv * nebula_scale);
    nebula = smoothstep(0.4 - nebula_density * 0.4, 0.6 + nebula_density * 0.4, nebula);


    float star_scale = 500.0 / star_size;
    float star_field = step(1.0 - star_density, random(floor(base_uv * star_scale)));
    float star_twinkle = 0.5;
    if (animate_stars) {
        star_twinkle = 0.5 + 0.5 * sin(TIME * time_scale + random(floor(base_uv * 50.0)) * 10.0);
    }
    float stars = star_field * star_twinkle;


    float star_clusters = 1.0 - worley(base_uv, 5.0);
    star_clusters = pow(star_clusters, 8.0) * 0.7;


    float color_mix = fbm(moving_uv * 2.0 + (animate_nebula ? TIME * 0.05 : 0.0));
    vec4 nebula_mix;
    if (color_mix < 0.33) {
        nebula_mix = mix(nebula_color1, nebula_color2, color_mix * 3.0);
    } else if (color_mix < 0.66) {
        nebula_mix = mix(nebula_color2, nebula_color3, (color_mix - 0.33) * 3.0);
    } else {
        nebula_mix = mix(nebula_color3, nebula_color1, (color_mix - 0.66) * 3.0);
    }


    vec4 final_color = mix(vec4(0.0, 0.0, 0.0, 1.0), nebula_mix, nebula * nebula_mix.a * texture_transparency);
    final_color += stars * star_color * texture_transparency;
    final_color += star_clusters * star_color * 0.5 * texture_transparency;


    if (use_texture) {
        vec4 blended_texture = texture_color * vec4(vec3(1.0), texture_visibility * texture_mask);

        if (!texture_on_top) {

            if (texture_blend_mode == 0) {

                final_color.rgb = mix(blended_texture.rgb, final_color.rgb * blended_texture.rgb, texture_transparency);
            } else if (texture_blend_mode == 1) {

                final_color.rgb = blended_texture.rgb + final_color.rgb * texture_transparency;
            } else if (texture_blend_mode == 2) {

                final_color.rgb = blend_overlay(blended_texture.rgb, final_color.rgb);
            } else if (texture_blend_mode == 3) {

                final_color.rgb = blend_screen(blended_texture.rgb, final_color.rgb);
            } else if (texture_blend_mode == 4) {

                final_color.rgb = mix(blended_texture.rgb, final_color.rgb, texture_transparency);
            } else if (texture_blend_mode == 5) {

                final_color.rgb = blend_soft_light(blended_texture.rgb, final_color.rgb);
            }
        } else {

            vec3 base = final_color.rgb;
            vec3 blend = blended_texture.rgb;

            if (texture_blend_mode == 0) {

                final_color.rgb = mix(base, base * blend, blended_texture.a);
            } else if (texture_blend_mode == 1) {

                final_color.rgb = base + blend * blended_texture.a;
            } else if (texture_blend_mode == 2) {

                final_color.rgb = mix(base, blend_overlay(base, blend), blended_texture.a);
            } else if (texture_blend_mode == 3) {

                final_color.rgb = mix(base, blend_screen(base, blend), blended_texture.a);
            } else if (texture_blend_mode == 4) {

                final_color.rgb = mix(base, blend, blended_texture.a);
            } else if (texture_blend_mode == 5) {

                final_color.rgb = mix(base, blend_soft_light(base, blend), blended_texture.a);
            }
        }
    }


    float rim = 0.0;
    if (use_rim_effect) {
        rim = 1.0 - max(dot(NORMAL, VIEW), 0.0);
        rim = pow(rim, rim_power);
        final_color.rgb += rim * rim_color.rgb;
    }


    if (use_fresnel) {
        float fresnel = pow(1.0 - dot(NORMAL, VIEW), fresnel_power);
        final_color.rgb += fresnel * nebula_mix.rgb * 0.5;
    }


    ALBEDO = final_color.rgb;


    if (use_texture && texture_on_top) {
        EMISSION = mix(final_color.rgb * emission_strength, texture_color.rgb * texture_emission, texture_color.a * texture_visibility);
    } else {
        EMISSION = final_color.rgb * emission_strength;
    }

    ROUGHNESS = roughness_value;
    METALLIC = metallic_value;
    SPECULAR = specular_value;
}