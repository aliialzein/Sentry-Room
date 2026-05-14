package com.example.sentryroommobile.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

class SentryApiClient(private val baseUrl: String) {
    suspend fun getStatus(): StatusResponse = withContext(Dispatchers.IO) {
        val json = JSONObject(request("GET", "/api/status"))
        StatusResponse(
            api = json.optString("api", "unknown"),
            database = json.optString("database", "unknown"),
        )
    }

    suspend fun getLiveStatus(): LiveStatusResponse = withContext(Dispatchers.IO) {
        val json = JSONObject(request("GET", "/api/live-status"))
        val latestReadingsJson = json.optJSONObject("latest_readings") ?: JSONObject()
        val readings = latestReadingsJson.keys().asSequence().associateWith { key ->
            val value = latestReadingsJson.opt(key)
            if (value == null || value == JSONObject.NULL) "No reading" else value.toString()
        }

        LiveStatusResponse(
            api = json.optString("api", "unknown"),
            database = json.optString("database", "unknown"),
            latestReadings = readings,
            activeUnacknowledgedEvents = json.optInt("active_unacknowledged_events", 0),
        )
    }

    suspend fun getPersons(): List<Person> = withContext(Dispatchers.IO) {
        val array = JSONArray(request("GET", "/api/persons"))
        buildList {
            for (index in 0 until array.length()) {
                val item = array.getJSONObject(index)
                add(
                    Person(
                        id = item.getInt("id"),
                        fullName = item.optString("full_name"),
                        role = item.nullableString("role"),
                        isAuthorized = item.optBoolean("is_authorized"),
                        notes = item.nullableString("notes"),
                    )
                )
            }
        }
    }

    suspend fun createPerson(fullName: String, role: String?): Person = withContext(Dispatchers.IO) {
        val body = JSONObject()
            .put("full_name", fullName)
            .put("role", role?.takeIf { it.isNotBlank() } ?: JSONObject.NULL)
            .put("is_authorized", true)

        val item = JSONObject(request("POST", "/api/persons", body))
        Person(
            id = item.getInt("id"),
            fullName = item.optString("full_name"),
            role = item.nullableString("role"),
            isAuthorized = item.optBoolean("is_authorized"),
            notes = item.nullableString("notes"),
        )
    }

    suspend fun getEvents(): List<Event> = withContext(Dispatchers.IO) {
        val array = JSONArray(request("GET", "/api/events?limit=50"))
        buildList {
            for (index in 0 until array.length()) {
                val item = array.getJSONObject(index)
                add(item.toEvent())
            }
        }
    }

    suspend fun acknowledgeEvent(eventId: Int): Event = withContext(Dispatchers.IO) {
        JSONObject(request("PATCH", "/api/events/$eventId/acknowledge")).toEvent()
    }

    suspend fun createTemperatureReading(temperature: Double, humidity: Double): SensorReading = withContext(Dispatchers.IO) {
        val body = JSONObject()
            .put("sensor_type", "temperature_humidity")
            .put(
                "value",
                JSONObject()
                    .put("temperature_c", temperature)
                    .put("humidity_percent", humidity),
            )
            .put("source", "mobile_app")

        JSONObject(request("POST", "/api/sensor-readings", body)).toSensorReading()
    }

    suspend fun createDistanceReading(distance: Double): SensorReading = withContext(Dispatchers.IO) {
        val body = JSONObject()
            .put("sensor_type", "distance")
            .put("value", JSONObject().put("distance_cm", distance))
            .put("unit", "cm")
            .put("source", "mobile_app")

        JSONObject(request("POST", "/api/sensor-readings", body)).toSensorReading()
    }

    private fun request(method: String, path: String, body: JSONObject? = null): String {
        val url = URL(baseUrl.trimEnd('/') + path)
        val connection = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = method
            connectTimeout = 5000
            readTimeout = 5000
            setRequestProperty("Accept", "application/json")
            if (body != null) {
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
            }
        }

        if (body != null) {
            OutputStreamWriter(connection.outputStream).use { writer ->
                writer.write(body.toString())
            }
        }

        val responseCode = connection.responseCode
        val stream = if (responseCode in 200..299) connection.inputStream else connection.errorStream
        val response = BufferedReader(InputStreamReader(stream)).use { reader ->
            reader.readText()
        }
        connection.disconnect()

        if (responseCode !in 200..299) {
            throw IllegalStateException("HTTP $responseCode: $response")
        }

        return response
    }
}

private fun JSONObject.nullableString(key: String): String? {
    return if (isNull(key)) null else optString(key)
}

private fun JSONObject.toEvent(): Event {
    return Event(
        id = getInt("id"),
        eventType = optString("event_type"),
        severity = optString("severity"),
        message = optString("message"),
        personId = if (isNull("person_id")) null else optInt("person_id"),
        confidence = if (isNull("confidence")) null else optDouble("confidence"),
        snapshotPath = nullableString("snapshot_path"),
        isAcknowledged = optBoolean("is_acknowledged"),
        createdAt = optString("created_at"),
    )
}

private fun JSONObject.toSensorReading(): SensorReading {
    return SensorReading(
        id = getInt("id"),
        sensorType = optString("sensor_type"),
        value = optJSONObject("value")?.toString() ?: "{}",
        source = nullableString("source"),
        createdAt = optString("created_at"),
    )
}
