package com.taskqueue.service;

import com.taskqueue.model.Task;
import com.taskqueue.repository.TaskRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Random;
import java.util.concurrent.atomic.AtomicLong;

@Slf4j
@Service
public class ProducerService {

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private final Random rnd = new Random();
    private final AtomicLong producedCount = new AtomicLong();

    @Transactional
    public void produceOneTask() {
        boolean isCritical = rnd.nextDouble() < 0.2; // 20% критических
        int priority = isCritical ? 100 : 0;
        String taskType = isCritical ? "PROCESS_PAYMENT" : "SEND_ORDER_EMAIL";

        // 1. Фиктивная бизнес-логика (создание заказа маркетплейса)
        String itemName = "Товар #" + rnd.nextInt(1000);
        jdbcTemplate.update("INSERT INTO orders (item_name) VALUES (?)", itemName);
        long dummyOrderId = rnd.nextLong(1000) + 1;

        // 2. Вставка задачи в рамках той же транзакции
        Task task = Task.builder()
                .orderId(dummyOrderId)
                .taskType(taskType)
                .priority(priority)
                .status("READY")
                .attempts(0)
                .maxAttempts(3)
                .createdAt(LocalDateTime.now())
                .scheduledAt(LocalDateTime.now())
                .build();

        taskRepository.save(task);
        producedCount.incrementAndGet();
    }

    public void startProducing(int targetRps, int durationSeconds) {
        long endTime = System.currentTimeMillis() + durationSeconds * 1000L;
        long delayBetweenTasksMs = 1000L / targetRps;

        log.info("Продьюсер запущен: цель ~{} RPS на {} секунд", targetRps, durationSeconds);
        while (System.currentTimeMillis() < endTime) {
            long start = System.currentTimeMillis();
            produceOneTask();
            long elapsed = System.currentTimeMillis() - start;

            if (elapsed < delayBetweenTasksMs) {
                try { Thread.sleep(delayBetweenTasksMs - elapsed); } catch (InterruptedException ignored) {}
            }
        }
        log.info("Продьюсер завершил работу. Создано задач: {}", producedCount.get());
    }
}