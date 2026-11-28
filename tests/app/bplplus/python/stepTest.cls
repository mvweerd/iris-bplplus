/// Tests of app.bplplus.python.step, which runs activities written as plain
/// Python classes (src/python/bplplus_steps), with the example activity
/// Normalize phone (bplplus_steps/phone.py). The Python side itself is tested
/// without IRIS in tests/python.
Class test.app.bplplus.python.stepTest Extends %UnitTest.TestCase
{

/// An activity in a plain Python module, run as the generated code does: the
/// parameters set by name, the results read by name.
Method TestRun()
{
	Set tAct = ##class(app.bplplus.python.step).%New("bplplus_steps.phone.NormalizePhone")
	Set tAct.Number = "06-12345678"
	Do $$$AssertEquals(tAct.Number, "06-12345678", "parameter read back")
	Do $$$AssertStatusOK(tAct.Run("", .tResult))
	Do $$$AssertEquals(tResult.Success, 1)
	Do $$$AssertEquals(tResult.E164, "+31612345678", "result read by name")

	Set tAct = ##class(app.bplplus.python.step).%New("bplplus_steps.phone.NormalizePhone")
	Set tAct.Number = "call me"
	Do $$$AssertStatusOK(tAct.Run("", .tResult), "not a number is a negative outcome")
	Do $$$AssertEquals(tResult.Success, 0)
	Do $$$AssertEquals(tResult.E164, "")
}

/// Mistakes in the process reach the activity as errors that say what is wrong.
Method TestErrors()
{
	Set tAct = ##class(app.bplplus.python.step).%New("bplplus_steps.phone.NormalizePhone")
	Set tSC = tAct.Run("", .tResult)
	Do $$$AssertStatusNotOK(tSC)
	Do $$$AssertTrue($System.Status.GetErrorText(tSC) [ "Number is required", $System.Status.GetErrorText(tSC))

	Set tAct = ##class(app.bplplus.python.step).%New("bplplus_steps.phone.NormalizePhone")
	Set tAct.Nummer = "0612345678"
	Set tSC = tAct.Run("", .tResult)
	Do $$$AssertTrue($System.Status.GetErrorText(tSC) [ "no parameter Nummer", "a typing error in the process")
}

/// The Python activities are in the catalog, as the editors need them.
Method TestInCatalog()
{
	Set tList = ##class(app.bplplus.catalog).Activities()
	Set tIter = tList.%GetIterator()
	While tIter.%GetNext(.k, .tEntry) {
		Set tByClass(tEntry.className) = tEntry
	}
	Do $$$AssertTrue($Data(tByClass("python:bplplus_steps.phone.NormalizePhone")), "listed")
	Do $$$AssertNotTrue($Data(tByClass("app.bplplus.python.step")), "the runner itself is not")
	Set tEntry = $Get(tByClass("python:bplplus_steps.phone.NormalizePhone"))
	If $IsObject(tEntry) {
		Do $$$AssertEquals(tEntry.caption, "Normalize phone (Python)")
		Do $$$AssertEquals(tEntry.create, "##class(app.bplplus.python.step).%New(""bplplus_steps.phone.NormalizePhone"")")
	}
}

/// The ObjectScript and the Python Normalize phone give the same answers.
Method TestSameAnswersAsObjectScript()
{
	Set tCases = $ListBuild("06-12345678", "(020) 555 1234", "0031 6 1234 5678", "+31 6 12345678", "+49 30 123456", "06-1234", "call me", "612345678")
	For i = 1:1:$ListLength(tCases) {
		Set tTyped = $List(tCases, i)
		Set tOS = ##class(app.bplplus.examples.normalizePhone).%New()
		Set tOS.Number = tTyped
		Do $$$AssertStatusOK(tOS.Run("", .tOSResult), "ObjectScript: "_tTyped)
		Set tPy = ##class(app.bplplus.python.step).%New("bplplus_steps.phone.NormalizePhone")
		Set tPy.Number = tTyped
		Do $$$AssertStatusOK(tPy.Run("", .tPyResult), "Python: "_tTyped)
		Do $$$AssertEquals(tOSResult.E164, tPyResult.E164, "E164 of "_tTyped)
		Do $$$AssertEquals(tOSResult.Success, tPyResult.Success, "Success of "_tTyped)
		Do $$$AssertEquals(tOSResult.ResultText, tPyResult.ResultText, "ResultText of "_tTyped)
	}
	Set tOS = ##class(app.bplplus.examples.normalizePhone).%New()
	Set tOS.Number = "030 123456", tOS.CountryCode = "49"
	Do $$$AssertStatusOK(tOS.Run("", .tOSResult))
	Do $$$AssertEquals(tOSResult.E164, "+4930123456", "another country code")
}

}
