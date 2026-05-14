package com.example.sentryroommobile

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.example.sentryroommobile.data.Event
import com.example.sentryroommobile.data.LiveStatusResponse
import com.example.sentryroommobile.data.Person
import com.example.sentryroommobile.data.SentryApiClient
import com.example.sentryroommobile.data.StatusResponse
import com.example.sentryroommobile.ui.theme.SentryRoomMobileTheme
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            SentryRoomMobileTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    SentryRoomApp()
                }
            }
        }
    }
}

private enum class AppTab(val title: String) {
    Dashboard("Status"),
    Persons("People"),
    Events("Events"),
    Sensors("Sensors"),
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SentryRoomApp() {
    var selectedTab by rememberSaveable { mutableStateOf(AppTab.Dashboard) }
    var baseUrl by rememberSaveable { mutableStateOf("http://10.0.2.2:8000") }
    val client = remember(baseUrl) { SentryApiClient(baseUrl) }
    val scope = rememberCoroutineScope()

    var loading by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf<String?>(null) }
    var status by remember { mutableStateOf<StatusResponse?>(null) }
    var liveStatus by remember { mutableStateOf<LiveStatusResponse?>(null) }
    var persons by remember { mutableStateOf<List<Person>>(emptyList()) }
    var events by remember { mutableStateOf<List<Event>>(emptyList()) }

    suspend fun refreshAll() {
        loading = true
        message = null
        runCatching {
            status = client.getStatus()
            liveStatus = client.getLiveStatus()
            persons = client.getPersons()
            events = client.getEvents()
        }.onFailure { error ->
            message = error.message ?: "Could not connect to backend."
        }
        loading = false
    }

    LaunchedEffect(client) {
        refreshAll()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Sentry Room", fontWeight = FontWeight.Bold)
                        Text(
                            text = baseUrl,
                            style = MaterialTheme.typography.bodySmall,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                },
                actions = {
                    OutlinedButton(onClick = { scope.launch { refreshAll() } }) {
                        Text(if (loading) "Loading" else "Refresh")
                    }
                },
            )
        },
        bottomBar = {
            NavigationBar {
                AppTab.entries.forEach { tab ->
                    NavigationBarItem(
                        selected = selectedTab == tab,
                        onClick = { selectedTab = tab },
                        label = { Text(tab.title) },
                        icon = {},
                    )
                }
            }
        },
    ) { innerPadding ->
        when (selectedTab) {
            AppTab.Dashboard -> DashboardScreen(
                paddingValues = innerPadding,
                baseUrl = baseUrl,
                onBaseUrlChange = { baseUrl = it },
                status = status,
                liveStatus = liveStatus,
                message = message,
            )

            AppTab.Persons -> PersonsScreen(
                paddingValues = innerPadding,
                persons = persons,
                message = message,
                onCreatePerson = { name, role ->
                    scope.launch {
                        loading = true
                        message = runCatching {
                            client.createPerson(name, role)
                            persons = client.getPersons()
                            "Person saved."
                        }.getOrElse { it.message ?: "Could not save person." }
                        loading = false
                    }
                },
            )

            AppTab.Events -> EventsScreen(
                paddingValues = innerPadding,
                events = events,
                message = message,
                onAcknowledge = { event ->
                    scope.launch {
                        loading = true
                        message = runCatching {
                            client.acknowledgeEvent(event.id)
                            events = client.getEvents()
                            liveStatus = client.getLiveStatus()
                            "Event acknowledged."
                        }.getOrElse { it.message ?: "Could not acknowledge event." }
                        loading = false
                    }
                },
            )

            AppTab.Sensors -> SensorsScreen(
                paddingValues = innerPadding,
                message = message,
                onSendEnvironment = { temperature, humidity ->
                    scope.launch {
                        loading = true
                        message = runCatching {
                            client.createTemperatureReading(temperature, humidity)
                            liveStatus = client.getLiveStatus()
                            events = client.getEvents()
                            "Temperature and humidity reading saved."
                        }.getOrElse { it.message ?: "Could not save reading." }
                        loading = false
                    }
                },
                onSendDistance = { distance ->
                    scope.launch {
                        loading = true
                        message = runCatching {
                            client.createDistanceReading(distance)
                            liveStatus = client.getLiveStatus()
                            events = client.getEvents()
                            "Distance reading saved."
                        }.getOrElse { it.message ?: "Could not save reading." }
                        loading = false
                    }
                },
            )
        }
    }
}

