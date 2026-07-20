shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_color_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D metallic_roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D emission_texture : source_color, filter_linear_mipmap_anisotropic;

uniform float midtone_lift : hint_range(0.0, 1.0) = 0.28;
uniform float midtone_gamma : hint_range(0.5, 1.0) = 0.78;
uniform float albedo_gain : hint_range(0.5, 1.5) = 1.05;
uniform float roughness_floor : hint_range(0.0, 1.0) = 0.72;
uniform float roughness_gain : hint_range(0.5, 2.0) = 1.25;
uniform float metallic_gain : hint_range(0.0, 1.5) = 1.0;
uniform float specular_level : hint_range(0.0, 1.0) = 0.18;
uniform float emission_strength : hint_range(0.0, 4.0) = 1.0;

void fragment() {
	vec4 base_color = texture(base_color_texture, UV);
	vec3 metallic_roughness = texture(metallic_roughness_texture, UV).rgb;

	vec3 protected_base = max(base_color.rgb, vec3(0.0001));
	vec3 lifted_midtones = pow(protected_base, vec3(midtone_gamma));
	ALBEDO = clamp(mix(base_color.rgb, lifted_midtones, midtone_lift) * albedo_gain, vec3(0.0), vec3(1.0));
	METALLIC = clamp(metallic_roughness.b * metallic_gain, 0.0, 1.0);
	ROUGHNESS = clamp(max(metallic_roughness.g * roughness_gain, roughness_floor), 0.0, 1.0);
	SPECULAR = specular_level;
	EMISSION = texture(emission_texture, UV).rgb * emission_strength;
}
