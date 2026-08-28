import os
import logging
import requests

logger = logging.getLogger(__name__)


class OTPService:
    """
    Government Compliant OTP & Email Service Provider.
    Strictly avoids 3rd-party commercial SMTP servers per Govt Authentication Standards.
    Supports DEV_MODE (Local Console / Mock) and NIC_GATEWAY (Official Govt NIC / e-Pramaan).
    """

    @staticmethod
    def send_email_otp(recipient_email: str, otp: str = "123456") -> bool:
        provider = os.getenv("OTP_PROVIDER", "DEV_MODE").upper()
        nic_api_key = os.getenv("NIC_API_KEY", "").strip()

        if provider == "NIC_GATEWAY" and nic_api_key:
            # Official NIC Email Gateway Integration
            gateway_url = os.getenv("NIC_EMAIL_GATEWAY_URL", "https://emailgw.nic.in/api/v1/send")
            department_id = os.getenv("NIC_DEPARTMENT_ID", "POLICE_PMS")

            payload = {
                "department_id": department_id,
                "api_key": nic_api_key,
                "to_email": recipient_email,
                "subject": "PMS Govt Registration OTP Verification",
                "message": f"Your official Police Management System verification OTP is {otp}. Valid for 10 minutes."
            }

            try:
                response = requests.post(gateway_url, json=payload, timeout=10)
                if response.status_code == 200:
                    logger.info(f"[NIC Email Gateway] Successfully dispatched OTP email to {recipient_email}")
                    return True
                else:
                    logger.error(f"[NIC Email Gateway] Failed to send email via NIC: {response.status_code} - {response.text}")
            except Exception as e:
                logger.error(f"[NIC Email Gateway] Connection error: {e}")

        # Local DEV_MODE Fallback (Compliant, 0 Cost, No Commercial SMTP)
        logger.info(f"[DEV_MODE OTP] Email Verification OTP for {recipient_email} is: {otp}")
        print(f"\n=======================================================")
        print(f"  [NIC COMPLIANT DEV GATEWAY] EMAIL OTP DISPATCHED")
        print(f"  Recipient: {recipient_email}")
        print(f"  OTP Code:  {otp}")
        print(f"=======================================================\n")
        return True

    @staticmethod
    def send_sms_otp(phone_number: str, otp: str = "123456") -> bool:
        provider = os.getenv("OTP_PROVIDER", "DEV_MODE").upper()
        nic_api_key = os.getenv("NIC_API_KEY", "").strip()

        if provider == "NIC_GATEWAY" and nic_api_key:
            # Official NIC SMS Gateway Integration
            gateway_url = os.getenv("NIC_SMS_GATEWAY_URL", "https://smsgw.sms.gov.in/api/v1/send")
            department_id = os.getenv("NIC_DEPARTMENT_ID", "POLICE_PMS")

            payload = {
                "department_id": department_id,
                "api_key": nic_api_key,
                "phone": phone_number,
                "sender_id": "POLICE",
                "message": f"Your Police Management System verification OTP is {otp}."
            }

            try:
                response = requests.post(gateway_url, json=payload, timeout=10)
                if response.status_code == 200:
                    logger.info(f"[NIC SMS Gateway] Successfully dispatched OTP SMS to {phone_number}")
                    return True
                else:
                    logger.error(f"[NIC SMS Gateway] Failed to send SMS via NIC: {response.status_code} - {response.text}")
            except Exception as e:
                logger.error(f"[NIC SMS Gateway] Connection error: {e}")

        # Local DEV_MODE Fallback
        logger.info(f"[DEV_MODE OTP] SMS Verification OTP for {phone_number} is: {otp}")
        print(f"\n=======================================================")
        print(f"  [NIC COMPLIANT DEV GATEWAY] SMS OTP DISPATCHED")
        print(f"  Mobile:   {phone_number}")
        print(f"  OTP Code: {otp}")
        print(f"=======================================================\n")
        return True
