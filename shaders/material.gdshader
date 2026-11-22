shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.25, 0.45, 1.0, 1.0);

// Set per mesh by script (see below). Local-space bounds of the mesh.
uniform vec3 aabb_center = vec3(0.0);
uniform vec3 half_size = vec3(1.0);

// Soft edges
uniform float bevel_radius : hint_range(0.0, 5.0) = 0.3;

// Fake AO
uniform float ao_height : hint_range(0.1, 30.0) = 3.0;
uniform float ao_strength : hint_range(0.0, 1.0) = 0.3;
uniform float ao_curve : hint_range(0.5, 4.0) = 1.5;

varying vec3 local_pos;
varying vec3 local_normal;

void vertex() {
    local_pos = VERTEX;
    local_normal = NORMAL;
}

void fragment() {
    vec3 p = local_pos - aabb_center;

    float r = clamp(bevel_radius, 0.0001, min(half_size.x, min(half_size.y, half_size.z)) * 0.9);
    vec3 q = abs(p) - (half_size - vec3(r));

    // Only bend normals on edges and corners, i.e. where 2+ axes are inside the bevel zone.
    vec3 inside = step(vec3(0.0), q);
    float edge_amount = step(1.5, inside.x + inside.y + inside.z);

    // Dominant-axis check: only treat a vertex as "on the box surface" if it really is near it.
    float on_surface = step(max(max(q.x, q.y), q.z), r + 0.001) * step(-0.001, max(max(q.x, q.y), q.z));

    vec3 bent = sign(p) * normalize(max(q, vec3(0.0)) + vec3(0.00001));
    vec3 flat_n = normalize(local_normal);
    vec3 n_obj = normalize(mix(flat_n, bent, edge_amount * on_surface));

    NORMAL = normalize((VIEW_MATRIX * vec4(MODEL_NORMAL_MATRIX * n_obj, 0.0)).xyz);

    float h = local_pos.y - (aabb_center.y - half_size.y);
    float g = pow(clamp(h / ao_height, 0.0, 1.0), 1.0 / ao_curve);
    ALBEDO = base_color.rgb * mix(1.0 - ao_strength, 1.0, g);
    ROUGHNESS = 1.0;
}