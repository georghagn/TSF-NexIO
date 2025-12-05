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

{ #category : 'initialization' }
TsfNexIOClient class >> defaultWaitTimeoutSeconds [

	^ 5 
]

{ #category : 'initialization' }
TsfNexIOClient class >> defaultWebSocketTimeout [

	^ 60 
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
    webSocket stream timeout: 60.
    
    pendingRequests := Dictionary new.
    requestCounter := 0.
    mutex := Mutex new.
    
    [ self listenLoop ] forkAt: Processor userBackgroundPriority named: 'TsfNexIOListener'.
]

{ #category : 'private - actions' }
TsfNexIOClient >> dispatchIncoming: json [
    | id |
    "Hier knallte es früher, wenn json nil war"
    id := json at: 'id' ifAbsent: [ nil ].
    id ifNotNil: [ self handleResponse: json id: id ]
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

{ #category : 'request handling' }
TsfNexIOClient >> listenLoop [
    "Wir laufen, solange der Socket denkt, er sei verbunden"
    [ webSocket isConnected ] whileTrue: [
        [
            | message json |
            
            "1. Lesen"
            message := webSocket readMessage.
            
            "2. WICHTIGSTE ZEILE: Wenn message nil ist, ist der Server weg."
            "Kein Error, sondern ein stilles Ende."
            message ifNil: [ 
                self close. 
                ^ self "Prozess beenden!" 
            ].

            "3. Parsen (Crasht, wenn message nil wäre, daher Schritt 2 wichtig)"
            json := NeoJSONReader fromString: message.
            
            "4. Dispatchen"
            json isArray 
                ifTrue: [ json do: [ :item | self dispatchIncoming: item ] ]
                ifFalse: [ self dispatchIncoming: json ].

        ] on: Error do: [ :ex |
            "Fangnetz für ALLES (Timeouts, Parse Errors, Logikfehler)"
            self logInfo: 'Listener gestorben: ', ex description.
            self close. 
            ^ self "Prozess beenden!"
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
    "Die Weiche: Haben wir einen Logger? Wenn ja, nutze ihn. Wenn nein, Transcript."

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

{ #category : 'as yet unclassified' }
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

{ #category : 'as yet unclassified' }
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
    
    (semaphore waitTimeoutSeconds: 5) ifTrue: [ 
        mutex critical: [ pendingRequests removeKey: id ifAbsent: [] ].
        self error: 'Timeout' 
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
