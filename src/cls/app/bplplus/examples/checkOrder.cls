/// Example of a process that Call process calls with a message: it checks an
/// order that came in over HTTP, as an EnsLib.HTTP.GenericMessage from an
/// EnsLib.HTTP.GenericService, and answers with an EnsLib.HTTP.GenericMessage
/// that has the HTTP status and a JSON body. See
/// app.bplplus.examples.receiveOrder.
/// <p>
/// The order is a POST of JSON such as
/// {"orderId": "A-1001", "lines": [{"sku": "PEN-01", "quantity": 3, "price": 1.25}]}.
/// The answer is 200 with the order id, the number of lines and the total, or
/// 405, 415, 400 or 422 with what is wrong. Its request and response are
/// messages, so the same process also works as an item of a production.
Class app.bplplus.examples.checkOrder Extends Ens.BusinessProcessBPL
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='EnsLib.HTTP.GenericMessage' response='EnsLib.HTTP.GenericMessage' height='2000' width='2000' >
<context>
<property name='method' type='%String' instantiate='0' />
<property name='contentType' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='200' />
</parameters>
</property>
<property name='status' type='%String' instantiate='0' />
<property name='error' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='500' />
</parameters>
</property>
<property name='orderId' type='%String' instantiate='0' />
<property name='lineCount' type='%Integer' instantiate='0' />
<property name='total' type='%Numeric' instantiate='0' />
</context>
<sequence xend='200' yend='550' >
<code name='Read the headers' xpos='200' ypos='250' >
<![CDATA[
 // Header names come in as the client sent them, so compare them in lower case.
 Set key = "" For {
   Set value = request.HTTPHeaders.GetNext(.key) Quit:key=""
   Set name = $ZConvert(key, "L")
   If name = "httprequest" Set context.method = $ZConvert(value, "U")
   If name = "content-type" Set context.contentType = $ZConvert(value, "L")
 }
]]>
</code>
<code name='Check the order' xpos='200' ypos='350' >
<![CDATA[
 Set context.status = "200 OK", context.error = ""
 If context.method '= "POST" {
   Set context.status = "405 Method Not Allowed", context.error = "send the order with POST"
   Quit
 }
 If $Piece(context.contentType, ";") '= "application/json" {
   Set context.status = "415 Unsupported Media Type", context.error = "send the order as application/json"
   Quit
 }
 Try {
   Do request.Stream.Rewind()
   Set order = ##class(%DynamicAbstractObject).%FromJSON(request.Stream)
 } Catch {
   Set order = ""
 }
 If '$IsObject(order) || 'order.%IsA("%DynamicObject") {
   Set context.status = "400 Bad Request", context.error = "the body is not a JSON object"
   Quit
 }
 Set context.orderId = order.orderId
 If context.orderId = "" Set context.error = "orderId is missing"
 Set lines = order.lines
 If (context.error = "") && ('$IsObject(lines) || 'lines.%IsA("%DynamicArray") || (lines.%Size() = 0)) {
   Set context.error = "an order needs at least one line"
 }
 Set total = 0
 For i = 0:1:$Select(context.error = "": lines.%Size() - 1, 1: -1) {
   Set line = lines.%Get(i)
   If '$IsObject(line) || (line.sku = "") { Set context.error = "line "_(i + 1)_" has no sku" Quit }
   If (line.quantity '? 1.N) || (line.quantity < 1) { Set context.error = "line "_(i + 1)_": quantity has to be a whole number of 1 or more" Quit }
   If ('$IsValidNum(line.price)) || (line.price < 0) { Set context.error = "line "_(i + 1)_": price has to be a number of 0 or more" Quit }
   Set total = total + (line.quantity * line.price)
 }
 If context.error '= "" {
   Set context.status = "422 Unprocessable Content"
   Quit
 }
 Set context.lineCount = lines.%Size(), context.total = $FNumber(total, "", 2)
]]>
</code>
<code name='Answer' xpos='200' ypos='450' >
<![CDATA[
 If context.error = "" {
   Set answer = {"orderId": (context.orderId), "lines": (context.lineCount), "total": (+context.total)}
 } Else {
   Set answer = {"error": (context.error)}
 }
 Set response.Stream = ##class(%Stream.GlobalCharacter).%New()
 Do response.Stream.Write(answer.%ToJSON())
 Do response.HTTPHeaders.SetAt("HTTP/1.1 "_context.status, "StatusLine")
 Do response.HTTPHeaders.SetAt("application/json", "Content-Type")
]]>
</code>
</sequence>
</process>
}

}
