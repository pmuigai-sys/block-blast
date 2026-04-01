abstract class SessionStore {
  Future<String?> loadSessionJson();

  Future<void> saveSessionJson(String json);
}

SessionStore createSessionStore() => throw UnimplementedError();
