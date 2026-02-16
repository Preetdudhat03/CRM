-- Function to update user role securely
CREATE OR REPLACE FUNCTION admin_update_profile(target_user_id UUID, new_name TEXT, new_role TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_role TEXT;
BEGIN
  -- Get current user's role
  SELECT role INTO current_user_role FROM profiles WHERE id = auth.uid();
  
  -- Check if current user is admin or superAdmin
  IF current_user_role NOT IN ('admin', 'superAdmin') THEN
    RAISE EXCEPTION 'Access Denied: Only admins can update profiles';
  END IF;

  -- Update the target user's profile
  UPDATE profiles 
  SET name = new_name, role = new_role, updated_at = NOW()
  WHERE id = target_user_id;

  -- Return the updated data (or minimal data needed)
  RETURN jsonb_build_object('id', target_user_id, 'name', new_name, 'role', new_role);
END;
$$;
