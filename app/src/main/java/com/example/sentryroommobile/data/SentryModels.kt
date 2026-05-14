package com.example.sentryroommobile.data

data class StatusResponse(
    val api: String,
    val database: String,
)

data class LiveStatusResponse(
    val api: String,
    val database: String,
    val latestReadings: Map<String, String>,
    val activeUnacknowledgedEvents: Int,
)

data class Person(
    val id: Int,
    val fullName: String,
    val role: String?,
    val isAuthorized: Boolean,
    val notes: String?,
)

data class Event(
    val id: Int,
    val eventType: String,
    val severity: String,
    val message: String,
    val personId: Int?,
    val confidence: Double?,
    val snapshotPath: String?,
    val isAcknowledged: Boolean,
    val createdAt: String,
)

data class SensorReading(
    val id: Int,
    val sensorType: String,
    val value: String,
    val source: String?,
    val createdAt: String,
)
