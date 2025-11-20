-- Update traffic_general to require LineString
UPDATE public.report_categories
SET requires_geometry_type = 'linestring'
WHERE name = 'traffic_general';

-- Insert new category blocked_line
INSERT INTO public.report_categories (id, name, type, requires_geometry_type, icon, color, sort_order)
VALUES (11, 'blocked_line', 'incident', 'linestring', 'TrafficCone', 'bg-orange-100', 11)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    requires_geometry_type = EXCLUDED.requires_geometry_type,
    icon = EXCLUDED.icon,
    color = EXCLUDED.color,
    sort_order = EXCLUDED.sort_order;
