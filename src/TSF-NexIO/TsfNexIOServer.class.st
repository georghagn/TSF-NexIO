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
		'heartbeatProcess'
	],
	#pools : [
		'TsfNexIOConstants'
	],
	#category : 'TSF-NexIO-Server',
	#package : 'TSF-NexIO',
	#tag : 'Server'
}

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
    
	"WICHTIG: Wir geben der App Zugriff auf den Socket via State"
	session at: '__socket__' put: webSocket.

	clientsMutex critical: [ clients add: webSocket ].

	[
		[ webSocket isConnected ] whileTrue: [
			self readAndDispatch: webSocket session: session.
		]
	] ensure: [ 
		"Cleanup: Wenn der Socket stirbt, User aus Registry entfernen"
		clientsMutex critical: [ 
		clients remove: webSocket ifAbsent: [].
		"Falls ein User eingeloggt war, entfernen wir ihn"
		self unregisterUser: (session user).
		].
	
		self logInfo: 'Client disconnected'.
	].

]

{ #category : 'initialization' }
TsfNexIOServer >> initialize [

	super initialize.
	
	clients := Set new.
	clientsMutex := Mutex new.
	userRegistry := Dictionary new. "Neu: Das Telefonbuch"

]

{ #category : 'error handling' }
TsfNexIOServer >> logError: aString [

    logger 
        ifNotNil: [ logger error: '[TsfNexIO] ', aString ]
        ifNil: [ Transcript show: '[TsfNexIO ERROR] '; show: aString; cr ]
]

{ #category : 'accessing' }
TsfNexIOServer >> logInfo: aString [
    "Die Weiche: Haben wir einen Logger? Wenn ja, nutze ihn. Wenn nein, Transcript."

    logger 
        ifNotNil: [ logger info: '[TsfNexIOServer] ', aString ]
        ifNil: [ Transcript show: '[TsfNexIOServer] ' ; show: aString; cr ]
]

{ #category : 'actions' }
TsfNexIOServer >> processRequest: json session: session [
    | method params id selector result |

    method := json at: 'method'.
    params := json at: 'params' ifAbsent: [ Dictionary new ].
    id := json at: 'id'.
    
    "Hier passiert die Magie: method 'login' -> #rpcLogin:state:"
    selector := ('rpc', method capitalized, ':session:') asSymbol.
    
    [
        (delegate respondsTo: selector) ifFalse: [
             ^ TsfNexIOProtocol createError: -32601 message: 'Method not found' data: method id: id
        ].
        
        result := delegate perform: selector with: params with: session.
        ^ TsfNexIOProtocol createResponse: result id: id.

    ] on: Error do: [ :ex |
        self logError: 'App Error: ', ex description.
        ^ TsfNexIOProtocol createError: -32603 message: ex messageText data: nil id: id.
    ].

]

{ #category : 'as yet unclassified' }
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
    | message json response |

    [
        message := webSocket readMessage.
        json := NeoJSONReader fromString: message.
        
        (json includesKey: 'id') 
            ifTrue: [ 
                response := self processRequest: json session: session.
                webSocket sendMessage: response. 
            ]
            ifFalse: [ 
                "Notification handling could go here" 
            ].

    ] on: ConnectionClosed, PrimitiveFailed do: [ :ex | ex return ].
]

{ #category : 'as yet unclassified' }
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

{ #category : 'as yet unclassified' }
TsfNexIOServer >> startHeartbeat [

	self stopHeartbeat. "Sicherstellen, dass er nicht doppelt läuft"

	heartbeatProcess := [
		[
			(Delay forSeconds: 30) wait.
			self pruneDeadConnections.
		] repeat.
	] forkAt: Processor systemBackgroundPriority named: 'TsfNexIOHeartbeat'.
    
	self logInfo: 'Heartbeat started.'.


]

{ #category : 'public' }
TsfNexIOServer >> startOn: port [

	server := ZnServer startDefaultOn: port.
   	server delegate map: 'ws' to: (ZnWebSocketDelegate handler: [ :webSocket |
		self handleConnection: webSocket
	]).

	self startHeartbeat.

	self logInfo: 'NexIO Server started on port ', port asString.
]

{ #category : 'accessing' }
TsfNexIOServer >> stop [

	self stopHeartbeat .
	server ifNotNil: [ server stop ].
]

{ #category : 'as yet unclassified' }
TsfNexIOServer >> stopHeartbeat [

	heartbeatProcess ifNotNil: [ 
		heartbeatProcess terminate. 
		heartbeatProcess := nil.
		self logInfo: 'Heartbeat stopped.'.
	].
]

{ #category : 'as yet unclassified' }
TsfNexIOServer >> unregisterUser: username [

	username ifNil: [ ^ self ].
	clientsMutex critical: [
		userRegistry removeKey: username ifAbsent: [].
		self logInfo: 'Unregistered user: ', username.
	].

]
