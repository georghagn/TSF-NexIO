Class {
	#name : 'BaselineOfTsfNexIO',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfTsfNexIO',
	#package : 'BaselineOfTsfNexIO'
}

{ #category : 'baselines' }
BaselineOfTsfNexIO >> baseline: spec [
    <baseline>

	spec for: #common do: [
		self defineDependencies: spec.
		self definePackages: spec.
		self defineGroups: spec 
	].
]

{ #category : 'baselines - dependencies' }
BaselineOfTsfNexIO >> defineDependencies: spec [ 

	spec baseline: 'ZincHTTPComponents' with: [ 
		spec 
			repository: 'github://svenvc/zinc/repository';
			"WICHTIG: Wir laden explizit NUR die WebSocket Gruppe.
			 Metacello versucht dann oft, den Core in Ruhe zu lassen,
			 wenn er schon da ist."
			loads: #('WebSocket') 
		].
            
       "Abhängigkeit zu NeoJSON"
	spec baseline: 'NeoJSON'
		with: [ spec repository: 'github://svenvc/NeoJSON/repository' ].

]

{ #category : 'baseline - groups' }
BaselineOfTsfNexIO >> defineGroups: spec [

	spec 
		group: 'core' with: #('TSF-NexIO');
		group: 'tests' with: #('TSF-NexIOr-Tests');
		group: 'default' with: #('core' 'tests').
		
]

{ #category : 'baseline - packages' }
BaselineOfTsfNexIO >> definePackages: spec [

	spec 
		package: 'TSF-NexIO';
		package: 'TSF-NexIO-Tests' with: [ spec requires: #('TSF-NexIO') ].

]
