import firebase_admin
from firebase_admin import credentials, messaging
import os

# Path to your downloaded JSON file
cred_path = os.path.join(os.path.dirname(__file__), 'firebase-adminsdk.json')
cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)
