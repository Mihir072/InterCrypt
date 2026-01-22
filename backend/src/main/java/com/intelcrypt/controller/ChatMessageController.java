package com.intelcrypt.controller;

import com.intelcrypt.dto.ChatDTO;
import com.intelcrypt.dto.MessageDTO;
import com.intelcrypt.security.UserPrincipal;
import com.intelcrypt.service.ChatMessageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Chat-based Message Controller.
 * 
 * Handles messages within chat conversations, aligned with frontend expectations.
 */
@RestController
@RequestMapping("/api/chats/{chatId}/messages")
@Tag(name = "Chat Messages", description = "Chat-based messaging endpoints")
@SecurityRequirement(name = "bearerAuth")
public class ChatMessageController {
    
    private final ChatMessageService chatMessageService;
    
    public ChatMessageController(ChatMessageService chatMessageService) {
        this.chatMessageService = chatMessageService;
    }
    
    @GetMapping
    @Operation(summary = "Get messages",
               description = "Get messages for a chat")
    public ResponseEntity<List<MessageDTO.ChatMessageResponse>> getMessages(
            @PathVariable UUID chatId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(defaultValue = "50") int limit,
            @RequestParam(required = false) String beforeMessageId) {
        
        UUID beforeId = beforeMessageId != null ? UUID.fromString(beforeMessageId) : null;
        List<MessageDTO.ChatMessageResponse> messages = chatMessageService.getMessages(
            chatId, principal.getUser().getId(), limit, beforeId);
        
        return ResponseEntity.ok(messages);
    }
    
    @PostMapping
    @Operation(summary = "Send message",
               description = "Send a message to a chat")
    public ResponseEntity<MessageDTO.ChatMessageResponse> sendMessage(
            @PathVariable UUID chatId,
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody MessageDTO.SendChatMessageRequest request,
            HttpServletRequest httpRequest) {
        
        MessageDTO.ChatMessageResponse response = chatMessageService.sendMessage(
            chatId,
            principal.getUser().getId(),
            request,
            getClientIp(httpRequest)
        );
        
        return ResponseEntity.ok(response);
    }
    
    @PutMapping("/{messageId}/read")
    @Operation(summary = "Mark message as read",
               description = "Mark a specific message as read")
    public ResponseEntity<Void> markAsRead(
            @PathVariable UUID chatId,
            @PathVariable UUID messageId,
            @AuthenticationPrincipal UserPrincipal principal) {
        
        chatMessageService.markMessageAsRead(chatId, messageId, principal.getUser().getId());
        return ResponseEntity.ok().build();
    }
    
    @PutMapping("/read-all")
    @Operation(summary = "Mark all messages as read",
               description = "Mark all messages in the chat as read")
    public ResponseEntity<Void> markAllAsRead(
            @PathVariable UUID chatId,
            @AuthenticationPrincipal UserPrincipal principal) {
        
        chatMessageService.markAllMessagesAsRead(chatId, principal.getUser().getId());
        return ResponseEntity.ok().build();
    }
    
    @DeleteMapping("/{messageId}")
    @Operation(summary = "Delete message",
               description = "Delete a message from the chat")
    public ResponseEntity<Void> deleteMessage(
            @PathVariable UUID chatId,
            @PathVariable UUID messageId,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest httpRequest) {
        
        chatMessageService.deleteMessage(chatId, messageId, principal.getUser().getId(), getClientIp(httpRequest));
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/search")
    @Operation(summary = "Search messages",
               description = "Search messages in the chat")
    public ResponseEntity<List<MessageDTO.ChatMessageResponse>> searchMessages(
            @PathVariable UUID chatId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam String q) {
        
        List<MessageDTO.ChatMessageResponse> messages = chatMessageService.searchMessages(
            chatId, principal.getUser().getId(), q);
        
        return ResponseEntity.ok(messages);
    }
    
    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
