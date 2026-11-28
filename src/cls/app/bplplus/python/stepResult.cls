/// Result of an activity written as a plain Python class: Success and
/// ResultText, plus the Python class's own results, read by name
/// (<code>bplstepResult.E164</code>) as if they were properties.
Class app.bplplus.python.stepResult Extends app.bplplus.activityResult
{

/// The Python class's own results, by name.
Property Values As %String [ MultiDimensional ];

/// Reads a result of the Python class: "" when it was not set.
Method %DispatchGetProperty(pName As %String)
{
	Quit $Get(..Values(pName))
}

Method %DispatchSetProperty(pName As %String, pValue)
{
	Set ..Values(pName) = pValue
}

/// The result from the JSON object bplplus.run returns.
ClassMethod FromJSON(pJSON As %String) As app.bplplus.python.stepResult
{
	Set tResult = ..%New()
	Set tOut = ##class(%DynamicAbstractObject).%FromJSON(pJSON)
	Set tIter = tOut.%GetIterator()
	While tIter.%GetNext(.tKey, .tValue) {
		If tKey = "Success" {
			Set tResult.Success = +tValue
		}
		ElseIf tKey = "ResultText" {
			Set tResult.ResultText = tValue
		}
		Else {
			Set tResult.Values(tKey) = tValue
		}
	}
	Quit tResult
}

}
