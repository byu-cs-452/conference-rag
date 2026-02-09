# Conference RAG

A production-ready Retrieval Augmented Generation (RAG) application that lets users ask questions about General Conference talks using semantic search and AI-generated answers.

## 🚀 Features

- ✅ **Supabase Authentication** — Magic link login
- ✅ **Vector Search** — Semantic search with pgvector
- ✅ **Edge Functions** — Server-side OpenAI API calls (keys never exposed)
- ✅ **Row Level Security** — Database-level access control
- ✅ **GitHub Pages** — Free, automatic deployment

## 📋 Setup

### Google Colab Notebook (Recommended) ⭐

The setup notebook walks you through every step:

1. Upload `setup.ipynb` to [Google Colab](https://colab.research.google.com/)
2. Follow the guided steps (~85 minutes)
3. Your RAG app will be live on GitHub Pages!

**Prerequisites:**
- [Supabase](https://supabase.com) account (free tier)
- [GitHub](https://github.com) account
- [OpenAI API key](https://platform.openai.com/api-keys) (~$0.60 usage)

## 🏗️ Architecture

```
┌─────────────┐
│   Browser   │  Student asks question
│  (GitHub    │
│   Pages)    │
└──────┬──────┘
       │
       ├─── Supabase Auth (magic link)
       │
       ├─── Edge Function: embed-question
       │         ↓ OpenAI API (server-side 🔒)
       │         ↓ Returns embedding vector
       │
       ├─── Supabase Database (pgvector)
       │         ↓ match_sentences()
       │         ↓ Returns similar sentences
       │         ↓ Grouped by talk, ranked
       │
       └─── Edge Function: generate-answer
                 ↓ GPT-4o-mini (server-side 🔒)
                 ↓ Returns final answer
```

## 📚 Learning Objectives

1. **Vector Embeddings** — Representing text as searchable numbers
2. **Semantic Search** — Finding similar content with cosine similarity
3. **RAG Architecture** — Combining retrieval + generation
4. **Edge Functions** — Serverless compute for secure API management
5. **Row Level Security** — User-level data access control
6. **Production Deployment** — Full-stack app on GitHub Pages

## 🔒 Security Model

| Component | Security Approach |
|-----------|------------------|
| Supabase anon key | Safe to expose (protected by RLS) |
| OpenAI API key | Server-side only via Edge Functions |
| Database access | Row Level Security policies |
| Transport | HTTPS enforced by GitHub Pages |

## 📁 Project Structure

```
conference-rag/
├── index.html              # Main application UI
├── app.js                  # Authentication + RAG logic
├── styles.css              # Dark theme styling
├── config.js               # Supabase credentials (you edit this)
├── database-setup.sql      # Schema reference
├── setup.ipynb             # Setup notebook (run in Colab)
├── notebook_content/       # Markdown sources for notebook
│   ├── 00_welcome.md
│   ├── ...
│   └── 09_reflection.md
├── convert_to_notebook.py  # Regenerate setup.ipynb from markdown
└── .github/workflows/
    └── deploy.yml          # Auto-deploy to GitHub Pages
```

## 🎓 Assignment Deliverables

1. GitHub repository URL
2. Live deployment URL (GitHub Pages)
3. Screenshot of a working query + answer
4. Brief reflection on embedding strategies

## ⚠️ Important Notes

- Update `config.js` with your Supabase credentials before deploying
- Deploy Edge Functions before testing (the notebook handles this)
- Add your GitHub Pages URL to Supabase redirect URLs
- Never commit real API keys to public repositories

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Please configure Supabase" | Update `config.js` with your project URL and anon key |
| Magic link not working | Add your site URL to Supabase → Authentication → URL Configuration |
| "Failed to get embedding" | Deploy Edge Functions (see notebook Part 5) |
| "Database search failed" | Run the database schema SQL (see notebook Part 3) |
| No search results | Import data first (see notebook Parts 6-7) |

## 📄 License

Educational use only. Conference talk content is used under fair use for educational purposes.

---

Built with ❤️ for CS 452
