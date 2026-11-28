/// Demo production for the custom activities: the registration process that
/// combines three of them, and one small process per example activity
/// (category Examples). The activities run inside the processes, so there is no
/// other item. Demo Call process runs test.app.bplplus.demo.callee, which is not
/// an item either. Testing is enabled, so the process can be tried from the
/// portal's Testing Service.
Class test.app.bplplus.demo.production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="test.app.bplplus.demo.production" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description>Custom BPL activities demo</Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="Demo registration" Category="" ClassName="test.app.bplplus.demo.registration" PoolSize="1" Enabled="true" Foreground="false" Comment="Validates and confirms a registration" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo Send notification" Category="Examples" ClassName="test.app.bplplus.demo.sendNotification" PoolSize="1" Enabled="true" Foreground="false" Comment="One Send notification step" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo Validate value" Category="Examples" ClassName="test.app.bplplus.demo.validateValue" PoolSize="1" Enabled="true" Foreground="false" Comment="Checks a Dutch postcode" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo Handle error" Category="Examples" ClassName="test.app.bplplus.demo.handleError" PoolSize="1" Enabled="true" Foreground="false" Comment="A failing step caught by Handle error, with an alert" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo Check response" Category="Examples" ClassName="test.app.bplplus.demo.checkResponse" PoolSize="1" Enabled="true" Foreground="false" Comment="Checks Result/Message of a service answer" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo Build SQL insert" Category="Examples" ClassName="test.app.bplplus.demo.buildSqlInsert" PoolSize="1" Enabled="true" Foreground="false" Comment="INSERT statements from XML rows" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo Fuzzy match" Category="Examples" ClassName="test.app.bplplus.demo.fuzzyMatch" PoolSize="1" Enabled="true" Foreground="false" Comment="An activity written in Python: finds the supplier a typed name means" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo Normalize phone (Python)" Category="Examples" ClassName="test.app.bplplus.demo.normalizePhonePython" PoolSize="1" Enabled="true" Foreground="false" Comment="An activity in a plain Python module: a typed phone number in international form" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo Call process" Category="Examples" ClassName="test.app.bplplus.demo.callProcess" PoolSize="1" Enabled="true" Foreground="false" Comment="Runs test.app.bplplus.demo.callee, which is not in the production, with its whole context" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Example register contact" Category="Examples" ClassName="app.bplplus.examples.registerContact" PoolSize="1" Enabled="true" Foreground="false" Comment="The example of Call process: has app.bplplus.examples.cleanContact, not in the production, clean up a contact" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Example write letter" Category="Examples" ClassName="app.bplplus.examples.writeLetter" PoolSize="1" Enabled="true" Foreground="false" Comment="The example of Call process with a stream: has app.bplplus.examples.signLetter, not in the production, sign a letter" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Example receive order" Category="Examples" ClassName="app.bplplus.examples.receiveOrder" PoolSize="1" Enabled="true" Foreground="false" Comment="The example of Call process with a message: has app.bplplus.examples.checkOrder check an order that came in over HTTP" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo Normalize phone (ObjectScript)" Category="Examples" ClassName="test.app.bplplus.demo.normalizePhoneObjectScript" PoolSize="1" Enabled="true" Foreground="false" Comment="The same activity in ObjectScript, to compare with the Python one" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}
