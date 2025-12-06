Class {
	#name : 'TsfNexIOIntegrationTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'client',
		'port'
	],
	#category : 'TSF-NexIO-Tests',
	#package : 'TSF-NexIO-Tests'
}

{ #category : 'running' }
TsfNexIOIntegrationTest >> setUp [

    super setUp.
    
    "Server mit unserem Test-Delegate starten"
    port := 40000 + 100 atRandom.
    server := TsfNexIOServer new.
    server delegate: TsfNexIOTestDelegate new.
    server startOn: port. 
    
    "Client erstellen"
    client := TsfNexIOClient new.
    "Timeout für Tests etwas aggressiver setzen, falls nötig"
    client requestTimeout: 2.

    (Delay forMilliseconds: 100) wait.
]

{ #category : 'running' }
TsfNexIOIntegrationTest >> tearDown [

    client ifNotNil: [ client close ].
    server ifNotNil: [ server stop ].
    super tearDown.
]

{ #category : 'tests' }
TsfNexIOIntegrationTest >> testBatchRequest [
    "Da der Client sendBatch: hat, testen wir das auch"
    | batch results |
    
    client connectTo: 'ws://localhost:', port asString, '/ws'.
    
    batch := OrderedCollection new.
    batch add: 'echo' -> {'id' -> 1} asDictionary.
    batch add: 'echo' -> {'id' -> 2} asDictionary.
    
    results := client sendBatch: batch.
    
    self assert: results size equals: 2.
    self assert: ((results first at: 'result') at: 'id') equals: 1.
    self assert: ((results second at: 'result') at: 'id') equals: 2.
]

{ #category : 'tests' }
TsfNexIOIntegrationTest >> testClientErrorHandling [
    "Prüft, ob der Client Server-Fehler korrekt in TsfNexIOError umwandelt"
    
    client connectTo: 'ws://localhost:', port asString, '/ws'.
    
    [ client sendSynchronous: 'error' params: Dictionary new ]
        on: TsfNexIOError 
        do: [ :ex | 
            "Wir erwarten MethodNotFound (-32601)"
            self assert: ex code equals: -32601. 
            ^ self "Test bestanden"
        ].
        
    self fail: 'Should have raised TsfNexIOError'.
]

{ #category : 'tests' }
TsfNexIOIntegrationTest >> testClientTimeout [
    "Prüft den Timeout Mechanismus im Client"
    
    client connectTo: 'ws://localhost:', port asString, '/ws'.
    
    "Wir setzen Timeout sehr kurz (0.5s)"
    client requestTimeout: 500 milliSeconds.
    
    "Der Server wartet bei 'test.slow' 2 Sekunden -> Timeout muss feuern"
    self should: [ 
        client sendSynchronous: 'slow' params: Dictionary new 
    ] raise: TsfNexIOTimeoutError description: 'test.slow'.

]

{ #category : 'tests' }
TsfNexIOIntegrationTest >> testMethodNotFound [
    "Testet den Fall, wenn der Server die Methode nicht kennt"
    
    client connectTo: 'ws://localhost:', port asString , '/ws'.
    
    [ client sendSynchronous: 'unknownMethod' params: Dictionary new ]
        on: TsfNexIOError
        do: [ :ex |
            "Wir erwarten den Code für MethodNotFound (meist -32601)"
            self assert: ex code equals: TsfNexIOConstants methodNotFound.
            ^ self "Erfolg"
        ].
    self fail: 'Sollte TsfNexIOError werfen'
]

{ #category : 'tests' }
TsfNexIOIntegrationTest >> testSynchronousEcho [
    "Prüft den Happy Path: Request raus, Response rein, Result extrahieren"
    | result params |
    
    client connectTo: 'ws://localhost:', port asString, '/ws'.
    
    params := {'text' -> 'Pharo rocks'} asDictionary.
    
	"Prüfung des Ergebnisses"
    result := client sendSynchronous: 'echo' params: params.
    
    "Dein Client gibt direkt (jsonResponse at: 'result') zurück, also prüfen wir das Dictionary"
    self assert: (result at: 'text') equals: 'Pharo rocks'.

	"Prüfung: Wurde die Session im Delegate gesetzt?"
    self assert: (server delegate lastReceivedSession) notNil.
    self assert: (server delegate lastReceivedSession) socket isConnected
]
