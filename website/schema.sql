-- -----------------------------------------------------------------------------
-- File: schema.sql
-- Project: Look Chang Maps
-- Description: Complete SQL schema for the community mapping platform
-- Version: 2.0 - Production Ready
-- -----------------------------------------------------------------------------

-- =============================================================================
-- 1. EXTENSIONS
-- =============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


-- =============================================================================
-- 2. CUSTOM TYPES (ENUMS)
-- =============================================================================
CREATE TYPE public.role_enum AS ENUM (
  'member',
  'security',
  'admin'
);

CREATE TYPE public.report_status_enum AS ENUM (
  'pending',
  'resolved_approved',
  'resolved_rejected'
);

CREATE TYPE public.report_visibility_enum AS ENUM (
  'public',
  'staff_only'
);

CREATE TYPE public.category_type_enum AS ENUM (
  'incident',
  'general'
);

CREATE TYPE public.geometry_type_enum AS ENUM (
  'point',
  'linestring',
  'point_or_linestring'
);

CREATE TYPE public.blur_status_enum AS ENUM (
  'pending',
  'processing',
  'completed',
  'failed'
);

CREATE TYPE public.audit_action_enum AS ENUM (
  'create_report',
  'resolve_report',
  'delete_report',
  'ban_user',
  'unban_user',
  'assign_security_zone',
  'update_report',
  'delete_comment'
);


-- =============================================================================
-- 3. TABLES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Table: profiles
-- Description: User profiles linked to auth.users
-- -----------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text,
  role public.role_enum DEFAULT 'member'::public.role_enum NOT NULL,
  is_banned boolean DEFAULT false NOT NULL,
  ban_reason text,
  banned_at timestamp with time zone,
  banned_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE INDEX profiles_role_idx ON public.profiles(role);
CREATE INDEX profiles_is_banned_idx ON public.profiles(is_banned);

COMMENT ON TABLE public.profiles IS 'User profiles with role-based access control';
COMMENT ON COLUMN public.profiles.role IS 'User role: member (student), security (guard), or admin';
COMMENT ON COLUMN public.profiles.is_banned IS 'Whether user is banned from posting';

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;


