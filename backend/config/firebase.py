import os
import firebase_admin
from firebase_admin import credentials, auth, messaging, firestore

# Path to serviceAccountKey.json
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVICE_ACCOUNT_KEY_PATH = os.path.join(BASE_DIR, 'serviceAccountKey.json')

firebase_app = None
db_firestore = None

def initialize_firebase():
    global firebase_app, db_firestore
    if not firebase_admin._apps:
        if os.path.exists(SERVICE_ACCOUNT_KEY_PATH):
            cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
            firebase_app = firebase_admin.initialize_app(cred)
            db_firestore = firestore.client()
            print("[Firebase] Firebase Admin SDK initialized successfully!")
        else:
            print("[Firebase] serviceAccountKey.json not found in pms_backend. Firebase Admin SDK not initialized.")
    else:
        firebase_app = firebase_admin.get_app()

initialize_firebase()
