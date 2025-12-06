"
I am an ErrorCode Object
"
Class {
	#name : 'TsfNexIOErrorDef',
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
TsfNexIOErrorDef class >> code: anInteger message: aString [
    ^ self new code: anInteger; message: aString; yourself.

]

{ #category : 'accessing' }
TsfNexIOErrorDef >> code [

	^ code
]

{ #category : 'accessing' }
TsfNexIOErrorDef >> code: anObject [

	code := anObject
]

{ #category : 'accessing' }
TsfNexIOErrorDef >> message [

	^ message
]

{ #category : 'accessing' }
TsfNexIOErrorDef >> message: anObject [

	message := anObject
]
