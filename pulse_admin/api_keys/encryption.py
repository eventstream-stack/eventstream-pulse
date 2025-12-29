"""
Encryption utilities for secure API key storage.
Uses Fernet symmetric encryption (AES-128-CBC with HMAC).
"""

import base64
import hashlib

from cryptography.fernet import Fernet
from django.conf import settings


def get_encryption_key():
    """
    Derive Fernet key from Django SECRET_KEY.
    Uses SHA256 to create a consistent 32-byte key, then base64 encodes.

    WARNING: If SECRET_KEY changes, all encrypted values become unreadable.
    """
    key_bytes = hashlib.sha256(settings.SECRET_KEY.encode()).digest()
    return base64.urlsafe_b64encode(key_bytes)


def encrypt_value(plaintext: str) -> str:
    """Encrypt a plaintext string value."""
    fernet = Fernet(get_encryption_key())
    encrypted = fernet.encrypt(plaintext.encode())
    return encrypted.decode()


def decrypt_value(ciphertext: str) -> str:
    """Decrypt an encrypted value."""
    fernet = Fernet(get_encryption_key())
    decrypted = fernet.decrypt(ciphertext.encode())
    return decrypted.decode()
