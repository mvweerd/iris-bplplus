/// Demo of Validate value: checks whether the request's text is a Dutch postcode
/// (four digits, two capitals) and replies with the outcome. A text that does not
/// match is a normal outcome, not an error: Success is 0.
Class test.app.bplplus.demo.validateValue Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='test.app.bplplus.demo.textRequest' response='test.app.bplplus.demo.response' height='2000' width='2000' >
<sequence xend='200' yend='350' >
<code name='Validate value' languageOverride='objectscript' xpos='200' ypos='250' >
<![CDATA[
 // bplstep app.bplplus.examples.validateValue - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.examples.validateValue).%New()
 Set bplstep.Value = request.Text
 Set bplstep.Pattern = "[1-9][0-9]{3} ?[A-Z]{2}"
 Set bplstep.FailureText = "Not a Dutch postcode"
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
