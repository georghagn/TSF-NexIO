"
Copyright 2025 Georg Hagn
SPDX-License-Identifier: Apache-2.0


I am a aubclass from Error and I process TsfNexIO errorss
"
Class {
	#name : 'TsfNexIOError',
	#superclass : 'Error',
	#instVars : [
		'code',
		'data'
	],
	#category : 'TSF-NexIO-Core',
	#package : 'TSF-NexIO',
	#tag : 'Core'
}

{ #category : 'accessing' }
TsfNexIOError >> code [

	^code
]

{ #category : 'accessing' }
TsfNexIOError >> code: anInteger [

	code := anInteger
]

{ #category : 'accessing' }
TsfNexIOError >> data: anObject [

	data := anObject
]

{ #category : 'accessing' }
TsfNexIOError >> messageText [

    ^ 'NexIO Error [', code asString, ']: ', super messageText.
]
