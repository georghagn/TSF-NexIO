Class {
	#name : 'TsfCodeRegistry',
	#superclass : 'Object',
	#instVars : [
		'codes'
	],
	#classInstVars : [
		'default'
	],
	#category : 'TSF-NexIO-Core',
	#package : 'TSF-NexIO',
	#tag : 'Core'
}

{ #category : 'accessing' }
TsfCodeRegistry class >> default [

	^ default ifNil: [ default := self new initializeDefaults ]
]

{ #category : 'accessing' }
TsfCodeRegistry class >> definitionFor:  aSymbol [

    ^ (self default) codes at: (aSymbol asSymbol) ifAbsent: [ nil ]

]

{ #category : 'initialization' }
TsfCodeRegistry class >> reset [

    default := nil

]

{ #category : 'accessing' }
TsfCodeRegistry >> at: aSymbol [

    ^ codes at: (aSymbol asSymbol) ifAbsent: [ nil ]
]

{ #category : 'initialization' }
TsfCodeRegistry >> codeFor: aSymbol [

    ^ (self at: (aSymbol asSymbol)) code
]

{ #category : 'accessing' }
TsfCodeRegistry >> definitionFor:  aSymbol [

    ^ codes at: (aSymbol asSymbol) ifAbsent: [ nil ]
]

{ #category : 'initialization' }
TsfCodeRegistry >> initializeDefaults [

	codes := IdentityDictionary new.

	"Standard JSON-RPC 2.0 Codes"
	codes at: #ParseError put:       (TsfCodeDefinition code: -32700 message: 'Parse error').
	codes at: #InvalidRequest put:   (TsfCodeDefinition code: -32600 message: 'Invalid Request').
	codes at: #MethodNotFound put:   (TsfCodeDefinition code: -32601 message: 'Method not found').
	codes at: #InvalidParams put:    (TsfCodeDefinition code: -32602 message: 'Invalid params').
	codes at: #InternalError put:    (TsfCodeDefinition code: -32603 message: 'Internal error').

	codes at: #JsonRPCVersion put:    (TsfCodeDefinition code: '2.0' message: 'JsonRPC Version').

	"Reserved for implementation-defined server-errors"
	codes at: #ServerErrorMin put: (TsfCodeDefinition code: -32000 message: 'ServerError Min').
	codes at: #ServerErrorMax put: (TsfCodeDefinition code: -32099 message: 'ServerError Max').
	
    "Bereich für anwendungsspezifische Fehler"
    codes at: #Timeout put:          (TsfCodeDefinition code: -32000 message: 'Timeout').
    codes at: #DatabaseError put:    (TsfCodeDefinition code: -32001 message: 'Database error').

	^ self.

]

{ #category : 'accessing' }
TsfCodeRegistry >> messageFor: aSymbol [

    ^ (self at: (aSymbol asSymbol)) message
]
