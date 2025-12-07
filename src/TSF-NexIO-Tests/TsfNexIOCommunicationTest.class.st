"
Brief explanation of the test

1. **Semaphores:** Since reception is asynchronous (the client listener thread calls the handler), we use semaphores (`sem1`, `sem2`) to pause the main test thread until the message arrives.

2. **Independence:** We check `server sessions size equals: 2` to ensure that our broadcast *should* actually go to two destinations.

3. **Payload Check:** We carefully examine whether the JSON (`method` and `params`) arrives correctly.
"
Class {
	#name : 'TsfNexIOCommunicationTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'client1',
		'client2',
		'port'
	],
	#category : 'TSF-NexIO-Tests',
	#package : 'TSF-NexIO-Tests'
}

{ #category : 'running' }
TsfNexIOCommunicationTest >> setUp [

	super setUp.
  
	 port := 40000 + 100 atRandom.
    "start server (The delegate is secondary here, as the server-push logic resides within the server itself."
    server := TsfNexIOServer new.
    server delegate: TsfNexIOBaseDelegate new. 
    server startOn: port.
    
    "Zwei Clients vorbereiten"
    client1 := TsfNexIOClient new.
    client2 := TsfNexIOClient new.
]

{ #category : 'running' }
TsfNexIOCommunicationTest >> tearDown [
    "clean up everything"

    client1 ifNotNil: [ client1 close ].
    client2 ifNotNil: [ client2 close ].
    server ifNotNil: [ server stop ].

    super tearDown.
]

{ #category : 'tests' }
TsfNexIOCommunicationTest >> testBroadcastNotification [
    "Szenario: server sends a notification to ALL clients."
    
    | sem1 sem2 received1 received2 |
    
    sem1 := Semaphore new.
    sem2 := Semaphore new.
    received1 := nil.
    received2 := nil.
    
    "1. We define what happens when clients receive a notification."
    client1 notificationHandler: [ :json | 
        received1 := json.
        sem1 signal. "Signalisiert: client 1 got something"
    ].
    
    client2 notificationHandler: [ :json | 
        received2 := json. 
        sem2 signal. "Signalisiert: client 2 got something"
    ].
    
    "2. Beide Clients verbinden"
    client1 connectTo: 'ws://localhost:', port asString , '/ws'.
    client2 connectTo: 'ws://localhost:', port asString , '/ws'.
    
    "Wait briefly until the handshake is complete on both sides (important for async tests!)."
    (Delay forMilliseconds: 200) wait.
    
    "Check: Are both actually registered on the server?"
    self assert: server sessions size equals: 2.
    
    "3. ACTION: server sends broadcast"
    server broadcastNotification: 'system.alert' params: {'text' -> 'Shutdown imminent'} asDictionary.
    
    "4. wait for receive (max 1 second)"
    (sem1 waitTimeoutSeconds: 1) ifTrue: [ self fail: 'Timeout: Client 1 hat nichts empfangen' ].
    (sem2 waitTimeoutSeconds: 1) ifTrue: [ self fail: 'Timeout: Client 2 hat nichts empfangen' ].
    
    "5. ASSERT: check content"
    self assert: (received1 at: 'method') equals: 'system.alert'.
    self assert: ((received1 at: 'params') at: 'text') equals: 'Shutdown imminent'.
    
    self assert: (received2 at: 'method') equals: 'system.alert'.
    self assert: ((received2 at: 'params') at: 'text') equals: 'Shutdown imminent'.
]
