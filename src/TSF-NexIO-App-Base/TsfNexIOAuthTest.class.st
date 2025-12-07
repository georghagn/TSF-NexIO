Class {
	#name : 'TsfNexIOAuthTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'client',
		'port',
		'delegate'
	],
	#category : 'TSF-NexIO-App-Base-Tests',
	#package : 'TSF-NexIO-App-Base',
	#tag : 'Tests'
}

{ #category : 'running' }
TsfNexIOAuthTest >> setUp [

    super setUp.
    
    port := 40000 + 100 atRandom.
    delegate := TsfNexIOAuthTestDelegate new.
    server := TsfNexIOServer new.
    server delegate: delegate.
    server startOn: port.
    
    client := TsfNexIOClient new.
    client connectTo: 'ws://localhost:', port asString , '/ws'.
]

{ #category : 'running' }
TsfNexIOAuthTest >> tearDown [

    client ifNotNil: [ client close ].
    server ifNotNil: [ server stop ].

    super tearDown.
]

{ #category : 'tests' }
TsfNexIOAuthTest >> testAuthLogin [
    "Check login-flow and put session-attribute"
    | result params session |
    
    params := {'username' -> 'TsfUser'} asDictionary.
    
    "1. Send Login Request"
    result := client sendSynchronous: 'auth.login' params: params.
    
    "2. Check answer"
    self assert: (result at: 'status') equals: 'logged_in'.
    self assert: (result at: 'user') equals: 'TsfUser'.

    "3. Check server-states (session), we have only one"
    session := server sessions anyOne.
    self assert: session isAuthenticated.
    self assert: session user equals: 'TsfUser'
]

{ #category : 'tests' }
TsfNexIOAuthTest >> testSystemPing [
    "Checks subclassede system-method"
    | result |

    result := client sendSynchronous: 'system.ping' params: Dictionary new.
    self assert: result equals: 'pong'.
]
