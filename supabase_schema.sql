-- Closet Fairy Database Schema
-- Run this SQL in your Supabase SQL editor to create all necessary tables

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE clothing_category AS ENUM (
    'tops', 'bottoms', 'dresses', 'outerwear', 'shoes', 'accessories'
);

CREATE TYPE clothing_season AS ENUM (
    'all-year', 'spring', 'summer', 'fall', 'winter'
);

CREATE TYPE formality_level AS ENUM (
    'casual', 'smart-casual', 'business-casual', 'business', 'formal', 'black-tie'
);

CREATE TYPE occasion_type AS ENUM (
    'work', 'date-night', 'wedding-guest', 'job-interview', 'casual-weekend', 
    'party', 'travel', 'gym', 'other'
);

CREATE TYPE style_preference AS ENUM (
    'minimalist', 'boho', 'preppy', 'edgy', 'romantic', 'casual', 'vintage', 'modern'
);

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    profile_image_url TEXT,
    style_preferences style_preference[] DEFAULT '{}',
    demographics JSONB DEFAULT '{}', -- age_range, body_type, height, lifestyle, etc.
    color_preferences JSONB DEFAULT '{}', -- favorite_colors, avoid_colors, palette_preference
    budget_preferences JSONB DEFAULT '{}', -- budget_ranges for different categories
    shopping_frequency TEXT DEFAULT 'moderate', -- low, moderate, high
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Clothing items table
CREATE TABLE public.clothing_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    category clothing_category NOT NULL,
    subcategory TEXT NOT NULL, -- blouse, jeans, sneakers, etc.
    color TEXT NOT NULL,
    pattern TEXT, -- solid, striped, floral, etc.
    fabric TEXT, -- cotton, silk, denim, etc.
    brand TEXT,
    size TEXT,
    tags TEXT[] DEFAULT '{}',
    season clothing_season DEFAULT 'all-year',
    formality formality_level DEFAULT 'casual',
    times_worn INTEGER DEFAULT 0,
    last_worn TIMESTAMP WITH TIME ZONE,
    is_favorite BOOLEAN DEFAULT FALSE,
    purchase_date DATE,
    purchase_price DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Outfits table
CREATE TABLE public.outfits (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT,
    description TEXT,
    occasion occasion_type,
    formality formality_level,
    weather_conditions TEXT, -- hot, cold, rainy, etc.
    is_favorite BOOLEAN DEFAULT FALSE,
    is_public BOOLEAN DEFAULT FALSE,
    inspiration_image_url TEXT,
    style_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Junction table for outfit items (many-to-many relationship)
CREATE TABLE public.outfit_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    outfit_id UUID REFERENCES public.outfits(id) ON DELETE CASCADE NOT NULL,
    clothing_item_id UUID REFERENCES public.clothing_items(id) ON DELETE CASCADE NOT NULL,
    position_order INTEGER DEFAULT 0, -- for ordering items in outfit display
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(outfit_id, clothing_item_id)
);

-- Inspiration images table
CREATE TABLE public.inspirations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    image_url TEXT NOT NULL,
    source_url TEXT, -- original source of the inspiration
    source TEXT, -- pinterest, instagram, website, etc.
    style_keywords TEXT[] DEFAULT '{}',
    color_palette TEXT[] DEFAULT '{}',
    occasion occasion_type,
    formality formality_level,
    is_saved BOOLEAN DEFAULT FALSE,
    is_public BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Wishlist items table
CREATE TABLE public.wishlist_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    category clothing_category NOT NULL,
    subcategory TEXT,
    color TEXT,
    brand TEXT,
    size TEXT,
    target_price DECIMAL(10,2),
    current_price DECIMAL(10,2),
    shopping_urls JSONB DEFAULT '{}', -- multiple retailer URLs
    versatility_score INTEGER DEFAULT 0, -- how many outfits it could create
    priority INTEGER DEFAULT 1, -- 1-5 priority level
    occasion occasion_type,
    formality formality_level,
    notes TEXT,
    is_purchased BOOLEAN DEFAULT FALSE,
    purchased_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Outfit suggestions table (AI-generated suggestions)
