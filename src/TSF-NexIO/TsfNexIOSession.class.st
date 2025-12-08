"
Copyright 2025 Georg Hagn
SPDX-License-Identifier: Apache-2.0


I am a session object and store user and socket informations
"
Class {
	#name : 'TsfNexIOSession',
	#superclass : 'Object',
	#instVars : [
		'socket',
		'user',
		'data',
		'creationTime',
		'authenticated'
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
	data := IdentityDictionary new. "For data, that do not require instance variables"
]

{ #category : 'testing' }
TsfNexIOSession >> isAuthenticated [

	^ authenticated
]

{ #category : 'accessing' }
TsfNexIOSession >> isAuthenticated: aBool [

    authenticated := aBool
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
