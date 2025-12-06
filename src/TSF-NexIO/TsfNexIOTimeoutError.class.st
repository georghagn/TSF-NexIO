Class {
	#name : 'TsfNexIOTimeoutError',
	#superclass : 'Error',
	#instVars : [
		'method',
		'requestParams'
	],
	#category : 'TSF-NexIO-Core',
	#package : 'TSF-NexIO',
	#tag : 'Core'
}

{ #category : 'signalling' }
TsfNexIOTimeoutError class >> signalForMethod: aMethod params: aParams [

    ^ self new
        method: aMethod params: aParams;
        signal
]

{ #category : 'accessing' }
TsfNexIOTimeoutError >> messageText [
    "Pharo nutzt dies für den Debugger-Titel"

    ^ 'Timeout waiting for request: ', method asString
]

{ #category : 'as yet unclassified' }
TsfNexIOTimeoutError >> method: aString params: aDictionary [

    method := aString.
    requestParams := aDictionary.
]
