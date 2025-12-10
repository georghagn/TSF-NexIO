"
Copyright 2025 Georg Hagn
SPDX-License-Identifier: Apache-2.0


"
Class {
	#name : 'TsfNexIOTestApp',
	#superclass : 'Object',
	#instVars : [
		'server',
		'lastReceivedSession'
	],
	#category : 'TSF-NexIO-Tests',
	#package : 'TSF-NexIO-Tests'
}

{ #category : 'accessing' }
TsfNexIOTestApp >> lastReceivedSession [

	^ lastReceivedSession
]

{ #category : 'rpc - methods' }
TsfNexIOTestApp >> rpcCrash: params session: session [

	Error signal: 'Boom'.

]

{ #category : 'rpc - methods' }
TsfNexIOTestApp >> rpcEcho: params session: session [

	lastReceivedSession := session. 
	^ params.
]

{ #category : 'rpc - methods' }
TsfNexIOTestApp >> rpcLogin: params session: session [

	session user: (params at: 'user').
	^ 'OK'.
	
]

{ #category : 'accessing' }
TsfNexIOTestApp >> server [

	^ server
]

{ #category : 'accessing' }
TsfNexIOTestApp >> server: anObject [

	server := anObject
]
