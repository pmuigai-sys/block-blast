import 'dart:collection';

class TelemetryEvent {
  const TelemetryEvent({
    required this.name,
    required this.timestamp,
    required this.properties,
  });

  final String name;
  final DateTime timestamp;
  final Map<String, Object?> properties;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'properties': properties,
    };
  }
}

class TelemetryClient {
  final List<TelemetryEvent> _events = <TelemetryEvent>[];

  UnmodifiableListView<TelemetryEvent> get events =>
      UnmodifiableListView<TelemetryEvent>(_events);

  void logEvent(String name, {Map<String, Object?> properties = const {}}) {
    _events.add(
      TelemetryEvent(
        name: name,
        timestamp: DateTime.now(),
        properties: Map<String, Object?>.from(properties),
      ),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'eventCount': _events.length,
      'events': _events.map((event) => event.toJson()).toList(growable: false),
    };
  }
}
