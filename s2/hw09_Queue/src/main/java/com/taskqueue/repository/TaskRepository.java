package com.taskqueue.repository;

import com.taskqueue.model.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;

public interface TaskRepository extends JpaRepository<Task, Long> {

    // 1. Метод для захвата задачи (используется в ConsumerService)
    @Query(value = """
        UPDATE tasks 
        SET status = 'RUNNING', started_at = :now, version = version + 1
        WHERE id = (
            SELECT id FROM tasks 
            WHERE status = 'READY' AND scheduled_at <= :now
            ORDER BY priority DESC, scheduled_at ASC
            FOR UPDATE SKIP LOCKED
            LIMIT 1
        )
        RETURNING *
        """, nativeQuery = true)
    Optional<Task> claimNextTask(@Param("now") LocalDateTime now);

    // 2. Метод для завершения задачи
    @Modifying
    @Query("UPDATE Task t SET t.status = 'COMPLETED', t.completedAt = :now WHERE t.id = :id")
    void markCompleted(@Param("id") Long id, @Param("now") LocalDateTime now);

    // 3. Метод для мониторинга: расчет лага (используется в TaskQueueApplication)
    // Лаг — это разница в секундах между текущим временем и самой старой задачей в очереди
    @Query(value = """
        SELECT COALESCE(EXTRACT(EPOCH FROM (NOW() - MIN(scheduled_at))), 0)
        FROM tasks 
        WHERE status = 'READY'
        """, nativeQuery = true)
    double getQueueLagSeconds();

    // 4. Стандартный метод Spring Data JPA для подсчета по статусу
    long countByStatus(String status);
}