-- -----------------------------------------------------------------------------
-- Table: campus_boundaries
-- Description: Geographic boundaries of CMU campus
-- -----------------------------------------------------------------------------
CREATE TABLE public.campus_boundaries (
  id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
  name text NOT NULL,
  description text,
  geometry public.geometry(Polygon, 4326) NOT NULL,
  is_active boolean DEFAULT true NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE INDEX campus_boundaries_geometry_idx ON public.campus_boundaries USING gist (geometry);

COMMENT ON TABLE public.campus_boundaries IS 'Campus boundaries for restricting report locations';

ALTER TABLE public.campus_boundaries ENABLE ROW LEVEL SECURITY;


-- -----------------------------------------------------------------------------
-- Table: security_zones
-- Description: Security guard responsibility zones
-- -----------------------------------------------------------------------------
CREATE TABLE public.security_zones (
  id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
  name text NOT NULL,
  description text,
  geometry public.geometry(Polygon, 4326) NOT NULL,
  is_active boolean DEFAULT true NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE INDEX security_zones_geometry_idx ON public.security_zones USING gist (geometry);
CREATE INDEX security_zones_is_active_idx ON public.security_zones(is_active);

COMMENT ON TABLE public.security_zones IS 'Geographic zones assigned to security officers';

ALTER TABLE public.security_zones ENABLE ROW LEVEL SECURITY;


-- -----------------------------------------------------------------------------
-- Table: report_categories
-- Description: Report types and their configurations
-- -----------------------------------------------------------------------------
CREATE TABLE public.report_categories (
  id int PRIMARY KEY,
  name text NOT NULL,
  name_th text,
  type public.category_type_enum NOT NULL,
  requires_geometry_type public.geometry_type_enum DEFAULT 'point'::public.geometry_type_enum NOT NULL,
  special_flag text,
  icon text,
  color text,
  is_active boolean DEFAULT true NOT NULL,
  sort_order int DEFAULT 0
);

CREATE INDEX report_categories_type_idx ON public.report_categories(type);
CREATE INDEX report_categories_is_active_idx ON public.report_categories(is_active);

COMMENT ON TABLE public.report_categories IS 'Categories for incident and general reports';
COMMENT ON COLUMN public.report_categories.special_flag IS 'Special handling flags: send_help, flood_animation';
COMMENT ON COLUMN public.report_categories.requires_geometry_type IS 'Required geometry: point, linestring, or both';

ALTER TABLE public.report_categories ENABLE ROW LEVEL SECURITY;


-- -----------------------------------------------------------------------------
-- Table: reports
-- Description: Main reports/pins table
-- -----------------------------------------------------------------------------
CREATE TABLE public.reports (
  id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
  created_by_user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  category_id int NOT NULL REFERENCES public.report_categories(id),
  title text NOT NULL CHECK (char_length(title) >= 3 AND char_length(title) <= 200),
  description text CHECK (char_length(description) <= 2000),
  geometry public.geometry(Geometry, 4326) NOT NULL,
  status public.report_status_enum DEFAULT 'pending'::public.report_status_enum NOT NULL,
  is_anonymous boolean DEFAULT true NOT NULL,
  visibility public.report_visibility_enum DEFAULT 'public'::public.report_visibility_enum NOT NULL,
  is_emergency boolean DEFAULT false NOT NULL,
  assigned_zone_id uuid REFERENCES public.security_zones(id) ON DELETE SET NULL,
  resolved_by_user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  resolved_at timestamp with time zone,
  resolution_note text,
  verification_score int DEFAULT 0 NOT NULL,
  view_count int DEFAULT 0 NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE INDEX reports_geometry_idx ON public.reports USING gist (geometry);
CREATE INDEX reports_category_id_idx ON public.reports(category_id);
CREATE INDEX reports_status_idx ON public.reports(status);
CREATE INDEX reports_visibility_idx ON public.reports(visibility);
CREATE INDEX reports_created_at_idx ON public.reports(created_at DESC);
CREATE INDEX reports_assigned_zone_id_idx ON public.reports(assigned_zone_id);
CREATE INDEX reports_created_by_user_id_idx ON public.reports(created_by_user_id);
CREATE INDEX reports_is_emergency_idx ON public.reports(is_emergency) WHERE is_emergency = true;
CREATE INDEX reports_active_public_idx ON public.reports(status, visibility) WHERE status = 'pending' AND visibility = 'public';

COMMENT ON TABLE public.reports IS 'User-submitted incident and general reports';
COMMENT ON COLUMN public.reports.is_emergency IS 'Emergency reports (Send Help) - not shown on public map';
COMMENT ON COLUMN public.reports.verification_score IS 'Crowd verification score (likes - dislikes)';

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;


-- -----------------------------------------------------------------------------
-- Table: report_photos
-- Description: Photos attached to reports
-- -----------------------------------------------------------------------------
CREATE TABLE public.report_photos (
  id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
  report_id uuid NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  blurred_path text,
  blur_status public.blur_status_enum DEFAULT 'pending'::public.blur_status_enum NOT NULL,
  blur_error text,
  file_size int,
  mime_type text,
  uploaded_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE INDEX report_photos_report_id_idx ON public.report_photos(report_id);
CREATE INDEX report_photos_blur_status_idx ON public.report_photos(blur_status);

COMMENT ON TABLE public.report_photos IS 'Photo attachments with automatic face/license plate blurring';

ALTER TABLE public.report_photos ENABLE ROW LEVEL SECURITY;


-- -----------------------------------------------------------------------------
-- Table: security_zone_assignments
-- Description: Many-to-many relationship between security officers and zones
-- -----------------------------------------------------------------------------
CREATE TABLE public.security_zone_assignments (
  security_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  zone_id uuid NOT NULL REFERENCES public.security_zones(id) ON DELETE CASCADE,
  assigned_at timestamp with time zone DEFAULT now() NOT NULL,
  assigned_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  PRIMARY KEY (security_user_id, zone_id)
);

CREATE INDEX security_zone_assignments_zone_id_idx ON public.security_zone_assignments(zone_id);

COMMENT ON TABLE public.security_zone_assignments IS 'Assignment of security officers to zones';

ALTER TABLE public.security_zone_assignments ENABLE ROW LEVEL SECURITY;


-- -----------------------------------------------------------------------------
-- Table: report_verifications
-- Description: User likes/dislikes on reports (crowd verification)
-- -----------------------------------------------------------------------------
CREATE TABLE public.report_verifications (
  report_id uuid NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  vote smallint NOT NULL CHECK (vote IN (1, -1)),
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  PRIMARY KEY (report_id, user_id)
);

CREATE INDEX report_verifications_report_id_idx ON public.report_verifications(report_id);

COMMENT ON TABLE public.report_verifications IS 'User votes on reports (1 = like/verify, -1 = dislike/dispute)';

ALTER TABLE public.report_verifications ENABLE ROW LEVEL SECURITY;


-- -----------------------------------------------------------------------------
-- Table: report_comments
-- Description: User comments on reports
-- -----------------------------------------------------------------------------
CREATE TABLE public.report_comments (
  id bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  report_id uuid NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body text NOT NULL CHECK (char_length(body) >= 1 AND char_length(body) <= 500),
  is_anonymous boolean DEFAULT false NOT NULL,
  is_deleted boolean DEFAULT false NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE INDEX report_comments_report_id_idx ON public.report_comments(report_id);
CREATE INDEX report_comments_user_id_idx ON public.report_comments(user_id);
CREATE INDEX report_comments_created_at_idx ON public.report_comments(created_at DESC);

COMMENT ON TABLE public.report_comments IS 'User comments on reports (map chat feature)';

ALTER TABLE public.report_comments ENABLE ROW LEVEL SECURITY;


-- -----------------------------------------------------------------------------
-- Table: post_reports
-- Description: User reports of inappropriate content
-- -----------------------------------------------------------------------------
CREATE TABLE public.post_reports (
  id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
  report_id uuid NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
  reported_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reason text NOT NULL CHECK (char_length(reason) >= 1 AND char_length(reason) <= 500),
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed')),
  reviewed_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  UNIQUE(report_id, reported_by)
);

CREATE INDEX post_reports_report_id_idx ON public.post_reports(report_id);
CREATE INDEX post_reports_status_idx ON public.post_reports(status);
CREATE INDEX post_reports_created_at_idx ON public.post_reports(created_at DESC);

COMMENT ON TABLE public.post_reports IS 'User reports of inappropriate or false content';

ALTER TABLE public.post_reports ENABLE ROW LEVEL SECURITY;


-- -----------------------------------------------------------------------------
-- Table: banned_words
-- Description: Text moderation blacklist
-- -----------------------------------------------------------------------------
CREATE TABLE public.banned_words (
  word text PRIMARY KEY,
  severity text DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high')),
  added_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  added_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.banned_words IS 'Blacklist for AI text moderation';

ALTER TABLE public.banned_words ENABLE ROW LEVEL SECURITY;


-- -----------------------------------------------------------------------------
-- Table: audit_log
-- Description: Audit trail for important actions
-- -----------------------------------------------------------------------------
CREATE TABLE public.audit_log (
  id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  action public.audit_action_enum NOT NULL,
  target_type text,
  target_id uuid,
  details jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE INDEX audit_log_user_id_idx ON public.audit_log(user_id);
CREATE INDEX audit_log_action_idx ON public.audit_log(action);
CREATE INDEX audit_log_created_at_idx ON public.audit_log(created_at DESC);
CREATE INDEX audit_log_target_idx ON public.audit_log(target_type, target_id);

COMMENT ON TABLE public.audit_log IS 'Audit trail for security and admin actions';

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;


-- =============================================================================
-- 4. DATABASE FUNCTIONS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Function: handle_new_user
-- Description: Auto-create profile when new user signs up
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Only allow @cmu.ac.th emails
  IF NEW.email LIKE '%@cmu.ac.th' THEN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
      'member'
    );
  ELSE
    RAISE EXCEPTION 'Only @cmu.ac.th email addresses are allowed to register.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- -----------------------------------------------------------------------------
-- Function: match_report_to_zone
-- Description: Auto-assign report to security zone based on location
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.match_report_to_zone()
RETURNS TRIGGER AS $$
BEGIN
  -- Find zone that contains the report location
  SELECT id INTO NEW.assigned_zone_id
  FROM public.security_zones
  WHERE is_active = true
    AND ST_Contains(geometry, NEW.geometry)
  LIMIT 1;

  -- Check if report is within campus boundaries
  IF NOT EXISTS (
    SELECT 1 FROM public.campus_boundaries
    WHERE is_active = true
      AND ST_Contains(geometry, NEW.geometry)
  ) THEN
    RAISE EXCEPTION 'Report location must be within campus boundaries';
  END IF;

  -- Set is_emergency flag for Send Help reports
  IF EXISTS (
    SELECT 1 FROM public.report_categories
    WHERE id = NEW.category_id
      AND special_flag = 'send_help'
  ) THEN
    NEW.is_emergency := true;
    NEW.visibility := 'staff_only';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Function: update_report_verification_score
-- Description: Update report score when verification vote is added/changed
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_report_verification_score()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.reports
  SET verification_score = (
    SELECT COALESCE(SUM(vote), 0)
    FROM public.report_verifications
    WHERE report_id = COALESCE(NEW.report_id, OLD.report_id)
  )
  WHERE id = COALESCE(NEW.report_id, OLD.report_id);

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Function: update_updated_at
-- Description: Update updated_at timestamp on row modification
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Function: check_banned_words
-- Description: Check text for banned words before insert/update
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_banned_words()
RETURNS TRIGGER AS $$
DECLARE
  found_word text;
BEGIN
  -- Check title and description for banned words
  SELECT word INTO found_word
  FROM public.banned_words
  WHERE NEW.title ILIKE '%' || word || '%'
     OR (NEW.description IS NOT NULL AND NEW.description ILIKE '%' || word || '%')
  LIMIT 1;

  IF found_word IS NOT NULL THEN
    RAISE EXCEPTION 'Content contains prohibited word: %', found_word;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Function: validate_geometry_type
-- Description: Validate that report geometry matches category requirements
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_geometry_type()
RETURNS TRIGGER AS $$
DECLARE
  required_type public.geometry_type_enum;
  actual_type text;
BEGIN
  -- Get required geometry type for category
  SELECT requires_geometry_type INTO required_type
  FROM public.report_categories
  WHERE id = NEW.category_id;

  -- Get actual geometry type
  actual_type := lower(ST_GeometryType(NEW.geometry));

  -- Validate
  IF required_type = 'point' AND actual_type != 'st_point' THEN
    RAISE EXCEPTION 'This category requires a point geometry';
  ELSIF required_type = 'linestring' AND actual_type != 'st_linestring' THEN
    RAISE EXCEPTION 'This category requires a linestring geometry';
  ELSIF required_type = 'point_or_linestring'
    AND actual_type NOT IN ('st_point', 'st_linestring') THEN
    RAISE EXCEPTION 'This category requires a point or linestring geometry';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Function: log_audit
-- Description: Helper function to create audit log entries
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.log_audit(
  p_action public.audit_action_enum,
  p_target_type text DEFAULT NULL,
  p_target_id uuid DEFAULT NULL,
  p_details jsonb DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  new_id uuid;
BEGIN
  INSERT INTO public.audit_log (user_id, action, target_type, target_id, details)
  VALUES (auth.uid(), p_action, p_target_type, p_target_id, p_details)
  RETURNING id INTO new_id;

  RETURN new_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =============================================================================
-- 5. TRIGGERS
-- =============================================================================

-- Auto-create profile on user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-assign zone to report
CREATE TRIGGER on_report_created_match_zone
  BEFORE INSERT ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.match_report_to_zone();

-- Validate geometry type matches category
CREATE TRIGGER on_report_validate_geometry
  BEFORE INSERT OR UPDATE ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.validate_geometry_type();

-- Check for banned words
CREATE TRIGGER on_report_check_banned_words
  BEFORE INSERT OR UPDATE ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.check_banned_words();

-- Update verification score
CREATE TRIGGER on_verification_change_update_score
  AFTER INSERT OR UPDATE OR DELETE ON public.report_verifications
  FOR EACH ROW EXECUTE FUNCTION public.update_report_verification_score();

-- Update updated_at timestamps
CREATE TRIGGER on_profiles_update
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER on_reports_update
  BEFORE UPDATE ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER on_security_zones_update
  BEFORE UPDATE ON public.security_zones
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER on_comments_update
  BEFORE UPDATE ON public.report_comments
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


-- =============================================================================
-- 6. ROW LEVEL SECURITY POLICIES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Policies: profiles
-- -----------------------------------------------------------------------------

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile (limited fields)
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND role = (SELECT role FROM public.profiles WHERE id = auth.uid()) -- Can't change own role
  );

-- Security can view other security officers in their zones
CREATE POLICY "Security can view other officers"
  ON public.profiles FOR SELECT
  USING (
    role = 'security'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('security', 'admin')
    )
  );

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update any profile
CREATE POLICY "Admins can update profiles"
  ON public.profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );


-- -----------------------------------------------------------------------------
-- Policies: campus_boundaries
-- -----------------------------------------------------------------------------

-- Everyone can view active campus boundaries
CREATE POLICY "Anyone can view campus boundaries"
  ON public.campus_boundaries FOR SELECT
  USING (is_active = true);

-- Only admins can manage boundaries
CREATE POLICY "Admins can manage boundaries"
  ON public.campus_boundaries FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );


-- -----------------------------------------------------------------------------
-- Policies: security_zones
-- -----------------------------------------------------------------------------

-- Security and admins can view zones
CREATE POLICY "Staff can view zones"
  ON public.security_zones FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('security', 'admin')
    )
  );

-- Only admins can manage zones
CREATE POLICY "Admins can manage zones"
  ON public.security_zones FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );


