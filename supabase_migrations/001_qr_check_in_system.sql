-- ============================================
-- QR CODE CHECK-IN SYSTEM - SUPABASE MIGRATION
-- ============================================
-- This migration creates the necessary tables and RPC function
-- for a simple QR code check-in system with no security requirements.

-- ============================================
-- 1. EVENTS TABLE (Update if needed)
-- ============================================
-- Note: Assuming events table already exists with these columns
-- If not, create it with:
/*
CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brand_id UUID REFERENCES brands(id),
  store_name TEXT NOT NULL,
  location TEXT NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  description TEXT,
  date_start TIMESTAMPTZ NOT NULL,
  date_end TIMESTAMPTZ NOT NULL,
  fallback_code TEXT UNIQUE,
  qr_code_url TEXT,
  status TEXT DEFAULT 'Active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
*/

-- Ensure fallback_code column exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'events' AND column_name = 'fallback_code'
  ) THEN
    ALTER TABLE events ADD COLUMN fallback_code TEXT UNIQUE;
  END IF;
END $$;

-- ============================================
-- 2. EVENT_CHECKINS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS event_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  fallback_code TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Prevent duplicate check-ins
  UNIQUE(user_id, event_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_event_checkins_user_id ON event_checkins(user_id);
CREATE INDEX IF NOT EXISTS idx_event_checkins_event_id ON event_checkins(event_id);
CREATE INDEX IF NOT EXISTS idx_event_checkins_timestamp ON event_checkins(timestamp);

-- ============================================
-- 3. POINTS_LEDGER TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS points_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_id UUID REFERENCES events(id) ON DELETE SET NULL,
  points INTEGER NOT NULL,
  description TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_points_ledger_user_id ON points_ledger(user_id);
CREATE INDEX IF NOT EXISTS idx_points_ledger_event_id ON points_ledger(event_id);
CREATE INDEX IF NOT EXISTS idx_points_ledger_timestamp ON points_ledger(timestamp);

-- ============================================
-- 4. RPC FUNCTION: check_in_event
-- ============================================
CREATE OR REPLACE FUNCTION check_in_event(
  p_user_id UUID,
  p_event_id UUID,
  p_fallback_code TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_event RECORD;
  v_existing_checkin UUID;
  v_points INTEGER := 50; -- Default points awarded
  v_result JSON;
BEGIN
  -- 1. Look up the event by eventId
  SELECT * INTO v_event
  FROM events
  WHERE id = p_event_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'status', 'error',
      'message', 'Event not found'
    );
  END IF;
  
  -- 2. Verify that the fallback code matches
  IF v_event.fallback_code IS NULL OR v_event.fallback_code != p_fallback_code THEN
    RETURN json_build_object(
      'status', 'error',
      'message', 'Invalid fallback code'
    );
  END IF;
  
  -- 3. Verify that the current timestamp is within the event's time range
  IF NOW() < v_event.date_start OR NOW() > v_event.date_end THEN
    RETURN json_build_object(
      'status', 'error',
      'message', 'Event not active'
    );
  END IF;
  
  -- 4. Verify that the user has not already checked in
  SELECT id INTO v_existing_checkin
  FROM event_checkins
  WHERE user_id = p_user_id AND event_id = p_event_id;
  
  IF v_existing_checkin IS NOT NULL THEN
    RETURN json_build_object(
      'status', 'error',
      'message', 'Already checked in'
    );
  END IF;
  
  -- 5. Insert a row into event_checkins table
  INSERT INTO event_checkins (user_id, event_id, fallback_code)
  VALUES (p_user_id, p_event_id, p_fallback_code);
  
  -- 6. Insert a row into points_ledger table
  INSERT INTO points_ledger (user_id, event_id, points, description)
  VALUES (
    p_user_id,
    p_event_id,
    v_points,
    'Event check-in: ' || v_event.store_name
  );
  
  -- 7. Update user's total points (if users table has points column)
  UPDATE users
  SET points = COALESCE(points, 0) + v_points,
      updated_at = NOW()
  WHERE id = p_user_id;
  
  -- 8. Return success response
  RETURN json_build_object(
    'status', 'success',
    'points', v_points
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'status', 'error',
      'message', 'Database error: ' || SQLERRM
    );
END;
$$;

-- ============================================
-- 5. GRANT PERMISSIONS (if using RLS)
-- ============================================
-- Enable RLS if needed
ALTER TABLE event_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_ledger ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own check-ins
CREATE POLICY "Users can view their own check-ins"
  ON event_checkins
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can read their own points ledger
CREATE POLICY "Users can view their own points"
  ON points_ledger
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: RPC function can insert check-ins (handled by SECURITY DEFINER)
-- No additional policy needed for inserts via RPC

-- ============================================
-- 6. HELPER FUNCTION: Generate QR Code Data
-- ============================================
-- This is a helper function to generate QR code JSON for an event
CREATE OR REPLACE FUNCTION get_event_qr_data(p_event_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_event RECORD;
BEGIN
  SELECT id, fallback_code INTO v_event
  FROM events
  WHERE id = p_event_id;
  
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  
  RETURN json_build_object(
    'eventId', v_event.id::TEXT,
    'fallbackCode', v_event.fallback_code
  );
END;
$$;

