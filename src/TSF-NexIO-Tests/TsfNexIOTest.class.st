Class {
	#name : 'TsfNexIOTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'client',
		'app',
		'port'
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
    "WICHTIG: First kill client, so that the listener gives peace"
    client ifNotNil: [ client close ].
    
    "Allow it to breathe briefly so the process can die."
    (Delay forMilliseconds: 10) wait.
    
    "Then server out"
    server ifNotNil: [ server stop ].
    
    super tearDown.
]

{ #category : 'tests' }
TsfNexIOTest >> testApplicationError [
    "The app throws a 'Boom'; the server must capture this and send it as a JSON error."

    self 
        should: [ client sendSynchronous: 'crash' params: {} asDictionary ]
        raise: TsfNexIOError
        withExceptionDo: [ :ex | 
            self assert: ex code equals: TsfNexIOConstants internalError code.
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
TsfNexIOTest >> testMethodNotFound [

    self 
        should: [ client sendSynchronous: 'gibtsNicht' params: {} asDictionary ]
        raise: TsfNexIOError
        withExceptionDo: [ :ex | 
            "We use Classmethode"
            self assert: ex code equals: TsfNexIOConstants methodNotFound code.
            self assert: (ex messageText includesSubstring: 'Method not found').
        ].
]

{ #category : 'testing' }
TsfNexIOTest >> testSynchronousEcho [
    | result params |

    params := {'text' -> 'Hello'} asDictionary.
    
    result := client sendSynchronous: 'echo' params: params.
    
    self assert: (result at: 'text') equals: 'Hello'.
    
    "Check if the session was passed correctly"
    self assert: app lastReceivedSession notNil.
    self assert: app lastReceivedSession socket isConnected.
]