-- -----------------------------------------------------------------------------
-- Policies: report_categories
-- -----------------------------------------------------------------------------

-- Everyone can view active categories
CREATE POLICY "Anyone can view categories"
  ON public.report_categories FOR SELECT
  USING (is_active = true);

-- Only admins can manage categories
CREATE POLICY "Admins can manage categories"
  ON public.report_categories FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );


-- -----------------------------------------------------------------------------
-- Policies: reports
-- -----------------------------------------------------------------------------

-- Public can view public, pending reports (not emergencies)
CREATE POLICY "Public can view public reports"
  ON public.reports FOR SELECT
  USING (
    visibility = 'public'
    AND status = 'pending'
    AND is_emergency = false
    AND auth.role() = 'authenticated'
  );

-- Users can view their own reports
CREATE POLICY "Users can view own reports"
  ON public.reports FOR SELECT
  USING (created_by_user_id = auth.uid());

-- Security can view reports in their zones
CREATE POLICY "Security can view zone reports"
  ON public.reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.security_zone_assignments sza ON sza.security_user_id = p.id
      WHERE p.id = auth.uid()
        AND p.role = 'security'
        AND sza.zone_id = reports.assigned_zone_id
    )
  );

-- Admins can view all reports
CREATE POLICY "Admins can view all reports"
  ON public.reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Authenticated users can create reports (if not banned)
