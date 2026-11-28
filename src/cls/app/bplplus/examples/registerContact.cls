/// Example of Call process: registers a contact sent as "e-mail, phone" in an
/// Ens.StringRequest. It keeps the contact in context.contact and gives that to
/// app.bplplus.examples.cleanContact as Aux; that process, which is not in the
/// production, fills in PhoneE164, PhoneValid and EmailValid of the very same
/// contact. The reply is the phone number in international form and whether
/// the e-mail address is valid.
Class app.bplplus.examples.registerContact Extends Ens.BusinessProcessBPL [ DependsOn = (app.bplplus.examples.contact, app.bplplus.call.callProcess) ]
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Ens.StringRequest' response='Ens.StringResponse' height='2000' width='2000' >
<context>
<property name='contact' type='app.bplplus.examples.contact' instantiate='1' />
<property name='CallProcessSuccess' type='%Boolean' instantiate='0' />
<property name='CallProcessResultText' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='1000' />
</parameters>
</property>
</context>
<sequence xend='200' yend='550' >
<code name='Split the request' xpos='200' ypos='250' >
<![CDATA[
 Set context.contact.Email = $ZStrip($Piece(request.StringValue, ",", 1), "<>W")
 Set context.contact.Phone = $ZStrip($Piece(request.StringValue, ",", 2, *), "<>W")
]]>
</code>
<code name='Call process' languageOverride='objectscript' xpos='200' ypos='350' >
<![CDATA[
 // bplstep app.bplplus.call.callProcess - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.call.callProcess).%New()
 Set bplstep.Target = "app.bplplus.examples.cleanContact"
 Set bplstep.Aux = context.contact
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set context.CallProcessSuccess = bplstepResult.Success
 Set context.CallProcessResultText = bplstepResult.ResultText
]]>
</code>
<code name='Reply' xpos='200' ypos='450' >
<![CDATA[
 Set response.StringValue = $Select(context.contact.PhoneValid: context.contact.PhoneE164, 1: "no valid phone number")_", e-mail "_$Select(context.contact.EmailValid: "valid", 1: "not valid")
]]>
</code>
</sequence>
</process>
}

}
