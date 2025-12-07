Class {
	#name : 'TsfNexIOBaseDelegate',
	#superclass : 'Object',
	#instVars : [
		'sessionsMonitor'
	],
	#category : 'TSF-NexIO-App-Base-Core',
	#package : 'TSF-NexIO-App-Base',
	#tag : 'Core'
}

{ #category : 'initialization' }
TsfNexIOBaseDelegate >> initialize [

    super initialize.
    sessionsMonitor := Monitor new.
]

{ #category : 'hooks' }
TsfNexIOBaseDelegate >> onUserLoggedIn: username session: aSession [
    "Hook for subclasses - Standard: do nothing"

    ^ self
]

{ #category : 'rpc - methods' }
TsfNexIOBaseDelegate >> rpcAuthLogin: params session: aSession [
    "JSON-RPC: auth.login"
    | username |
    
    username := params at: 'username' ifAbsent: [ 
        TsfNexIOError new
            code: TsfNexIOConstants invalidParams;
            messageText: 'Missing parameter: username';
            signal.
    ].

    "Session Update"
    aSession user: username.
    aSession isAuthenticated: true.
    
    "Hook for subclassec (e.g. Globale User List)"
    sessionsMonitor critical: [ self onUserLoggedIn: username session: aSession ].
    
    ^ Dictionary new
        at: 'status' put: 'logged_in';
        at: 'user' put: username;
        yourself
]

{ #category : 'subclassing' }
TsfNexIOBaseDelegate >> rpcMethodNotImplemented: methodName params: params session: aSession [

    self subclassResponsibility
]

{ #category : 'rpc - methods' }
TsfNexIOBaseDelegate >> rpcSystemPing: params session: aSession [
    "JSON-RPC: system.ping"

    ^ 'pong'
]
