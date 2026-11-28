/// Demo of Check response: the request's text plays the answer of a SOAP service
/// (in a real process: the stream of the call's response). The step checks that
/// Result/Message in it is OK, namespaces ignored. With FailOnMismatch = 0 an
/// answer that says something else is a normal outcome (Success 0) and the reply
/// names what the service said; with 1 the process would fail.
Class test.app.bplplus.demo.checkResponse Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='test.app.bplplus.demo.textRequest' response='test.app.bplplus.demo.response' height='2000' width='2000' >
<context>
<property name='Answer' type='%Stream.GlobalCharacter' instantiate='1' />
<property name='Found' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='1000' />
</parameters>
</property>
</context>
<sequence xend='200' yend='450' >
<code name='Answer as a stream' xpos='200' ypos='250' >
<![CDATA[
 Do context.Answer.Write(request.Text)
]]>
</code>
<code name='Check response' languageOverride='objectscript' xpos='200' ypos='350' >
<![CDATA[
 // bplstep app.bplplus.examples.checkResponse - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.examples.checkResponse).%New()
 Set bplstep.Response = context.Answer
 Set bplstep.ElementPath = "Result/Message"
 Set bplstep.ExpectedValue = "OK"
 Set bplstep.ErrorText = "The service refused the request"
 Set bplstep.FailOnMismatch = 0
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set response.Success = bplstepResult.Success
 Set response.ResultText = bplstepResult.ResultText
 Set context.Found = bplstepResult.FoundValue
]]>
</code>
</sequence>
</process>
}

}
