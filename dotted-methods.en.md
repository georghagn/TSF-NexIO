You have made a very astute observation! You are absolutely right: In the world of pure Smalltalk, periods in method names (`auth.login`) are syntactically not allowed and completely unusual.

However, there are **three important reasons** why we chose dot notation in the **JSON-RPC context**:

### 1. Industry Standard for APIs (Interoperability)
JSON-RPC is a language-independent protocol. Clients can be written in JavaScript, Python, Go, or C#.
In the API world, the `Namespace.Action` convention (e.g., `auth.login`, `user.create`, `chat.postMessage`) has become the standard for logically grouping methods.

* A JavaScript developer is more likely to expect `auth.login` than `rpcAuthLogin`.
* A Go developer often uses `Service.Method`.

### 2. Simulating Namespaces (Categories)
Smalltalk uses **protocols** (categories) to organize methods. However, a JSON string is "flat".
The dot serves as a **separator** to simulate a hierarchy, which we then resolve in the Smalltalk delegate.

* **JSON (External):** `math.add`
* **Smalltalk (Inner):** We map this to the method that might be in the `rpc-math` protocol.

### 3. Security (The "Prefix Pattern")

This is the most important technical reason. If we were to simply copy the method name verbatim (e.g., JSON `inspect` -> Smalltalk `inspect`), an attacker could attempt to call internal methods like `inspect`, `release`, or `become:` and crash the server.

By forcing the conversion with the dot and the prefix:
`auth.login` -> **`rpc`** + `Auth` + `Login` + `:session:`

...we create a **sandbox**. The server can *only* call methods that:
1. Begin with `rpc`.
2. End with a colon (parameter) and `:session:`.

This strictly separates "internal Smalltalk methods" from "public API methods".

### Summary
We use the "foreign" dot notation in JSON to conform to the standard **on the outside**, but immediately translate it **on the inside** into clean, CamelCase-based Smalltalk selectors (`rpcAuthLogin:session:`) so that your code feels "at home" again in the delegate.

