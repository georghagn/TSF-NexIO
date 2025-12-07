
Du hast eine sehr aufmerksame Beobachtung! Du hast absolut recht: In der reinen Smalltalk-Welt sind Punkte in Methodennamen (`auth.login`) syntaktisch nicht erlaubt und völlig unüblich.

Es gibt jedoch **drei gewichtige Gründe**, warum wir uns im **JSON-RPC Kontext** für die Punkt-Notation entschieden haben:

### 1. Industriestandard für APIs (Interoperabilität)
JSON-RPC ist ein sprachunabhängiges Protokoll. Clients können in JavaScript, Python, Go oder C# geschrieben sein.
In der API-Welt hat sich die Konvention `Namespace.Action` (z.B. `auth.login`, `user.create`, `chat.postMessage`) als Standard etabliert, um Methoden logisch zu gruppieren.

* Ein JavaScript-Entwickler erwartet eher `auth.login` als `rpcAuthLogin`.
* Ein Go-Entwickler nutzt oft `Service.Method`.

### 2. Simulation von Namespaces (Kategorien)
Smalltalk hat **Protokolle** (Kategorien), um Methoden zu ordnen. Ein JSON-String ist aber "flach".
Der Punkt dient uns als **Trennzeichen**, um eine Hierarchie zu simulieren, die wir im Smalltalk-Delegate dann wieder auflösen.

* **JSON (Außen):** `math.add`
* **Smalltalk (Innen):** Wir mappen das auf die Methode, die im Protocol `rpc-math` liegen könnte.

### 3. Security (Das "Prefix-Pattern")
Das ist der wichtigste technische Grund. Würden wir einfach den Methodennamen 1:1 übernehmen (z.B. JSON `inspect` -> Smalltalk `inspect`), könnte ein Angreifer versuchen, interne Methoden wie `inspect`, `release` oder `become:` aufzurufen und den Server zum Absturz bringen.

Durch die erzwungene Umwandlung mit dem Punkt und dem Prefix:
`auth.login` -> **`rpc`** + `Auth` + `Login` + `:session:`

...schaffen wir eine **Sandbox**. Der Server kann *nur* Methoden aufrufen, die:
1.  Mit `rpc` beginnen.
2.  Einen Doppelpunkt (Parameter) und `:session:` am Ende haben.

Das trennt "Interne Smalltalk Methoden" strikt von "Öffentlichen API Methoden".

### Zusammenfassung
Wir nutzen die "fremde" Punkt-Notation im JSON, um **außen** dem Standard zu entsprechen, übersetzen sie aber **innen** sofort in saubere, CamelCase-basierte Smalltalk-Selektoren (`rpcAuthLogin:session:`), damit sich dein Code im Delegate wieder "heimisch" anfühlt.

