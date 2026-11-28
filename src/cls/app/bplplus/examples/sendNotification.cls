Include Ensemble

/// Sends a notification to a person or team. This example writes it to the
/// Event Log (a high priority one as a warning); replace Execute with a mail,
/// Teams or SMS call to make it real.
/// <p>
/// Copy this class as the starting point for a new activity: the properties are
/// the parameters the designer shows, Execute is what the activity does.
Class app.bplplus.examples.sendNotification Extends app.bplplus.activity
{

Parameter ACTIVITYCAPTION = "Send notification";

Parameter ACTIVITYCOLOR = "#E3F2FD";

/// Who receives the notification: an e-mail address or a team name.
Property Recipient As %String(MAXLEN = 250) [ Required ];

/// Subject line of the notification.
Property Subject As %String(MAXLEN = 250);

/// Body text of the notification.
Property MessageText As %String(MAXLEN = "");

/// How urgent it is. high is also logged as a warning, so it stands out in the
/// Event Log.
Property Priority As %String(VALUELIST = ",low,normal,high") [ InitialExpression = "normal" ];

/// Logs the notification and reports what was sent.
Method Execute(pProcess As Ens.BusinessProcess, Output pResult As app.bplplus.activityResult) As %Status
{
	Set pResult = ##class(app.bplplus.activityResult).%New()
	Set tLine = "Notification to "_..Recipient_" ("_..Priority_"): "_..Subject
	If ..Priority = "high" {
		$$$LOGWARNING(tLine_" - "_..MessageText)
	}
	Else {
		$$$LOGINFO(tLine_" - "_..MessageText)
	}
	Set pResult.Success = 1
	Set pResult.ResultText = tLine
	Quit $$$OK
}

}
