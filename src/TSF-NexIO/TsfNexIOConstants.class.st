"
I am a SharedPool and register errorCode to String representation
"
Class {
	#name : 'TsfNexIOConstants',
	#superclass : 'SharedPool',
	#classInstVars : [
		'ParseError',
		'InvalidRequest',
		'MethodNotFound',
		'InvalidParams',
		'InternalError',
		'ServerErrorMin',
		'ServerErrorMax'
	],
	#category : 'TSF-NexIO-Core',
	#package : 'TSF-NexIO',
	#tag : 'Core'
}

{ #category : 'class initialization' }
TsfNexIOConstants class >> initialize [
	"Standard JSON-RPC 2.0 Errors"

	ParseError      := -32700. "Invalid JSON was received by the server."
	InvalidRequest  := -32600. "The JSON sent is not a valid Request object."
	MethodNotFound  := -32601. "The method does not exist / is not available."
	InvalidParams   := -32602. "Invalid method parameter(s)."
	InternalError   := -32603. "Internal JSON-RPC error."

	"Reserved for implementation-defined server-errors"
	ServerErrorMin  := -32000.
	ServerErrorMax  := -32099.

	"Einmalig ausführen, um die Variablen zu füllen:"
	"TsfNexIOConstants initialize."
	
]
