"
I am a session object
"
Class {
	#name : 'TsfNexIOSession',
	#superclass : 'Object',
	#instVars : [
		'socket',
		'user',
		'data',
		'creationTime'
	],
	#category : 'TSF-NexIO-Core',
	#package : 'TSF-NexIO',
	#tag : 'Core'
}

{ #category : 'accessing' }
TsfNexIOSession >> at: key [

	^ data at: (key asSymbol) ifAbsent: [ nil ].
]

{ #category : 'accessing' }
TsfNexIOSession >> at: key put: value [

	data at: (key asSymbol) put: value.
]

{ #category : 'initialization' }
TsfNexIOSession >> initialize [

	super initialize.
	creationTime := DateAndTime now.
	data := IdentityDictionary new. "Für sonstige Daten, die keine Instanzvariablen brauchen"
]

{ #category : 'testing' }
TsfNexIOSession >> isAuthenticated [

	^ user notNil.
]

{ #category : 'accessing' }
TsfNexIOSession >> socket [

	^ socket.
]

{ #category : 'accessing' }
TsfNexIOSession >> socket: aWebSocket [

	socket := aWebSocket.
]

{ #category : 'accessing' }
TsfNexIOSession >> user [

	^ user.
]

{ #category : 'accessing' }
TsfNexIOSession >> user: aString [

	user := aString
]
