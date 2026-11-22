shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// --- Color ---
uniform vec4 base_color : source_color = vec4(0.25, 0.45, 1.0, 1.0);

// --- Soft edges ---
// Half of the BoxMesh size, e.g. size (4, 6, 4) -> half_size (2, 3, 2).
uniform vec3 half_size = vec3(1.0, 1.5, 1.0);
// Must be smaller than the smallest half_size value.
uniform float bevel_radius : hint_range(0.0, 2.0) = 0.3;

// --- Fake ambient occlusion (darkens toward the ground) ---
uniform float ao_height : hint_range(0.1, 20.0) = 3.0;
uniform float ao_strength : hint_range(0.0, 1.0) = 0.3;
uniform float ao_curve : hint_range(0.5, 4.0) = 1.5; // higher = AO stays tighter to the base

varying vec3 local_pos;

void vertex() {
    local_pos = VERTEX;
}

void fragment() {
    // Soft-edge normal (rounded-box approximation)
    vec3 center = vec3(0.0, half_size.y, 0.0);
    vec3 p = local_pos - center;

    float r = clamp(bevel_radius, 0.0001, min(half_size.x, min(half_size.y, half_size.z)));
    vec3 q = abs(p) - (half_size - vec3(r));

    // Flat faces keep their normal; only the bevel zone bends it.
    vec3 n = sign(p) * normalize(max(q, vec3(0.0)) + vec3(0.00001));

    // Object space -> world space -> view space
    NORMAL = normalize((VIEW_MATRIX * vec4(MODEL_NORMAL_MATRIX * n, 0.0)).xyz);

    // Fake AO
    float g = clamp(local_pos.y / ao_height, 0.0, 1.0);
    g = pow(g, 1.0 / ao_curve);
    float ao = mix(1.0 - ao_strength, 1.0, g);

    ALBEDO = base_color.rgb * ao;
    ROUGHNESS = 1.0;
}