CREATE TABLE public.outfit_suggestions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    base_item_id UUID REFERENCES public.clothing_items(id) ON DELETE CASCADE,
    inspiration_id UUID REFERENCES public.inspirations(id) ON DELETE SET NULL,
    occasion occasion_type,
    formality formality_level,
    weather_conditions TEXT,
    suggestion_data JSONB NOT NULL, -- contains the full outfit suggestion
    explanation TEXT, -- AI explanation of why this works
    confidence_score DECIMAL(3,2) DEFAULT 0.0, -- 0.0 to 1.0
    is_liked BOOLEAN,
    is_saved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Social features tables
CREATE TABLE public.friendships (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    friend_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);

CREATE TABLE public.outfit_shares (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    outfit_id UUID REFERENCES public.outfits(id) ON DELETE CASCADE NOT NULL,
    shared_by UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    shared_with UUID REFERENCES public.users(id) ON DELETE CASCADE,
    is_public BOOLEAN DEFAULT FALSE,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.outfit_feedback (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    outfit_share_id UUID REFERENCES public.outfit_shares(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    reaction TEXT, -- heart, fire, clap, etc.
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User activity tracking
CREATE TABLE public.user_activities (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    activity_type TEXT NOT NULL, -- upload_item, create_outfit, save_inspiration, etc.
    activity_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_clothing_items_user_id ON public.clothing_items(user_id);
CREATE INDEX idx_clothing_items_category ON public.clothing_items(category);
CREATE INDEX idx_clothing_items_color ON public.clothing_items(color);
CREATE INDEX idx_clothing_items_season ON public.clothing_items(season);
CREATE INDEX idx_clothing_items_created_at ON public.clothing_items(created_at);

CREATE INDEX idx_outfits_user_id ON public.outfits(user_id);
CREATE INDEX idx_outfits_occasion ON public.outfits(occasion);
CREATE INDEX idx_outfits_created_at ON public.outfits(created_at);

CREATE INDEX idx_outfit_items_outfit_id ON public.outfit_items(outfit_id);
CREATE INDEX idx_outfit_items_clothing_item_id ON public.outfit_items(clothing_item_id);

CREATE INDEX idx_inspirations_user_id ON public.inspirations(user_id);
CREATE INDEX idx_inspirations_is_saved ON public.inspirations(is_saved);
CREATE INDEX idx_inspirations_created_at ON public.inspirations(created_at);

CREATE INDEX idx_wishlist_items_user_id ON public.wishlist_items(user_id);
CREATE INDEX idx_wishlist_items_priority ON public.wishlist_items(priority);
CREATE INDEX idx_wishlist_items_is_purchased ON public.wishlist_items(is_purchased);

CREATE INDEX idx_outfit_suggestions_user_id ON public.outfit_suggestions(user_id);
CREATE INDEX idx_outfit_suggestions_base_item_id ON public.outfit_suggestions(base_item_id);
CREATE INDEX idx_outfit_suggestions_created_at ON public.outfit_suggestions(created_at);

CREATE INDEX idx_friendships_user_id ON public.friendships(user_id);
CREATE INDEX idx_friendships_friend_id ON public.friendships(friend_id);
CREATE INDEX idx_friendships_status ON public.friendships(status);

CREATE INDEX idx_user_activities_user_id ON public.user_activities(user_id);
CREATE INDEX idx_user_activities_type ON public.user_activities(activity_type);
CREATE INDEX idx_user_activities_created_at ON public.user_activities(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_clothing_items_updated_at BEFORE UPDATE ON public.clothing_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_outfits_updated_at BEFORE UPDATE ON public.outfits FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_inspirations_updated_at BEFORE UPDATE ON public.inspirations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_wishlist_items_updated_at BEFORE UPDATE ON public.wishlist_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_friendships_updated_at BEFORE UPDATE ON public.friendships FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clothing_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outfits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outfit_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspirations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outfit_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outfit_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outfit_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

-- Clothing items policies
CREATE POLICY "Users can view own clothing items" ON public.clothing_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own clothing items" ON public.clothing_items FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own clothing items" ON public.clothing_items FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own clothing items" ON public.clothing_items FOR DELETE USING (auth.uid() = user_id);

-- Outfits policies
CREATE POLICY "Users can view own outfits" ON public.outfits FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own outfits" ON public.outfits FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own outfits" ON public.outfits FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own outfits" ON public.outfits FOR DELETE USING (auth.uid() = user_id);

-- Outfit items policies
CREATE POLICY "Users can view outfit items for own outfits" ON public.outfit_items FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.outfits WHERE id = outfit_id AND user_id = auth.uid())
);
CREATE POLICY "Users can insert outfit items for own outfits" ON public.outfit_items FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.outfits WHERE id = outfit_id AND user_id = auth.uid())
);
CREATE POLICY "Users can update outfit items for own outfits" ON public.outfit_items FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.outfits WHERE id = outfit_id AND user_id = auth.uid())
);
CREATE POLICY "Users can delete outfit items for own outfits" ON public.outfit_items FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.outfits WHERE id = outfit_id AND user_id = auth.uid())
);

