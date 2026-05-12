package com.taskqueue;

import com.taskqueue.repository.TaskRepository;
import com.taskqueue.service.ConsumerService;
import com.taskqueue.service.ProducerService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@Slf4j
@SpringBootApplication
public class TaskQueueApplication {

    public static void main(String[] args) {
        SpringApplication.run(TaskQueueApplication.class, args);
    }

    @Bean
    CommandLineRunner runDemo(ProducerService producer,
                              ConsumerService consumerService,
                              TaskRepository repository) {
        return args -> {
            log.info("=== Запуск системы очередей Маркетплейса ===");

            // Запуск двух независимых процессов-воркеров
            Thread w1 = new Thread(() -> consumerService.startWorker("Worker-1"));
            Thread w2 = new Thread(() -> consumerService.startWorker("Worker-2"));
            w1.setDaemon(true); w2.setDaemon(true);
            w1.start(); w2.start();

            // Даем воркерам запуститься и встать в режим LISTEN
            Thread.sleep(500);

            // Запускаем интенсивную генерацию задач: 100 вставок/сек на протяжении 30 секунд
            new Thread(() -> producer.startProducing(100, 30)).start();

            // Мониторинг Лага и Пропускной способности
            long startTime = System.currentTimeMillis();
            long lastThroughput = 0;

            while (true) {
                Thread.sleep(3000);
                long currentThroughput = consumerService.getThroughput();
                long processedInWindow = currentThroughput - lastThroughput;
                lastThroughput = currentThroughput;

                double lagSeconds = repository.getQueueLagSeconds();
                long readyCount = repository.countByStatus("READY");
                double tps = processedInWindow / 3.0;

                log.info("[МОНИТОРИНГ] Очередь (READY): {} шт | Лаг: {} сек | Скорость обработки: {} задач/сек",
                        readyCount,
                        String.format("%.2f", lagSeconds),
                        String.format("%.1f", tps));
            }
        };
    }
}