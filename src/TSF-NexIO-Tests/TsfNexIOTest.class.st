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
    port := 40000 + 100 atRandom.
    app := TsfNexIOTestApp new.
    server := TsfNexIOServer new. server delegate: app. server startOn: port.
    client := TsfNexIOClient new. client connectTo: 'ws://localhost:', port asString, '/ws'.
    (Delay forMilliseconds: 100) wait.
]

{ #category : 'running' }
TsfNexIOTest >> tearDown [
    "WICHTIG: Erst Client töten, damit der Listener Ruhe gibt"
    client ifNotNil: [ client close ].
    
    "Kurz atmen lassen, damit der Prozess sterben kann"
    (Delay forMilliseconds: 10) wait.
    
    "Dann Server aus"
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
TsfNexIOTest >> testBatch [
    | requests results |
    requests := { 'echo' -> {'txt'->'A'} asDictionary. 'echo' -> {'txt'->'B'} asDictionary }.
    results := client sendBatch: requests.
    self assert: results size equals: 2.
    self assert: ((results first at: 'result') at: 'txt') equals: 'A'.
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
    self 
        should: [ client sendSynchronous: 'gibtsNicht' params: {} asDictionary ]
        raise: TsfNexIOError
        withExceptionDo: [ :ex | 
            "Wir nutzen deine Klassenmethode"
            self assert: ex code equals: TsfNexIOConstants MethodNotFound code.
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
