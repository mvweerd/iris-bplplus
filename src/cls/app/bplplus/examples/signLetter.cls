/// Example of a process that Call process calls with a stream: its request is
/// a %Stream.Object, the very letter of the process that calls it (Aux). It
/// adds a closing and a signature to the end of that letter, so the caller
/// reads them back in its own stream. See app.bplplus.examples.writeLetter.
/// <p>
/// A stream is not a message, so a process whose request is a stream can be
/// called; it cannot be put in a production.
Class app.bplplus.examples.signLetter Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='%Stream.Object' height='2000' width='2000' >
<sequence xend='200' yend='450' >
<code name='Add closing' xpos='200' ypos='250' >
<![CDATA[
 Do request.MoveToEnd()
 Do request.Write($Char(10, 10)_"Kind regards,")
]]>
</code>
<code name='Add signature' xpos='200' ypos='350' >
<![CDATA[
 Do request.Write($Char(10)_"The registration desk")
]]>
</code>
</sequence>
</process>
}

}
