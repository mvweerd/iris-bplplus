/// Example of Call process with a stream: writes a letter to the name sent in
/// an Ens.StringRequest. It writes the letter in context.letter, a stream, and
/// gives that stream to app.bplplus.examples.signLetter as Aux; that process,
/// which is not in the production, adds a closing and a signature to the very
/// same stream. The reply is the whole letter.
Class app.bplplus.examples.writeLetter Extends Ens.BusinessProcessBPL [ DependsOn = (app.bplplus.call.callProcess, app.bplplus.examples.signLetter) ]
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Ens.StringRequest' response='Ens.StringResponse' height='2000' width='2000' >
<context>
<property name='letter' type='%Stream.GlobalCharacter' instantiate='0' />
<property name='CallProcessSuccess' type='%Boolean' instantiate='0' />
<property name='CallProcessResultText' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='1000' />
</parameters>
</property>
</context>
<sequence xend='200' yend='550' >
<code name='Write the letter' xpos='200' ypos='250' >
<![CDATA[
 Do context.letter.Write("Dear "_$ZStrip(request.StringValue, "<>W")_","_$Char(10, 10)_"Thank you for registering.")
]]>
</code>
<code name='Call process' languageOverride='objectscript' xpos='200' ypos='350' >
<![CDATA[
 // bplstep app.bplplus.call.callProcess - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.call.callProcess).%New()
 Set bplstep.Target = "app.bplplus.examples.signLetter"
 Set bplstep.Aux = context.letter
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set context.CallProcessSuccess = bplstepResult.Success
 Set context.CallProcessResultText = bplstepResult.ResultText
]]>
</code>
<code name='Reply' xpos='200' ypos='450' >
<![CDATA[
 Do context.letter.Rewind()
 Set response.StringValue = context.letter.Read(32000)
]]>
</code>
</sequence>
</process>
}

}
