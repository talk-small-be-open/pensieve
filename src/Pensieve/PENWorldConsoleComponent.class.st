Class {
	#name : #PENWorldConsoleComponent,
	#superclass : #PENComponent,
	#category : #'Pensieve-View'
}

{ #category : #'as yet unclassified' }
PENWorldConsoleComponent class >> registerAsApplication [
	| app  |

	app := WAAdmin 
		register: self
		asApplicationAt: 'pen'.

	app configuration addParent: WAEmailConfiguration instance.
	
	app
		"exceptionHandler: PPLFrontendErrorHandler;"
		preferenceAt: #sessionClass put: PENSession;
"		preferenceAt: #trackingStrategy put: WACookieIfSupportedSessionTrackingStrategy new;"
		preferenceAt: #scriptGeneratorClass put: JQScriptGenerator.
"		preferenceAt: #documentClass put: VIAHtmlDocument;"
		

		"Für REST"
"		addFilterFirst: PPLRestfulFilter new."

"	app
		preferenceAt: #smtpServer put: configuration smtpServer;
		preferenceAt: #smtpUsername put: configuration smtpUsername;
		preferenceAt: #smtpPassword put: configuration smtpPassword.
"		
	 (GRPlatform current label = 'Pharo')
		ifTrue: [
			app exceptionHandler: WADebugErrorHandler].

"	app cache expiryPolicy configuration at: #cacheTimeout put: (60 * 60 * 1)."

	^ app
]

{ #category : #rendering }
PENWorldConsoleComponent >> renderContentOn: html [
	html paragraph: 'hi'.
	
	html div id: 'terminal'.
	html script: '
var term = new Terminal();
term.open(document.getElementById("terminal"));
term.write("Hello from \x1B[1;3;31mxterm.js\x1B[0m $ ");

var webSocket = new WebSocket("ws://localhost:4199");
var attachAddon = new AttachAddon.AttachAddon(webSocket);
term.loadAddon(attachAddon);

term.prompt = () => {
	term.write("\r\n > ");
};

term.writeln("Welcome to Pharo NeoConsole via WebSockets!");
//term.prompt();

term.onKey(function(e){
	var ev = e.domEvent;
	var printable = !ev.altKey && !ev.ctrlKey && !ev.metaKey;

	if (ev.keyCode === 13) {
		term.write("\r\n");
	} else if (ev.keyCode === 8) {
		// Do not delete the prompt
		if (term._core.buffer.x > 2) {
			term.write("\b \b");
		}
	} else if (printable) {
		term.write(e.key);
	}
})
'
]

{ #category : #updating }
PENWorldConsoleComponent >> updateRoot: anHtmlRoot [
	super updateRoot: anHtmlRoot.
	
	anHtmlRoot stylesheet url: '/lib/node_modules/xterm/css/xterm.css'.
	anHtmlRoot javascript url: '/lib/node_modules/xterm/lib/xterm.js'.
	anHtmlRoot javascript url: '/lib/node_modules/xterm-addon-attach/lib/xterm-addon-attach.js'.

]
