/// Example of Call process with a message: receives an order over HTTP, as an
/// EnsLib.HTTP.GenericMessage from an EnsLib.HTTP.GenericService. It gives that
/// very message to app.bplplus.examples.checkOrder as Aux and stores the
/// response, also an EnsLib.HTTP.GenericMessage, in context.check. A good order
/// is accepted: logged, and answered with 202 Accepted. Anything else gets the
/// status and error of checkOrder. context.check is cleared once it is used,
/// as a message left in the context would be stored with it.
Class app.bplplus.examples.receiveOrder Extends Ens.BusinessProcessBPL [ DependsOn = (app.bplplus.call.callProcess, app.bplplus.examples.checkOrder) ]
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='EnsLib.HTTP.GenericMessage' response='EnsLib.HTTP.GenericMessage' height='2000' width='2000' >
<context>
<property name='check' type='EnsLib.HTTP.GenericMessage' instantiate='0' />
<property name='CallProcessSuccess' type='%Boolean' instantiate='0' />
<property name='CallProcessResultText' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='1000' />
</parameters>
</property>
</context>
<sequence xend='200' yend='450' >
<code name='Call process' languageOverride='objectscript' xpos='200' ypos='250' >
<![CDATA[
 // bplstep app.bplplus.call.callProcess - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.call.callProcess).%New()
 Set bplstep.Target = "app.bplplus.examples.checkOrder"
 Set bplstep.Aux = request
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set context.CallProcessSuccess = bplstepResult.Success
 Set context.CallProcessResultText = bplstepResult.ResultText
 Set context.check = bplstepResult.Response
]]>
</code>
<code name='Accept or refuse' xpos='200' ypos='350' >
<![CDATA[
 Set statusLine = context.check.HTTPHeaders.GetAt("StatusLine")
 Do context.check.Stream.Rewind()
 Set answer = {}.%FromJSON(context.check.Stream)
 If $Piece(statusLine, " ", 2) = 200 {
   $$$LOGINFO("Order "_answer.orderId_" accepted: "_answer.lines_" lines, total "_answer.total)
   Set answer.status = "accepted"
   Set statusLine = "HTTP/1.1 202 Accepted"
 }
 Set response.Stream = ##class(%Stream.GlobalCharacter).%New()
 Do response.Stream.Write(answer.%ToJSON())
 Do response.HTTPHeaders.SetAt(statusLine, "StatusLine")
 Do response.HTTPHeaders.SetAt("application/json", "Content-Type")
 // Done with it: a message left in the context is stored with the context.
 Set context.check = ""
]]>
</code>
</sequence>
</process>
}

}
