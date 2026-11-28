/// Runs the demo production end to end: a registration goes through the demo
/// process, whose custom activities run inside it. It starts test.app.bplplus.demo.production and stops it again, so
/// run it in a namespace where no other production is running.
Class test.app.bplplus.demo.productionTest Extends %UnitTest.TestCase
{

/// Whether this test started the production, and so has to stop it again.
Property StartedHere As %Boolean [ InitialExpression = 0 ];

Method OnBeforeAllTests() As %Status
{
	Set tSC = ##class(Ens.Director).GetProductionStatus(.tName, .tState)
	// Troubled (4): it was running when the instance went down. Clean it up
	// first, as it neither runs nor starts in that state.
	If tState = 4 {
		Set tSC = ##class(Ens.Director).RecoverProduction()
		If $$$ISERR(tSC) Quit tSC
		Set tSC = ##class(Ens.Director).GetProductionStatus(.tName, .tState)
	}
	If tState = 1 {
		If tName '= "test.app.bplplus.demo.production" {
			Quit $$$ERROR($$$GeneralError, "Production "_tName_" is running in this namespace. Stop it, or run this test in another namespace.")
		}
		// Already running: bring it up to date, so items added since it started
		// run too.
		Quit ##class(Ens.Director).UpdateProduction()
	}
	Set tSC = ##class(Ens.Director).StartProduction("test.app.bplplus.demo.production")
	If $$$ISOK(tSC) Set ..StartedHere = 1
	Quit tSC
}

Method OnAfterAllTests() As %Status
{
	If ..StartedHere Quit ##class(Ens.Director).StopProduction(10, 1)
	Quit $$$OK
}