CREATE POLICY "Users can create reports"
  ON public.reports FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_banned = true
    )
  );

-- Security can update reports in their zones
CREATE POLICY "Security can resolve zone reports"
  ON public.reports FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.security_zone_assignments sza ON sza.security_user_id = p.id
      WHERE p.id = auth.uid()
        AND p.role = 'security'
        AND sza.zone_id = reports.assigned_zone_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.security_zone_assignments sza ON sza.security_user_id = p.id
      WHERE p.id = auth.uid()
        AND p.role = 'security'
        AND sza.zone_id = reports.assigned_zone_id
    )
  );

-- Admins can update any report
CREATE POLICY "Admins can update reports"
  ON public.reports FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can delete reports
CREATE POLICY "Admins can delete reports"
  ON public.reports FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );


-- -----------------------------------------------------------------------------
-- Policies: report_photos
-- -----------------------------------------------------------------------------

-- Users can view photos of reports they can see
CREATE POLICY "Users can view report photos"
  ON public.report_photos FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.reports
      WHERE id = report_photos.report_id
        AND (
          -- Public reports
          (visibility = 'public' AND status = 'pending' AND is_emergency = false)
          -- Own reports
          OR created_by_user_id = auth.uid()
          -- Security in zone
          OR EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.security_zone_assignments sza ON sza.security_user_id = p.id
            WHERE p.id = auth.uid()
              AND p.role = 'security'
              AND sza.zone_id = reports.assigned_zone_id
          )
          -- Admin
          OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
          )
        )
    )
  );

