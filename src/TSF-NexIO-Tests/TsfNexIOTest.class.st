Class {
	#name : 'TsfNexIOTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'client',
		'app',
		'port'
	],
	#pools : [
		'TsfNexIOConstants'
	],
	#category : 'TSF-NexIO-Tests',
	#package : 'TSF-NexIO-Tests'
}

{ #category : 'running' }
TsfNexIOTest >> setUp [

    super setUp.
    
    "1. Zufälligen Port wählen um Konflikte zu vermeiden"
    port := 40000 + 100 atRandom.
    
    "2. Mock App vorbereiten"
    app := TsfNexIOTestApp new.
    
    "3. Server starten"
    server := TsfNexIOServer new.
    server delegate: app.
    server startOn: port.
    
    "4. Client starten"
    client := TsfNexIOClient new.
    client connectTo: 'ws://localhost:', port asString, '/ws'.
    
    "Kurz warten bis Verbindung steht"
    (Delay forMilliseconds: 100) wait.
]

{ #category : 'running' }
TsfNexIOTest >> tearDown [

    "Wichtig: Alles sauber beenden, sonst bleiben Ports belegt!"
    client ifNotNil: [ client close ].
    server ifNotNil: [ server stop ].
    super tearDown.
]

{ #category : 'tests' }
TsfNexIOTest >> testApplicationError [
    "Die App wirft 'Boom', der Server muss das fangen und als JSON Error senden"

    self 
        should: [ client sendSynchronous: 'crash' params: {} asDictionary ]
        raise: TsfNexIOError
        withExceptionDo: [ :ex | 
            self assert: ex code equals: -32603. "Internal Error"
            self assert: (ex messageText includesSubstring: 'Boom').
        ].
]

{ #category : 'tests' }
TsfNexIOTest >> testLoginAndState [
    client sendSynchronous: 'login' params: {'user' -> 'Tester'} asDictionary.
    
    "Der Mock merkt sich die Session im lastReceivedState"
    "Wir simulieren einen zweiten Call, um zu prüfen ob der User noch da ist"
    client sendSynchronous: 'echo' params: {} asDictionary.
    
    self assert: app lastReceivedSession user equals: 'Tester'.
    self assert: app lastReceivedSession isAuthenticated.
]

{ #category : 'tests' }
TsfNexIOTest >> testMethodNotFound [
    "Erwartet: Fehlercode -32601"

    self 
        should: [ client sendSynchronous: 'gibtEsNicht' params: {} asDictionary ]
        raise: TsfNexIOError
        withExceptionDo: [ :ex | 
            self assert: ex code equals: -32601.
            self assert: (ex messageText includesSubstring: 'Method not found').
        ].
]

{ #category : 'testing' }
TsfNexIOTest >> testSynchronousEcho [

    | result params |
    params := {'text' -> 'Hello'} asDictionary.
    
    result := client sendSynchronous: 'echo' params: params.
    
    self assert: (result at: 'text') equals: 'Hello'.
    
    "Prüfen ob Session korrekt übergeben wurde"
    self assert: app lastReceivedSession notNil.
    self assert: app lastReceivedSession socket isConnected.
]
