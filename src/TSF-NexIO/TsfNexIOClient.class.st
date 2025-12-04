"
I am the central WebSocket client for the TsfNexIO framework. I send messegase synchron and listen on notification


Example:
```
| result params |
params := {'text' -> 'Hello'} asDictionary.
result := client sendSynchronous: 'echo' params: params.
```
"
Class {
	#name : 'TsfNexIOClient',
	#superclass : 'Object',
	#instVars : [
		'webSocket',
		'pendingRequests',
		'requestCounter',
		'notificationHandler',
		'mutex',
		'logger'
	],
	#pools : [
		'TsfNexIOConstants'
	],
	#category : 'TSF-NexIO-Client',
	#package : 'TSF-NexIO',
	#tag : 'Client'
}

{ #category : 'initialize-release' }
TsfNexIOClient >> close [

    webSocket close.
]

{ #category : 'public - line' }
TsfNexIOClient >> connectTo: urlString [

	webSocket := ZnWebSocket to: urlString.

	"Wir greifen auf den unterliegenden SocketStream zu"
	"Der SocketStream kennt 'timeout:', das standardmäßig für Reads gilt."
	webSocket socket timeout: 60.

	pendingRequests := Dictionary new.
	requestCounter := 0.
	mutex := Mutex new.
    
	[ self listenLoop ] forkAt: Processor userBackgroundPriority named: 'TsfNexIOListener'.
]

{ #category : 'error handling' }
TsfNexIOClient >> handleNotification: json [

    notificationHandler ifNotNil: [ notificationHandler value: json ].
]

{ #category : 'actions' }
TsfNexIOClient >> handleResponse: json id: id [

    mutex critical: [
        (pendingRequests at: id ifAbsent: [ nil ]) ifNotNil: [ :arr |
            arr at: 2 put: json.
            (arr first) signal.
        ]
    ].
]

{ #category : 'request handling' }
TsfNexIOClient >> listenLoop [

	[ webSocket isConnected ] whileTrue: [
		[ 
			| message json id |
			message := webSocket readMessage.
			json := NeoJSONReader fromString: message.
			id := json at: 'id' ifAbsent: [ nil ].

			id 
				ifNotNil: [ self handleResponse: json id: id ]
				ifNil:    [ self handleNotification: json ].

		] on: ConnectionClosed, PrimitiveFailed do: [ :ex | 
			self logInfo: 'Verbindung verloren: ', ex description.
			^ self 
		]
	].
]

{ #category : 'error handling' }
TsfNexIOClient >> logError: aString [

    logger 
        ifNotNil: [ logger error: '[TsfNexClient] ', aString ]
        ifNil: [ Transcript show: '[TsfNexIO ERROR] '; show: aString; cr ]
]

{ #category : 'accessing' }
TsfNexIOClient >> logInfo: aString [
    "Die Weiche: Haben wir einen Logger? Wenn ja, nutze ihn. Wenn nein, Transcript."

    logger 
        ifNotNil: [ logger info: '[TsfNexIOClient] ', aString ]
        ifNil: [ Transcript show: '[TsfNexIOSClient] ' ; show: aString; cr ]
]

{ #category : 'accessing' }
TsfNexIOClient >> notificationHandler: aBlock [

    notificationHandler := aBlock.
]

{ #category : 'actions' }
TsfNexIOClient >> sendSynchronous: method params: params [
    | id semaphore resultContainer jsonResponse errorDict |

    mutex critical: [ 
        requestCounter := requestCounter + 1. 
        id := requestCounter.
        semaphore := Semaphore new.
        resultContainer := Array with: semaphore with: nil.
        pendingRequests at: id put: resultContainer.
    ].

    webSocket sendMessage: (TsfNexIOProtocol createRequest: method params: params id: id).

    (semaphore waitTimeoutSeconds: 5) ifTrue: [ 
        mutex critical: [ pendingRequests removeKey: id ifAbsent: [] ].
        self error: 'Timeout waiting for server' 
    ].

    jsonResponse := resultContainer at: 2.
    mutex critical: [ pendingRequests removeKey: id ifAbsent: [] ].

    (jsonResponse includesKey: 'error') ifTrue: [
        errorDict := jsonResponse at: 'error'.
        (TsfNexIOError new)
            code: (errorDict at: 'code');
            messageText: (errorDict at: 'message');
            signal.
    ].
    
    ^ jsonResponse at: 'result'.

]
