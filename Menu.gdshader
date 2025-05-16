shader_type canvas_item;

uniform float pixel_size = 50.0;

float grid(vec2 uv, float velocity, float iTime)
{
    vec2 size = vec2(uv.y, uv.y * uv.y * 0.2) * 0.01;
    uv += vec2(0.0, iTime * 4.0 * (velocity + 0.05));
    uv = abs(fract(uv) - 0.5);
 	vec2 lines = smoothstep(size, vec2(0.0), uv);
 	lines += smoothstep(size * 5.0, vec2(0.0), uv) * 0.4 * velocity;
    return clamp(lines.x + lines.y, 0.0, 3.0);
}


void fragment()
{
    vec2 uv = (UV - 0.5) * 2.0;
	uv = floor(uv * pixel_size) / pixel_size;
    float velocity = 0.30;
   
    {
        // Grid
        vec3 col_0 = vec3(0.6, 0.0, 1.0) * 0.85;
        vec3 col_1 = vec3(1.0, 0.75, 0.0) * 0.5;
		vec3 bg_col = vec3(0.0);
		
		float gridVal = 0.0;
		if (uv.y < 1.0) {
			uv.y = 2.0 / (abs(uv.y + 0.0) * 1.0);
			uv.x *= uv.y - 1.01;
			gridVal = clamp(grid(uv, velocity, TIME), 0.0, 1.0);
		}
		
		float theta = (sin(TIME) + 1.0) * 0.5;
		COLOR.rgb = mix(bg_col, mix(col_0, col_1, theta), gridVal);
	}
}