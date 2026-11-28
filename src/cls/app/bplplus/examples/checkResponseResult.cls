/// Result of Check response: Success and ResultText, plus the value that was
/// found, for a trace or a later decision.
Class app.bplplus.examples.checkResponseResult Extends app.bplplus.activityResult
{

/// The value of the element, or "" when it is empty or missing.
Property FoundValue As %String(MAXLEN = "");

}
