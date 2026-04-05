package com.intelcrypt.controller;

import com.intelcrypt.entity.AuditLog;
import com.intelcrypt.repository.AuditLogRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@Tag(name = "Admin", description = "Administrative Control Panel APIs")
@SecurityRequirement(name = "bearerAuth")
public class AdminController {

    private final AuditLogRepository auditLogRepository;

    public AdminController(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    @GetMapping("/audit")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Get system audit logs", description = "Retrieves recent system-wide audit logs with pagination")
    public ResponseEntity<List<AuditLog>> getAuditLogs(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "100") int size) {
        
        PageRequest pageRequest = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "timestamp"));
        Page<AuditLog> logPage = auditLogRepository.findAll(pageRequest);
        return ResponseEntity.ok(logPage.getContent());
    }
}
