/// Demo of Send notification: sends the notification described by the request
/// (e-mail, name, priority) and replies with what was sent. Look for it in the
/// Event Log; priority high comes out as a warning, a priority outside
/// low/normal/high fails the process.
Class test.app.bplplus.demo.sendNotification Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='test.app.bplplus.demo.registrationRequest' response='test.app.bplplus.demo.response' height='2000' width='2000' >
<sequence xend='200' yend='350' >
<code name='Send notification' languageOverride='objectscript' xpos='200' ypos='250' >
<![CDATA[
 // bplstep app.bplplus.examples.sendNotification - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.examples.sendNotification).%New()
 Set bplstep.Recipient = request.Email
 Set bplstep.Subject = "Hello "_request.Name
 Set bplstep.MessageText = "This is a demo notification."
 Set bplstep.Priority = $Select(request.Priority="":"normal",1:request.Priority)
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
