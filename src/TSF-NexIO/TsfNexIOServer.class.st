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
		'delegate',
		'sessions',
		'sessionsMutex',
		'logger',
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

{ #category : 'communication' }
TsfNexIOServer >> broadcastNotification: method params: params [
    "sends a notification to ALL connected clients"
    
    | payload jsonString currentSessions |
    
    "1. build payload via protocol"
    payload := TsfNexIOProtocol createNotification: method params: params.
    jsonString := NeoJSONWriter toString: payload.
    
    "2. Copy list (thread-safe) so we can immediately release the monitor again."
    currentSessions := sessionsMutex critical: [ sessions copy ].
    
    "3. Send (outside the monitor)"
    currentSessions do: [ :session | 
        (session socket isNotNil and: [ session socket isConnected ])
            ifTrue: [ 
                [ session socket sendMessage: jsonString ] 
                    on: Error do: [ :ex | 
                        "logging, but but continue broadcast"
                        Transcript show: 'Broadcast fail for one client'; cr.
                    ]
            ]
    ].
]

{ #category : 'accessing' }
TsfNexIOServer >> delegate [

    ^ delegate

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

    "1. create session object"
    session := TsfNexIOSession new.
    session socket: webSocket.
    
    "2. register session (Thread-Safe)"
    sessionsMutex critical: [ 
        sessions add: session 
    ].

    "3. start loop - with Ensure block for cleanup"
    [
        "The loop runs as long as the connection is active."
        [ webSocket isConnected ] whileTrue: [
            [
                "Things will get loud when the test ends. (tearDown)"
                self readAndDispatch: webSocket session: session.
            ] on: ConnectionClosed, PrimitiveFailed do: [ :ex |
                "This is normal: client is gone."
                self logInfo: 'Server: Client disconnected (', ex description, ')'.
                
                "Very important: ^self trminates the method and jumps to ensure:"
                ^ self. 
            ]
        ]
    ] ensure: [ 
        "4. Cleanup: Regardless of why the loop ends (error, close, timeout),
         we remove the session from the list."
        sessionsMutex critical: [ 
            sessions remove: session ifAbsent: [].
           " self unregisterUser: session user."
        ].
        self logInfo: 'Server: Cleanup complete.'.
    ].

]

{ #category : 'initialization' }
TsfNexIOServer >> initialize [

	super initialize.

	sessions := Set new.
	sessionsMutex := Monitor new.

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
    "Do we have a logger? If so, use it. If not, use a transcript.."

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
    "selector := ('rpc', method capitalized, ':session:') asSymbol."

    "We dynamically assemble the selector to remove points.n"
    "Example: 'auth.login' -> 'rpc' + 'Auth' + 'Login' + ':session:'"
    selector := (String streamContents: [ :stream |
        stream nextPutAll: 'rpc'.
        (method findTokens: '.') do: [ :part | 
            stream nextPutAll: part capitalized 
        ].
        stream nextPutAll: ':session:'
    ]) asSymbol.
    
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

	sessionsMutex critical: [
		sessions copy do: [ :session |  "Copy verwenden, um Modifikationen während der Iteration zu vermeiden"
			[
				(session isNotNil and: [ session isConnected ]) ifTrue: [ 
					session socket ping.
				] ifFalse: [
					"Aufräumen, wenn wir merken, dass er tot ist"
					"Triggert das ensure:"
					session socket close.
				]
			] on: Error do: [ :ex |
				 "Heartbeat failure -> session is probably gone"
				self logInfo: 'Heartbeat: Found dead connection. Closing...'.
				session socket close.
			]
		].
	]


]

{ #category : 'actions' }
TsfNexIOServer >> readAndDispatch: webSocket session: session [

    [ webSocket isConnected ] whileTrue: [
        | message responseObj json |
        
        message := webSocket readMessage.
        message ifNil: [ ^ self ]. "Socket closed by peer"
        
        json := NeoJSONReader fromString: message.
        responseObj := json isArray
            ifTrue: [ self processBatch: json session: session ]
            ifFalse: [ self processRequest: json session: session ].
		
        "send answer - MIT Panic-Room"
        responseObj ifNotNil: [
            "First check, then send. This drastically reduces the error."
            (webSocket isNotNil and: [ webSocket isConnected ]) ifTrue: [
                [
                    webSocket sendMessage: (NeoJSONWriter toString: responseObj)
                ] on: Error do: [ :ex | 
                    "Ignore. Client is gone." 
                    ^ self 
                ]
            ]
        ].
    ].

]

{ #category : 'accessing' }
TsfNexIOServer >> sessions [

    ^ sessions
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

	self stopHeartbeat. "Make sure it's not running twice."

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

    self stop. "Make sure it's not running twice."

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
		"self logInfo: 'Heartbeat stopped.'."
	].
]

{ #category : 'actions' }
TsfNexIOServer >> whisper: aDictionary toUser: username [
    "Sends a message ONLY to a specific user"
    
    | targetSession jsonString |
    
    sessionsMutex critical: [
        "search session of this specific user"
        targetSession := sessions 
            detect: [ :s | s user = username ] 
            ifNone: [ ^ self ]. "User not found -> stop"
    ].

    jsonString := NeoJSONWriter toString: aDictionary.
    
    (targetSession socket isNotNil and: [ targetSession socket isConnected ])
        ifTrue: [ targetSession socket sendMessage: jsonString ]
]

{ #category : 'communication' }
TsfNexIOServer >> whisperNotification: method params: params toUser: username [
    "Sends a notification ONLY to a specific user"
    
    | payload jsonString targetSession |
    
    payload := TsfNexIOProtocol createNotification: method params: params.
    jsonString := NeoJSONWriter toString: payload.
    
    "1. search target-session (Thread-Safe)"
    sessionsMutex critical: [
        targetSession := sessions 
            detect: [ :s | s user = username ] 
            ifNone: [ ^ self ]. "User nicht gefunden -> Abbruch"
    ].

    "2. Send (outside the monitor"
    (targetSession socket isNotNil and: [ targetSession socket isConnected ])
        ifTrue: [ 
            [ targetSession socket sendMessage: jsonString ] on: Error do: []
        ]
]
