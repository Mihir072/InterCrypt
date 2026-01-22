package com.intelcrypt.exception;

public class SecurityPolicyException extends RuntimeException {
    
    public SecurityPolicyException(String message) {
        super(message);
    }
    
    public SecurityPolicyException(String message, Throwable cause) {
        super(message, cause);
    }
}
