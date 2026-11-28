/// Result of Normalize phone (ObjectScript): the number in international form.
Class app.bplplus.examples.normalizePhoneResult Extends app.bplplus.activityResult
{

/// The number in international form, such as +31612345678; empty when the text is not a phone number.
Property E164 As %String(MAXLEN = 20);

}
