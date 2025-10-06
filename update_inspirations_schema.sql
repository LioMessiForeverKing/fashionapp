-- Update inspirations schema to support curated content and user saves
-- Run this in your Supabase SQL editor

-- First, let's add the missing columns to the inspirations table
ALTER TABLE public.inspirations 
ADD COLUMN IF NOT EXISTS title TEXT,
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- Make user_id nullable to support curated content
ALTER TABLE public.inspirations 
ALTER COLUMN user_id DROP NOT NULL;

-- Create user_inspirations table to track saved inspirations
CREATE TABLE IF NOT EXISTS public.user_inspirations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    inspiration_id UUID REFERENCES public.inspirations(id) ON DELETE CASCADE,
    is_saved BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, inspiration_id)
);

-- Create indexes for user_inspirations
CREATE INDEX IF NOT EXISTS idx_user_inspirations_user_id ON public.user_inspirations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_inspirations_inspiration_id ON public.user_inspirations(inspiration_id);
CREATE INDEX IF NOT EXISTS idx_user_inspirations_is_saved ON public.user_inspirations(is_saved);

-- Add RLS policies for user_inspirations
ALTER TABLE public.user_inspirations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own saved inspirations" ON public.user_inspirations 
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own saved inspirations" ON public.user_inspirations 
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own saved inspirations" ON public.user_inspirations 
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own saved inspirations" ON public.user_inspirations 
FOR DELETE USING (auth.uid() = user_id);

-- Update RLS policies for inspirations to allow viewing curated content
DROP POLICY IF EXISTS "Users can view own inspirations" ON public.inspirations;
CREATE POLICY "Users can view inspirations" ON public.inspirations 
FOR SELECT USING (
    auth.uid() = user_id OR 
    is_public = true OR 
    user_id IS NULL -- Allow viewing curated content
);

-- Add trigger for user_inspirations updated_at
CREATE TRIGGER update_user_inspirations_updated_at 
BEFORE UPDATE ON public.user_inspirations 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
