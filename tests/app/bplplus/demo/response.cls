/// Reply of the demo process: whether the registration was accepted, and why.
Class test.app.bplplus.demo.response Extends Ens.Response
{

/// 1 when the registration was accepted (even if its confirmation could not be
/// sent), 0 when it was rejected.
Property Success As %Boolean [ InitialExpression = 1 ];

/// The confirmation that was sent, why it could not be, or why the registration
/// was rejected.
Property ResultText As %String(MAXLEN = "");

}
