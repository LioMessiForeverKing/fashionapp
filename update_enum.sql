-- Update script to ensure style_preference enum has correct values
-- Run this in your Supabase SQL editor if you're getting enum errors

-- First, let's check if the enum exists and what values it has
SELECT enumlabel FROM pg_enum WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'style_preference');

-- If the enum doesn't have the correct values, you may need to:
-- 1. Drop and recreate the enum (if no data exists)
-- 2. Or add missing values

-- Option 1: Drop and recreate (ONLY if you have no important data)
-- DROP TYPE IF EXISTS style_preference CASCADE;
-- CREATE TYPE style_preference AS ENUM (
--     'minimalist', 'boho', 'preppy', 'edgy', 'romantic', 'casual', 'vintage', 'modern'
-- );

-- Option 2: Add missing values (safer approach)
-- ALTER TYPE style_preference ADD VALUE IF NOT EXISTS 'minimalist';
-- ALTER TYPE style_preference ADD VALUE IF NOT EXISTS 'boho';
-- ALTER TYPE style_preference ADD VALUE IF NOT EXISTS 'preppy';
-- ALTER TYPE style_preference ADD VALUE IF NOT EXISTS 'edgy';
-- ALTER TYPE style_preference ADD VALUE IF NOT EXISTS 'romantic';
-- ALTER TYPE style_preference ADD VALUE IF NOT EXISTS 'casual';
-- ALTER TYPE style_preference ADD VALUE IF NOT EXISTS 'vintage';
-- ALTER TYPE style_preference ADD VALUE IF NOT EXISTS 'modern';

-- Check the current enum values after update
SELECT enumlabel FROM pg_enum WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'style_preference') ORDER BY enumlabel;
