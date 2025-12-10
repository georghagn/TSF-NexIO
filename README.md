|<sub>🇩🇪 [German translation →](README.de.md)</sub>|
|----:|
|    |

|[![Pharo Version](https://img.shields.io/badge/Pharo-12.0%2B-blue.svg)](https://pharo.org)|[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](./LICENSE) [![Dependencies](https://img.shields.io/badge/dependencies-zero-brightgreen.svg)](#)|
|----|----|
|![TSF-NexIO Logo](logo-nexio.png)| ***TSF-NexIO***<br>A lightweight, robust framework for JSON-RPC 2.0 communication over WebSockets in Pharo Smalltalk. Part of the **Tiny Smalltalk Framework Suite**|

<sup>***TSF*** stands for ***Tiny Smalltalk Framework*** — a collection of minimalist tools for robust applications.</sup>


## Overview
**TsfNexIO - JSON-RPC 2.0 over WebSockets** is a lightweight, robust framework for JSON-RPC 2.0 communication over WebSockets in Pharo Smalltalk. It is designed to enable **synchronous semantics on asynchronous channels** and enforces a strict separation between transport (Server) and business logic (Delegate).

## Features

  * **JSON-RPC 2.0 Compliance:** Full support for Requests, Notifications, and **Batch Requests**.
  * **Synchronous Client:** Blocking calls (`sendSynchronous:...`) that feel like local method calls, abstracting away the async nature of WebSockets.
  * **Thread-Safety:** Safe operation in concurrent environments (protected via Monitor/Mutex).
  * **Auto-Heartbeat:** Automatically detects and cleans up "dead" connections.
  * **Reflection Dispatch:** No manual `if/else` cascades – incoming JSON methods are automatically mapped to Pharo selectors.


## Highlight: Batch Requests

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

## Architecture & Usage

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

<sup>[Why we use *"dotted method notation"*](dotted-methods.en.md)</sup>

```smalltalk
MyChatApp >> rpcAuthLogin: params session: aSession
    | user |
    user := params at: 'username'.
    
    "The session object is the single source of truth for user state"
    aSession user: user.
    aSession isAuthenticated: true.
    
    ^ {'status' -> 'logged_in'} asDictionary
```

## Installation

```smalltalk
Metacello new
    baseline: 'TsfNexIO';
    repository: 'github://georghagn/TSF-NexIO:main';
    load.
```


## Origin: The Name "TsfNexIO"

The name is composed of two components reflecting the framework's philosophy:

  * **Tsf:** Stands for **Tiny Smalltalk Framework**. It underscores the goal of being small, understandable, and free of unnecessary bloat — staying true to the Smalltalk philosophy.
  * **NexIO:** Stands for **Nex**t Generation **I/O**. It symbolizes the modern approach of encapsulating asynchronous I/O (WebSockets) in a way that makes it simple and logical to use.


## Development-Process & Credits


With special thanks to my AI sparring partner, acting as an architectural consultant and 
pair programmer during the refactoring and stabilization phase. The AI assisted 
in designing the thread-safe concurrency model, the robust error-handling strategy, 
and the reflection-based dispatching logic.


## License

This project is licensed under the Apache 2.0 license. See LICENSE.


## Contact

If you have any questions or are interested in this project, you can reach me at
📧 *georghagn [at] tiny-frameworks.io*

<sup>*(Please do not send inquiries to the private GitHub account addresses.)*</sup>