@Composable
private fun DashboardScreen(
    paddingValues: PaddingValues,
    baseUrl: String,
    onBaseUrlChange: (String) -> Unit,
    status: StatusResponse?,
    liveStatus: LiveStatusResponse?,
    message: String?,
) {
    Column(
        modifier = Modifier
            .padding(paddingValues)
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        OutlinedTextField(
            value = baseUrl,
            onValueChange = onBaseUrlChange,
            label = { Text("Backend URL") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
        )

        InfoCard(title = "Connection") {
            KeyValueRow("API", status?.api ?: "unknown")
            KeyValueRow("Database", status?.database ?: "unknown")
            KeyValueRow("Active alerts", liveStatus?.activeUnacknowledgedEvents?.toString() ?: "0")
        }

        InfoCard(title = "Latest Sensor Readings") {
            val readings = liveStatus?.latestReadings.orEmpty()
            if (readings.isEmpty()) {
                Text("No readings yet.", style = MaterialTheme.typography.bodyMedium)
            } else {
                readings.forEach { (key, value) ->
                    KeyValueRow(key.replace('_', ' '), value)
                }
            }
        }

        message?.let {
            MessageCard(it)
        }
    }
}

@Composable
private fun PersonsScreen(
    paddingValues: PaddingValues,
    persons: List<Person>,
    message: String?,
    onCreatePerson: (String, String?) -> Unit,
) {
    var name by rememberSaveable { mutableStateOf("") }
    var role by rememberSaveable { mutableStateOf("") }

    LazyColumn(
        modifier = Modifier
            .padding(paddingValues)
            .fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            InfoCard(title = "Register Authorized Person") {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Full name") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                )
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = role,
                    onValueChange = { role = it },
                    label = { Text("Role") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                )
                Spacer(modifier = Modifier.height(12.dp))
                Button(
                    onClick = {
                        onCreatePerson(name.trim(), role.trim())
                        name = ""
                        role = ""
                    },
                    enabled = name.isNotBlank(),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("Save Person")
                }
            }
        }

        message?.let {
            item { MessageCard(it) }
        }

        if (persons.isEmpty()) {
            item { EmptyCard("No people registered yet.") }
        } else {
            items(persons, key = { it.id }) { person ->
                InfoCard(title = person.fullName) {
                    KeyValueRow("Role", person.role ?: "Not set")
                    KeyValueRow("Access", if (person.isAuthorized) "Authorized" else "Revoked")
                    person.notes?.let { Text(it, style = MaterialTheme.typography.bodySmall) }
                }
            }
        }
    }
}

@Composable
private fun EventsScreen(
    paddingValues: PaddingValues,
    events: List<Event>,
    message: String?,
    onAcknowledge: (Event) -> Unit,
) {
    LazyColumn(
        modifier = Modifier
            .padding(paddingValues)
            .fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        message?.let {
            item { MessageCard(it) }
        }

        if (events.isEmpty()) {
            item { EmptyCard("No events yet.") }
        } else {
            items(events, key = { it.id }) { event ->
                InfoCard(title = event.eventType.replace('_', ' ')) {
                    KeyValueRow("Severity", event.severity)
                    KeyValueRow("Acknowledged", if (event.isAcknowledged) "Yes" else "No")
                    KeyValueRow("Created", event.createdAt)
                    event.confidence?.let { KeyValueRow("Confidence", "%.2f".format(it)) }
                    Text(event.message, style = MaterialTheme.typography.bodyMedium)
                    if (!event.isAcknowledged && event.severity != "info") {
                        Spacer(modifier = Modifier.height(10.dp))
                        Button(onClick = { onAcknowledge(event) }) {
                            Text("Acknowledge")
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SensorsScreen(
    paddingValues: PaddingValues,
    message: String?,
    onSendEnvironment: (Double, Double) -> Unit,
    onSendDistance: (Double) -> Unit,
) {
    var temperature by rememberSaveable { mutableStateOf("24.5") }
    var humidity by rememberSaveable { mutableStateOf("52") }
    var distance by rememberSaveable { mutableStateOf("25") }

    Column(
        modifier = Modifier
            .padding(paddingValues)
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        InfoCard(title = "Temperature And Humidity") {
            NumberField("Temperature C", temperature) { temperature = it }
            Spacer(modifier = Modifier.height(8.dp))
            NumberField("Humidity %", humidity) { humidity = it }
            Spacer(modifier = Modifier.height(12.dp))
            Button(
                onClick = {
                    val temperatureValue = temperature.toDoubleOrNull()
                    val humidityValue = humidity.toDoubleOrNull()
                    if (temperatureValue != null && humidityValue != null) {
                        onSendEnvironment(temperatureValue, humidityValue)
                    }
                },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("Send Environment Reading")
            }
        }

        InfoCard(title = "Distance") {
            NumberField("Distance cm", distance) { distance = it }
            Spacer(modifier = Modifier.height(12.dp))
            Button(
                onClick = {
                    distance.toDoubleOrNull()?.let(onSendDistance)
                },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("Send Distance Reading")
            }
        }

        message?.let {
            MessageCard(it)
        }
    }
}

@Composable
private fun NumberField(label: String, value: String, onValueChange: (String) -> Unit) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label) },
        modifier = Modifier.fillMaxWidth(),
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
    )
}

@Composable
private fun InfoCard(title: String, content: @Composable ColumnScope.() -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainer),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Spacer(modifier = Modifier.height(4.dp))
            content()
        }
    }
}

@Composable
private fun EmptyCard(text: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(16.dp),
            style = MaterialTheme.typography.bodyMedium,
        )
    }
}

@Composable
private fun MessageCard(text: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer),
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(16.dp),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSecondaryContainer,
        )
    }
}

@Composable
private fun KeyValueRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = label,
            modifier = Modifier.weight(1f),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(modifier = Modifier.width(12.dp))
        Text(
            text = value,
            modifier = Modifier.weight(1f),
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
        )
    }
}
