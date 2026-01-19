# Knot Backend API

FastAPI backend for handling email webhooks, cron jobs, and background processing.

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Create a `.env` file:
```
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_KEY=your_supabase_service_key
OPENAI_API_KEY=your_openai_api_key
```

3. Run the server:
```bash
uvicorn main:app --reload
```

## Endpoints

### POST `/webhook/email`
Receives email webhooks from SendGrid/Mailgun when users BCC their custom address.

### POST `/cron/update-health`
Cron job to update relationship health for all contacts (run every 15 minutes).

### POST `/cron/check-meetings`
Cron job to check for upcoming meetings and send pre-meeting briefs (run every 15 minutes).

## Email Service Setup

### SendGrid
1. Create a SendGrid account
2. Set up Inbound Parse webhook pointing to `/webhook/email`
3. Configure domain: `inbound.careercaddie.com` (or your domain)

### Mailgun
1. Create a Mailgun account
2. Set up Routes to forward emails to `/webhook/email`
3. Configure domain: `inbound.careercaddie.com` (or your domain)
