Include Ensemble

/// Runs another BPL process, in this process, with Aux as its request, the way a
/// transform gives a DTL its aux: by reference. The process called reads
/// and writes request.Property, and so the object of this process itself, such
/// as its context; what it writes is there as soon as it is done.
/// <p>
/// The process called is an ordinary BPL process whose request class is not a
/// message (not persistent): the class of Aux, such as a serial class that holds
/// what it works on, or %Library.RegisteredObject for any object. It is not an item of the
/// production, and it cannot wait for anything: a &lt;call&gt;, &lt;delay&gt; or
/// &lt;receive&gt; in it fails this activity. The magnifier next to Target lists
/// the BPL processes that can be called.
Class app.bplplus.call.callProcess Extends app.bplplus.activity
{

Parameter ACTIVITYCAPTION = "Call process";

Parameter ACTIVITYCOLOR = "#E3F2FD";

/// Aux is the whole context, unless you give the process called less.
XData ActivityDefaults [ MimeType = application/json ]
{
{ "Aux": "context" }
}

/// The BPL process to run, as its class name, such as "my.bp.cleanContact".
/// It does not have to be in the production.
Property Target As app.bplplus.lookup(CONTEXT = "app.bplplus.call.search/Processes") [ Required ];

/// What the process called gets as its request, by reference: context, or a
/// part of it such as context.contact.
Property Aux As %RegisteredObject [ Required ];

/// Runs Target with Aux as its request, in this job.
Method Execute(pProcess As Ens.BusinessProcess, Output pResult As app.bplplus.activityResult) As %Status
{
	Set pResult = ##class(app.bplplus.activityResult).%New()
	If '$IsObject($Get(pProcess)) || 'pProcess.%IsA("Ens.BusinessProcess") {
		Quit $$$ERROR($$$GeneralError, "Call process only runs in a business process")
	}
	If '..CanBeCalled(..Target, .tReason) Quit $$$ERROR($$$GeneralError, ..Target_" cannot be called: "_tReason)
	Set tExpected = $ListGet($ClassMethod(..Target, "GetRequestClassList"))
	If (tExpected '= "") && '..Aux.%Extends(tExpected) {
		Quit $$$ERROR($$$GeneralError, ..Target_" takes a "_tExpected_" as its request, and Aux is a "_$ClassName(..Aux))
	}

	// The BPL engine as the production runs it. A process object needs the name
	// of a running item for its settings: this process's.
	Set tCallee = $ClassMethod(..Target, "%New", pProcess.%ConfigName)
	If '$IsObject(tCallee) Quit $$$ADDSC($$$ERROR($$$GeneralError, ..Target_" could not be started"), $Get(%objlasterror, $$$OK))
	Set tSC = tCallee.OnRequest(..Aux, .tResponse)
	If $$$ISERR(tSC) Quit $$$ADDSC($$$ERROR($$$GeneralError, ..Target_" failed"), tSC)
	If tCallee.%Thread.%Status '= $$$eRunStatusCompleted {
		Quit $$$ERROR($$$GeneralError, ..Target_" stopped to wait (for a call, a delay or a message). A process that Call process runs has to run straight through")
	}
	Set pResult.ResultText = "Ran "_..Target
	Quit $$$OK
}

/// 1 when Call process can run <var>pClass</var>: a compiled BPL process whose
/// request class is not persistent, so not a message (it is meant to get an
/// object of a process, not a message from the production); otherwise 0, with
/// why not in <var>pReason</var>.
ClassMethod CanBeCalled(pClass As %String, Output pReason As %String) As %Boolean
{
	Set pReason = ""
	If (pClass = "") || '##class(%Dictionary.CompiledClass).%ExistsId(pClass) {
		Set pReason = "there is no compiled class "_pClass
		Quit 0
	}
	If '$ClassMethod(pClass, "%Extends", "Ens.BusinessProcessBPL") {
		Set pReason = pClass_" is not a BPL process"
		Quit 0
	}
	Set tRequest = $ListGet($ClassMethod(pClass, "GetRequestClassList"))
	If (tRequest = "") || '##class(%Dictionary.CompiledClass).%ExistsId(tRequest) {
		Set pReason = "it has no request class"
		Quit 0
	}
	If $ClassMethod(tRequest, "%Extends", "%Library.Persistent") {
		Set pReason = "its request class "_tRequest_" is persistent, so a message: it takes messages from the production"
		Quit 0
	}
	Quit 1
}

}
