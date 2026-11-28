/// Base class of a custom BPL activity written in Python. Everything else is
/// the same as for app.bplplus.activity: the properties are the parameters, the
/// class parameters say how the designer shows it, and it is added and filled in
/// the same way in both editors. Only the work is done in Python, with its
/// standard library and the packages installed for IRIS.
/// <p>
/// Implement <method>Perform</method>:
/// <example language="python">
/// def Perform(self, process, result):
///     # self.Value, self.Pattern ...: the parameters
///     # process: the business process (None outside one)
///     result.Success = 1
///     result.ResultText = "done"
/// </example>
/// Raising an exception fails the activity, as an error status does in
/// ObjectScript: the process raises a fault, with the exception's type and
/// message in the error, which a catchall can handle.
Class app.bplplus.python.activity Extends app.bplplus.activity [ Abstract ]
{

/// Does the activity's work, in Python. <var>process</var> is the business
/// process the activity runs in; <var>result</var> is the result object to fill
/// in (an instance of the activity's ACTIVITYRESULT class, with Success already
/// 1). Raise an exception when the activity cannot do its work.
Method Perform(process As Ens.BusinessProcess, result As app.bplplus.activityResult) [ Abstract, Language = python ]
{
    pass
}

/// Runs <method>Perform</method> with a new result object, and turns a Python
/// exception into an error status naming the activity.
Method Execute(pProcess As Ens.BusinessProcess, Output pResult As app.bplplus.activityResult) As %Status
{
	Set pResult = $ClassMethod($Parameter($this, "ACTIVITYRESULT"), "%New")
	Try {
		Do ..Perform($Select($IsObject($Get(pProcess)): pProcess, 1: ""), pResult)
	}
	Catch ex {
		Set pResult = ""
		Set tCaption = $Parameter($this, "ACTIVITYCAPTION")
		If tCaption = "" Set tCaption = $ClassName($this)
		Return $$$ERROR($$$GeneralError, tCaption_" (Python): "_ex.DisplayString())
	}
	Quit $$$OK
}

}
