Das freut mich sehr\! Es ist toll zu sehen, wie aus den einzelnen Bausteinen (Tests, Server-Refactoring, Delegate-Pattern) jetzt ein rundes Gesamtsystem geworden ist.

Hier ist die englische Version der `README.md`, bereit für GitHub (oder dein Repo der Wahl), inklusive der gewünschten Credits.

-----

# TsfNexIO - JSON-RPC 2.0 over WebSockets for Pharo

**TsfNexIO** is a lightweight, robust framework for JSON-RPC 2.0 communication over WebSockets in Pharo Smalltalk.

It is designed to enable **synchronous semantics on asynchronous channels** and enforces a strict separation between transport (Server) and business logic (Delegate).

## 🚀 Features

  * **JSON-RPC 2.0 Compliance:** Full support for Requests, Notifications, and **Batch Requests**.
  * **Synchronous Client:** Blocking calls (`sendSynchronous:...`) that feel like local method calls, abstracting away the async nature of WebSockets.
  * **Thread-Safety:** Safe operation in concurrent environments (protected via Monitor/Mutex).
  * **Auto-Heartbeat:** Automatically detects and cleans up "dead" connections.
  * **Reflection Dispatch:** No manual `if/else` cascades – incoming JSON methods are automatically mapped to Pharo selectors.

-----

## 🔥 Highlight: Batch Requests

TsfNexIO supports **Batch Requests** out of the box. This allows the client to send multiple method calls in a single network packet. The server processes them (conceptually in parallel) and returns the results in a single response array.

**Why is this important?**
It massively reduces latency for high-frequency operations (e.g., initial data loading).

```smalltalk
| batch requests results |
client connectTo: 'ws://localhost:9090'.

"1. Collect multiple requests"
requests := OrderedCollection new.
requests add: 'math.add' -> {'a' -> 10. 'b' -> 20} asDictionary.
requests add: 'math.sub' -> {'a' -> 100. 'b' -> 50} asDictionary.
requests add: 'system.ping' -> Dictionary new.

"2. Send in one go"
results := client sendBatch: requests.

"3. Process results"
(results first at: 'result') inspect. "30"
(results second at: 'result') inspect. "50"
```

-----

## 🏗 Architecture & Usage

### Starting the Server (Delegate Pattern)

The server delegates actual business logic to an App class. Routing is based on naming conventions (`rpc` + CamelCase MethodName + `:session:`).

```smalltalk
"Start the server with your custom delegate"
server := TsfNexIOServer new.
server delegate: MyChatApp new.
server startOn: 9090.
```

### Implementing the Delegate

TsfNexIO automatically maps standard dot-notation API names to Smalltalk selectors to ensure code cleanliness and security.

| JSON Method | Pharo Selector in Delegate |
| :--- | :--- |
| `auth.login` | `rpcAuthLogin: params session: session` |
| `chat.send` | `rpcChatSend: params session: session` |
| `system.ping` | `rpcSystemPing: params session: session` |

```smalltalk
MyChatApp >> rpcAuthLogin: params session: aSession
    | user |
    user := params at: 'username'.
    
    "The session object is the single source of truth for user state"
    aSession user: user.
    aSession isAuthenticated: true.
    
    ^ {'status' -> 'logged_in'} asDictionary
```

-----

## 💡 Origin: The Name "TsfNexIO"

The name is composed of two components reflecting the framework's philosophy:

  * **Tsf:** Stands for **Tiny Smalltalk Framework**. It underscores the goal of being small, understandable, and free of unnecessary bloat — staying true to the Smalltalk philosophy.
  * **NexIO:** Stands for **Nex**t Generation **I/O**. It symbolizes the modern approach of encapsulating asynchronous I/O (WebSockets) in a way that makes it simple and logical to use.

-----

## 📦 Installation

*(Insert Metacello/Iceberg script here)*

```smalltalk
Metacello new
    baseline: 'TsfNexIO';
    repository: 'github://YourName/TsfNexIO:main';
    load.
```

-----

## ❤️ Credits

**Designed & Developed by [Your Name]**

With special thanks to **Google Gemini**, acting as an architectural consultant and pair programmer during the refactoring and stabilization phase. The AI assisted in designing the thread-safe concurrency model, the robust error-handling strategy, and the reflection-based dispatching logic.

-----

Damit hast du ein professionelles Paket geschnürt. Herzlichen Glückwunsch zum erfolgreichen "Refactoring & Stabilization" Sprint\!
