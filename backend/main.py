"""
Knot Backend API
FastAPI server for handling BCC email webhooks and background jobs
"""

from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
from typing import Optional
import os
from dotenv import load_dotenv
import logging

load_dotenv()

app = FastAPI(title="Knot API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*", "ngrok-skip-browser-warning"],  # Allow ngrok bypass header
)

# Middleware to add ngrok skip warning header
@app.middleware("http")
async def add_ngrok_header(request: Request, call_next):
    response = await call_next(request)
    # Add header to bypass ngrok browser warning
    response.headers["ngrok-skip-browser-warning"] = "true"
    return response

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class EmailWebhook(BaseModel):
    """Email webhook payload from SendGrid/Mailgun"""
    to: str
    from_email: str
    subject: Optional[str] = None
    text: Optional[str] = None
    html: Optional[str] = None
    headers: Optional[dict] = None


@app.get("/")
async def root():
    return {"message": "Knot API", "version": "1.0.0"}


@app.post("/webhook/email")
async def handle_email_webhook(request: Request):
    """
    Handle incoming email webhook from SendGrid/Mailgun
    This endpoint receives emails that were BCC'd to user's custom address
    """
    try:
        # Parse webhook payload (format depends on email service)
        body = await request.json()
        
        # Extract email details
        to_email = body.get("to", "")
        from_email = body.get("from", "")
        subject = body.get("subject", "")
        text_content = body.get("text", "") or body.get("html", "")
        
        # Extract username from BCC email (e.g., username@inbound.careercaddie.com)
        username = to_email.split("@")[0] if "@" in to_email else None
        
        if not username:
            raise HTTPException(status_code=400, detail="Invalid email format")
        
        # TODO: 
        # 1. Find user by username
        # 2. Parse "To:" field to identify contact
        # 3. Create email_interaction record
        # 4. Update contact's last_contacted_at
        # 5. Update user's streak if needed
        
        logger.info(f"Received email from {from_email} to {to_email}")
        
        return {"status": "success", "message": "Email processed"}
        
    except Exception as e:
        logger.error(f"Error processing email webhook: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/cron/update-health")
async def cron_update_relationship_health():
    """
    Cron job endpoint to update relationship health for all users
    Should be called every 15 minutes
    """
    try:
        # TODO: 
        # 1. Get all users
        # 2. For each user, calculate relationship health for all contacts
        # 3. Update database
        
        logger.info("Updating relationship health for all users")
        return {"status": "success"}
        
    except Exception as e:
        logger.error(f"Error updating relationship health: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/cron/check-meetings")
async def cron_check_upcoming_meetings():
    """
    Cron job endpoint to check for upcoming meetings and send pre-meeting briefs
    Should be called every 15 minutes
    """
    try:
        # TODO:
        # 1. Get all users with calendar sync enabled
        # 2. For each user, check calendar events in next 30 minutes
        # 3. Match events with contacts
        # 4. Generate pre-meeting briefs
        # 5. Send push notifications
        
        logger.info("Checking upcoming meetings")
        return {"status": "success"}
        
    except Exception as e:
        logger.error(f"Error checking meetings: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/linkedin-callback")
