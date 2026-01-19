"""
LinkedIn OAuth Callback Handler
This endpoint receives the OAuth callback from LinkedIn and redirects to the app
"""

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import RedirectResponse
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/linkedin-callback")
async def linkedin_callback(request: Request):
    """
    Handle LinkedIn OAuth callback
    Receives the authorization code and redirects to the mobile app
    """
    code = request.query_params.get("code")
    state = request.query_params.get("state")
    error = request.query_params.get("error")
    
    if error:
        # Handle error - redirect to app with error
        app_deep_link = f"knot://linkedin-callback?error={error}"
        return RedirectResponse(url=app_deep_link)
    
    if not code:
        return {"error": "No authorization code received"}
    
    # Redirect to app with the code
    # The app will handle exchanging the code for an access token
    app_deep_link = f"knot://linkedin-callback?code={code}&state={state or ''}"
    return RedirectResponse(url=app_deep_link)


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)
