-- Fix Row Level Security (RLS) policies for security_zones table
-- The issue: Database has zones but browser fetches 0 = RLS is blocking

-- First, check current RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'security_zones';

-- Enable RLS if not already enabled
ALTER TABLE public.security_zones ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow public read access to active security zones" ON public.security_zones;
DROP POLICY IF EXISTS "security_zones_select_policy" ON public.security_zones;

-- Create a policy that allows everyone to SELECT active security zones
CREATE POLICY "Allow public read access to active security zones"
ON public.security_zones
FOR SELECT
TO public
USING (is_active = true);

-- Verify the policy was created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'security_zones';

-- Test the query (this should return zones now)
SELECT id, name, is_active, ST_GeometryType(geometry) as geom_type
FROM public.security_zones
WHERE is_active = true;