-- Inspirations policies
CREATE POLICY "Users can view own inspirations" ON public.inspirations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own inspirations" ON public.inspirations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own inspirations" ON public.inspirations FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own inspirations" ON public.inspirations FOR DELETE USING (auth.uid() = user_id);

-- Wishlist items policies
CREATE POLICY "Users can view own wishlist items" ON public.wishlist_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own wishlist items" ON public.wishlist_items FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own wishlist items" ON public.wishlist_items FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own wishlist items" ON public.wishlist_items FOR DELETE USING (auth.uid() = user_id);

-- Outfit suggestions policies
CREATE POLICY "Users can view own outfit suggestions" ON public.outfit_suggestions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own outfit suggestions" ON public.outfit_suggestions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own outfit suggestions" ON public.outfit_suggestions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own outfit suggestions" ON public.outfit_suggestions FOR DELETE USING (auth.uid() = user_id);

-- Friendships policies
CREATE POLICY "Users can view own friendships" ON public.friendships FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);
CREATE POLICY "Users can insert own friendships" ON public.friendships FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own friendships" ON public.friendships FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = friend_id);
CREATE POLICY "Users can delete own friendships" ON public.friendships FOR DELETE USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Outfit shares policies
CREATE POLICY "Users can view outfit shares they created or received" ON public.outfit_shares FOR SELECT USING (
    auth.uid() = shared_by OR auth.uid() = shared_with OR is_public = true
);
CREATE POLICY "Users can insert own outfit shares" ON public.outfit_shares FOR INSERT WITH CHECK (auth.uid() = shared_by);
CREATE POLICY "Users can update own outfit shares" ON public.outfit_shares FOR UPDATE USING (auth.uid() = shared_by);
CREATE POLICY "Users can delete own outfit shares" ON public.outfit_shares FOR DELETE USING (auth.uid() = shared_by);

-- Outfit feedback policies
CREATE POLICY "Users can view feedback on shared outfits" ON public.outfit_feedback FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.outfit_shares 
        WHERE id = outfit_share_id 
        AND (shared_by = auth.uid() OR shared_with = auth.uid() OR is_public = true)
    )
);
CREATE POLICY "Users can insert own feedback" ON public.outfit_feedback FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own feedback" ON public.outfit_feedback FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own feedback" ON public.outfit_feedback FOR DELETE USING (auth.uid() = user_id);

-- User activities policies
CREATE POLICY "Users can view own activities" ON public.user_activities FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own activities" ON public.user_activities FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create storage buckets for images
INSERT INTO storage.buckets (id, name, public) VALUES 
    ('clothing-items', 'clothing-items', true),
    ('outfit-images', 'outfit-images', true),
    ('inspiration-images', 'inspiration-images', true),
    ('profile-images', 'profile-images', true);

-- Storage policies for clothing items
CREATE POLICY "Users can upload own clothing item images" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'clothing-items' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view own clothing item images" ON storage.objects FOR SELECT USING (
    bucket_id = 'clothing-items' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update own clothing item images" ON storage.objects FOR UPDATE USING (
    bucket_id = 'clothing-items' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete own clothing item images" ON storage.objects FOR DELETE USING (
    bucket_id = 'clothing-items' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Storage policies for outfit images
