Class {
	#name : 'TsfNexIOTestDelegate',
	#superclass : 'Object',
	#instVars : [
		'lastReceivedSession'
	],
	#category : 'TSF-NexIO-Tests',
	#package : 'TSF-NexIO-Tests'
}

{ #category : 'rpc - methods' }
TsfNexIOTestDelegate >> lastReceivedSession [

    ^ lastReceivedSession
]

{ #category : 'rpc - methods' }
TsfNexIOTestDelegate >> rpcEcho: params session: aSession [
    "korresponding to JSON method: 'echo'"
    
    lastReceivedSession := aSession.
    ^ params
]

{ #category : 'rpc - methods' }
TsfNexIOTestDelegate >> rpcErrorTrigger: params session: aSession [
    "korrespondiert to JSON method: 'errorTrigger'"
    
    "Simulates a Business-Logic error"
    Error signal: 'Simulated Crash'
]

{ #category : 'rpc - methods' }
TsfNexIOTestDelegate >> rpcSlow: params session: aSession [
    "korresponding to JSON method: 'slow'"
    
    (Delay forSeconds: 3) wait.
    ^ 'done'
]
