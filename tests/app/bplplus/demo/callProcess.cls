/// Demo of Call process: puts the request's text in context.Name, writes a Note
/// stream and a Tags list, and runs test.app.bplplus.demo.callee, which is not in
/// the production, with the whole context as Aux. The callee writes Greeting,
/// Note and Tags straight into this context, and the demo replies with them.
Class test.app.bplplus.demo.callProcess Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='test.app.bplplus.demo.textRequest' response='test.app.bplplus.demo.response' height='2000' width='2000' >
<context>
<property name='Name' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='100' />
</parameters>
</property>
<property name='Greeting' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='200' />
</parameters>
</property>
<property name='Note' type='%Stream.GlobalCharacter' instantiate='0' />
<property name='Tags' type='%String' collection='list' instantiate='0' />
<property name='CallProcessSuccess' type='%Boolean' instantiate='0' />
<property name='CallProcessResultText' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='1000' />
</parameters>
</property>
</context>
<sequence xend='200' yend='550' >
<code name='Prepare' xpos='200' ypos='250' >
<![CDATA[
 Set context.Name = request.Text
 Do context.Note.Write("Note of the caller")
 Do context.Tags.Insert("caller")
]]>
</code>
<code name='Call process' languageOverride='objectscript' xpos='200' ypos='350' >
<![CDATA[
 // bplstep app.bplplus.call.callProcess - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.call.callProcess).%New()
 Set bplstep.Target = "test.app.bplplus.demo.callee"
 Set bplstep.Aux = context
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set context.CallProcessSuccess = bplstepResult.Success
 Set context.CallProcessResultText = bplstepResult.ResultText
]]>
</code>
<code name='Reply' xpos='200' ypos='450' >
<![CDATA[
 Set response.Success = context.CallProcessSuccess
 Do context.Note.Rewind()
 Set tags = "" For i = 1:1:context.Tags.Count() { Set tags = tags_$Select(i > 1: ",", 1: "")_context.Tags.GetAt(i) }
 Set response.ResultText = context.Greeting_" | "_context.Note.Read()_" | "_tags
]]>
</code>
</sequence>
</process>
}

}
