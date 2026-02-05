-- ============================================
-- SUPABASE DATABASE SETUP
-- ============================================
-- Run this in your Supabase SQL Editor

-- Step 1: Enable the pgvector extension for vector similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- Step 2: Create the documents table
CREATE TABLE IF NOT EXISTS documents (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    embedding vector(1536),  -- OpenAI text-embedding-3-small uses 1536 dimensions
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create an index for faster vector similarity search
-- This uses IVFFlat algorithm which is good for large datasets
CREATE INDEX IF NOT EXISTS documents_embedding_idx 
ON documents 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Step 4: Create the vector search function
-- This function performs cosine similarity search
CREATE OR REPLACE FUNCTION search_documents(
    query_embedding vector(1536),
    match_count INT DEFAULT 5,
    min_similarity FLOAT DEFAULT 0.0
)
RETURNS TABLE (
    id BIGINT,
    content TEXT,
    metadata JSONB,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        documents.id,
        documents.content,
        documents.metadata,
        1 - (documents.embedding <=> query_embedding) AS similarity
    FROM documents
    WHERE 1 - (documents.embedding <=> query_embedding) > min_similarity
    ORDER BY documents.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- Step 5: Enable Row Level Security (RLS)
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- ============================================
-- TODO: STUDENTS IMPLEMENT RLS POLICIES
-- ============================================
-- You need to create policies that:
-- 1. Allow authenticated users to read all documents
-- 2. (Optional) Control who can insert/update/delete documents

-- Example Policy 1: Allow all authenticated users to read documents
-- Uncomment and modify as needed:
/*
CREATE POLICY "authenticated_users_read_documents"
    ON documents
    FOR SELECT
    TO authenticated
    USING (true);
*/

-- Example Policy 2: Only allow service role to insert documents
-- This prevents regular users from adding fake data
/*
CREATE POLICY "service_role_insert_documents"
    ON documents
    FOR INSERT
    TO service_role
    WITH CHECK (true);
*/

-- Example Policy 3: Prevent all users from deleting documents
/*
CREATE POLICY "no_delete_documents"
    ON documents
    FOR DELETE
    TO authenticated
    USING (false);
*/

-- ============================================
-- TESTING QUERIES
-- ============================================
-- After setting up, test with these queries:

-- Check if pgvector is enabled
-- SELECT * FROM pg_extension WHERE extname = 'vector';

-- Count documents in the table
-- SELECT COUNT(*) FROM documents;

-- View sample documents
-- SELECT id, LEFT(content, 100) as content_preview, metadata 
-- FROM documents 
-- LIMIT 5;

-- Test the search function (you'll need actual embeddings)
-- SELECT * FROM search_documents(
--     '[0.1, 0.2, ...]'::vector(1536),  -- Replace with actual embedding
--     5  -- Number of results
-- );

-- ============================================
-- OPTIONAL: Create a user_queries table to track searches
-- ============================================
/*
CREATE TABLE IF NOT EXISTS user_queries (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    query TEXT NOT NULL,
    results JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_queries ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own queries
CREATE POLICY "users_read_own_queries"
    ON user_queries
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own queries
CREATE POLICY "users_insert_own_queries"
    ON user_queries
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);
*/

-- ============================================
-- HELPFUL FUNCTIONS
-- ============================================

-- Function to get document count
CREATE OR REPLACE FUNCTION get_document_count()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    doc_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO doc_count FROM documents;
    RETURN doc_count;
END;
$$;

-- Function to get embedding statistics
CREATE OR REPLACE FUNCTION get_embedding_stats()
RETURNS TABLE (
    total_documents BIGINT,
    documents_with_embeddings BIGINT,
    documents_without_embeddings BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) as total_documents,
        COUNT(embedding) as documents_with_embeddings,
        COUNT(*) - COUNT(embedding) as documents_without_embeddings
    FROM documents;
END;
$$;
