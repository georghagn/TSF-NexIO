"
I am the core server for the TsfNexIO JSON-RPC framework.
I manage the WebSocket lifecycle, maintain active client sessions, and route incoming requests to a delegate.

*Responsibilities*
- **Lifecycle:** I start and stop the underlying Zinc HTTP/WebSocket server.
- **Session Management:** I keep track of connected clients in `sessions` and authenticated users in `userRegistry`.
- **Heartbeat:** I run a background process to ping clients and detect timeouts.
- **Dispatching:** I receive raw JSON, parse it, and delegate the logic to my `delegate`.

*Collaborators*
- `ZnWebSocket`: Handles the low-level connection.
- `TsfNexIOSession`: Represents a connected client.
- `TsfNexIOConstants`: Provides protocol constants.

*Public API*
- `startOn: aPort` - Starts the server on the given port.
- `stop` - Stops the server and disconnects all clients.
- `delegate:` - Sets the object responsible for handling actual RPC methods.

*Example*
```
server := TsfNexIOServer new.
server delegate: MyChatApp new.
server startOn: 9090.
```

"
Class {
	#name : 'TsfNexIOServer',
	#superclass : 'Object',
	#instVars : [
		'server',
		'clients',
		'clientsMutex',
		'delegate',
		'logger',
		'userRegistry',
		'heartbeatProcess',
		'heartbeatInterval',
		'waitTimeout',
		'port'
	],
	#category : 'TSF-NexIO-Server',
	#package : 'TSF-NexIO',
	#tag : 'Server'
}