-- Users can upload photos to their own reports
CREATE POLICY "Users can upload photos"
  ON public.report_photos FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.reports
      WHERE id = report_photos.report_id
        AND created_by_user_id = auth.uid()
    )
  );

-- Admins can delete photos
CREATE POLICY "Admins can delete photos"
  ON public.report_photos FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );


-- -----------------------------------------------------------------------------
-- Policies: security_zone_assignments
-- -----------------------------------------------------------------------------

-- Security can view their own assignments
CREATE POLICY "Security can view own assignments"
  ON public.security_zone_assignments FOR SELECT
  USING (
    security_user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can manage assignments
CREATE POLICY "Admins can manage assignments"
  ON public.security_zone_assignments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );


-- -----------------------------------------------------------------------------
-- Policies: report_verifications
-- -----------------------------------------------------------------------------

-- Users can view verifications on reports they can see
CREATE POLICY "Users can view verifications"
  ON public.report_verifications FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.reports
      WHERE id = report_verifications.report_id
        AND visibility = 'public'
        AND status = 'pending'
    )
  );

-- Users can add/update their own verifications
CREATE POLICY "Users can verify reports"
  ON public.report_verifications FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.reports
      WHERE id = report_verifications.report_id
        AND visibility = 'public'
        AND status = 'pending'
    )
  );

CREATE POLICY "Users can update own verifications"
  ON public.report_verifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own verifications"
  ON public.report_verifications FOR DELETE
  USING (user_id = auth.uid());


-- -----------------------------------------------------------------------------
-- Policies: report_comments
-- -----------------------------------------------------------------------------

-- Users can view comments on reports they can see
CREATE POLICY "Users can view comments"
  ON public.report_comments FOR SELECT
  USING (
    is_deleted = false
    AND EXISTS (
      SELECT 1 FROM public.reports
      WHERE id = report_comments.report_id
        AND (
          (visibility = 'public' AND status = 'pending' AND is_emergency = false)
          OR created_by_user_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.security_zone_assignments sza ON sza.security_user_id = p.id
            WHERE p.id = auth.uid()
              AND p.role = 'security'
              AND sza.zone_id = reports.assigned_zone_id
          )
          OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
          )
        )
    )
  );

-- Users can create comments
CREATE POLICY "Users can create comments"
  ON public.report_comments FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND NOT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_banned = true
    )
    AND EXISTS (
      SELECT 1 FROM public.reports
      WHERE id = report_comments.report_id
        AND (visibility = 'public' OR created_by_user_id = auth.uid())
    )
  );

-- Users can update their own comments
CREATE POLICY "Users can update own comments"
  ON public.report_comments FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Users can delete their own comments (soft delete)
CREATE POLICY "Users can delete own comments"
  ON public.report_comments FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid() AND is_deleted = true);

-- Admins can delete any comment
CREATE POLICY "Admins can delete comments"
  ON public.report_comments FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );


-- -----------------------------------------------------------------------------
-- Policies: post_reports
-- -----------------------------------------------------------------------------

-- Users can view their own reports
CREATE POLICY "Users can view own post reports"
  ON public.post_reports FOR SELECT
  USING (reported_by = auth.uid());

-- Admins can view all post reports
CREATE POLICY "Admins can view post reports"
  ON public.post_reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Users can report posts
CREATE POLICY "Users can report posts"
  ON public.post_reports FOR INSERT
  WITH CHECK (
    reported_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.reports
      WHERE id = post_reports.report_id
    )
  );

-- Admins can update post reports
CREATE POLICY "Admins can review post reports"
  ON public.post_reports FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );


-- -----------------------------------------------------------------------------
-- Policies: banned_words
-- -----------------------------------------------------------------------------

-- Only admins can manage banned words
CREATE POLICY "Admins can manage banned words"
  ON public.banned_words FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );


-- -----------------------------------------------------------------------------
-- Policies: audit_log
-- -----------------------------------------------------------------------------

