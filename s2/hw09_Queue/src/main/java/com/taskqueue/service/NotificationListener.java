package com.taskqueue.service;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Statement;

@Slf4j
@Component
public class NotificationListener {

    @Autowired
    private DataSource dataSource;

    private final Object monitor = new Object();
    private Connection connection;

    @PostConstruct
    public void startListening() {
        new Thread(() -> {
            try {
                connection = dataSource.getConnection();
                try (Statement stmt = connection.createStatement()) {
                    stmt.execute("LISTEN new_task_channel");
                }
                org.postgresql.PGConnection pgConn = connection.unwrap(org.postgresql.PGConnection.class);

                while (!Thread.currentThread().isInterrupted()) {
                    // Ожидаем нотификации от базы данных
                    org.postgresql.PGNotification[] notifications = pgConn.getNotifications(1000);
                    if (notifications != null && notifications.length > 0) {
                        synchronized (monitor) {
                            monitor.notifyAll(); // Будим всех спящих воркеров
                        }
                    }
                }
            } catch (Exception e) {
                log.error("Ошибка соединения в потоке LISTEN", e);
            }
        }, "pg-listen-thread").start();
    }

    public void waitForNewTask(long timeoutMs) {
        synchronized (monitor) {
            try { monitor.wait(timeoutMs); } catch (InterruptedException ignored) {}
        }
    }

    @PreDestroy
    public void stop() {
        try { if (connection != null) connection.close(); } catch (Exception ignored) {}
    }
}