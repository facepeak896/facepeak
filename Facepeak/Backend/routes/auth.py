from fastapi import APIRouter
import resend
import os
from dotenv import load_dotenv

load_dotenv()
resend.api_key = os.getenv("RESEND_API_KEY")

router = APIRouter()

@router.post("/test-email")
def test_email():
    resend.Emails.send({
        "from": "onboarding@resend.dev",
        "to": "mihael.bjelis28@gmail.com",
        "subject": "Test",
        "html": "<p>Radi 🔥</p>"
    })
    return {"status": "sent"}