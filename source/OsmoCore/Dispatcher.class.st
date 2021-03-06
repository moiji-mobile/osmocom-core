"
I run tasks from the same context.
"
Class {
	#name : #Dispatcher,
	#superclass : #Object,
	#instVars : [
		'queue',
		'dispatch',
		'quit'
	],
	#category : #'OsmoCore-Core'
}

{ #category : #'as yet unclassified' }
Dispatcher class >> initialize [
	self instance

]

{ #category : #singleton }
Dispatcher class >> install [
	| dispatcher |
	dispatcher := Smalltalk at: #OsmoDispatcher ifAbsentPut: [self new].
	^dispatcher class = self 
	    ifTrue: [dispatcher]
	    ifFalse: 
		[dispatcher terminate.
		Smalltalk at: #OsmoDispatcher put: self new]

]

{ #category : #singleton }
Dispatcher class >> instance [
	^Smalltalk at: #OsmoDispatcher ifAbsent: [self install]

]

{ #category : #private }
Dispatcher class >> new [
	^(super new)
	    addToBeFinalized;
	    startDispatching;
	    yourself

]

{ #category : #'as yet unclassified' }
Dispatcher >> dispatch [
	| block sem |
	block := queue next.
	sem := Semaphore new.

	"Run the code in a new process as the debugger might terminate this
	 and then the dispatcher would not dispatch anymore. Use a Semaphore
	 to make sure we keep on processing items in order."
	
	[
		[
			ModuleBoundary runSynchronous: block
		]  ensure: [sem signal]
	] fork.
	sem wait
]

{ #category : #insert }
Dispatcher >> dispatchBlock: aBlock [
	queue nextPut: aBlock

]

{ #category : #'as yet unclassified' }
Dispatcher >> initialize [
	super initialize.
]

{ #category : #'as yet unclassified' }
Dispatcher >> pendingBlocks [
	^queue size
]

{ #category : #'as yet unclassified' }
Dispatcher >> quit [
	queue nextPut: [].
	quit := true.
]

{ #category : #private }
Dispatcher >> startDispatching [
	quit := false.
	queue := SharedQueue new.
	dispatch := 
		[Processor activeProcess name: 'OsmoDispatcher'.
		[quit] whileFalse: [self dispatch]] 
			forkAt: Processor highIOPriority

]

{ #category : #private }
Dispatcher >> terminate [
	dispatch terminate

]
