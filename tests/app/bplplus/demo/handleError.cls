/// Demo of Handle error: validates the text "1234AB" against the regular
/// expression in the request, inside a scope. A broken expression, such as "([a-z",
/// makes Validate value fail; the scope's catchall then runs Handle error, which
/// logs the error as a warning, raises an alert (SendAlert = 1) and lets the process
/// reply normally with the error text (ReturnAsError = 0).
Class test.app.bplplus.demo.handleError Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='test.app.bplplus.demo.textRequest' response='test.app.bplplus.demo.response' height='2000' width='2000' >
<sequence xend='200' yend='650' >
<scope name='Validate safely' xpos='200' ypos='250' xend='200' yend='550' >
<code name='Validate value' languageOverride='objectscript' xpos='200' ypos='350' >
<![CDATA[
 // bplstep app.bplplus.examples.validateValue - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.examples.validateValue).%New()
 Set bplstep.Value = "1234AB"
 Set bplstep.Pattern = request.Text
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set response.Success = bplstepResult.Success
 Set response.ResultText = bplstepResult.ResultText
]]>
</code>
<faulthandlers>
<catchall name='Validation failed' xpos='200' ypos='450' xend='200' yend='350' >
<code name='Handle error' languageOverride='objectscript' xpos='200' ypos='250' >
<![CDATA[
 // bplstep app.bplplus.examples.handleError - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.examples.handleError).%New()
 Set bplstep.ErrorStatus = context.%LastError
 Set bplstep.ReturnAsError = 0
 Set bplstep.ErrorPrefix = "Demo Handle error"
 Set bplstep.SendAlert = 1
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set response.ResultText = bplstepResult.ResultText
]]>
</code>
<assign name='Reply failure' property="response.Success" value="0" action="set" xpos='200' ypos='300' />
</catchall>
</faulthandlers>
</scope>
</sequence>
</process>
}

}
