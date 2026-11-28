/// Example of a process that Call process calls: it cleans up a contact. Its
/// request is an app.bplplus.examples.contact, the very object of the process
/// that calls it (Aux): it puts Phone in international form with Normalize
/// phone and checks Email with Validate value, and writes the outcome straight
/// into that contact. See app.bplplus.examples.registerContact.
/// <p>
/// What makes it callable is only its request class: not a message, but the
/// class of what it works on.
Class app.bplplus.examples.cleanContact Extends Ens.BusinessProcessBPL [ DependsOn = (app.bplplus.examples.contact, app.bplplus.examples.normalizePhone, app.bplplus.examples.validateValue) ]
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='app.bplplus.examples.contact' height='2000' width='2000' >
<sequence xend='200' yend='450' >
<code name='Normalize phone (ObjectScript)' languageOverride='objectscript' xpos='200' ypos='250' >
<![CDATA[
 // bplstep app.bplplus.examples.normalizePhone - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.examples.normalizePhone).%New()
 Set bplstep.Number = request.Phone
 Set bplstep.CountryCode = "31"
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set request.PhoneValid = bplstepResult.Success
 Set request.PhoneE164 = bplstepResult.E164
]]>
</code>
<code name='Validate value' languageOverride='objectscript' xpos='200' ypos='350' >
<![CDATA[
 // bplstep app.bplplus.examples.validateValue - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.examples.validateValue).%New()
 Set bplstep.Value = request.Email
 Set bplstep.Pattern = "[^@ ]+@[^@ ]+\.[A-Za-z]{2,}"
 Set bplstep.FailureText = "Not an e-mail address"
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set request.EmailValid = bplstepResult.Success
]]>
</code>
</sequence>
</process>
}

}
