-- Setup storage bucket for clothing images
-- Run this in your Supabase SQL editor

-- Create storage bucket for clothing images (if it doesn't exist)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'clothing-items',
  'clothing-items',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Set up RLS policies for the storage bucket
CREATE POLICY "Users can upload their own clothing images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'clothing-items' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view their own clothing images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'clothing-items' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their own clothing images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'clothing-items' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own clothing images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'clothing-items' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow public read access to clothing images (for displaying in the app)
CREATE POLICY "Public can view clothing images" ON storage.objects
FOR SELECT USING (bucket_id = 'clothing-items');
