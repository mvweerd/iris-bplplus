/// Demo of Normalize phone, an activity in a plain Python module
/// (src/python/bplplus_steps/phone.py), with no ObjectScript class of its own:
/// turns the request's text, a phone number as people type it, into its
/// international form. A text that is not a phone number is a normal outcome:
/// Success is 0. Its ObjectScript twin is Demo Normalize phone (ObjectScript).
Class test.app.bplplus.demo.normalizePhonePython Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='test.app.bplplus.demo.textRequest' response='test.app.bplplus.demo.response' height='2000' width='2000' >
<sequence xend='200' yend='350' >
<code name='Normalize phone (Python)' languageOverride='objectscript' xpos='200' ypos='250' >
<![CDATA[
 // bplstep python:bplplus_steps.phone.NormalizePhone - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.python.step).%New("bplplus_steps.phone.NormalizePhone")
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
