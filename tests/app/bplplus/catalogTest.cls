/// Tests that the activity catalog the designer reads describes the example
/// activities correctly: what is listed, and what each parameter carries.
Class test.app.bplplus.catalogTest Extends %UnitTest.TestCase
{

/// Both examples are listed, sorted by caption; the abstract base class is not.
Method TestListsActivities()
{
	Set tList = ##class(app.bplplus.catalog).Activities()
	Set tIter = tList.%GetIterator()
	Set tCaptions = ""
	While tIter.%GetNext(.k, .tEntry) {
		Set tFound(tEntry.className) = ""
		Set tCaptions = tCaptions_$ListBuild(tEntry.caption)
	}
	Do $$$AssertTrue($Data(tFound("app.bplplus.examples.sendNotification")), "sendNotification is listed")
	Do $$$AssertTrue($Data(tFound("app.bplplus.examples.validateValue")), "validateValue is listed")
	Do $$$AssertNotTrue($Data(tFound("app.bplplus.activity")), "the abstract base is left out")
	Set tPosSend = $ListFind(tCaptions, "Send notification")
	Set tPosValidate = $ListFind(tCaptions, "Validate value")
	Do $$$AssertTrue(tPosSend && tPosValidate && (tPosSend < tPosValidate), "sorted by caption")
}

/// Caption, target, response class and the parameters of Send notification,
/// with their required marks, defaults and value lists.
Method TestDescribesParameters()
{
	Set tEntry = ##class(app.bplplus.catalog).Describe("app.bplplus.examples.sendNotification")
	Do $$$AssertEquals(tEntry.caption, "Send notification")
	Do $$$AssertEquals(tEntry.resultClass, "app.bplplus.activityResult")
	Do $$$AssertEquals(tEntry.autoMap, 1, "results are mapped automatically by default")
	Do $$$AssertTrue(tEntry.description [ "notification", "description is the first paragraph of the class comment")
	Do $$$AssertNotTrue(tEntry.description [ "Copy this class", "later paragraphs are left out")

	Set tNames = ""
	Set tIter = tEntry.inputs.%GetIterator()
	While tIter.%GetNext(.k, .tInput) {
		Set tNames = tNames_$ListBuild(tInput.name)
		Set tInputs(tInput.name) = tInput
	}
	Do $$$AssertEquals($ListToString(tNames), "Recipient,Subject,MessageText,Priority", "parameters in declaration order, nothing from the system classes")
	Do $$$AssertEquals(tInputs("Recipient").required, 1)
	Do $$$AssertEquals(tInputs("Subject").required, 0)
	Do $$$AssertEquals(tInputs("Subject").default, "", "no InitialExpression means no default")
	Do $$$AssertEquals(tInputs("Priority").default, """normal""", "default is a quoted BPL expression")
	Do $$$AssertEquals(tInputs("Priority").valueList, ",low,normal,high")

	Set tNames = ""
	Set tIter = tEntry.outputs.%GetIterator()
	While tIter.%GetNext(.k, .tOutput) {
		Set tNames = tNames_$ListBuild(tOutput.name)
	}
	Do $$$AssertEquals($ListToString(tNames), "Success,ResultText", "results come from the result class")
	Set tResultText = tEntry.outputs.%Get(1)
	Do $$$AssertTrue(tResultText.%IsDefined("maxLen"), "MAXLEN is passed on for the context property")
	Do $$$AssertEquals(tResultText.maxLen, "", "unlimited")
	Do $$$AssertNotTrue(tEntry.outputs.%Get(0).%IsDefined("maxLen"), "no MAXLEN on a boolean")
}

/// A default from the ActivityDefaults XData wins over InitialExpression, and the
/// other parameters keep theirs.
Method TestDesignerDefaults()
{
	Set tEntry = ##class(app.bplplus.catalog).Describe("app.bplplus.examples.handleError")
	Set tIter = tEntry.inputs.%GetIterator()
	While tIter.%GetNext(.k, .tInput) {
		Set tInputs(tInput.name) = tInput
	}
	Do $$$AssertEquals(tInputs("ErrorStatus").default, "context.%LastError", "from ActivityDefaults")
	Do $$$AssertEquals(tInputs("ReturnAsError").default, "0", "from InitialExpression")
	Do $$$AssertEquals(##class(app.bplplus.catalog).DesignerDefaults("app.bplplus.examples.sendNotification").%ToJSON(), "{}", "no block, no defaults")
}

/// Call process: Target has a magnifier, whose context search lists the demo
/// callee and no process that cannot be called. Only parameters of activities
/// with a context search give choices.
Method TestLookup()
{
	Set tEntry = ##class(app.bplplus.catalog).Describe("app.bplplus.call.callProcess")
	Set tIter = tEntry.inputs.%GetIterator()
	While tIter.%GetNext(.k, .tInput) { Set tInputs(tInput.name) = tInput }
	Do $$$AssertEquals(tInputs("Target").lookup, 1)
	Do $$$AssertEquals(tInputs("Aux").default, "context", "the whole context, unless you give less")
	Set tOther = ##class(app.bplplus.catalog).Describe("app.bplplus.examples.sendNotification").inputs.%Get(0)
	Do $$$AssertNotTrue(tOther.%IsDefined("lookup"), "no magnifier on an ordinary parameter")

	Set tChoices = ##class(app.bplplus.catalog).Choices("app.bplplus.call.callProcess", "Target")
	Do $$$AssertTrue(tChoices.caption [ "BPL processes", tChoices.caption)
	Set tAll = tChoices.top.%ToJSON()_tChoices.other.%ToJSON()
	Do $$$AssertTrue(tAll [ """test.app.bplplus.demo.callee""", tAll)
	Do $$$AssertNotTrue(tAll [ "validateValue", "a process that cannot be called is not listed")

	Do $$$AssertEquals(##class(app.bplplus.catalog).Choices("app.bplplus.examples.sendNotification", "Recipient").top.%Size(), 0, "no magnifier, no choices")
	Do $$$AssertEquals(##class(app.bplplus.catalog).Choices("%Library.String", "Target").top.%Size(), 0, "not an activity")
}

/// A class that is not an activity is not described.
Method TestRejectsOtherClasses()
{
	Do $$$AssertEquals(##class(app.bplplus.catalog).Describe("%RegisteredObject"), "")
	Do $$$AssertEquals(##class(app.bplplus.catalog).Describe("app.bplplus.activity"), "", "abstract")
	Do $$$AssertEquals(##class(app.bplplus.catalog).Describe("No.Such.Class"), "")
}

/// Comments become one line of plain text.
Method TestFirstParagraph()
{
	Do $$$AssertEquals(##class(app.bplplus.catalog).FirstParagraph("One <b>bold</b>"_$Char(10)_"line.<p>Second."), "One bold line.")
	Do $$$AssertEquals(##class(app.bplplus.catalog).FirstParagraph("First."_$Char(13,10,13,10)_"Second."), "First.")
}

}