CREATE POLICY "Users can upload own outfit images" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'outfit-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view own outfit images" ON storage.objects FOR SELECT USING (
    bucket_id = 'outfit-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update own outfit images" ON storage.objects FOR UPDATE USING (
    bucket_id = 'outfit-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete own outfit images" ON storage.objects FOR DELETE USING (
    bucket_id = 'outfit-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Storage policies for inspiration images
CREATE POLICY "Users can upload own inspiration images" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'inspiration-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view own inspiration images" ON storage.objects FOR SELECT USING (
    bucket_id = 'inspiration-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update own inspiration images" ON storage.objects FOR UPDATE USING (
    bucket_id = 'inspiration-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete own inspiration images" ON storage.objects FOR DELETE USING (
    bucket_id = 'inspiration-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Storage policies for profile images
CREATE POLICY "Users can upload own profile images" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view own profile images" ON storage.objects FOR SELECT USING (
    bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update own profile images" ON storage.objects FOR UPDATE USING (
    bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete own profile images" ON storage.objects FOR DELETE USING (
    bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name, profile_image_url)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'name',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create user profile when auth user is created
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to log user activities
CREATE OR REPLACE FUNCTION public.log_user_activity(
    activity_type_param TEXT,
    activity_data_param JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    activity_id UUID;
BEGIN
    INSERT INTO public.user_activities (user_id, activity_type, activity_data)
    VALUES (auth.uid(), activity_type_param, activity_data_param)
    RETURNING id INTO activity_id;
    
    RETURN activity_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update clothing item wear count
CREATE OR REPLACE FUNCTION public.increment_wear_count(item_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.clothing_items 
    SET 
        times_worn = times_worn + 1,
        last_worn = NOW()
    WHERE id = item_id AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate outfit versatility score
CREATE OR REPLACE FUNCTION public.calculate_versatility_score(item_id UUID)
RETURNS INTEGER AS $$
DECLARE
    outfit_count INTEGER;
BEGIN
    SELECT COUNT(DISTINCT o.id) INTO outfit_count
    FROM public.outfits o
    JOIN public.outfit_items oi ON o.id = oi.outfit_id
    WHERE oi.clothing_item_id = item_id
    AND o.user_id = auth.uid();
    
    RETURN outfit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create some sample data for testing (optional)
-- Uncomment the following lines if you want to add sample data

/*
-- Sample user (this will be created automatically when a real user signs up)
INSERT INTO public.users (id, email, name, style_preferences, demographics)
VALUES (
    '00000000-0000-0000-0000-000000000000',
    'test@example.com',
    'Test User',
    ARRAY['minimalist', 'casual'],
    '{"age_range": "25-34", "body_type": "hourglass", "height": "5ft 6in", "lifestyle": "professional"}'
);

-- Sample clothing items
INSERT INTO public.clothing_items (user_id, image_url, category, subcategory, color, tags, season)
VALUES 
    ('00000000-0000-0000-0000-000000000000', 'https://example.com/black-skirt.jpg', 'bottoms', 'skirt', 'black', ARRAY['work', 'casual'], 'all-year'),
    ('00000000-0000-0000-0000-000000000000', 'https://example.com/white-blouse.jpg', 'tops', 'blouse', 'white', ARRAY['work', 'formal'], 'all-year'),
    ('00000000-0000-0000-0000-000000000000', 'https://example.com/jeans.jpg', 'bottoms', 'jeans', 'blue', ARRAY['casual', 'weekend'], 'all-year');
*/

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Closet Fairy database schema created successfully!';
    RAISE NOTICE 'Tables created: users, clothing_items, outfits, outfit_items, inspirations, wishlist_items, outfit_suggestions, friendships, outfit_shares, outfit_feedback, user_activities';
    RAISE NOTICE 'Storage buckets created: clothing-items, outfit-images, inspiration-images, profile-images';
    RAISE NOTICE 'Row Level Security policies enabled for all tables';
    RAISE NOTICE 'Triggers and functions created for user management and activity tracking';
END $$;
