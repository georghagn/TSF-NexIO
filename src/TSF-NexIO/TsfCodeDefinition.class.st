Class {
	#name : 'TsfCodeDefinition',
	#superclass : 'Object',
	#instVars : [
		'code',
		'message'
	],
	#category : 'TSF-NexIO-Core',
	#package : 'TSF-NexIO',
	#tag : 'Core'
}

{ #category : 'class initialization' }
TsfCodeDefinition class >> code: anInteger message: aString [

	^ (self new)
		code: anInteger; message: aString; yourself.
]

{ #category : 'accessing' }
TsfCodeDefinition >> code [

	^ code
]

{ #category : 'accessing' }
TsfCodeDefinition >> code: anObject [

	code := anObject
]

{ #category : 'accessing' }
TsfCodeDefinition >> message [

	^ message
]

{ #category : 'accessing' }
TsfCodeDefinition >> message: anObject [

	message := anObject
]
