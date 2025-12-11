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

		"Zinc (nur WebSocket nachladen)"
		spec baseline: 'ZincHTTPComponents' with: [
			spec repository: 'github://svenvc/zinc/repository' ].

		"NeoJSON"
		spec baseline: 'NeoJSON' with: [
			spec repository: 'github://svenvc/NeoJSON/repository' ].


		"Eigene Packages"
		spec package: 'TSF-NexIO' with: [
			spec requires: #('NeoJSON' 'ZincHTTPComponents') ].

		spec package: 'TSF-NexIO-Tests' with: [
			spec requires: #('TSF-NexIO') ].

		spec package: 'TSF-NexIO-App-Base' with: [
			spec requires: #('TSF-NexIO') ].

		"Gruppen eigene Pakete"
		spec group: 'core'     with: #('TSF-NexIO').
		spec group: 'tests'    with: #('TSF-NexIO-Tests').
		spec group: 'delegate' with: #('TSF-NexIO-App-Base').

		"Diese Gruppe lädt NUR WebSocket aus Zinc"
		spec group: 'websocket' with: #('WebSocket').

		"Standardgruppe → lädt alles + WebSocket"
		spec group: 'default'
			with: #('core' 'tests' 'delegate' 'websocket').

	].

]
