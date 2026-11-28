/// Result of a custom BPL activity. Subclass it when an activity has more to
/// return; every property it has is offered in the designer as a result that is
/// stored in the process context.
Class app.bplplus.activityResult Extends %RegisteredObject
{

/// 1 when the activity did what it was asked, 0 when it ran but the outcome was
/// negative, such as a value that failed validation. An activity that could not
/// run at all raises a fault instead, so a process only branches on this for
/// outcomes it expects.
Property Success As %Boolean [ InitialExpression = 1 ];

/// What happened, in words: useful to store in the context for a later trace or
/// reply.
Property ResultText As %String(MAXLEN = "");

}
