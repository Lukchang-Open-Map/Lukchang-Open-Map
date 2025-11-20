-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.audit_log (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  action USER-DEFINED NOT NULL,
  target_type text,
  target_id uuid,
  details jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT audit_log_pkey PRIMARY KEY (id),
  CONSTRAINT audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.banned_words (
  word text NOT NULL,
  severity text DEFAULT 'medium'::text CHECK (severity = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text])),
  added_by uuid,
  added_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT banned_words_pkey PRIMARY KEY (word),
  CONSTRAINT banned_words_added_by_fkey FOREIGN KEY (added_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.campus_boundaries (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  geometry USER-DEFINED NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT campus_boundaries_pkey PRIMARY KEY (id)
);
CREATE TABLE public.map_pins (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  pin_type USER-DEFINED NOT NULL DEFAULT 'general'::pin_type_enum,
  category text NOT NULL,
  icon text,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  title text,
  description text,
  is_anonymous boolean NOT NULL DEFAULT false,
  visibility USER-DEFINED NOT NULL DEFAULT 'public'::pin_visibility_enum,
  status USER-DEFINED NOT NULL DEFAULT 'active'::pin_status_enum,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT map_pins_pkey PRIMARY KEY (id),
  CONSTRAINT map_pins_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.post_reports (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  report_id uuid NOT NULL,
  reported_by uuid NOT NULL,
  reason text NOT NULL CHECK (char_length(reason) >= 1 AND char_length(reason) <= 500),
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'reviewed'::text, 'dismissed'::text])),
  reviewed_by uuid,
  reviewed_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT post_reports_pkey PRIMARY KEY (id),
  CONSTRAINT post_reports_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id),
  CONSTRAINT post_reports_reported_by_fkey FOREIGN KEY (reported_by) REFERENCES public.profiles(id),
  CONSTRAINT post_reports_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  email text NOT NULL UNIQUE,
  full_name text,
  role USER-DEFINED NOT NULL DEFAULT 'member'::role_enum,
  is_banned boolean NOT NULL DEFAULT false,
  ban_reason text,
  banned_at timestamp with time zone,
  banned_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id),
  CONSTRAINT profiles_banned_by_fkey FOREIGN KEY (banned_by) REFERENCES auth.users(id)
);
CREATE TABLE public.report_categories (
  id integer NOT NULL,
  name text NOT NULL,
  name_th text,
  type USER-DEFINED NOT NULL,
  requires_geometry_type USER-DEFINED NOT NULL DEFAULT 'point'::geometry_type_enum,
  special_flag text,
  icon text,
  color text,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer DEFAULT 0,
  CONSTRAINT report_categories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.report_comments (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  report_id uuid NOT NULL,
  user_id uuid NOT NULL,
  body text NOT NULL CHECK (char_length(body) >= 1 AND char_length(body) <= 500),
  is_anonymous boolean NOT NULL DEFAULT false,
  is_deleted boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT report_comments_pkey PRIMARY KEY (id),
  CONSTRAINT report_comments_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id),
  CONSTRAINT report_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.report_photos (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  report_id uuid NOT NULL,
  storage_path text NOT NULL,
  blurred_path text,
  blur_status USER-DEFINED NOT NULL DEFAULT 'pending'::blur_status_enum,
  blur_error text,
  file_size integer,
  mime_type text,
  uploaded_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT report_photos_pkey PRIMARY KEY (id),
  CONSTRAINT report_photos_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id)
);
CREATE TABLE public.report_verifications (
  report_id uuid NOT NULL,
  user_id uuid NOT NULL,
  vote smallint NOT NULL CHECK (vote = ANY (ARRAY[1, '-1'::integer])),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT report_verifications_pkey PRIMARY KEY (report_id, user_id),
  CONSTRAINT report_verifications_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id),
  CONSTRAINT report_verifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.reports (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  created_by_user_id uuid,
  category_id integer NOT NULL,
  title text NOT NULL CHECK (char_length(title) >= 3 AND char_length(title) <= 200),
  description text CHECK (char_length(description) <= 2000),
  geometry USER-DEFINED NOT NULL,
  status USER-DEFINED NOT NULL DEFAULT 'pending'::report_status_enum,
  is_anonymous boolean NOT NULL DEFAULT true,
  visibility USER-DEFINED NOT NULL DEFAULT 'public'::report_visibility_enum,
  is_emergency boolean NOT NULL DEFAULT false,
  assigned_zone_id uuid,
  resolved_by_user_id uuid,
  resolved_at timestamp with time zone,
  resolution_note text,
  verification_score integer NOT NULL DEFAULT 0,
  view_count integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT reports_pkey PRIMARY KEY (id),
  CONSTRAINT reports_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES public.profiles(id),
  CONSTRAINT reports_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.report_categories(id),
  CONSTRAINT reports_assigned_zone_id_fkey FOREIGN KEY (assigned_zone_id) REFERENCES public.security_zones(id),
  CONSTRAINT reports_resolved_by_user_id_fkey FOREIGN KEY (resolved_by_user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.security_posts (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  guard_user_id uuid,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  location USER-DEFINED NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT security_posts_pkey PRIMARY KEY (id),
  CONSTRAINT security_posts_guard_user_id_fkey FOREIGN KEY (guard_user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.security_zone_assignments (
  security_user_id uuid NOT NULL,
  zone_id uuid NOT NULL,
  assigned_at timestamp with time zone NOT NULL DEFAULT now(),
  assigned_by uuid,
  CONSTRAINT security_zone_assignments_pkey PRIMARY KEY (security_user_id, zone_id),
  CONSTRAINT security_zone_assignments_security_user_id_fkey FOREIGN KEY (security_user_id) REFERENCES public.profiles(id),
  CONSTRAINT security_zone_assignments_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.security_zones(id),
  CONSTRAINT security_zone_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.security_zones (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  geometry USER-DEFINED NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT security_zones_pkey PRIMARY KEY (id)
);
CREATE TABLE public.spatial_ref_sys (
  srid integer NOT NULL CHECK (srid > 0 AND srid <= 998999),
  auth_name character varying,
  auth_srid integer,
  srtext character varying,
  proj4text character varying,
  CONSTRAINT spatial_ref_sys_pkey PRIMARY KEY (srid)
);

-- Seed data for report_categories
INSERT INTO public.report_categories (id, name, type, requires_geometry_type, icon, color, sort_order)
VALUES
  (1, 'accident', 'incident', 'point', 'AlertTriangle', 'bg-red-100', 1),
  (2, 'blocked', 'incident', 'point', 'TrafficCone', 'bg-orange-100', 2),
  (3, 'beware', 'incident', 'point', 'HelpCircle', 'bg-gray-200', 3),
  (4, 'flood', 'incident', 'point', 'Droplet', 'bg-blue-100', 4),
  (5, 'send_help', 'incident', 'point', 'LifeBuoy', 'bg-red-100', 5),
  (6, 'traffic_general', 'general', 'linestring', 'CarFront', 'bg-red-100', 6),
  (7, 'parking', 'general', 'point', 'ParkingSquare', 'bg-blue-100', 7),
  (8, 'events', 'general', 'point', 'PartyPopper', 'bg-purple-100', 8),
  (9, 'map_chat', 'general', 'point', 'MessageSquare', 'bg-green-100', 9),
  (10, 'lost_found', 'general', 'point', 'Briefcase', 'bg-orange-200', 10),
  (11, 'blocked_line', 'incident', 'linestring', 'TrafficCone', 'bg-orange-100', 11)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  type = EXCLUDED.type,
  requires_geometry_type = EXCLUDED.requires_geometry_type,
  icon = EXCLUDED.icon,
  color = EXCLUDED.color,
  sort_order = EXCLUDED.sort_order;