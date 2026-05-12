package com.taskqueue.service;

import com.taskqueue.model.Task;
import com.taskqueue.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Scope;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.Random;
import java.util.concurrent.atomic.AtomicLong;

@Slf4j
@Service
@Scope("prototype") // Важно для создания нескольких экземпляров воркеров
@RequiredArgsConstructor
public class ConsumerService {

    private final TaskRepository repo;
    private final TransactionTemplate transactionTemplate;
    private final Random rnd = new Random();

    // Счетчики для мониторинга
    private final AtomicLong completedCount = new AtomicLong();

    /**
     * Точка входа для TaskQueueApplication
     */
    public void startWorker(String workerId) {
        log.info("[{}] Воркер запущен", workerId);

        while (!Thread.currentThread().isInterrupted()) {
            try {
                // Пытаемся захватить и обработать задачу в отдельной транзакции
                boolean hasProcessed = transactionTemplate.execute(status -> processOne(workerId));

                if (!hasProcessed) {
                    // Если задач нет, засыпаем, чтобы не нагружать БД
                    Thread.sleep(100);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            } catch (Exception e) {
                log.error("[{}] Сбой в цикле воркера: {}", workerId, e.getMessage());
            }
        }
    }

    private boolean processOne(String workerId) {
        LocalDateTime now = LocalDateTime.now();

        // Атомарный захват задачи (использует UPDATE ... RETURNING и SKIP LOCKED)
        Optional<Task> taskOpt = repo.claimNextTask(now);

        if (taskOpt.isEmpty()) {
            return false;
        }

        Task task = taskOpt.get();
        log.info("[{}] Взял задачу #{} (Тип: {}, Приоритет: {})",
                workerId, task.getId(), task.getTaskType(), task.getPriority());

        try {
            // Имитация работы
            Thread.sleep(200 + rnd.nextInt(300));

            if (rnd.nextDouble() < 0.1) {
                throw new RuntimeException("Симулированная ошибка");
            }

            // Завершаем задачу
            repo.markCompleted(task.getId(), LocalDateTime.now());
            completedCount.incrementAndGet();
            return true;

        } catch (Exception e) {
            handleFailure(task, e.getMessage(), workerId);
            return true;
        }
    }

    private void handleFailure(Task task, String error, String workerId) {
        log.warn("[{}] Задача #{} упала: {}", workerId, task.getId(), error);

        task.setAttempts(task.getAttempts() + 1);
        task.setErrorMessage(error);

        if (task.getAttempts() < task.getMaxAttempts()) {
            // Экспоненциальный откат (retry)
            long delay = (long) Math.pow(2, task.getAttempts()) * 60;
            task.setStatus("READY");
            task.setScheduledAt(LocalDateTime.now().plusSeconds(delay));
        } else {
            task.setStatus("FAILED");
            task.setCompletedAt(LocalDateTime.now());
        }

        // Сохраняем состояние ошибки
        repo.save(task);
    }

    /**
     * Метод для мониторинга в TaskQueueApplication
     */
    public long getThroughput() {
        return completedCount.get();
    }

    public long getCompleted() {
        return completedCount.get();
    }
}