-- Users can view their own audit logs
CREATE POLICY "Users can view own audit logs"
  ON public.audit_log FOR SELECT
  USING (user_id = auth.uid());

-- Admins can view all audit logs
CREATE POLICY "Admins can view all audit logs"
  ON public.audit_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- System can insert audit logs (via SECURITY DEFINER function)
CREATE POLICY "System can insert audit logs"
  ON public.audit_log FOR INSERT
  WITH CHECK (true);


-- =============================================================================
-- 7. VIEWS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- View: active_public_reports
-- Description: Public-facing reports for map display
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.active_public_reports AS
SELECT
  r.id,
  r.category_id,
  rc.name AS category_name,
  rc.type AS category_type,
  rc.special_flag,
  rc.icon,
  rc.color,
  r.title,
  r.description,
  r.geometry,
  ST_X(r.geometry::geometry) AS longitude,
  ST_Y(r.geometry::geometry) AS latitude,
  r.verification_score,
  r.view_count,
  r.created_at,
  CASE
    WHEN r.is_anonymous THEN NULL
    ELSE p.full_name
  END AS reporter_name,
  (
    SELECT COUNT(*)
    FROM public.report_photos
    WHERE report_id = r.id
  ) AS photo_count,
  (
    SELECT COUNT(*)
    FROM public.report_comments
    WHERE report_id = r.id AND is_deleted = false
  ) AS comment_count
FROM public.reports r
JOIN public.report_categories rc ON rc.id = r.category_id
LEFT JOIN public.profiles p ON p.id = r.created_by_user_id
WHERE r.status = 'pending'
  AND r.visibility = 'public'
  AND r.is_emergency = false;

COMMENT ON VIEW public.active_public_reports IS 'Active public reports for map display';


-- -----------------------------------------------------------------------------
-- View: security_zone_reports
-- Description: Reports for security dashboard with zone info
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.security_zone_reports AS
SELECT
  r.id,
  r.category_id,
  rc.name AS category_name,
  rc.type AS category_type,
  rc.special_flag,
  r.title,
  r.description,
  r.geometry,
  ST_X(r.geometry::geometry) AS longitude,
  ST_Y(r.geometry::geometry) AS latitude,
  r.status,
  r.is_emergency,
  r.verification_score,
  r.created_at,
  r.assigned_zone_id,
  sz.name AS zone_name,
  p.full_name AS reporter_name,
  p.email AS reporter_email,
  (
    SELECT COUNT(*)
    FROM public.report_photos
    WHERE report_id = r.id
  ) AS photo_count
FROM public.reports r
JOIN public.report_categories rc ON rc.id = r.category_id
LEFT JOIN public.security_zones sz ON sz.id = r.assigned_zone_id
LEFT JOIN public.profiles p ON p.id = r.created_by_user_id
WHERE r.status = 'pending'
  AND rc.type = 'incident';

COMMENT ON VIEW public.security_zone_reports IS 'Incident reports for security dashboard';


-- -----------------------------------------------------------------------------
-- View: admin_reports_summary
-- Description: Comprehensive report view for admin dashboard
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.admin_reports_summary AS
SELECT
  r.id,
  r.category_id,
  rc.name AS category_name,
  rc.type AS category_type,
  r.title,
  r.description,
  r.geometry,
  r.status,
  r.visibility,
  r.is_anonymous,
  r.is_emergency,
  r.verification_score,
  r.view_count,
  r.created_at,
  r.resolved_at,
  p.id AS reporter_id,
  p.full_name AS reporter_name,
  p.email AS reporter_email,
  resolver.full_name AS resolved_by_name,
  sz.name AS zone_name,
  (
    SELECT COUNT(*)
    FROM public.report_photos
    WHERE report_id = r.id
  ) AS photo_count,
  (
    SELECT COUNT(*)
    FROM public.report_comments
    WHERE report_id = r.id AND is_deleted = false
  ) AS comment_count,
  (
    SELECT COUNT(*)
    FROM public.post_reports
    WHERE report_id = r.id AND status = 'pending'
  ) AS user_report_count,
  (
    SELECT COUNT(*)
    FROM public.report_verifications
    WHERE report_id = r.id AND vote = -1
  ) AS dislike_count
FROM public.reports r
JOIN public.report_categories rc ON rc.id = r.category_id
LEFT JOIN public.profiles p ON p.id = r.created_by_user_id
LEFT JOIN public.profiles resolver ON resolver.id = r.resolved_by_user_id
LEFT JOIN public.security_zones sz ON sz.id = r.assigned_zone_id
ORDER BY r.created_at DESC;

COMMENT ON VIEW public.admin_reports_summary IS 'Comprehensive report view for admin dashboard';


