/// Tests the example activities on their own, without a production, and the
/// Run method the generated BPL code calls.
Class test.app.bplplus.activityTest Extends %UnitTest.TestCase
{

/// A matching value succeeds; a value that does not match is a negative result,
/// not an error.
Method TestValidateValue()
{
	Set tReq = ##class(app.bplplus.examples.validateValue).%New()
	Set tReq.Pattern = "[0-9]{4}[A-Z]{2}"
	Set tReq.Value = "1234AB"
	Do $$$AssertStatusOK(tReq.Execute("", .tResp))
	Do $$$AssertEquals(tResp.Success, 1)

	Set tReq.Value = "12AB"
	Set tReq.FailureText = "Not a postcode"
	Do $$$AssertStatusOK(tReq.Execute("", .tResp), "no match is not an error")
	Do $$$AssertEquals(tResp.Success, 0)
	Do $$$AssertEquals(tResp.ResultText, "Not a postcode")
}

/// An invalid regular expression fails the activity, naming the pattern.
Method TestValidateBadPattern()
{
	Set tReq = ##class(app.bplplus.examples.validateValue).%New()
	Set tReq.Pattern = "([a-z"
	Set tReq.Value = "x"
	Set tSC = tReq.Execute("", .tResp)
	Do $$$AssertStatusNotOK(tSC)
	Do $$$AssertTrue($System.Status.GetErrorText(tSC) [ "([a-z", "error names the pattern")
}

/// Send notification reports what it sent.
Method TestSendNotification()
{
	Set tReq = ##class(app.bplplus.examples.sendNotification).%New()
	Set tReq.Recipient = "ops@example.com"
	Set tReq.Subject = "Test"
	Do $$$AssertEquals(tReq.Priority, "normal", "initial value")
	Do $$$AssertStatusOK(tReq.Execute("", .tResp))
	Do $$$AssertEquals(tResp.Success, 1)
	Do $$$AssertTrue(tResp.ResultText [ "ops@example.com")
}

/// Run checks the parameters before the activity runs: a missing required one or
/// a value outside the value list fails it, naming the activity.
Method TestRunValidates()
{
	Set tAct = ##class(app.bplplus.examples.sendNotification).%New()
	Set tSC = tAct.Run("", .tResult)
	Do $$$AssertStatusNotOK(tSC, "Recipient is required")
	Do $$$AssertTrue($System.Status.GetErrorText(tSC) [ "Send notification", "error names the activity")
	Set tAct.Recipient = "ops@example.com"
	Set tAct.Priority = "urgent"
	Do $$$AssertStatusNotOK(tAct.Run("", .tResult), "Priority outside its value list")
	Set tAct.Priority = "high"
	Do $$$AssertStatusOK(tAct.Run("", .tResult))
	Do $$$AssertTrue($IsObject(tResult), "result returned")
}

/// Handle error, not returning the error: logs it and succeeds, with the
/// prefix in front of the error text.
Method TestHandleErrorAsWarning()
{
	Set tReq = ##class(app.bplplus.examples.handleError).%New()
	Set tReq.ErrorStatus = $$$ERROR($$$GeneralError, "Order 42 not found")
	Set tReq.ErrorPrefix = "Order import"
	Do $$$AssertEquals(tReq.ReturnAsError, 0, "logs by default")
	Do $$$AssertStatusOK(tReq.Execute("", .tResp))
	Do $$$AssertEquals(tResp.Success, 1)
	Do $$$AssertTrue(tResp.ResultText [ "Order import: ", "prefix")
	Do $$$AssertTrue(tResp.ResultText [ "Order 42 not found", "error text")
}

/// Handle error, returning the error: fails with the prefixed error and keeps
/// the original one inside it.
Method TestHandleErrorReturned()
{
	Set tReq = ##class(app.bplplus.examples.handleError).%New()
	Set tReq.ErrorStatus = $$$ERROR($$$GeneralError, "Order 42 not found")
	Set tReq.ErrorPrefix = "Order import"
	Set tReq.ReturnAsError = 1
	Set tSC = tReq.Execute("", .tResp)
	Do $$$AssertStatusNotOK(tSC)
	Set tText = $System.Status.GetErrorText(tSC)
	Do $$$AssertTrue(tText [ "Order import: ", "prefix")
	Do $$$AssertTrue(tText [ "Order 42 not found", "original error")
}

/// Handle error with no error (OK or empty status) does nothing, either way.
Method TestHandleErrorNothingToHandle()
{
	Set tReq = ##class(app.bplplus.examples.handleError).%New()
	Set tReq.ReturnAsError = 1
	Do $$$AssertStatusOK(tReq.Execute("", .tResp), "empty status")
	Set tReq.ErrorStatus = $$$OK
	Do $$$AssertStatusOK(tReq.Execute("", .tResp), "OK status")
	Do $$$AssertEquals(tResp.ResultText, "No error to handle")
}

/// Run passes the activity's result on, of the activity's result class.
Method TestRunGuards()
{
	Set tAct = ##class(app.bplplus.examples.validateValue).%New()
	Set tAct.Pattern = "a+"
	Set tAct.Value = "aaa"
	Do $$$AssertStatusOK(tAct.Run("", .tResult))
	Do $$$AssertEquals(tResult.Success, 1)
	Do $$$AssertEquals($ClassName(tResult), "app.bplplus.activityResult")
}

}
