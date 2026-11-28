/// Checks a value against a regular expression. A value that does not match is
/// a normal outcome, not an error: Success is 0 and ResultText holds the failure
/// text, so the process can branch on it.
Class app.bplplus.examples.validateValue Extends app.bplplus.activity
{

Parameter ACTIVITYCAPTION = "Validate value";

Parameter ACTIVITYCOLOR = "#E8F5E9";

/// The value to check, usually a property of the request or the context, such
/// as request.Email.
Property Value As %String(MAXLEN = "");

/// Regular expression the whole value has to match, in the ICU syntax $MATCH
/// uses, for example "[0-9]{4}[A-Z]{2}" for a Dutch postcode.
Property Pattern As %String(MAXLEN = 1000) [ Required ];

/// Returned in ResultText when the value does not match.
Property FailureText As %String(MAXLEN = 1000) [ InitialExpression = "Value is not valid" ];

/// Matches Value against Pattern. A pattern that is not a valid regular
/// expression fails the activity, because no value can be checked against it.
Method Execute(pProcess As Ens.BusinessProcess, Output pResult As app.bplplus.activityResult) As %Status
{
	Set pResult = ##class(app.bplplus.activityResult).%New()
	Try {
		Set tMatch = $Match(..Value, ..Pattern)
	}
	Catch ex {
		Set pResult = ""
		Return $$$ERROR($$$GeneralError, "Pattern "_..Pattern_" of activity Validate value is not a valid regular expression: "_ex.DisplayString())
	}
	Set pResult.Success = tMatch
	Set pResult.ResultText = $Select(tMatch: "Value is valid", 1: ..FailureText)
	Quit $$$OK
}

}
