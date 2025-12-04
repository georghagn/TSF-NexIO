"
I define the Json RPC Messages . I have only class methods
"
Class {
	#name : 'TsfNexIOProtocol',
	#superclass : 'Object',
	#pools : [
		'TsfNexIOConstants'
	],
	#category : 'TSF-NexIO-Core',
	#package : 'TSF-NexIO',
	#tag : 'Core'
}

{ #category : 'class initialization' }
TsfNexIOProtocol class >> createError: code message: message data: data id: id [
    | errorDict |

    errorDict := { 'code' -> code. 'message' -> message } asDictionary.
    data ifNotNil: [ errorDict at: 'data' put: data ].
    
    ^ NeoJSONWriter toString: {
        'jsonrpc' -> '2.0'.
        'error' -> errorDict.
        'id' -> id
    } asDictionary.
]

{ #category : 'class initialization' }
TsfNexIOProtocol class >> createNotification: method params: params [

    ^ NeoJSONWriter toString: {
        'jsonrpc' -> '2.0'.
        'method' -> method.
        'params' -> params.
    } asDictionary.
]

{ #category : 'class initialization' }
TsfNexIOProtocol class >> createRequest: method params: params id: id [

    ^ NeoJSONWriter toString: {
        'jsonrpc' -> '2.0'.
        'method' -> method.
        'params' -> params.
        'id' -> id
    } asDictionary.
]

{ #category : 'class initialization' }
TsfNexIOProtocol class >> createResponse: result id: id [

    ^ NeoJSONWriter toString: {
        'jsonrpc' -> '2.0'.
        'result' -> result.
        'id' -> id
    } asDictionary.

]
