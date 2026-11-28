/// Request of the demo process: a registration to check and confirm.
Class test.app.bplplus.demo.registrationRequest Extends Ens.Request
{

/// E-mail address of the person registering; the process validates it.
Property Email As %String(MAXLEN = 250);

/// Name of the person, used in the notification's subject.
Property Name As %String(MAXLEN = 250);

/// Priority of the confirmation; empty means normal. A value other than low,
/// normal or high makes the notification fail, which the process's catchall
/// handles: try it to see "Handle error" at work.
Property Priority As %String(MAXLEN = 50);

}
