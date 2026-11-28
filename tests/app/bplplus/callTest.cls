/// Tests Call process (app.bplplus.call) without a production: which processes
/// can be called, the search behind the magnifier, and the errors outside a
/// process. The call itself is tested in test.app.bplplus.demo.productionTest.
Class test.app.bplplus.callTest Extends %UnitTest.TestCase
{

/// The demo callee and the example cleanContact can be called; a process that
/// takes messages, or a class that is not a process, cannot, and the reason
/// says why.
Method TestCanBeCalled()
{
	Do $$$AssertTrue(##class(app.bplplus.call.callProcess).CanBeCalled("test.app.bplplus.demo.callee", .tReason), tReason)
	Do $$$AssertTrue(##class(app.bplplus.call.callProcess).CanBeCalled("app.bplplus.examples.cleanContact", .tReason), tReason)
	Do $$$AssertTrue(##class(app.bplplus.call.callProcess).CanBeCalled("app.bplplus.examples.signLetter", .tReason), tReason)
	Do $$$AssertNotTrue(##class(app.bplplus.call.callProcess).CanBeCalled("test.app.bplplus.demo.validateValue", .tReason))
	Do $$$AssertTrue(tReason [ "a message", tReason)
	Do $$$AssertNotTrue(##class(app.bplplus.call.callProcess).CanBeCalled("test.app.bplplus.demo.response", .tReason))
	Do $$$AssertTrue(tReason [ "not a BPL process", tReason)
	Do $$$AssertNotTrue(##class(app.bplplus.call.callProcess).CanBeCalled("No.Such.Class", .tReason))
}

/// The search behind the magnifier lists only the BPL processes that can be
/// called: the callee and cleanContact, not the other demo processes or those of
/// IRIS.
Method TestSearch()
{
	Do $$$AssertStatusOK(##class(app.bplplus.call.search).Processes(.tCaption, .tTop, .tResults, , ""))
	Set tKey = "" For { Set tKey = $Order(tResults(tKey), 1, tValue) Quit:tKey=""  Set tAll(tValue) = "" }
	Do $$$AssertTrue($Data(tAll("test.app.bplplus.demo.callee")), "the callee is listed")
	Do $$$AssertTrue($Data(tAll("app.bplplus.examples.cleanContact")), "the example is listed")
	Do $$$AssertTrue($Data(tAll("app.bplplus.examples.signLetter")), "so is the one that takes a stream")
	Do $$$AssertNotTrue($Data(tAll("test.app.bplplus.demo.validateValue")), "a process that takes messages is not")
	Do $$$AssertNotTrue($Data(tAll("EnsLib.Printing.Dispatcher")), "nor one of IRIS")
}

/// Outside a business process, or without Target or Aux, Call process fails
/// with a clear error rather than breaking.
Method TestErrors()
{
	Set tAct = ##class(app.bplplus.call.callProcess).%New()
	Set tAct.Target = "test.app.bplplus.demo.callee"
	Set tAct.Aux = ##class(%ArrayOfDataTypes).%New()
	Set tSC = tAct.Run("", .tResult)
	Do $$$AssertStatusNotOK(tSC)
	Do $$$AssertTrue($System.Status.GetErrorText(tSC) [ "business process", $System.Status.GetErrorText(tSC))
	Do $$$AssertStatusNotOK(##class(app.bplplus.call.callProcess).%New().Run("", .tResult), "Target and Aux are required")
}

}
