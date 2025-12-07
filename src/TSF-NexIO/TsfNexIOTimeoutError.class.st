Class {
	#name : 'TsfNexIOTimeoutError',
	#superclass : 'Error',
	#instVars : [
		'method',
		'params'
	],
	#category : 'TSF-NexIO-Core',
	#package : 'TSF-NexIO',
	#tag : 'Core'
}

{ #category : 'signalling' }
TsfNexIOTimeoutError class >> signalForMethod: aMethod params: aDict [

    ^ self new
        method: aMethod params: aDict;
        signal
]

{ #category : 'accessing' }
TsfNexIOTimeoutError >> messageText [
    "Pharo uses this for debugger-title"

	^ method 
        ifNotNil: [ 'Timeout waiting for request: ', method asString ]
        ifNil: [ super messageText ifNil: ['Unknown Timeout'] ]
]

{ #category : 'error handling' }
TsfNexIOTimeoutError >> method: aString params: aDictionary [

    method := aString.
    params := aDictionary.
]

{ #category : 'accessing' }
TsfNexIOTimeoutError >> params [

	^ params
]
