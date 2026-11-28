/// Demo process built from the two example activities: it validates the
/// e-mail address of a registration with "Validate value" and, when it is valid,
/// confirms it with "Send notification"; otherwise it traces the rejection.
/// The notification runs in a scope whose catchall uses "Handle error" to log a
/// failed notification as a warning, so the registration still succeeds: send a
/// Priority outside low/normal/high to see it happen.
/// <p>
/// The custom activities are the code activities app.bplplus.classic.editor writes:
/// open the process there to see them as steps with fields, and in the standard
/// designer to see the code.
Class test.app.bplplus.demo.registration Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='test.app.bplplus.demo.registrationRequest' response='test.app.bplplus.demo.response' height='2000' width='2000' >
<context>
<property name='EmailValid' type='%Boolean' instantiate='0' />
<property name='ValidationText' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='1000' />
</parameters>
</property>
</context>
<sequence xend='200' yend='1100' >
<code name='Validate value' languageOverride='objectscript' xpos='200' ypos='250' >
<![CDATA[
 // bplstep app.bplplus.examples.validateValue - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.examples.validateValue).%New()
 Set bplstep.Value = request.Email
 Set bplstep.Pattern = "[^@ ]+@[^@ ]+\.[A-Za-z]{2,}"
 Set bplstep.FailureText = "Not an e-mail address"
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set context.EmailValid = bplstepResult.Success
 Set context.ValidationText = bplstepResult.ResultText
]]>
</code>
<if name='E-mail valid?' condition='context.EmailValid' xpos='200' ypos='350' xend='200' yend='900' >
<true>
<scope name='Notify safely' xpos='335' ypos='450' xend='335' yend='800' >
<code name='Send notification' languageOverride='objectscript' xpos='335' ypos='550' >
<![CDATA[
 // bplstep app.bplplus.examples.sendNotification - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.examples.sendNotification).%New()
 Set bplstep.Recipient = request.Email
 Set bplstep.Subject = "Welcome "_request.Name
 Set bplstep.MessageText = "Your registration has been received."
 Set bplstep.Priority = $Select(request.Priority="":"normal",1:request.Priority)
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set response.Success = bplstepResult.Success
 Set response.ResultText = bplstepResult.ResultText
]]>
</code>
<faulthandlers>
<catchall name='Notification failed' xpos='335' ypos='650' xend='200' yend='350' >
<code name='Handle error' languageOverride='objectscript' xpos='200' ypos='250' >
<![CDATA[
 // bplstep app.bplplus.examples.handleError - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.examples.handleError).%New()
 Set bplstep.ErrorStatus = context.%LastError
 Set bplstep.ReturnAsError = 0
 Set bplstep.ErrorPrefix = "Notification"
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set response.ResultText = bplstepResult.ResultText
]]>
</code>
</catchall>
</faulthandlers>
</scope>
</true>
<false>
<trace name='Rejected' value='"Registration rejected: "_context.ValidationText' xpos='65' ypos='450' />
<assign name='Reply rejected' property="response.Success" value="0" action="set" xpos='65' ypos='500' />
</false>
</if>
<assign name='Reply text' property="response.ResultText" value="$Select(response.ResultText'=&quot;&quot;:response.ResultText,1:context.ValidationText)" action="set" xpos='200' ypos='1000' />
</sequence>
</process>
}

}
