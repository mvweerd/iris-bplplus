/// Runs a custom activity written as a plain Python class (a bplplus.Activity in
/// a module of the package bplplus_steps, in the python directory of the
/// installation). The generated BPL code creates it with the class's path, sets
/// the parameters by name as for any activity, and calls Run:
/// <example>
/// Set bplstep = ##class(app.bplplus.python.step).%New("bplplus_steps.phone.NormalizePhone")
/// Set bplstep.Number = request.Text
/// Set status = bplstep.Run(process, .bplstepResult)
/// </example>
/// The parameters are not properties of this class: they are collected by name
/// and handed to Python, which checks and converts them (bplplus.run). The
/// results come back the same way, in an app.bplplus.python.stepResult.
/// <p>
/// Not an activity in the menu itself (ACTIVITYLISTED = 0): app.bplplus.catalog
/// lists the Python classes instead.
Class app.bplplus.python.step Extends app.bplplus.activity
{

Parameter ACTIVITYLISTED As BOOLEAN = 0;

Parameter ACTIVITYRESULT = "app.bplplus.python.stepResult";

/// Path of the Python class: module and class name, such as
/// bplplus_steps.phone.NormalizePhone.
Property StepClass As %String(MAXLEN = 500);

/// The parameters the process set, by name.
Property StepParams As %String [ MultiDimensional ];

Method %OnNew(pStepClass As %String = "") As %Status
{
	Set ..StepClass = pStepClass
	Quit $$$OK
}

/// Collects a parameter: <code>Set bplstep.Number = ...</code> for a name this
/// class has no property for.
Method %DispatchSetProperty(pName As %String, pValue)
{
	Set ..StepParams(pName) = pValue
}

/// Reads back a parameter set before.
Method %DispatchGetProperty(pName As %String)
{
	Quit $Get(..StepParams(pName))
}

/// Runs the Python class with the collected parameters. A Python exception (a
/// required parameter missing, a value of the wrong type, an error in the
/// activity) fails the activity with its message.
Method Execute(pProcess As Ens.BusinessProcess, Output pResult As app.bplplus.activityResult) As %Status
{
	Set pResult = ""
	Set tParams = {}
	Set tName = ""
	For {
		Set tName = $Order(..StepParams(tName), 1, tValue)
		Quit:tName=""
		Do tParams.%Set(tName, tValue)
	}
	Try {
		Set tJSON = ..RunPython(..StepClass, tParams.%ToJSON(), $Select($IsObject($Get(pProcess)): pProcess, 1: ""))
	}
	Catch ex {
		Return $$$ERROR($$$GeneralError, ..StepClass_" (Python): "_ex.DisplayString())
	}
	Set pResult = ##class(app.bplplus.python.stepResult).FromJSON(tJSON)
	Quit $$$OK
}

/// bplplus.run: the activity's results as a JSON object.
ClassMethod RunPython(pStepClass As %String, pParams As %String, pProcess) As %String [ Language = python ]
{
    import bplplus
    # "" outside a business process; an IRIS object has no truth value, so no
    # "pProcess or None" here.
    return bplplus.run(pStepClass, pParams, None if isinstance(pProcess, str) else pProcess)
}

/// bplplus.catalog: the Python activities, as a JSON array, for
/// app.bplplus.catalog.
ClassMethod Catalog() As %String [ Language = python ]
{
    import bplplus
    return bplplus.catalog()
}

}