{ #category : 'defaults' }
TsfNexIOServer class >> defaultHeartbeatInterval [

    "Server sends a ping every 30 seconds"
    ^ 30
]

{ #category : 'defaults' }
TsfNexIOServer class >> defaultPort [

    "Default port if none is specified"
    ^ 9090
]

{ #category : 'defaults' }
TsfNexIOServer class >> defaultWaitTimeout [

    "If no pong received within 60 seconds, connection is considered dead"
    ^ 60 seconds
]

{ #category : 'actions' }
TsfNexIOServer >> broadcast: method params: params [
    | json |

    json := TsfNexIOProtocol createNotification: method params: params.
    clientsMutex critical: [
        clients do: [ :ws | [ ws sendMessage: json ] on: Error do: [ nil ] ]
    ].
]

{ #category : 'accessing' }
TsfNexIOServer >> delegate: anObject [

    delegate := anObject.
    "Dependency Injection: The App must know the server for broadcasts"
    (delegate respondsTo: #server:) ifTrue: [ delegate server: self ].
]

{ #category : 'actions' }
TsfNexIOServer >> handleConnection: webSocket [
    | session |

    session := TsfNexIOSession new.
    session socket: webSocket.
    
    clientsMutex critical: [ clients add: webSocket ].
    
    [
        "Der Loop läuft solange die Verbindung steht"
        [ webSocket isConnected ] whileTrue: [
            [
                "Hier knallt es, wenn der Test endet (tearDown)"
                self readAndDispatch: webSocket session: session.
            ] on: ConnectionClosed, PrimitiveFailed do: [ :ex |
                "Das ist normal: Client ist weg."
                self logInfo: 'Server: Client disconnected (', ex description, ')'.
                
                "Ganz wichtig: ^self beendet die Methode und springt ins ensure:"
                ^ self. 
            ]
        ]
    ] ensure: [ 
        "Cleanup läuft hier sicher weiter"
        clientsMutex critical: [ 
            clients remove: webSocket ifAbsent: [].
            self unregisterUser: session user.
        ].
        self logInfo: 'Server: Cleanup complete.'.
    ].

]

{ #category : 'initialization' }
TsfNexIOServer >> initialize [

	super initialize.
	
	clients := Set new.
	clientsMutex := Mutex new.
	userRegistry := Dictionary new.
	
"  sessions := Set new."
    
    "Thread-Safety: WebSockets laufen in eigenen Prozessen. 
     Ein Monitor (Mutex) schützt unsere Listen vor ConcurrentModificationExceptions."
"    sessionsMonitor := Monitor new. "
    
    "Lade Defaults"
    port := self class defaultPort .
    heartbeatInterval := self class defaultHeartbeatInterval.
    waitTimeout := self class defaultWaitTimeout.

]

{ #category : 'error handling' }
TsfNexIOServer >> logError: aString [

    logger ifNotNil: [ 
		logger error: '[TsfNexIO] ', aString 
	] ifNil: [ 
		Transcript show: '[TsfNexIO ERROR] '; show: aString; cr 
	]
]

{ #category : 'accessing' }
TsfNexIOServer >> logInfo: aString [
    "Die Weiche: Haben wir einen Logger? Wenn ja, nutze ihn. Wenn nein, Transcript."

	logger ifNotNil: [ 
		logger info: '[TsfNexIOServer] ', aString 
	] ifNil: [ 
		Transcript show: '[TsfNexIOServer] ' ; show: aString; cr 
	]
]

{ #category : 'actions' }
TsfNexIOServer >> processBatch: batchArray session: session [
    | responses |

    batchArray isEmpty ifTrue: [
        ^ TsfNexIOProtocol createError: TsfNexIOConstants invalidRequest data: 'Empty Batch' id: nil
    ].
    responses := OrderedCollection new.
    batchArray do: [ :req |
        | resp |
        resp := self processRequest: req session: session.
        resp ifNotNil: [ responses add: resp ].
    ].
    responses isEmpty ifTrue: [ ^ nil ].
    ^ responses asArray.
]

{ #category : 'actions' }
TsfNexIOServer >> processRequest: json session: session [
    | method params id selector result |

    (json isDictionary and: [ json includesKey: 'method' ]) ifFalse: [
         ^ TsfNexIOProtocol createError: TsfNexIOConstants invalidRequest data: json id: nil
    ].

    method := json at: 'method'.
    params := json at: 'params' ifAbsent: [ Dictionary new ].
    id := json at: 'id' ifAbsent: [ nil ].
    selector := ('rpc', method capitalized, ':session:') asSymbol.
    
    [
        (delegate respondsTo: selector) ifFalse: [
             id ifNil: [ ^ nil ].
             ^ TsfNexIOProtocol createError: (TsfNexIOConstants methodNotFound) data: method id: id
        ].
        result := delegate perform: selector with: params with: session.
        id ifNil: [ ^ nil ].
        ^ TsfNexIOProtocol createResponse: result id: id.

    ] on: Error do: [ :ex |
        id ifNil: [ ^ nil ].
        ^ TsfNexIOProtocol createError: TsfNexIOConstants internalError message: ex messageText data: nil id: id.
    ].

]

{ #category : 'actions' }
TsfNexIOServer >> pruneDeadConnections [
	
	clientsMutex critical: [
		"WICHTIG: Wir iterieren über eine Kopie, da wir das Original 
		potenziell verändern (wenn connections sterben)"
		clients copy do: [ :ws |
			[
				ws ping. "Sendet WebSocket Opcode 9"
			] on: Error do: [ :ex |
				self logInfo: 'Heartbeat: Found dead connection. Closing...'.
				ws close. "Das triggert das Cleanup im anderen Prozess"
			]
		]
	].

]

{ #category : 'actions' }
TsfNexIOServer >> readAndDispatch: webSocket session: session [
	| message json responseObj |

	message := webSocket readMessage.
	message ifNil: [ ConnectionClosed signal ]. "Safety Check"

	json := NeoJSONReader fromString: message.
	responseObj := json isArray
		ifTrue: [ self processBatch: json session: session ]
		ifFalse: [ self processRequest: json session: session ].

	responseObj ifNotNil: [ webSocket sendMessage: (NeoJSONWriter toString: responseObj) ]
]

{ #category : 'actions' }
TsfNexIOServer >> registerUser: username on: webSocket [

	clientsMutex critical: [
		userRegistry at: username put: webSocket.
		self logInfo: 'Registered user: ', username.
	].


]

{ #category : 'actions' }
TsfNexIOServer >> send: method params: params toUser: username [
	| socket json |

	clientsMutex critical: [
		socket := userRegistry at: username ifAbsent: [ 
			self logInfo: 'User not found: ', username. 
			^ self 
		].
	].
    
	json := TsfNexIOProtocol createNotification: method params: params.

	[ socket sendMessage: json ] on: Error do: [ :ex |
		"Wenn senden fehlschlägt, aufräumen"
		self unregisterUser: username. 
	].

]

{ #category : 'public' }
TsfNexIOServer >> start [

    port ifNil: [port := self class defaultPort ].

    server := ZnServer startDefaultOn: port.
    server delegate map: 'ws' to: (ZnWebSocketDelegate handler: [ :ws |
        self handleConnection: ws
    ]).
    self startHeartbeat.
]

{ #category : 'actions' }
TsfNexIOServer >> startHeartbeat [

	self stopHeartbeat. "Sicherstellen, dass er nicht doppelt läuft"

	heartbeatProcess := [
		[
			(Delay forSeconds: heartbeatInterval) wait.
			self pruneDeadConnections.
		] repeat.
	] forkAt: Processor systemBackgroundPriority named: 'TsfNexIOHeartbeat'.
    
	self logInfo: 'Heartbeat started.'.


]

{ #category : 'public' }
TsfNexIOServer >> startOn: aPort [

    self stop. "Sicherstellen, dass nichts Altes läuft"

    port := aPort.
    server := ZnServer startDefaultOn: port.
    server delegate map: 'ws' to: (ZnWebSocketDelegate handler: [ :ws |
        self handleConnection: ws
    ]).
    self startHeartbeat.

    self logInfo: 'Server started on port ', port asString.
]

{ #category : 'accessing' }
TsfNexIOServer >> stop [

	self stopHeartbeat .
	server ifNotNil: [ server stop ].
]

{ #category : 'actions' }
TsfNexIOServer >> stopHeartbeat [

	heartbeatProcess ifNotNil: [ 
		heartbeatProcess terminate. 
		heartbeatProcess := nil.
		self logInfo: 'Heartbeat stopped.'.
	].
]

{ #category : 'actions' }
TsfNexIOServer >> unregisterUser: username [

	username ifNil: [ ^ self ].
	clientsMutex critical: [
		userRegistry removeKey: username ifAbsent: [].
		self logInfo: 'Unregistered user: ', username.
	].

]