-- -----------------------------------------------------------------------------
-- View: report_statistics
-- Description: Statistical summary of reports
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.report_statistics AS
SELECT
  COUNT(*) AS total_reports,
  COUNT(*) FILTER (WHERE status = 'pending') AS pending_reports,
  COUNT(*) FILTER (WHERE status = 'resolved_approved') AS approved_reports,
  COUNT(*) FILTER (WHERE status = 'resolved_rejected') AS rejected_reports,
  COUNT(*) FILTER (WHERE is_emergency = true) AS emergency_reports,
  COUNT(*) FILTER (WHERE visibility = 'public') AS public_reports,
  COUNT(*) FILTER (WHERE visibility = 'staff_only') AS staff_only_reports,
  COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE) AS today_reports,
  COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') AS week_reports,
  COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') AS month_reports
FROM public.reports;

COMMENT ON VIEW public.report_statistics IS 'Statistical summary of all reports';


-- =============================================================================
-- 8. STORAGE BUCKETS
-- =============================================================================

-- Create report_photos bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'report_photos',
  'report_photos',
  false,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------------------------
-- Storage Policies: report_photos bucket
-- -----------------------------------------------------------------------------

-- Users can upload photos (insert)
CREATE POLICY "Users can upload report photos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'report_photos'
    AND auth.role() = 'authenticated'
  );

-- Users can view photos they have access to
CREATE POLICY "Users can view report photos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'report_photos'
    AND (
      -- Own uploads
      owner = auth.uid()
      -- Or photos from reports they can access
      OR EXISTS (
        SELECT 1 FROM public.report_photos rp
        JOIN public.reports r ON r.id = rp.report_id
        WHERE rp.storage_path = storage.objects.name
          AND (
            r.visibility = 'public'
            OR r.created_by_user_id = auth.uid()
            OR EXISTS (
              SELECT 1 FROM public.profiles p
              JOIN public.security_zone_assignments sza ON sza.security_user_id = p.id
              WHERE p.id = auth.uid()
                AND p.role = 'security'
                AND sza.zone_id = r.assigned_zone_id
            )
            OR EXISTS (
              SELECT 1 FROM public.profiles
              WHERE id = auth.uid() AND role = 'admin'
            )
          )
      )
    )
  );

-- Users can update their own uploads
CREATE POLICY "Users can update own photos"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'report_photos'
    AND owner = auth.uid()
  );

-- Users can delete their own uploads
CREATE POLICY "Users can delete own photos"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'report_photos'
    AND (
      owner = auth.uid()
      OR EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
      )
    )
  );


-- =============================================================================
-- 9. REALTIME PUBLICATION
-- =============================================================================

-- Enable realtime for critical tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.reports;
ALTER PUBLICATION supabase_realtime ADD TABLE public.report_comments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.report_verifications;


-- =============================================================================
-- 10. SEED DATA
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Seed: report_categories
-- -----------------------------------------------------------------------------
INSERT INTO public.report_categories (id, name, name_th, type, requires_geometry_type, special_flag, icon, color, sort_order)
VALUES
  -- Incident Reports (1-9)
  (1, 'Accident/Hazard', 'อุบัติเหตุ/จุดเสี่ยง', 'incident', 'point', NULL, '🚨', '#EF4444', 1),
  (2, 'Blocked', 'ทางปิด/สิ่งกีดขวาง', 'incident', 'point_or_linestring', NULL, '🚧', '#F59E0B', 2),
  (3, 'Beware', 'เตือนภัย', 'incident', 'point', NULL, '⚠️', '#F97316', 3),
  (4, 'Flood', 'น้ำท่วม', 'incident', 'point', 'flood_animation', '🌊', '#3B82F6', 4),
  (5, 'Send Help', 'ขอความช่วยเหลือ', 'incident', 'point', 'send_help', '🆘', '#DC2626', 5),

  -- General Reports (10-19)
  (10, 'Traffic', 'จราจรติดขัด', 'general', 'point_or_linestring', NULL, '🚗', '#EF4444', 10),
  (11, 'Parking', 'ที่จอดรถ', 'general', 'point', NULL, '🅿️', '#6366F1', 11),
  (12, 'Events', 'กิจกรรม', 'general', 'point', NULL, '🎉', '#8B5CF6', 12),
  (13, 'Lost & Found', 'ของหาย/เจอของ', 'general', 'point', NULL, '🔍', '#06B6D4', 13)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  name_th = EXCLUDED.name_th,
  type = EXCLUDED.type,
  requires_geometry_type = EXCLUDED.requires_geometry_type,
  special_flag = EXCLUDED.special_flag,
  icon = EXCLUDED.icon,
  color = EXCLUDED.color,
  sort_order = EXCLUDED.sort_order;


-- -----------------------------------------------------------------------------
-- Seed: Common banned words (Thai profanity - add more as needed)
-- -----------------------------------------------------------------------------
INSERT INTO public.banned_words (word, severity)
VALUES
  ('ควย', 'high'),
  ('สัส', 'high'),
  ('เหี้ย', 'high'),
  ('เชี่ย', 'medium'),
  ('ไอ้สัตว์', 'medium')
ON CONFLICT (word) DO NOTHING;


