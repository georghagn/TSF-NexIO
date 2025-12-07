"
I am the client-side implementation of the TsfNexIO JSON-RPC 2.0 framework.
I handle the connection to the server, serialization of requests, and mapping asynchronous responses back to synchronous calls.

*Responsibilities*
- **Connection Management:** Connect to a WebSocket URL.
- **Protocol:** Implement JSON-RPC 2.0 (Request, Notification, Batch).
- **Concurrency:** Map incoming responses (by ID) to the waiting process using Semaphores.
- **Thread Safety:** Protect pending request storage with a Monitor.

*Collaborators*
- `ZnWebSocket`: Underlying transport.
- `NeoJSON`: Serialization.

*Public API*
- `connectTo: urlString` - Establish connection.
- `sendSynchronous: method params: args` - Sends request and waits for result.
- `sendNotification: method params: args` - Fire and forget.
- `close` - Clean up.

*Internal State*
- `pendingRequests`: A Dictionary mapping Request-IDs to Semaphores.
- `requestMutex`: A Monitor ensuring thread-safe access to `pendingRequests`.

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
		'logger',
		'requestMutex',
		'requestTimeout',
		'streamTimeOut'
	],
	#category : 'TSF-NexIO-Client',
	#package : 'TSF-NexIO',
	#tag : 'Client'
}

{ #category : 'defaults' }
TsfNexIOClient class >> defaultRequestTimeout [

    "How long to wait for a synchronous response before raising an error (e.g., 30 seconds)"
    ^ 5 
]

{ #category : 'defaults' }
TsfNexIOClient class >> defaultStreamTimeOut [

	^ 60
]

{ #category : 'defaults' }
TsfNexIOClient class >> defaultUserAgent [

    ^ 'TsfNexIO-Client/1.0'
]

{ #category : 'initialize-release' }
TsfNexIOClient >> close [
    webSocket ifNotNil: [ webSocket close ].
]

{ #category : 'actions' }
TsfNexIOClient >> collectBatchResults: batchIds [

    ^ batchIds collect: [ :id |
        | container semaphore |
        container := pendingRequests at: id ifAbsent: [ self error: 'ID lost' ].
        semaphore := container first.
        (semaphore waitTimeoutSeconds: 5) ifTrue: [ self error: 'Batch Timeout' ].
        mutex critical: [ pendingRequests removeKey: id ifAbsent: [] ].
        container second.
    ].
]

{ #category : 'public - line' }
TsfNexIOClient >> connectTo: urlString [

    webSocket := ZnWebSocket to: urlString.
    webSocket stream timeout: streamTimeOut. 
    
    pendingRequests := Dictionary new.
    requestCounter := 0.
    mutex := Mutex new.
    
    [ self listenLoop ] forkAt: Processor userBackgroundPriority named: 'TsfNexIOListener'.
]

{ #category : 'private - actions' }
TsfNexIOClient >> dispatchIncoming: json [
    | id |

    "TODO: The id could also be JSON 'null'! It should be intercepted."
    id := json at: 'id' ifAbsent: [ nil ].
    id 
        ifNotNil: [ self handleResponse: json id: id ]
        ifNil:    [ self handleNotification: json ].
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
            (arr at: 1) signal.
        ]
    ].
]

{ #category : 'initialization' }
TsfNexIOClient >> initialize [

    super initialize.

    mutex := Mutex new.
    requestCounter := 0.
    streamTimeOut := self class defaultStreamTimeOut.
    requestTimeout := self class defaultRequestTimeout.
]

{ #category : 'request handling' }
TsfNexIOClient >> listenLoop [

    "We'll keep running as long as the socket thinks it's connected."
    [ webSocket isConnected ] whileTrue: [
        [
            | message json |
            
            "1. Read"
            message := webSocket readMessage.
            
            "2. MOST IMPORTANT LINE: If message is nil, the server is down."
            "No error, but a quiet end."
            message ifNil: [ 
                self close. 
                ^ self "end process!" 
            ].

            "3. Parsen (Crashes if message is nil, therefore step 2 is important)"
            json := NeoJSONReader fromString: message.
            
            "4. Dispatchen"
            json isArray 
                ifTrue: [ json do: [ :item | self dispatchIncoming: item ] ]
                ifFalse: [ self dispatchIncoming: json ].

        ] on: Error do: [ :ex |
        "IMPORTANT: We catch 'Exception' (everything), not just 'Error'.
         We do NOT log anything to the transcript to avoid race conditions 
         when viewing it. We simply terminate the process."
        ^ self
        ]
    ].

]

{ #category : 'error handling' }
TsfNexIOClient >> logError: aString [

	logger ifNotNil: [ 
		logger error: '[TsfNexClient] ', aString 
	] ifNil: [ 
		Transcript show: '[TsfNexIO ERROR] '; show: aString; cr.
	]
]

{ #category : 'accessing' }
TsfNexIOClient >> logInfo: aString [
    "Have we a logger? If yes, use him. If no, Transcript."

	logger ifNotNil: [ 
		logger info: '[TsfNexIOClient] ', aString 
	] ifNil: [
		Transcript show: '[TsfNexIOSClient] ' ; show: aString; cr.
	]
]

{ #category : 'accessing' }
TsfNexIOClient >> notificationHandler: aBlock [

    notificationHandler := aBlock.
]

{ #category : 'actions' }
TsfNexIOClient >> registerRequest: method params: params [
    | id semaphore |

    mutex critical: [
        requestCounter := requestCounter + 1.
        id := requestCounter.
        semaphore := Semaphore new.
        pendingRequests at: id put: (Array with: semaphore with: nil).
    ].
    ^ TsfNexIOProtocol createRequest: method params: params id: id.
]

{ #category : 'accessing' }
TsfNexIOClient >> requestTimeout: anInteger [

    requestTimeout := anInteger.
]

{ #category : 'actions' }
TsfNexIOClient >> sendBatch: requestCollection [
    | batchArray batchIds |

    mutex critical: [
        batchArray := requestCollection collect: [ :assoc |
            self registerRequest: assoc key params: assoc value
        ].
    ].
    batchIds := batchArray collect: [ :json | json at: 'id' ].
    webSocket sendMessage: (NeoJSONWriter toString: batchArray).
    ^ self collectBatchResults: batchIds.
]

{ #category : 'actions' }
TsfNexIOClient >> sendSynchronous: method params: params [
    | id semaphore reqDict jsonResponse errorDict |
    
    reqDict := self registerRequest: method params: params.
    id := reqDict at: 'id'.
    semaphore := (pendingRequests at: id) first.
    
    webSocket sendMessage: (NeoJSONWriter toString: reqDict).
    
    (semaphore waitTimeoutSeconds: requestTimeout ) ifTrue: [ 
        mutex critical: [ pendingRequests removeKey: id ifAbsent: [] ].
			TsfNexIOTimeoutError signalForMethod: method params: params
    ].

    jsonResponse := (pendingRequests removeKey: id) second.

    (jsonResponse includesKey: 'error') ifTrue: [
        errorDict := jsonResponse at: 'error'.
        TsfNexIOError new
            code: (errorDict at: 'code');
            messageText: (errorDict at: 'message');
            signal.
    ].
    
    ^ jsonResponse at: 'result'.
]
