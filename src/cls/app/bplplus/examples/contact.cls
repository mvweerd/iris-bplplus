/// A contact, as the example processes of Call process share it:
/// app.bplplus.examples.registerContact keeps one in its context and gives it to
/// app.bplplus.examples.cleanContact as Aux, which fills in the last three
/// properties. Serial, so a context can hold it, and XML-enabled, so the
/// message viewer and trace show it.
Class app.bplplus.examples.contact Extends (%SerialObject, %XML.Adaptor)
{

/// The e-mail address as typed.
Property Email As %String(MAXLEN = 200);

/// The phone number as typed.
Property Phone As %String(MAXLEN = 100);

/// The phone number in international form, such as +31612345678; empty when
/// Phone is not a phone number.
Property PhoneE164 As %String(MAXLEN = 20);

/// 1 when Phone is a phone number.
Property PhoneValid As %Boolean;

/// 1 when Email looks like an e-mail address.
Property EmailValid As %Boolean;

}
