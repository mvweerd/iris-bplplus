/// Demo of Fuzzy match, an activity written in Python: finds the known supplier
/// the request's text means, typos and all, and replies with it and how alike
/// they are. A name that resembles none of them well enough is a normal
/// outcome: Success is 0, and the reply names the closest one.
Class test.app.bplplus.demo.fuzzyMatch Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='test.app.bplplus.demo.textRequest' response='test.app.bplplus.demo.response' height='2000' width='2000' >
<sequence xend='200' yend='350' >
<code name='Fuzzy match' languageOverride='objectscript' xpos='200' ypos='250' >
<![CDATA[
 // bplstep app.bplplus.examples.fuzzyMatch - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.examples.fuzzyMatch).%New()
 Set bplstep.Value = request.Text
 Set bplstep.Candidates = "Acme Foods B.V.;Globex Trading;Initech Supplies;Umbrella Logistics"
 Set bplstep.MinimumScore = 0.8
 Set bplstep.IgnoreCase = 1
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