async def linkedin_callback(request: Request):
    """
    Handle LinkedIn OAuth callback
    Receives the authorization code and redirects to the mobile app via deep link
    For web, redirects to the Flutter web app
    """
    # Log everything for debugging
    logger.info(f"LinkedIn callback received")
    logger.info(f"Request URL: {request.url}")
    logger.info(f"Query string: {request.url.query}")
    logger.info(f"Query params dict: {dict(request.query_params)}")
    logger.info(f"Headers: {dict(request.headers)}")
    
    # Try multiple ways to get the code
    code = request.query_params.get("code")
    state = request.query_params.get("state")
    error = request.query_params.get("error")
    
    # Also try parsing from query string directly
    if not code and request.url.query:
        from urllib.parse import parse_qs
        parsed = parse_qs(request.url.query)
        if "code" in parsed:
            code = parsed["code"][0] if parsed["code"] else None
        if "error" in parsed:
            error = parsed["error"][0] if parsed["error"] else None
        if "state" in parsed:
            state = parsed["state"][0] if parsed["state"] else None
        logger.info(f"Parsed from query string - Code: {code}, Error: {error}, State: {state}")
    
    # Check if this is a web request (has Referer or User-Agent indicating browser)
    user_agent = request.headers.get("user-agent", "").lower()
    is_web = "chrome" in user_agent or "firefox" in user_agent or "safari" in user_agent or "edge" in user_agent
    
    logger.info(f"Code: {code}, State: {state}, Error: {error}, Is Web: {is_web}")
    
    if error:
        if is_web:
            # For web, redirect to the Flutter app with error
            return RedirectResponse(url=f"http://localhost:52444/#/import/linkedin?error={error}")
        else:
            # For mobile, use deep link
            app_deep_link = f"knot://linkedin-callback?error={error}"
            return RedirectResponse(url=app_deep_link)
    
    if not code:
        # Return helpful error page with debugging info
        error_html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>OAuth Error</title>
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    padding: 40px;
                    max-width: 600px;
                    margin: 0 auto;
                }}
                .error {{
                    background: #fee;
                    border: 2px solid #fcc;
                    padding: 20px;
                    border-radius: 5px;
                }}
                .info {{
                    background: #eef;
                    border: 1px solid #ccf;
                    padding: 15px;
                    margin-top: 20px;
                    border-radius: 5px;
                    font-size: 12px;
                }}
            </style>
        </head>
        <body>
            <div class="error">
                <h2>⚠️ OAuth Error: No authorization code received</h2>
                <p>LinkedIn did not provide an authorization code in the callback.</p>
            </div>
            <div class="info">
                <h3>Debug Information:</h3>
                <p><strong>Query Parameters:</strong> {dict(request.query_params)}</p>
                <p><strong>Full URL:</strong> {request.url}</p>
                <p><strong>Error Parameter:</strong> {error or 'None'}</p>
                <p><strong>State Parameter:</strong> {state or 'None'}</p>
            </div>
            <p><a href="http://localhost:52444/#/import/linkedin">Return to App</a></p>
        </body>
        </html>
        """
        from fastapi.responses import HTMLResponse
        return HTMLResponse(content=error_html, status_code=400)
    
    if is_web:
        # For web, return an HTML page that redirects to the Flutter app
        # Try to detect the Flutter app port from common ports or use default
        # Common Flutter web dev ports: 52444, 50000-60000 range
        flutter_port = "52444"  # Default Flutter web port
        
        # Try to get port from referer if available
        referer = request.headers.get("referer", "")
        if referer:
            import re
            port_match = re.search(r':(\d+)', referer)
            if port_match:
                flutter_port = port_match.group(1)
        
        redirect_url = f"http://localhost:{flutter_port}/#/import/linkedin?code={code}&state={state or ''}"
        
        # Return HTML page with multiple redirect methods
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>LinkedIn OAuth Success - Redirecting...</title>
            <meta http-equiv="refresh" content="2;url={redirect_url}">
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                }}
                .container {{
                    text-align: center;
                    padding: 40px;
                    background: rgba(255, 255, 255, 0.1);
                    border-radius: 20px;
                    backdrop-filter: blur(10px);
                }}
                h1 {{
                    margin-top: 0;
                }}
                .spinner {{
                    border: 4px solid rgba(255, 255, 255, 0.3);
                    border-top: 4px solid white;
                    border-radius: 50%;
                    width: 40px;
                    height: 40px;
                    animation: spin 1s linear infinite;
                    margin: 20px auto;
                }}
                @keyframes spin {{
                    0% {{ transform: rotate(0deg); }}
                    100% {{ transform: rotate(360deg); }}
                }}
                a {{
                    color: white;
                    text-decoration: underline;
                    font-weight: bold;
                    margin-top: 20px;
                    display: inline-block;
                    padding: 10px 20px;
                    background: rgba(255, 255, 255, 0.2);
                    border-radius: 5px;
                }}
                a:hover {{
                    background: rgba(255, 255, 255, 0.3);
                }}
            </style>
            <script>
                // Try multiple redirect methods
                function redirect() {{
                    window.location.href = "{redirect_url}";
                }}
                
                // Try immediate redirect
                setTimeout(redirect, 100);
                
                // Fallback after 2 seconds
                setTimeout(redirect, 2000);
            </script>
        </head>
        <body>
            <div class="container">
                <h1>✅ LinkedIn Authorization Successful!</h1>
                <p>Redirecting to your app...</p>
                <div class="spinner"></div>
                <p>If you're not redirected automatically, click below:</p>
                <a href="{redirect_url}" onclick="redirect(); return false;">Continue to App</a>
            </div>
        </body>
        </html>
        """
        from fastapi.responses import HTMLResponse
        return HTMLResponse(content=html_content)
    else:
        # For mobile, use deep link
        app_deep_link = f"knot://linkedin-callback?code={code}&state={state or ''}"
        return RedirectResponse(url=app_deep_link)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
