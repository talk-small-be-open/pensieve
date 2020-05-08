Class {
	#name : #PENNeoConsoleWebSocketServer,
	#superclass : #Object,
	#instVars : [
		'port',
		'process',
		'serverSocket'
	],
	#category : #'Pensieve-Core'
}

{ #category : #public }
PENNeoConsoleWebSocketServer class >> startOn: port [
	"self startOn: 4999"
	
	^ self new
		port: port;
		start
]

{ #category : #'as yet unclassified' }
PENNeoConsoleWebSocketServer >> handleWebSocket: aWebSocket [
	
	[
		| commandLine |
		commandLine := ''.

		aWebSocket runWith: [ :message |
			aWebSocket logGeneric: 'Received message: ', message printString, ', echoing'.

			(message = String cr)
				ifFalse: [ commandLine := commandLine, message ]
				ifTrue: [
					| command |
					aWebSocket logGeneric: 'Got CR. Command is: ', commandLine.

					command := self readInputFrom: commandLine.
					commandLine := ''.
					[
					command execute.
					self writeOutput: command result to: aWebSocket.
					self writePromptTo: aWebSocket.
					]
						on: Error do: [ :exception |
							self writeOutput: command printString, ' failed with ', exception printString to: aWebSocket ].

				].
		
"			aWebSocket sendMessage: ('Neo Console ', SystemVersion current asString)."
		] ] 
		on: ConnectionClosed 
		do: [ aWebSocket logGeneric: 'Ignoring connection close, done' ]
]

{ #category : #private }
PENNeoConsoleWebSocketServer >> initializeServerSocket [

	ZnServer stopDefault.
	ZnServer startDefaultOn: port.
	ZnServer default logToTranscript.
	ZnServer default
	   delegate: (
	      ZnWebSocketDelegate
	         handler: [:webSocket | self handleWebSocket: webSocket ]).
]

{ #category : #testing }
PENNeoConsoleWebSocketServer >> isRunning [
	"Return true when I am running"
	
	^ process notNil and: [ serverSocket notNil ]
]

{ #category : #accessing }
PENNeoConsoleWebSocketServer >> port [
	^ port ifNil: [ port := 4999 ]
]

{ #category : #accessing }
PENNeoConsoleWebSocketServer >> port: integer [
	port := integer
]

{ #category : #printing }
PENNeoConsoleWebSocketServer >> printOn: stream [
	super printOn: stream.
	stream << $(.
	self isRunning ifTrue: [ stream << #running; space; print: self port ].
	stream << $)
]

{ #category : #protocol }
PENNeoConsoleWebSocketServer >> readInputFrom: line [
	| commandClass |
	line isEmptyOrNil ifTrue: [ ^ NeoConsoleQuitCommand new ].
	commandClass := NeoConsoleCommand forLine: line.
	commandClass isSingleLine
		ifTrue: [ ^ commandClass new on: line; yourself ]
		ifFalse: [ ^ NeoConsoleQuitCommand new ]
]

{ #category : #protocol }
PENNeoConsoleWebSocketServer >> serveConnectionsOn: listeningSocket [
	"We wait up to acceptWaitTimeout seconds for an incoming connection.
	If we get one we wrap it in a SocketStream and #executeRequestResponseLoopOn: on it"
		 
	| stream socket |
	socket := listeningSocket waitForAcceptFor: 300.
	socket ifNil: [ ^ self ].
	stream := self socketStreamOn: socket.
	[ [ [ self executeRequestResponseLoopOn: stream ]
		ensure: [ [ stream close ] on: Exception do: [ ] ] ]
			ifCurtailed: [ socket destroy ] ]
				forkAt: Processor lowIOPriority
				named: self workerProcessName 
]

{ #category : #accessing }
PENNeoConsoleWebSocketServer >> serverProcessName [
	^ self class name asString , ' port ' , self port asString
]

{ #category : #public }
PENNeoConsoleWebSocketServer >> start [
"	self stop."

	self initializeServerSocket
]

{ #category : #public }
PENNeoConsoleWebSocketServer >> stop [
	self isRunning ifFalse: [ ^ self ].
	process terminate. 
	process := nil.

]

{ #category : #accessing }
PENNeoConsoleWebSocketServer >> timeout [
	^ 60
]

{ #category : #accessing }
PENNeoConsoleWebSocketServer >> workerProcessName [
	^ self serverProcessName, ' Connection Handler'
]

{ #category : #protocol }
PENNeoConsoleWebSocketServer >> writeLine: aString to: aWebSocket [
	aWebSocket sendMessage: (aString, String crlf)
]

{ #category : #protocol }
PENNeoConsoleWebSocketServer >> writeOutput: aString to: aWebSocket [
	aString lines
		do: [ :each |
			self writeLine: each to: aWebSocket ]
]

{ #category : #protocol }
PENNeoConsoleWebSocketServer >> writePromptTo: aWebSocket [
	aWebSocket sendMessage: '> '
]
