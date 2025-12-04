"
I am a Demo / Test App. for usage: see Tests
"
Class {
	#name : 'TsfNexIOTestApp',
	#superclass : 'Object',
	#instVars : [
		'server',
		'lastReceivedSession'
	],
	#category : 'TSF-NexIO-Tests',
	#package : 'TSF-NexIO-Tests'
}

{ #category : 'accessing' }
TsfNexIOTestApp >> lastReceivedSession [

	^ lastReceivedSession.
]

{ #category : 'as yet unclassified' }
TsfNexIOTestApp >> rpcCrash: params session: session [

	Error signal: 'Boom'.
]

{ #category : 'as yet unclassified' }
TsfNexIOTestApp >> rpcEcho: params session: session [

	lastReceivedSession := session. "Wir merken uns die Session für Assertions"
	^ params.
]

{ #category : 'as yet unclassified' }
TsfNexIOTestApp >> rpcLogin: params session: session [

	session user: (params at: 'user').
	server registerUser: (params at: 'user') on: session socket.
	^ 'OK'.
]

{ #category : 'as yet unclassified' }
TsfNexIOTestApp >> rpcWhisper: params session: session [
    | recipient text |
    
    "Check: Darf er überhaupt flüstern?"
    session isAuthenticated ifFalse: [ Error signal: 'Du musst eingeloggt sein!' ].
    
    recipient := params at: 'to'.
    text := params at: 'text'.
    
    server 
        send: 'chatMessage' 
        params: { 'from' -> session user. 'text' -> text } asDictionary 
        toUser: recipient.
        
    ^ 'Sent'.

]

{ #category : 'accessing' }
TsfNexIOTestApp >> server [

	^ server
]

{ #category : 'accessing' }
TsfNexIOTestApp >> server: anObject [

	server := anObject
]
