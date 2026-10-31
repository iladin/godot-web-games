shader_type canvas_item;
// Full-screen darkness with a soft circular hole around the lantern.
uniform vec2 light_pos = vec2(200.0, 800.0);
uniform float light_radius = 340.0;
uniform vec4 dark_color : source_color = vec4(0.027, 0.024, 0.051, 1.0);
uniform vec4 danger_color : source_color = vec4(0.886, 0.286, 0.231, 1.0);
uniform float danger = 0.0;
uniform float max_alpha = 0.965;
varying vec2 wpos;

void vertex() {
	wpos = VERTEX;
}

void fragment() {
	float d = distance(wpos, light_pos);
	float t = smoothstep(light_radius * 0.4, light_radius, d);
	float edge = smoothstep(0.35, 0.75, length(UV - vec2(0.5)));
	float vig = danger * edge * 0.55;
	vec3 c = mix(dark_color.rgb, danger_color.rgb * 0.6, vig);
	COLOR = vec4(c, max(t * max_alpha, vig));
}
