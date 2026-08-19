import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def send_password_reset_email(to_email: str, reset_token: str):
    """
    Sends a password reset email.
    If SMTP variables are not configured in .env, it defaults to printing the token
    to the console (useful for development).
    """
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = os.getenv("SMTP_PORT")
    smtp_user = os.getenv("SMTP_USER")
    smtp_pass = os.getenv("SMTP_PASS")
    
    frontend_url = os.getenv("FRONTEND_URL", "http://localhost:8080")
    reset_link = f"{frontend_url}/reset-password?token={reset_token}"
    
    if not all([smtp_host, smtp_port, smtp_user, smtp_pass]):
        print("\n" + "="*50)
        print("📧 [DUMMY EMAIL SERVICE] Password Reset Requested")
        print(f"To: {to_email}")
        print(f"Token: {reset_token}")
        print(f"Link: {reset_link}")
        print("="*50 + "\n")
        return True

    try:
        msg = MIMEMultipart()
        msg['From'] = smtp_user
        msg['To'] = to_email
        msg['Subject'] = "CYO Game - Password Reset Request"
        
        body = f"""
        Hello,
        
        We received a request to reset your password.
        Please use the following code to reset your password:
        
        {reset_token}
        
        Or click this link:
        {reset_link}
        
        If you did not request this, please ignore this email.
        """
        
        msg.attach(MIMEText(body, 'plain'))
        
        server = smtplib.SMTP(smtp_host, int(smtp_port))
        server.starttls()
        server.login(smtp_user, smtp_pass)
        server.send_message(msg)
        server.quit()
        return True
    except Exception as e:
        print(f"Failed to send email: {e}")
        return False
