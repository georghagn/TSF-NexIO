"
I am a SharedPool and register errorCode to String representation
"
Class {
	#name : 'TsfNexIOConstants',
	#superclass : 'SharedPool',
	#classVars : [
		'InternalError',
		'InvalidParams',
		'InvalidRequest',
		'MethodNotFound',
		'ParseError'
	],
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

{ #category : 'accessing' }
TsfNexIOConstants class >> MethodNotFound [

	^ MethodNotFound
]

{ #category : 'class initialization' }
TsfNexIOConstants class >> initialize [
	"Standard JSON-RPC 2.0 Errors"

    ParseError      := TsfNexIOErrorDef code: -32700 message: 'Parse error'.
    InvalidRequest  := TsfNexIOErrorDef code: -32600 message: 'Invalid Request'.
    MethodNotFound  := TsfNexIOErrorDef code: -32601 message: 'Method not found'.
    InvalidParams   := TsfNexIOErrorDef code: -32602 message: 'Invalid params'.
    InternalError   := TsfNexIOErrorDef code: -32603 message: 'Internal error'.
	
	"Einmalig ausführen, um die Variablen zu füllen:"
	"TsfNexIOConstants initialize."
	
]
