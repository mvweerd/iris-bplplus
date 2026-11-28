/// Request of the single-step demo processes: one piece of text, whose meaning
/// depends on the process (a postcode, a regular expression, a service answer,
/// XML records).
Class test.app.bplplus.demo.textRequest Extends Ens.Request
{

/// The input of the demo.
Property Text As %String(MAXLEN = "");

}
