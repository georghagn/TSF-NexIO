
### Zusammenfassung des Status Quo (Architektur)

Wir haben ein funktionierendes **JSON-RPC 2.0 Framework** über **WebSockets**.

  * **Core:**
      * Basiert auf **Pharo**, **Zinc** (Networking) und **NeoJSON** (Parsing).
      * Thread-Safe Implementierung (Monitors/Mutex) für Server und Client.
  * **Server (`TsfNexIOServer`):**
      * Verwaltet WebSocket-Verbindungen in `TsfNexIOSession`.
      * Verarbeitet Nachrichten asynchron in einem Listener-Loop.
      * **Routing:** Nutzt "Convention over Configuration" (Reflection).
          * JSON Methode: `'auth.login'`
          * Pharo Methode: `#rpcAuthLogin:session:`
      * **Features:** Heartbeat-Mechanismus (Ping/Pong), autom. Cleanup toter Sockets.
  * **Client (`TsfNexIOClient`):**
      * Kann Requests **synchron** (`sendSynchronous:...`) senden (wartet via Semaphore auf Antwort).
      * Unterstützt **Batch-Requests** und **Notifications**.
      * Robustes Error-Handling (Timeouts, Verbindungsabbruch).
  * **Tests:**
      * Integrationstests laufen gegen einen echten Server auf Port 0.
      * Abdeckung: Happy Path, Timeouts, Concurrency, Batching, Error-Mapping.

