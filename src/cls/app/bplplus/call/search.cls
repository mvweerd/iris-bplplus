/// The search behind the magnifier of Call process's Target, in the form of the
/// Management Portal's context searches (see Ens.ContextSearch).
Class app.bplplus.call.search Extends %ZEN.Portal.ContextSearch
{

/// The BPL processes of the namespace that Call process can run: of the ones
/// Ens.ContextSearch:SubclassOf lists, those app.bplplus.call.callProcess:CanBeCalled
/// accepts. Other processes are left out, as picking one would only fail.
ClassMethod Processes(Output pCaption As %String, Output pTopResults, Output pResults, ByRef pParms As %String, pSearchKey As %String = "") As %Status
{
	Set pCaption = "BPL processes that Call process can run"
	Kill pTopResults, pResults
	Set tParms("class") = "Ens.BusinessProcessBPL"
	Set tSC = ##class(Ens.ContextSearch).SubclassOf(.tCaption, .tTop, .tAll, .tParms, pSearchKey)
	If $$$ISERR(tSC) Quit tSC
	Set tKey = "", tCount = 0
	For {
		Set tKey = $Order(tAll(tKey), 1, tClass)
		Quit:tKey=""
		If ##class(app.bplplus.call.callProcess).CanBeCalled(tClass) Set tCount = tCount + 1, pResults(tCount) = tClass
	}
	Quit $$$OK
}

}
