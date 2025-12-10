"
Copyright 2025 Georg Hagn
SPDX-License-Identifier: Apache-2.0


I handle RPC 2.0 Error Codes. I have only class methods
"
Class {
	#name : 'TsfNexIOConstants',
	#superclass : 'Object',
	#classInstVars : [
		'ParseError',
		'InvalidRequest',
		'MethodNotFound',
		'InvalidParams',
		'InternalError'
	],
	#category : 'TSF-NexIO-Core',
	#package : 'TSF-NexIO',
	#tag : 'Core'
}

{ #category : 'class initialization' }
TsfNexIOConstants class >> internalError [

    ^ InternalError ifNil: [ 
        InternalError := TsfNexIOErrorDef code: -32603 message: 'Internal error' 
    ].
]

{ #category : 'class initialization' }
TsfNexIOConstants class >> invalidParams [

    ^ InvalidParams ifNil: [ 
        InvalidParams := TsfNexIOErrorDef code: -32602 message: 'Invalid params' 
    ].
]

{ #category : 'class initialization' }
TsfNexIOConstants class >> invalidRequest [

    ^ InvalidRequest ifNil: [ 
        InvalidRequest := TsfNexIOErrorDef code: -32600 message: 'Invalid Request' 
    ].
]

{ #category : 'class initialization' }
TsfNexIOConstants class >> methodNotFound [

    ^ MethodNotFound ifNil: [ 
        MethodNotFound := TsfNexIOErrorDef code: -32601 message: 'Method not found' 
    ].
]

{ #category : 'parsing' }
TsfNexIOConstants class >> parseError [

    "Lazy Initialization: Wenn nil, erzeuge neu."
    ^ ParseError ifNil: [ 
        ParseError := TsfNexIOErrorDef code: -32700 message: 'Parse error' 
    ].
]

{ #category : 'initialization' }
TsfNexIOConstants class >> reset [

    ParseError := nil.
    InvalidRequest := nil.
    MethodNotFound := nil.
    InvalidParams := nil.
    InternalError := nil.
]
