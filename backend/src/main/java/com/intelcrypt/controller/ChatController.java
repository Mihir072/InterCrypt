package com.intelcrypt.controller;

import com.intelcrypt.dto.ChatDTO;
import com.intelcrypt.service.ChatService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Chat Controller.
 * 
 * Handles chat creation, management, and participant operations.
 */
@RestController
@RequestMapping("/api/chats")
@Tag(name = "Chats", description = "Chat management endpoints")
@SecurityRequirement(name = "bearerAuth")
public class ChatController {
    
    private final ChatService chatService;
    
    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }
    
    @GetMapping
    @Operation(summary = "Get all chats",
               description = "Get all chats for the current user")
    public ResponseEntity<List<ChatDTO.ChatResponse>> getAllChats() {
        List<ChatDTO.ChatResponse> chats = chatService.getChatsForCurrentUser();
        return ResponseEntity.ok(chats);
    }
    
    @GetMapping("/paginated")
    @Operation(summary = "Get chats paginated",
               description = "Get paginated chats for the current user")
    public ResponseEntity<Page<ChatDTO.ChatResponse>> getChatsPaginated(
            @PageableDefault(size = 20) Pageable pageable) {
        Page<ChatDTO.ChatResponse> chats = chatService.getChatsForCurrentUser(pageable);
        return ResponseEntity.ok(chats);
    }
    
    @GetMapping("/{chatId}")
    @Operation(summary = "Get chat by ID",
               description = "Get a specific chat by its ID")
    public ResponseEntity<ChatDTO.ChatResponse> getChatById(@PathVariable UUID chatId) {
        ChatDTO.ChatResponse chat = chatService.getChatById(chatId);
        return ResponseEntity.ok(chat);
    }
    
    @PostMapping
    @Operation(summary = "Create a new chat",
               description = "Create a new group or channel chat")
    public ResponseEntity<ChatDTO.ChatResponse> createChat(
            @Valid @RequestBody ChatDTO.CreateChatRequest request) {
        ChatDTO.ChatResponse chat = chatService.createChat(request);
        return ResponseEntity.ok(chat);
    }
    
    @PostMapping("/direct/{userId}")
    @Operation(summary = "Get or create direct chat",
               description = "Get existing direct chat with user or create a new one")
    public ResponseEntity<ChatDTO.ChatResponse> getOrCreateDirectChat(@PathVariable UUID userId) {
        ChatDTO.ChatResponse chat = chatService.getOrCreateDirectChat(userId);
        return ResponseEntity.ok(chat);
    }
    
    @PutMapping("/{chatId}")
    @Operation(summary = "Update chat",
               description = "Update chat details")
    public ResponseEntity<ChatDTO.ChatResponse> updateChat(
            @PathVariable UUID chatId,
            @Valid @RequestBody ChatDTO.UpdateChatRequest request) {
        ChatDTO.ChatResponse chat = chatService.updateChat(chatId, request);
        return ResponseEntity.ok(chat);
    }
    
    @PostMapping("/{chatId}/participants/{userId}")
    @Operation(summary = "Add participant",
               description = "Add a user to the chat")
    public ResponseEntity<ChatDTO.ChatResponse> addParticipant(
            @PathVariable UUID chatId,
            @PathVariable UUID userId) {
        ChatDTO.ChatResponse chat = chatService.addParticipant(chatId, userId);
        return ResponseEntity.ok(chat);
    }
    
    @DeleteMapping("/{chatId}/participants/{userId}")
    @Operation(summary = "Remove participant",
               description = "Remove a user from the chat")
    public ResponseEntity<ChatDTO.ChatResponse> removeParticipant(
            @PathVariable UUID chatId,
            @PathVariable UUID userId) {
        ChatDTO.ChatResponse chat = chatService.removeParticipant(chatId, userId);
        return ResponseEntity.ok(chat);
    }
    
    @PostMapping("/{chatId}/leave")
    @Operation(summary = "Leave chat",
               description = "Leave the chat")
    public ResponseEntity<Void> leaveChat(@PathVariable UUID chatId) {
        chatService.leaveChat(chatId);
        return ResponseEntity.ok().build();
    }
    
    @DeleteMapping("/{chatId}")
    @Operation(summary = "Delete chat",
               description = "Delete a chat (creator only)")
    public ResponseEntity<Void> deleteChat(@PathVariable UUID chatId) {
        chatService.deleteChat(chatId);
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/search")
    @Operation(summary = "Search chats",
               description = "Search chats by name")
    public ResponseEntity<List<ChatDTO.ChatResponse>> searchChats(@RequestParam String query) {
        List<ChatDTO.ChatResponse> chats = chatService.searchChats(query);
        return ResponseEntity.ok(chats);
    }
}
