-- ============================================
-- SUPABASE DATABASE SETUP
-- ============================================
-- Run this in your Supabase SQL Editor
-- This creates the schema for the Conference RAG application

-- Step 1: Enable the pgvector extension for vector similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- Step 2: Create the sentence_embeddings table
-- Each row is one sentence from a conference talk, with its embedding vector
CREATE TABLE IF NOT EXISTS sentence_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    talk_id UUID NOT NULL,
    title TEXT NOT NULL,
    speaker TEXT,
    calling TEXT,
    year INTEGER,
    season TEXT,
    url TEXT,
    sentence_num INTEGER,
    text TEXT NOT NULL,
    embedding vector(1536),  -- OpenAI text-embedding-3-small uses 1536 dimensions
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 3: Create an index for faster vector similarity search
-- This uses IVFFlat algorithm which is good for large datasets
CREATE INDEX IF NOT EXISTS sentence_embeddings_embedding_idx
ON sentence_embeddings USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Create index for grouping sentences by talk
CREATE INDEX IF NOT EXISTS sentence_embeddings_talk_id_idx
ON sentence_embeddings(talk_id);

-- Step 4: Enable Row Level Security (RLS)
ALTER TABLE sentence_embeddings ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies
-- Allow authenticated users to read all sentences
CREATE POLICY "Allow authenticated users to read"
ON sentence_embeddings FOR SELECT
TO authenticated
USING (true);

-- Step 6: Create the vector search function
-- This function performs cosine similarity search and returns matching sentences
CREATE OR REPLACE FUNCTION match_sentences(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 20
)
RETURNS TABLE (
    id uuid,
    talk_id uuid,
    title text,
    speaker text,
    text text,
    similarity float
)
LANGUAGE sql STABLE
AS $$
    SELECT
        sentence_embeddings.id,
        sentence_embeddings.talk_id,
        sentence_embeddings.title,
        sentence_embeddings.speaker,
        sentence_embeddings.text,
        1 - (sentence_embeddings.embedding <=> query_embedding) as similarity
    FROM sentence_embeddings
    WHERE 1 - (sentence_embeddings.embedding <=> query_embedding) > match_threshold
    ORDER BY sentence_embeddings.embedding <=> query_embedding
    LIMIT match_count;
$$;

-- ============================================
-- TESTING QUERIES
-- ============================================
-- After setting up, test with these queries:

-- Check if pgvector is enabled
-- SELECT * FROM pg_extension WHERE extname = 'vector';

-- Count sentences in the table
-- SELECT COUNT(*) FROM sentence_embeddings;

-- View sample sentences
-- SELECT id, title, speaker, LEFT(text, 100) as text_preview
-- FROM sentence_embeddings
-- LIMIT 5;

-- Check unique talks
-- SELECT DISTINCT title, speaker, year, season
-- FROM sentence_embeddings
-- ORDER BY year DESC, season;
