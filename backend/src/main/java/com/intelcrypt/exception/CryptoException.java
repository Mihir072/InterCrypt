package com.intelcrypt.exception;

/**
 * Custom exception for cryptographic operations.
 * Used to wrap low-level crypto exceptions with meaningful messages.
 */
public class CryptoException extends RuntimeException {
    
    public CryptoException(String message) {
        super(message);
    }
    
    public CryptoException(String message, Throwable cause) {
        super(message, cause);
    }
}
