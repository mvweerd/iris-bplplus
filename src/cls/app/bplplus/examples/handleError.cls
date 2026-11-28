Include Ensemble

/// Handles the error a catchall caught: either fails with it, so the process
/// ends in error (or the next catchall out handles it), or only logs it as a
/// warning in the Event Log so the process carries on; optionally it also raises
/// an alert. Place it inside a catchall (or catch) of a scope.
/// <p>
/// Meant as the one standard block for a catchall. Hand-written catchall code
/// tends to break in exactly the situation it is there for: one that sets a
/// property the context does not have raises a new error and hides the real one.
/// <p>
/// By default it takes the error from context.%LastError, which is where BPL
/// puts the status of the activity that failed inside the scope.
Class app.bplplus.examples.handleError Extends app.bplplus.activity
{

Parameter ACTIVITYCAPTION = "Handle error";

Parameter ACTIVITYCOLOR = "#FDECEA";

/// Values the designer fills in when the activity is added. ErrorStatus cannot
/// use InitialExpression for this: that is evaluated when the activity object
/// is created, where there is no context.
XData ActivityDefaults [ MimeType = application/json ]
{
{ "ErrorStatus": "context.%LastError" }
}

/// The error to handle. context.%LastError holds the status of the activity that
/// failed inside the scope.
Property ErrorStatus As %Status;

/// 1 returns the error as the result of this activity, so the process fails with
/// it; 0 only logs it as a warning in the Event Log and the process continues.
Property ReturnAsError As %Boolean [ InitialExpression = 0 ];

/// Optional text put in front of the error, to say where it happened, for example
/// "Order import".
Property ErrorPrefix As %String(MAXLEN = 250);

/// 1 also sends an alert with the error text to the production's alert
/// handling (Ens.Alert), so the error is reported and not only logged. The alert
/// names the business process as its source.
Property SendAlert As %Boolean [ InitialExpression = 0 ];

/// Fails with the error, or logs it as a warning, depending on ReturnAsError,
/// and sends an alert when SendAlert is 1. A status that is not an error (nothing
/// went wrong) does none of these.
Method Execute(pProcess As Ens.BusinessProcess, Output pResult As app.bplplus.activityResult) As %Status
{
	Set pResult = ##class(app.bplplus.activityResult).%New()
	// An empty status counts as an error to $$$ISERR, but here it means there is
	// nothing to handle.
	If (..ErrorStatus = "") || $$$ISOK(..ErrorStatus) {
		Set pResult.ResultText = "No error to handle"
		Quit $$$OK
	}
	Set tText = $System.Status.GetErrorText(..ErrorStatus)
	If ..ErrorPrefix '= "" Set tText = ..ErrorPrefix_": "_tText
	If ..SendAlert Do ..RaiseAlert(pProcess, tText)
	If ..ReturnAsError {
		Set pResult = ""
		Quit $$$ADDSC($$$ERROR($$$GeneralError, tText), ..ErrorStatus)
	}
	$$$LOGWARNING(tText)
	Set pResult.Success = 1
	Set pResult.ResultText = "Logged as warning: "_tText
	Quit $$$OK
}

/// Sends an alert with <var>pText</var> on behalf of business process
/// <var>pProcess</var>. Outside a business process (a unit test, a call from a
/// terminal) there is nothing to send it through, so it is logged instead. A
/// failure to send never hides the error being handled.
Method RaiseAlert(pProcess As Ens.BusinessProcess, pText As %String)
{
	Try {
		If '$IsObject($Get(pProcess)) || 'pProcess.%IsA("Ens.BusinessProcess") {
			$$$LOGWARNING("Alert not sent (not in a business process): "_pText)
			Quit
		}
		Set tAlert = ##class(Ens.AlertRequest).%New()
		Set tAlert.SourceConfigName = pProcess.%ConfigName
		Set tAlert.AlertText = pText
		Set tSC = pProcess.SendAlert(tAlert)
		If $$$ISERR(tSC) $$$LOGWARNING("Alert not sent: "_$System.Status.GetErrorText(tSC))
	}
	Catch ex {
		$$$LOGWARNING("Alert not sent: "_ex.DisplayString())
	}
}

}