-- =============================================================================
-- 11. HELPER FUNCTIONS FOR APPLICATION
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Function: get_reports_in_zone
-- Description: Get all reports in a specific security zone
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_reports_in_zone(zone_id_param uuid)
RETURNS SETOF public.reports AS $$
BEGIN
  RETURN QUERY
  SELECT r.*
  FROM public.reports r
  WHERE r.assigned_zone_id = zone_id_param
    AND r.status = 'pending'
  ORDER BY r.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- -----------------------------------------------------------------------------
-- Function: get_nearby_reports
-- Description: Get reports within radius of a point (for clustering)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_nearby_reports(
  lat double precision,
  lng double precision,
  radius_meters integer DEFAULT 1000
)
RETURNS TABLE (
  id uuid,
  category_id int,
  title text,
  geometry geometry,
  distance_meters double precision,
  created_at timestamp with time zone
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    r.category_id,
    r.title,
    r.geometry,
    ST_Distance(
      r.geometry::geography,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
    ) AS distance_meters,
    r.created_at
  FROM public.reports r
  WHERE r.status = 'pending'
    AND r.visibility = 'public'
    AND r.is_emergency = false
    AND ST_DWithin(
      r.geometry::geography,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
      radius_meters
    )
  ORDER BY distance_meters;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- -----------------------------------------------------------------------------
-- Function: get_report_with_details
-- Description: Get complete report details including photos and comments
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_report_with_details(report_id_param uuid)
RETURNS json AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'report', row_to_json(r.*),
    'category', row_to_json(rc.*),
    'reporter', CASE
      WHEN r.is_anonymous THEN NULL
      ELSE json_build_object('id', p.id, 'full_name', p.full_name)
    END,
    'photos', (
      SELECT json_agg(row_to_json(rp.*))
      FROM public.report_photos rp
      WHERE rp.report_id = r.id
    ),
    'comments', (
      SELECT json_agg(json_build_object(
        'id', c.id,
        'body', c.body,
        'user_name', CASE WHEN c.is_anonymous THEN 'Anonymous' ELSE cp.full_name END,
        'created_at', c.created_at
      ))
      FROM public.report_comments c
      LEFT JOIN public.profiles cp ON cp.id = c.user_id
      WHERE c.report_id = r.id
        AND c.is_deleted = false
      ORDER BY c.created_at ASC
    ),
    'verification_score', r.verification_score,
    'user_vote', (
      SELECT vote
      FROM public.report_verifications
      WHERE report_id = r.id AND user_id = auth.uid()
    )
  ) INTO result
  FROM public.reports r
  JOIN public.report_categories rc ON rc.id = r.category_id
  LEFT JOIN public.profiles p ON p.id = r.created_by_user_id
  WHERE r.id = report_id_param;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- -----------------------------------------------------------------------------
-- Function: get_security_dashboard_stats
-- Description: Get statistics for security officer dashboard
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_security_dashboard_stats(security_user_id_param uuid)
RETURNS json AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'assigned_zones', (
      SELECT json_agg(json_build_object(
        'id', sz.id,
        'name', sz.name
      ))
      FROM public.security_zones sz
      JOIN public.security_zone_assignments sza ON sza.zone_id = sz.id
      WHERE sza.security_user_id = security_user_id_param
    ),
    'pending_reports', (
      SELECT COUNT(*)
      FROM public.reports r
      JOIN public.security_zone_assignments sza ON sza.zone_id = r.assigned_zone_id
      WHERE sza.security_user_id = security_user_id_param
        AND r.status = 'pending'
    ),
    'emergency_reports', (
      SELECT COUNT(*)
      FROM public.reports r
      JOIN public.security_zone_assignments sza ON sza.zone_id = r.assigned_zone_id
      WHERE sza.security_user_id = security_user_id_param
        AND r.status = 'pending'
        AND r.is_emergency = true
    ),
    'resolved_today', (
      SELECT COUNT(*)
      FROM public.reports r
      WHERE r.resolved_by_user_id = security_user_id_param
        AND r.resolved_at >= CURRENT_DATE
    )
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =============================================================================
-- 12. INDEXES FOR PERFORMANCE
-- =============================================================================

-- Additional composite indexes for common queries
CREATE INDEX IF NOT EXISTS reports_status_visibility_idx
  ON public.reports(status, visibility)
  WHERE is_emergency = false;

CREATE INDEX IF NOT EXISTS reports_zone_status_idx
  ON public.reports(assigned_zone_id, status)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS report_photos_report_blur_idx
  ON public.report_photos(report_id, blur_status);

CREATE INDEX IF NOT EXISTS post_reports_pending_idx
  ON public.post_reports(report_id, status)
  WHERE status = 'pending';


-- =============================================================================
-- END OF SCHEMA
-- =============================================================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres, authenticated, service_role;

-- Completion message
DO $$
BEGIN
  RAISE NOTICE 'Schema created successfully!';
  RAISE NOTICE 'Total tables: %', (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public');
  RAISE NOTICE 'Total views: %', (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public');
  RAISE NOTICE 'Total functions: %', (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public');
END $$;
