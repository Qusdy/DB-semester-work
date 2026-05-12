package com.taskqueue.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "tasks")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Task {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long orderId;
    private String taskType;
    private Integer priority;
    private String status;
    private Integer attempts;
    private Integer maxAttempts;
    private LocalDateTime createdAt;
    private LocalDateTime scheduledAt;
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private String errorMessage;

    @Version
    private Long version;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (scheduledAt == null) scheduledAt = LocalDateTime.now();
        if (status == null) status = "READY";
        if (attempts == null) attempts = 0;
        if (maxAttempts == null) maxAttempts = 3;
    }
}