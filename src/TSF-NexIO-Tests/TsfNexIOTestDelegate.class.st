Class {
	#name : 'TsfNexIOTestDelegate',
	#superclass : 'Object',
	#instVars : [
		'lastReceivedSession'
	],
	#category : 'TSF-NexIO-Tests',
	#package : 'TSF-NexIO-Tests'
}

{ #category : 'handling' }
TsfNexIOTestDelegate >> handleJsonRpcRequest: aRequest session: aSession [
    | method params |

    method := aRequest method.
    params := aRequest params.

    "Echo: Schickt Parameter zurück"
    method = 'test.echo' ifTrue: [ ^ params ].

    "Error: Simuliert einen Fehler"
    method = 'test.error' ifTrue: [ 
        TsfNexIOConstants methodNotFound signal 
    ].
    
    "Timeout Simulation"
    method = 'test.slow' ifTrue: [
        (Delay forSeconds: 2) wait.
        ^ 'done'
    ].

    ^ TsfNexIOConstants methodNotFound
]

{ #category : 'rpc - methods' }
TsfNexIOTestDelegate >> lastReceivedSession [

    ^ lastReceivedSession
]

{ #category : 'rpc - methods' }
TsfNexIOTestDelegate >> rpcEcho: params session: aSession [
    "Korrespondiert zu JSON method: 'echo'"
    
    lastReceivedSession := aSession.
    ^ params
]

{ #category : 'rpc - methods' }
TsfNexIOTestDelegate >> rpcErrorTrigger: params session: aSession [
    "Korrespondiert zu JSON method: 'errorTrigger'"
    
    "Simuliert einen Business-Logic Fehler"
    Error signal: 'Simulated Crash'
]

{ #category : 'rpc - methods' }
TsfNexIOTestDelegate >> rpcSlow: params session: aSession [
    "Korrespondiert zu JSON method: 'slow'"
    
    (Delay forSeconds: 2) wait.
    ^ 'done'
]
