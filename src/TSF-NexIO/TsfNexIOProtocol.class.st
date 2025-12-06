"
I define the Json RPC Messages . I have only class methods
"
Class {
	#name : 'TsfNexIOProtocol',
	#superclass : 'Object',
	#category : 'TSF-NexIO-Core',
	#package : 'TSF-NexIO',
	#tag : 'Core'
}

{ #category : 'error handling' }
TsfNexIOProtocol class >> createError: errorDef data: data id: id [

	^ self createError: errorDef message: nil data: data id: id.
]

{ #category : 'class initialization' }
TsfNexIOProtocol class >> createError: errorDefOrCode message: msgStringOrNil data: data id: id [
    | code message errorDict |
    (errorDefOrCode isKindOf: TsfNexIOErrorDef)
        ifTrue: [ 
            code := errorDefOrCode code.
            message := msgStringOrNil ifNil: [ errorDefOrCode message ].
        ]
        ifFalse: [ 
            code := errorDefOrCode.
            message := msgStringOrNil.
        ].

    errorDict := { 'code' -> code. 'message' -> message } asDictionary.
    data ifNotNil: [ errorDict at: 'data' put: data ].
    
    ^ {
        'jsonrpc' -> self rpcVersion.
        'error' -> errorDict.
        'id' -> id
    } asDictionary.

]

{ #category : 'class initialization' }
TsfNexIOProtocol class >> createNotification: method params: params [

    ^ {
        'jsonrpc' -> self rpcVersion.
        'method' -> method.
        'params' -> params.
    } asDictionary.
]

{ #category : 'class initialization' }
TsfNexIOProtocol class >> createRequest: method params: params id: id [

    ^ {
        'jsonrpc' -> self rpcVersion.
        'method' -> method.
        'params' -> params.
        'id' -> id
    } asDictionary.
]

{ #category : 'class initialization' }
TsfNexIOProtocol class >> createResponse: result id: id [

    ^ {
        'jsonrpc' -> self rpcVersion.
        'result' -> result.
        'id' -> id
    } asDictionary.

]

{ #category : 'defaults' }
TsfNexIOProtocol class >> rpcVersion [ 

	^ '2.0'
]
