/// Checks a value in an XML response, such as the status a SOAP or REST service
/// answers with, and fails when it is not the expected one. Without this a call
/// that the other side refused still counts as done: an HTTP 200 with
/// &lt;Message&gt;Error&lt;/Message&gt; in the body is not an error to the
/// production.
/// <p>
/// The value is found by element names only, ignoring namespaces and prefixes,
/// so a SOAP envelope needs no prefix mappings: ElementPath "Result/Message"
/// finds the first Message element directly inside a Result element, wherever
/// that is in the document.
Class app.bplplus.examples.checkResponse Extends app.bplplus.activity
{

Parameter ACTIVITYCAPTION = "Check response";

Parameter ACTIVITYCOLOR = "#FFF8E1";

Parameter ACTIVITYRESULT = "app.bplplus.examples.checkResponseResult";

/// The response to check, as a stream: for example the stream of the response
/// message of the call before this step.
Property Response As %Stream.Object [ Required ];

/// Element names leading to the value, separated by slashes, without namespace
/// prefixes, for example "Result/Message". It is matched against the end of
/// the element's path, so the leading elements can be left out.
Property ElementPath As %String(MAXLEN = 500) [ Required ];

/// The value the element must have, for example "OK". Compared after removing
/// leading and trailing white space.
Property ExpectedValue As %String(MAXLEN = 500) [ InitialExpression = "OK" ];

/// What went wrong, in words, put in front of the error, for example "NAF
/// refused the article".
Property ErrorText As %String(MAXLEN = 500) [ InitialExpression = "Unexpected response" ];

/// 1 fails the step when the value differs or the element is missing, so the
/// process raises a fault; 0 only sets Success to 0, for a process that branches
/// on it.
Property FailOnMismatch As %Boolean [ InitialExpression = 1 ];

/// Finds the value and compares it.
Method Execute(pProcess As Ens.BusinessProcess, Output pResult As app.bplplus.examples.checkResponseResult) As %Status
{
	Set pResult = ##class(app.bplplus.examples.checkResponseResult).%New()
	Set tSC = ..FindValue(..Response, ..ElementPath, .tFound, .tValue)
	If $$$ISERR(tSC) {
		Set pResult = ""
		Quit $$$ADDSC($$$ERROR($$$GeneralError, ..ErrorText_": the response is not readable XML"), tSC)
	}
	Set tValue = $ZStrip(tValue, "<>WC")
	Set pResult.FoundValue = tValue
	If tFound && (tValue = ..ExpectedValue) {
		Set pResult.Success = 1
		Set pResult.ResultText = ..ElementPath_" is "_tValue
		Quit $$$OK
	}
	Set tText = ..ErrorText_": "_$Select(tFound: ..ElementPath_" is '"_tValue_"', expected '"_..ExpectedValue_"'", 1: ..ElementPath_" is not in the response")
	If ..FailOnMismatch {
		Set pResult = ""
		Quit $$$ERROR($$$GeneralError, tText)
	}
	Set pResult.Success = 0
	Set pResult.ResultText = tText
	Quit $$$OK
}

/// Finds the text of the first element whose path ends in <var>pPath</var>
/// (element names separated by slashes, namespaces ignored) in XML stream
/// <var>pStream</var>. <var>pFound</var> says whether there is such an element; an
/// empty element is found with value "".
ClassMethod FindValue(pStream As %Stream.Object, pPath As %String, Output pFound As %Boolean, Output pValue As %String) As %Status
{
	Set pFound = 0, pValue = ""
	Set tWanted = $ListFromString($ZStrip(pPath, "<>W", "/"), "/")
	Set tWantedCount = $ListLength(tWanted)
	If tWantedCount = 0 Quit $$$OK
	If $IsObject(pStream) Do pStream.Rewind()
	Set tSC = ##class(%XML.TextReader).ParseStream(pStream, .tReader)
	If $$$ISERR(tSC) Quit tSC
	// %XML.TextReader gives an element's text the element's own Depth, and its
	// end one less.
	Set tTarget = ""
	While tReader.Read() {
		If tReader.NodeType = "element" {
			If tTarget '= "" Quit
			Set tDepth = tReader.Depth
			Set tName = tReader.LocalName
			If tName = "" Set tName = $Piece(tReader.Name, ":", *)
			Set tStack(tDepth) = tName
			Kill tStack(tDepth + 1)
			Set tMatch = (tDepth >= tWantedCount)
			For i = 1:1:tWantedCount {
				Quit:'tMatch
				If $Get(tStack(tDepth - tWantedCount + i)) '= $List(tWanted, i) Set tMatch = 0
			}
			If tMatch {
				Set pFound = 1, tTarget = tDepth
			}
		}
		ElseIf (tTarget '= "") && ((tReader.NodeType = "chars") || (tReader.NodeType = "cdata")) {
			If tReader.Depth >= tTarget Set pValue = pValue_tReader.Value
		}
		ElseIf (tTarget '= "") && (tReader.NodeType = "endelement") && (tReader.Depth < tTarget) {
			Quit
		}
	}
	Quit $$$OK
}

}