/// A valid address passes validation and is confirmed.
Method TestValidRegistration()
{
	Set tReq = ##class(test.app.bplplus.demo.registrationRequest).%New()
	Set tReq.Email = "jan@example.com"
	Set tReq.Name = "Jan"
	Set tSC = ##class(EnsLib.Testing.Service).SendTestRequest("Demo registration", tReq, .tResp, .tSession, 1)
	Do $$$AssertStatusOK(tSC)
	Do $$$AssertEquals(tResp.Success, 1)
	Do $$$AssertTrue(tResp.ResultText [ "jan@example.com", "reply carries the notification result")
	Do $$$AssertEquals(..CountNotifications(tSession), 1, "the notification was sent")
}

/// An invalid address is rejected without a notification.
Method TestInvalidRegistration()
{
	Set tReq = ##class(test.app.bplplus.demo.registrationRequest).%New()
	Set tReq.Email = "not-an-address"
	Set tSC = ##class(EnsLib.Testing.Service).SendTestRequest("Demo registration", tReq, .tResp, .tSession, 1)
	Do $$$AssertStatusOK(tSC)
	Do $$$AssertEquals(tResp.Success, 0)
	Do $$$AssertEquals(tResp.ResultText, "Not an e-mail address")
	Do $$$AssertEquals(..CountNotifications(tSession), 0, "no notification for a rejected registration")
}

/// A notification that fails (a priority outside its value list) is caught by
/// the catchall, logged as a warning by Handle error, and the registration still
/// succeeds.
Method TestFailedNotificationHandled()
{
	Set tReq = ##class(test.app.bplplus.demo.registrationRequest).%New()
	Set tReq.Email = "jan@example.com"
	Set tReq.Name = "Jan"
	Set tReq.Priority = "urgent"
	Set tSC = ##class(EnsLib.Testing.Service).SendTestRequest("Demo registration", tReq, .tResp, .tSession, 1)
	Do $$$AssertStatusOK(tSC, "the process does not fail")
	Do $$$AssertTrue(tResp.ResultText [ "Logged as warning: Notification", "reply comes from Handle error: "_tResp.ResultText)
}

/// Sends <var>pText</var> to demo process <var>pTarget</var> and returns the reply.
Method SendText(pTarget As %String, pText As %String, Output pResponse, Output pSession) As %Status
{
	Set tReq = ##class(test.app.bplplus.demo.textRequest).%New()
	Set tReq.Text = pText
	Quit ##class(EnsLib.Testing.Service).SendTestRequest(pTarget, tReq, .pResponse, .pSession, 1)
}

/// Demo Send notification: high priority is sent.
Method TestDemoSendNotification()
{
	Set tReq = ##class(test.app.bplplus.demo.registrationRequest).%New()
	Set tReq.Email = "piet@example.com", tReq.Name = "Piet", tReq.Priority = "high"
	Do $$$AssertStatusOK(##class(EnsLib.Testing.Service).SendTestRequest("Demo Send notification", tReq, .tResp, .tSession, 1))
	Do $$$AssertTrue(tResp.ResultText [ "(high)", "reply: "_tResp.ResultText)
	Do $$$AssertEquals(..CountNotifications(tSession), 1)
}

/// Demo Validate value: a postcode passes, other text is a negative outcome.
Method TestDemoValidateValue()
{
	Do $$$AssertStatusOK(..SendText("Demo Validate value", "1234 AB", .tResp))
	Do $$$AssertEquals(tResp.Success, 1)
	Do $$$AssertStatusOK(..SendText("Demo Validate value", "Kerkstraat 1", .tResp))
	Do $$$AssertEquals(tResp.Success, 0)
	Do $$$AssertEquals(tResp.ResultText, "Not a Dutch postcode")
}

/// Demo Handle error: a broken expression is caught and replied, not thrown.
Method TestDemoHandleError()
{
	Do $$$AssertStatusOK(..SendText("Demo Handle error", "[0-9]{4}[A-Z]{2}", .tResp), "a good expression")
	Do $$$AssertEquals(tResp.Success, 1)
	Do $$$AssertStatusOK(..SendText("Demo Handle error", "([a-z", .tResp), "a broken expression does not fail the process")
	Do $$$AssertEquals(tResp.Success, 0)
	Do $$$AssertTrue(tResp.ResultText [ "Demo Handle error", "reply: "_tResp.ResultText)
}

/// Demo Check response: OK passes, another message is reported.
Method TestDemoCheckResponse()
{
	Set tAnswer = "<s:Envelope xmlns:s=""http://schemas.xmlsoap.org/soap/envelope/""><s:Body><r:Answer xmlns:r=""urn:demo""><r:Result><r:Message>%1</r:Message></r:Result></r:Answer></s:Body></s:Envelope>"
	Do $$$AssertStatusOK(..SendText("Demo Check response", $Replace(tAnswer, "%1", "OK"), .tResp))
	Do $$$AssertEquals(tResp.Success, 1)
	Do $$$AssertStatusOK(..SendText("Demo Check response", $Replace(tAnswer, "%1", "Unknown article"), .tResp))
	Do $$$AssertEquals(tResp.Success, 0)
	Do $$$AssertTrue(tResp.ResultText [ "Unknown article", "reply: "_tResp.ResultText)
}

/// Demo Build SQL insert: two rows become two statements; a missing field fails.
Method TestDemoBuildSqlInsert()
{
	Set tRows = "<rows><row><ID>1</ID><Name>O'Brien</Name><Amount>12.50</Amount><Remark/></row><row><ID>2</ID><Name>Jansen</Name><Amount>7</Amount><Remark>ok</Remark></row></rows>"
	Do $$$AssertStatusOK(..SendText("Demo Build SQL insert", tRows, .tResp))
	Do $$$AssertEquals($Length(tResp.ResultText, $Char(13, 10)), 2, "two statements")
	Do $$$AssertTrue(tResp.ResultText [ "'O''Brien'", "quotes doubled")
	Do $$$AssertStatusNotOK(..SendText("Demo Build SQL insert", $Replace(tRows, "<Amount>7</Amount>", ""), .tResp), "row 2 without Amount fails")
}

/// Demo Fuzzy match: a typed supplier name finds the known one; an unknown one
/// is a normal outcome.
Method TestDemoFuzzyMatch()
{
	Do $$$AssertStatusOK(..SendText("Demo Fuzzy match", "initech supplys", .tResp))
	Do $$$AssertEquals(tResp.Success, 1, tResp.ResultText)
	Do $$$AssertTrue(tResp.ResultText [ "Initech Supplies", tResp.ResultText)
	Do $$$AssertStatusOK(..SendText("Demo Fuzzy match", "Wayne Enterprises", .tResp))
	Do $$$AssertEquals(tResp.Success, 0, tResp.ResultText)
}

/// Demo Normalize phone, in Python and in ObjectScript: a typed Dutch number
/// comes back international from both.
Method TestDemoNormalizePhone()
{
	For tTarget = "Demo Normalize phone (Python)", "Demo Normalize phone (ObjectScript)" {
		Do $$$AssertStatusOK(..SendText(tTarget, "06-12345678", .tResp), tTarget)
		Do $$$AssertEquals(tResp.Success, 1, tTarget_": "_tResp.ResultText)
		Do $$$AssertEquals(tResp.ResultText, "+31612345678", tTarget)
		Do $$$AssertStatusOK(..SendText(tTarget, "call me", .tResp), tTarget)
		Do $$$AssertEquals(tResp.Success, 0, tTarget_": "_tResp.ResultText)
	}
}

/// Demo Call process: the callee gets the caller's context as Aux and writes in
/// it: the name greeted, the note stream with the callee's addition and the tags
/// list with one more tag.
Method TestDemoCallProcess()
{
	Do $$$AssertStatusOK(..SendText("Demo Call process", "Jan", .tResp))
	Do $$$AssertEquals(tResp.Success, 1)
	Do $$$AssertEquals(tResp.ResultText, "Hello Jan | Note of the caller (seen by the callee) | caller,callee", "the callee wrote a value, the stream and the list straight into the caller's context")
}

/// Example register contact: cleanContact, which is not in the production,
/// cleans up the contact, and the caller reads its answer.
Method TestExampleRegisterContact()
{
	Set tReq = ##class(Ens.StringRequest).%New("jan@example.com, 06-12345678")
	Do $$$AssertStatusOK(##class(EnsLib.Testing.Service).SendTestRequest("Example register contact", tReq, .tResp, , 1))
	Do $$$AssertEquals(tResp.StringValue, "+31612345678, e-mail valid")
	Set tReq = ##class(Ens.StringRequest).%New("jan@, 12")
	Do $$$AssertStatusOK(##class(EnsLib.Testing.Service).SendTestRequest("Example register contact", tReq, .tResp, , 1))
	Do $$$AssertEquals(tResp.StringValue, "no valid phone number, e-mail not valid")
}

/// The example writeLetter gives its letter, a stream, to signLetter, which is
/// not in the production; the reply is the letter with what signLetter added.
Method TestExampleWriteLetter()
{
	Set tReq = ##class(Ens.StringRequest).%New("Jan")
	Do $$$AssertStatusOK(##class(EnsLib.Testing.Service).SendTestRequest("Example write letter", tReq, .tResp, , 1))
	Do $$$AssertEquals(tResp.StringValue, "Dear Jan,"_$Char(10, 10)_"Thank you for registering."_$Char(10, 10)_"Kind regards,"_$Char(10)_"The registration desk")
}

/// The example receiveOrder gives the HTTP message it gets to checkOrder, which
/// is not in the production, and answers with what checkOrder found: 202 for a
/// good order, the error of checkOrder otherwise.
Method TestExampleReceiveOrder()
{
	Set tOrder = "{""orderId"": ""A-1001"", ""lines"": [{""sku"": ""PEN-01"", ""quantity"": 3, ""price"": 1.25}, {""sku"": ""PAD-02"", ""quantity"": 1, ""price"": 4.5}]}"
	Do ..SendOrder("POST", "application/json; charset=utf-8", tOrder, .tStatus, .tBody)
	Do $$$AssertEquals(tStatus, "HTTP/1.1 202 Accepted")
	Do $$$AssertEquals(tBody, "{""orderId"":""A-1001"",""lines"":2,""total"":8.25,""status"":""accepted""}")
	Do ..SendOrder("GET", "application/json", tOrder, .tStatus, .tBody)
	Do $$$AssertEquals(tStatus, "HTTP/1.1 405 Method Not Allowed")
	Do ..SendOrder("POST", "text/plain", tOrder, .tStatus, .tBody)
	Do $$$AssertEquals(tStatus, "HTTP/1.1 415 Unsupported Media Type")
	Do ..SendOrder("POST", "application/json", "{not json", .tStatus, .tBody)
	Do $$$AssertEquals(tStatus, "HTTP/1.1 400 Bad Request")
	Do ..SendOrder("POST", "application/json", "{""orderId"": ""A-1002"", ""lines"": [{""sku"": ""PEN-01"", ""quantity"": 0, ""price"": 1}]}", .tStatus, .tBody)
	Do $$$AssertEquals(tStatus, "HTTP/1.1 422 Unprocessable Content")
	Do $$$AssertEquals(tBody, "{""error"":""line 1: quantity has to be a whole number of 1 or more""}")
}

/// Sends an order to Example receive order the way EnsLib.HTTP.GenericService
/// would, and returns the status line and body of the answer.
Method SendOrder(pMethod As %String, pContentType As %String, pBody As %String, Output pStatus As %String, Output pAnswer As %String)
{
	Set (pStatus, pAnswer) = ""
	Set tStream = ##class(%Stream.GlobalCharacter).%New()
	Do tStream.Write(pBody)
	Set tReq = ##class(EnsLib.HTTP.GenericMessage).%New(tStream)
	Do tReq.HTTPHeaders.SetAt(pMethod, "HttpRequest")
	Do tReq.HTTPHeaders.SetAt(pContentType, "Content-Type")
	Do $$$AssertStatusOK(##class(EnsLib.Testing.Service).SendTestRequest("Example receive order", tReq, .tResp, , 1))
	If '$IsObject($Get(tResp)) Quit
	Set pStatus = tResp.HTTPHeaders.GetAt("StatusLine")
	Do tResp.Stream.Rewind()
	Set pAnswer = tResp.Stream.Read(32000)
}

/// Number of notifications Send notification logged in the session.
Method CountNotifications(pSession As %String) As %Integer
{
	&sql(SELECT COUNT(*) INTO :tCount FROM Ens_Util.Log
		WHERE SessionId = :pSession AND Text %STARTSWITH 'Notification to')
	Quit $Select(SQLCODE = 0: tCount, 1: -1)
}

}
