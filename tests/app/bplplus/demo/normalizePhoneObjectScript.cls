/// Demo of Normalize phone (ObjectScript), the ObjectScript twin of the activity
/// in the plain Python module bplplus_steps/phone.py (Demo Normalize phone
/// (Python)): turns the request's text, a phone number as people type it, into
/// its international form. Send both demos the same text to compare the two.
Class test.app.bplplus.demo.normalizePhoneObjectScript Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='test.app.bplplus.demo.textRequest' response='test.app.bplplus.demo.response' height='2000' width='2000' >
<sequence xend='200' yend='350' >
<code name='Normalize phone (ObjectScript)' languageOverride='objectscript' xpos='200' ypos='250' >
<![CDATA[
 // bplstep app.bplplus.examples.normalizePhone - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.examples.normalizePhone).%New()
 Set bplstep.Number = request.Text
 Set bplstep.CountryCode = "31"
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set response.Success = bplstepResult.Success
 Set response.ResultText = bplstepResult.ResultText
]]>
</code>
</sequence>
</process>
}

}
