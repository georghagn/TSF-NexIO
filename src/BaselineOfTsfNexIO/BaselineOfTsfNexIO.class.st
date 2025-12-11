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

		"Abhängigkeit zu Zinc"
		spec baseline: 'ZincHTTPComponents' with: [ 
			spec 
				repository: 'github://svenvc/zinc/repository';
				"WICHTIG: Wir laden explizit NUR die WebSocket Gruppe.
				 Metacello versucht dann oft, den Core in Ruhe zu lassen,
				 wenn er schon da ist."
				loads: #('WebSocket') 
		].
            
		"Abhängigkeit zu NeoJSON"
		spec baseline: 'NeoJSON' with: [ spec repository: 'github://svenvc/NeoJSON/repository'	 ].

		"Packages"
		spec 
			package: 'TSF-NexIO';
			package: 'TSF-NexIO-Tests' with: [ spec requires: #('TSF-NexIO') ];
			package: 'TSF-NexIO-App-Base'.
		
		"Groups "
		spec 
			group: 'core' with: #('TSF-NexIO');
			group: 'tests' with: #('TSF-NexIO-Tests');
			group: 'delegate' with: #('TSF-NexIO-App-Base');
			group: 'default' with: #('core' 'tests' 'delegate').
		
	].


]
