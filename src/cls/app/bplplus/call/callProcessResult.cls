/// Result of Call process: the response of the process called.
Class app.bplplus.call.callProcessResult Extends app.bplplus.activityResult
{

/// The response of the process called, such as an Ens.StringResponse; empty
/// when it has no response class. Store it in a context property of the
/// response class of that process, so it is kept when this process waits.
Property Response As %RegisteredObject;

}
