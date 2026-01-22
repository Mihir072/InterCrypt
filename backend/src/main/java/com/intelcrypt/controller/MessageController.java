package com.intelcrypt.controller;

import com.intelcrypt.dto.MessageDTO;
import com.intelcrypt.security.UserPrincipal;
import com.intelcrypt.service.MessageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

/**
 * Secure Messaging Controller.
 * 
 * Handles sending, receiving, and decrypting encrypted messages.
 */
@RestController
@RequestMapping("/api/messages")
@Tag(name = "Messaging", description = "Secure messaging endpoints")
@SecurityRequirement(name = "bearerAuth")
public class MessageController {
    
    private final MessageService messageService;

    public MessageController(MessageService messageService) {
        this.messageService = messageService;
    }
    
    @PostMapping("/send")
    @Operation(summary = "Send encrypted message",
               description = "Send an encrypted message to another user")
    public ResponseEntity<MessageDTO.SendResponse> sendMessage(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody MessageDTO.SendRequest request,
            HttpServletRequest httpRequest) {
        
        MessageDTO.SendResponse response = messageService.sendMessage(
            principal.getUser().getId(),
            request,
            getClientIp(httpRequest)
        );
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/inbox")
    @Operation(summary = "Get inbox",
               description = "Retrieve received messages (encrypted)")
    public ResponseEntity<MessageDTO.MessageListResponse> getInbox(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        MessageDTO.MessageListResponse response = messageService.getInbox(
            principal.getUser().getId(), page, size);
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/sent")
    @Operation(summary = "Get sent messages",
               description = "Retrieve sent messages")
    public ResponseEntity<MessageDTO.MessageListResponse> getSentMessages(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        MessageDTO.MessageListResponse response = messageService.getSentMessages(
            principal.getUser().getId(), page, size);
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/{messageId}")
    @Operation(summary = "Get message details",
               description = "Get encrypted message details")
    public ResponseEntity<MessageDTO.MessageDetail> getMessage(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable String messageId,
            HttpServletRequest httpRequest) {
        
        MessageDTO.MessageDetail response = messageService.getMessage(
            principal.getUser().getId(),
            UUID.fromString(messageId),
            getClientIp(httpRequest)
        );
        
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/decrypt")
    @Operation(summary = "Decrypt message",
               description = "Decrypt a message using your private key")
    public ResponseEntity<MessageDTO.DecryptedMessage> decryptMessage(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody MessageDTO.DecryptRequest request,
            HttpServletRequest httpRequest) {
        
        MessageDTO.DecryptedMessage response = messageService.decryptMessage(
            principal.getUser().getId(),
            request,
            getClientIp(httpRequest)
        );
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/{messageId}/ack")
    @Operation(summary = "Get delivery acknowledgment",
               description = "Get delivery status without revealing content")
    public ResponseEntity<MessageDTO.DeliveryAck> getDeliveryAck(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable String messageId) {
        
        MessageDTO.DeliveryAck response = messageService.getDeliveryAcknowledgment(
            principal.getUser().getId(),
            UUID.fromString(messageId)
        );
        
        return ResponseEntity.ok(response);
    }
    
    @DeleteMapping("/{messageId}")
    @Operation(summary = "Delete message",
               description = "Securely delete a message")
    public ResponseEntity<Void> deleteMessage(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable String messageId,
            HttpServletRequest httpRequest) {
        
        messageService.deleteMessage(
            principal.getUser().getId(),
            UUID.fromString(messageId),
            getClientIp(httpRequest)
        );
        
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/unread/count")
    @Operation(summary = "Count unread messages",
               description = "Get count of unread messages")
    public ResponseEntity<Map<String, Long>> countUnread(
            @AuthenticationPrincipal UserPrincipal principal) {
        
        long count = messageService.countUnread(principal.getUser().getId());
        return ResponseEntity.ok(Map.of("unread", count));
    }
    
    // Classified message endpoints
    
    @PostMapping("/classified/send")
    @PreAuthorize("hasAnyRole('CLASSIFIED', 'ADMIN')")
    @Operation(summary = "Send classified message",
               description = "Send a message with elevated classification")
    public ResponseEntity<MessageDTO.SendResponse> sendClassifiedMessage(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody MessageDTO.SendRequest request,
            HttpServletRequest httpRequest) {
        
        // Force classified or higher classification
        if (request.getClassification() == null || 
            request.getClassification().ordinal() < 
            com.intelcrypt.entity.Message.MessageClassification.CONFIDENTIAL.ordinal()) {
            request.setClassification(
                com.intelcrypt.entity.Message.MessageClassification.CONFIDENTIAL);
        }
        
        MessageDTO.SendResponse response = messageService.sendMessage(
            principal.getUser().getId(),
            request,
            getClientIp(httpRequest)
        );
        
        return ResponseEntity.ok(response);
    }
    
    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
