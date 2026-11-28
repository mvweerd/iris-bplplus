/// Demo of Build SQL insert: the request's text is XML with &lt;row&gt; records
/// (in a real process: the output of an XSLT). The step builds one INSERT per row
/// into ORDERS, text quoted, amounts checked as numbers. The statements come as a
/// stream, stored in context.SqlStatements; for the demo the reply carries them. A row without a field, or text in a numeric column, fails the
/// process with an error that names it.
Class test.app.bplplus.demo.buildSqlInsert Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='test.app.bplplus.demo.textRequest' response='test.app.bplplus.demo.response' height='2000' width='2000' >
<context>
<property name='Rows' type='%Stream.GlobalCharacter' instantiate='1' />
<property name='RowCount' type='%Integer' instantiate='0' />
<property name='SqlStatements' type='%Stream.GlobalCharacter' instantiate='0' />
</context>
<sequence xend='200' yend='550' >
<code name='Rows as a stream' xpos='200' ypos='250' >
<![CDATA[
 Do context.Rows.Write(request.Text)
]]>
</code>
<code name='Build SQL insert' languageOverride='objectscript' xpos='200' ypos='350' >
<![CDATA[
 // bplstep app.bplplus.examples.buildSqlInsert - written by the designer: change it there, not here
 Set bplstep = ##class(app.bplplus.examples.buildSqlInsert).%New()
 Set bplstep.Source = context.Rows
 Set bplstep.RecordElement = "row"
 Set bplstep.TableName = "ORDERS"
 Set bplstep.Columns = "ORDER_ID=ID, CUSTOMER=Name, AMOUNT=Amount, REMARK=Remark"
 Set bplstep.NumericColumns = "ORDER_ID,AMOUNT"
 Set bplstep.EmptyAsNull = 1
 Set status = bplstep.Run(process, .bplstepResult)
 If $$$ISERR(status) Quit
 Set response.Success = bplstepResult.Success
 Set context.SqlStatements = bplstepResult.Statements
 Set context.RowCount = bplstepResult.RecordCount
]]>
</code>
<code name='Statements in the reply' xpos='200' ypos='450' >
<![CDATA[
 Do context.SqlStatements.Rewind()
 Set response.ResultText = context.SqlStatements.Read(100000)
]]>
</code>
</sequence>
</process>
}

}
