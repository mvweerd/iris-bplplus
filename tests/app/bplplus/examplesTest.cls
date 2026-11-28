/// Tests the example activities Check response and Build SQL insert, and the
/// alert option of Handle error, on their own, without a production.
Class test.app.bplplus.examplesTest Extends %UnitTest.TestCase
{

/// A stream with <var>pText</var>.
Method Stream(pText As %String) As %Stream.Object
{
	Set tStream = ##class(%Stream.TmpCharacter).%New()
	Do tStream.Write(pText)
	Quit tStream
}

/// A SOAP answer with namespaces and prefixes, as a service like NAF gives it.
Method SoapAnswer(pMessage As %String) As %Stream.Object
{
	Quit ..Stream("<soap:Envelope xmlns:soap=""http://schemas.xmlsoap.org/soap/envelope/""><soap:Body>"
		_"<ns1:InlezenResponse xmlns:ns1=""urn:x""><ns1:Result><ns1:Code>0</ns1:Code><ns1:Message> "_pMessage_" </ns1:Message></ns1:Result></ns1:InlezenResponse>"
		_"</soap:Body></soap:Envelope>")
}

/// The expected value passes; namespaces and surrounding white space do not
/// matter.
Method TestCheckResponseOk()
{
	Set tAct = ##class(app.bplplus.examples.checkResponse).%New()
	Set tAct.Response = ..SoapAnswer("OK")
	Set tAct.ElementPath = "Result/Message"
	Do $$$AssertStatusOK(tAct.Run("", .tResult))
	Do $$$AssertEquals(tResult.Success, 1)
	Do $$$AssertEquals(tResult.FoundValue, "OK")
}

/// Another value fails, naming path, found and expected value; with
/// FailOnMismatch 0 it is only Success 0.
Method TestCheckResponseMismatch()
{
	Set tAct = ##class(app.bplplus.examples.checkResponse).%New()
	Set tAct.Response = ..SoapAnswer("Article unknown")
	Set tAct.ElementPath = "Result/Message"
	Set tAct.ErrorText = "NAF refused the article"
	Set tSC = tAct.Run("", .tResult)
	Do $$$AssertStatusNotOK(tSC)
	Set tText = $System.Status.GetErrorText(tSC)
	Do $$$AssertTrue(tText [ "NAF refused the article", "error text")
	Do $$$AssertTrue(tText [ "'Article unknown'", "found value: "_tText)
	Do $$$AssertTrue(tText [ "'OK'", "expected value")

	Set tAct.Response = ..SoapAnswer("Article unknown")
	Set tAct.FailOnMismatch = 0
	Do $$$AssertStatusOK(tAct.Run("", .tResult))
	Do $$$AssertEquals(tResult.Success, 0)
	Do $$$AssertEquals(tResult.FoundValue, "Article unknown")
}

/// A missing element, an element of the same name elsewhere, and a response that
/// is not XML.
Method TestCheckResponseEdgeCases()
{
	Set tAct = ##class(app.bplplus.examples.checkResponse).%New()
	Set tAct.Response = ..SoapAnswer("OK")
	Set tAct.ElementPath = "Result/Status"
	Set tSC = tAct.Run("", .tResult)
	Do $$$AssertStatusNotOK(tSC)
	Do $$$AssertTrue($System.Status.GetErrorText(tSC) [ "not in the response", "missing element")

	Set tAct.Response = ..Stream("<a><Message>wrong one</Message><Result><Message>OK</Message></Result></a>")
	Set tAct.ElementPath = "Result/Message"
	Do $$$AssertStatusOK(tAct.Run("", .tResult), "only a Message inside Result counts")

	Set tAct.Response = ..Stream("<a><Result><Message/></Result></a>")
	Set tAct.ExpectedValue = ""
	Do $$$AssertStatusOK(tAct.Run("", .tResult), "empty element found with value ''")

	Set tAct.Response = ..Stream("this is not xml")
	Do $$$AssertStatusNotOK(tAct.Run("", .tResult), "not XML")
}

/// Records of the kind an XSLT for a table produces.
Method Records() As %Stream.Object
{
	Quit ..Stream("<drs xmlns=""urn:drs""><row><ID>1</ID><Name>O'Brien</Name><Amount>12.50</Amount><Remark/></row>"
		_"<row><ID>2</ID><Name> Jansen </Name><Amount></Amount><Remark>ok</Remark></row></drs>")
}

/// Text quoted with its quotes doubled, numbers bare, empty as NULL, COL=FIELD,
/// one statement per record.
Method TestBuildSqlInsert()
{
	Set tAct = ##class(app.bplplus.examples.buildSqlInsert).%New()
	Set tAct.Source = ..Records()
	Set tAct.RecordElement = "row"
	Set tAct.TableName = "ORDERS"
	Set tAct.Columns = "ORDER_ID=ID, CUSTOMER=Name, AMOUNT=Amount, REMARK=Remark"
	Set tAct.NumericColumns = "ORDER_ID,AMOUNT"
	Do $$$AssertStatusOK(tAct.Run("", .tResult))
	Do $$$AssertEquals(tResult.RecordCount, 2)
	Do $$$AssertTrue($IsObject(tResult.Statements) && tResult.Statements.%IsA("%Stream.Object"), "a stream")
	Set tLines = $ListFromString(tResult.Statements.Read(3641144), $Char(13, 10))
	Do $$$AssertEquals($List(tLines, 1), "INSERT INTO ORDERS (ORDER_ID, CUSTOMER, AMOUNT, REMARK) VALUES (1, 'O''Brien', 12.5, NULL)")
	Do $$$AssertEquals($List(tLines, 2), "INSERT INTO ORDERS (ORDER_ID, CUSTOMER, AMOUNT, REMARK) VALUES (2, 'Jansen', NULL, 'ok')")

	Set tAct.Source = ..Records()
	Set tAct.EmptyAsNull = 0
	Do $$$AssertStatusOK(tAct.Run("", .tResult))
	Do $$$AssertTrue($List($ListFromString(tResult.Statements.Read(3641144), $Char(13, 10)), 1) [ "12.5, '')", "empty text as '' when EmptyAsNull is 0")
}

/// More records than fit in a string still give every statement, in the stream.
Method TestBuildSqlInsertLargeBatch()
{
	Set tXML = ##class(%Stream.TmpCharacter).%New()
	Do tXML.Write("<rows>")
	Set tText = $Translate($Justify("", 4000), " ", "x")
	For i = 1:1:1000 {
		Do tXML.Write("<row><ID>"_i_"</ID><Remark>"_tText_"</Remark></row>")
	}
	Do tXML.Write("</rows>")
	Set tAct = ##class(app.bplplus.examples.buildSqlInsert).%New()
	Set tAct.Source = tXML
	Set tAct.RecordElement = "row"
	Set tAct.TableName = "ORDERS"
	Set tAct.Columns = "ORDER_ID=ID, REMARK=Remark"
	Set tAct.NumericColumns = "ORDER_ID"
	Do $$$AssertStatusOK(tAct.Run("", .tResult))
	Do $$$AssertEquals(tResult.RecordCount, 1000)
	Do $$$AssertTrue(tResult.Statements.Size > 3641144, "larger than a string: "_tResult.Statements.Size)
	Set tLine = ""
	For {
		Quit:tResult.Statements.AtEnd
		Set tLast = tResult.Statements.ReadLine()
		If tLast '= "" Set tLine = tLast
	}
	Do $$$AssertTrue(tLine [ "VALUES (1000, 'x", "the last statement is there")
}

/// The mistakes hand-built statements make: a misspelt field, text in a numeric
/// column, a column listed twice.
Method TestBuildSqlInsertRefusesMistakes()
{
	Set tAct = ##class(app.bplplus.examples.buildSqlInsert).%New()
	Set tAct.Source = ..Records()
	Set tAct.RecordElement = "row"
	Set tAct.TableName = "ORDERS"

	Set tAct.Columns = "ORDER_ID=ID, AMOUNT=Amout"
	Set tSC = tAct.Run("", .tResult)
	Do $$$AssertStatusNotOK(tSC)
	Do $$$AssertTrue($System.Status.GetErrorText(tSC) [ "no field Amout", "misspelt field named: "_$System.Status.GetErrorText(tSC))

	Set tAct.Source = ..Records()
	Set tAct.Columns = "ORDER_ID=ID, CUSTOMER=Name"
	Set tAct.NumericColumns = "CUSTOMER"
	Set tSC = tAct.Run("", .tResult)
	Do $$$AssertStatusNotOK(tSC)
	Do $$$AssertTrue($System.Status.GetErrorText(tSC) [ "is numeric", "text in a numeric column")

	Set tAct.Source = ..Records()
	Set tAct.NumericColumns = ""
	Set tAct.Columns = "ORDER_ID=ID, ORDER_ID=Name"
	Set tSC = tAct.Run("", .tResult)
	Do $$$AssertStatusNotOK(tSC)
	Do $$$AssertTrue($System.Status.GetErrorText(tSC) [ "listed twice", "duplicate column")

	Set tAct.Columns = "ORDER ID"
	Do $$$AssertStatusNotOK(tAct.Run("", .tResult), "invalid column name")
}

/// Fuzzy match (Python): a typo still finds the right candidate, case and
/// punctuation do not count, and a weak resemblance is no match.
Method TestFuzzyMatch()
{
	Set tAct = ##class(app.bplplus.examples.fuzzyMatch).%New()
	Set tAct.Candidates = "Acme Foods B.V.;Globex Trading;Initech Supplies"
	Set tAct.Value = "ACME fods bv"
	Do $$$AssertStatusOK(tAct.Run("", .tResult))
	Do $$$AssertEquals(tResult.Success, 1, tResult.ResultText)
	Do $$$AssertEquals(tResult.BestMatch, "Acme Foods B.V.")
	Do $$$AssertTrue(tResult.Score > 0.8, "score "_tResult.Score)

	Set tAct.Value = "Umbrella"
	Do $$$AssertStatusOK(tAct.Run("", .tResult))
	Do $$$AssertEquals(tResult.Success, 0, "no match is a normal outcome")
	Do $$$AssertTrue(tResult.ResultText [ "closest is", tResult.ResultText)
}

/// A Python exception fails the activity with its message, naming the activity.
Method TestFuzzyMatchPythonError()
{
	Set tAct = ##class(app.bplplus.examples.fuzzyMatch).%New()
	Set tAct.Value = "Acme"
	Set tAct.Candidates = " ; ;"
	Set tSC = tAct.Run("", .tResult)
	Do $$$AssertStatusNotOK(tSC)
	Set tText = $System.Status.GetErrorText(tSC)
	Do $$$AssertTrue(tText [ "Fuzzy match (Python)", "names the activity: "_tText)
	Do $$$AssertTrue(tText [ "Candidates is empty", "carries the Python message")
}

/// Without a business process the alert of Handle error is logged instead, and
/// the error is still handled.
Method TestHandleErrorAlertOutsideProcess()
{
	Set tAct = ##class(app.bplplus.examples.handleError).%New()
	Set tAct.ErrorStatus = $$$ERROR($$$GeneralError, "Order 42 not found")
	Set tAct.SendAlert = 1
	Do $$$AssertStatusOK(tAct.Run("", .tResult))
	Do $$$AssertTrue(tResult.ResultText [ "Order 42 not found")
}

}
