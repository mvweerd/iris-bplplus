/// Demo of a process that Call process calls with the whole context of the
/// caller as Aux: its request is %Library.RegisteredObject, so any object, and
/// here it is the context of test.app.bplplus.demo.callProcess itself. It
/// greets the Name it finds there, adds to the Note stream and the Tags list, all
/// straight in that context.
Class test.app.bplplus.demo.callee Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='%Library.RegisteredObject' height='2000' width='2000' >
<sequence xend='200' yend='350' >
<code name='Greet' xpos='200' ypos='250' >
<![CDATA[
 Set request.Greeting = "Hello "_request.Name
 Do request.Note.MoveToEnd()
 Do request.Note.Write(" (seen by the callee)")
 Do request.Tags.Insert("callee")
]]>
</code>
</sequence>
</process>
}

}
