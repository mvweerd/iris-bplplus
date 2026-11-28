Include Ensemble

/// Runs another BPL process, in this process, with Aux as its request, the way a
/// transform gives a DTL its aux: by reference. The process called reads
/// and writes request.Property, and so the object of this process itself, such
/// as its context; what it writes is there as soon as it is done.
/// When it has a response, that comes back as the result Response.
/// <p>
/// The process called is an ordinary BPL process of your own, and Aux is of its
/// request class: an object of this process, such as a serial class that holds
/// what it works on or %Library.RegisteredObject for any object, or a message
/// such as an Ens.Request or an EnsLib.HTTP.GenericMessage. Nothing is sent or
/// stored. It does not have to be an item of the production, and it cannot wait
/// for anything: a &lt;call&gt;, &lt;delay&gt; or &lt;receive&gt; in it fails
/// this activity. The magnifier next to Target lists the BPL processes that can
/// be called.
Class app.bplplus.call.callProcess Extends app.bplplus.activity
{

Parameter ACTIVITYCAPTION = "Call process";

Parameter ACTIVITYCOLOR = "#E3F2FD";

Parameter ACTIVITYRESULT = "app.bplplus.call.callProcessResult";

/// Aux is the whole context, unless you give the process called less.
XData ActivityDefaults [ MimeType = application/json ]
{
{ "Aux": "context" }
}

/// The BPL process to run, as its class name, such as "my.bp.cleanContact".
/// It does not have to be in the production.
Property Target As app.bplplus.lookup(CONTEXT = "app.bplplus.call.search/Processes") [ Required ];

/// What the process called gets as its request, by reference: context, a
/// part of it such as context.contact, or a message such as request.
Property Aux As %RegisteredObject [ Required ];

/// Runs Target with Aux as its request, in this job.
Method Execute(pProcess As Ens.BusinessProcess, Output pResult As app.bplplus.activityResult) As %Status
{
	Set pResult = ##class(app.bplplus.call.callProcessResult).%New()
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
	Set pResult.Response = $Get(tResponse)
	Set pResult.ResultText = "Ran "_..Target
	Quit $$$OK
}

/// Packages of IRIS itself: their processes are not offered.
Parameter SYSTEMPACKAGES = "%,Ens.,EnsLib.,EnsPortal.,HS.,HSMOD.,HSFHIR.,ISC.,CSPX.";

/// 1 when Call process can run <var>pClass</var>: a compiled BPL process of
/// your own (not of IRIS) that has a request class; otherwise 0, with why not
/// in <var>pReason</var>.
ClassMethod CanBeCalled(pClass As %String, Output pReason As %String) As %Boolean
{
	Set pReason = ""
	If (pClass = "") || '##class(%Dictionary.CompiledClass).%ExistsId(pClass) {
		Set pReason = "there is no compiled class "_pClass
		Quit 0
	}
	For i = 1:1:$Length(..#SYSTEMPACKAGES, ",") {
		Set tPackage = $Piece(..#SYSTEMPACKAGES, ",", i)
		If $Extract(pClass, 1, $Length(tPackage)) = tPackage {
			Set pReason = pClass_" is a process of IRIS itself"
			Quit
		}
	}
	If pReason '= "" Quit 0
	If '$ClassMethod(pClass, "%Extends", "Ens.BusinessProcessBPL") {
		Set pReason = pClass_" is not a BPL process"
		Quit 0
	}
	Set tRequest = $ListGet($ClassMethod(pClass, "GetRequestClassList"))
	If (tRequest = "") || '##class(%Dictionary.CompiledClass).%ExistsId(tRequest) {
		Set pReason = "it has no request class"
		Quit 0
	}
	Quit 1
}

}
