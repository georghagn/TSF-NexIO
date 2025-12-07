Class {
	#name : 'TsfNexIOAuthTestDelegate',
	#superclass : 'TsfNexIOBaseDelegate',
	#category : 'TSF-NexIO-App-Base-Tests',
	#package : 'TSF-NexIO-App-Base',
	#tag : 'Tests'
}

{ #category : 'subclassing' }
TsfNexIOAuthTestDelegate >> rpcMethodNotImplemented: methodName params: params session: aSession [
    "Minimal-Implementierung for Test"

    TsfNexIOError new
        code: TsfNexIOConstants methodNotFound;
        messageText: 'Not found';
        signal.
]
