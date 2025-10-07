-- Add gender field to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS gender VARCHAR(20);

-- Update the demographics structure to include gender
-- This will be handled in the application code by updating the demographics JSON field
