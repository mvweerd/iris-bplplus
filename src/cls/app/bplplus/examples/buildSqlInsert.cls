/// Builds one SQL INSERT statement per record of an XML document, with the
/// values quoted and checked, instead of gluing them into the statement by hand.
/// Hand-built statements go wrong in ways that only show in the target system:
/// text without quotes, more values than columns, a misspelt field name that
/// silently becomes an empty value. Here a column list drives both the columns
/// and the values, a missing field is an error that names it, text is quoted
/// with its quotes doubled, and a numeric column only accepts numbers.
/// <p>
/// The records are the elements named RecordElement; each child element of a
/// record is a field. The statements end up in the result as a stream,
/// separated by line ends, to write to a file or to send one by one.
Class app.bplplus.examples.buildSqlInsert Extends app.bplplus.activity
{

Parameter ACTIVITYCAPTION = "Build SQL insert";

Parameter ACTIVITYCOLOR = "#EDE7F6";

Parameter ACTIVITYRESULT = "app.bplplus.examples.buildSqlInsertResult";

/// The XML with the records, as a stream: for example the output of the XSLT
/// before this step.
Property Source As %Stream.Object [ Required ];

/// Name of the record elements, without namespace prefix, for example "record".
Property RecordElement As %String(MAXLEN = 250) [ Required ];

/// Table the rows go into, for example "ORDERS".
Property TableName As %String(MAXLEN = 250) [ Required ];

/// The columns, comma-separated, in the order of the statement. A column is
/// filled from the field of the same name, or from another field with
/// COLUMN=FIELD, for example "ORDER_ID=OrderId,AMOUNT,REMARK".
Property Columns As %String(MAXLEN = "") [ Required ];

/// Columns, comma-separated, whose values are numbers: written without quotes,
/// and a value that is not a number fails the step. Every other column is text.
Property NumericColumns As %String(MAXLEN = "");

/// 1 writes an empty field as NULL; 0 writes it as an empty text, '' (numeric
/// columns always get NULL).
Property EmptyAsNull As %Boolean [ InitialExpression = 1 ];

/// Builds the statements. Fails, naming record and field, when a record lacks a
/// field or a numeric column gets something else than a number, so no statement
/// is written for a broken record.
Method Execute(pProcess As Ens.BusinessProcess, Output pResult As app.bplplus.examples.buildSqlInsertResult) As %Status
{
	Set pResult = ##class(app.bplplus.examples.buildSqlInsertResult).%New()
	Set tSC = ..ParseColumns(..Columns, .tColumns, .tFields)
	If $$$ISERR(tSC) {
		Set pResult = ""
		Quit tSC
	}
	Set tNumeric = $ListFromString($Translate(..NumericColumns, " ", ""), ",")
	Set tSC = ..ReadRecords(..Source, ..RecordElement, .tRecords)
	If $$$ISERR(tSC) {
		Set pResult = ""
		Quit $$$ADDSC($$$ERROR($$$GeneralError, "Build SQL insert: the source is not readable XML"), tSC)
	}
	Set tHead = "INSERT INTO "_..TableName_" ("_$ListToString(tColumns, ", ")_") VALUES ("
	Set tStatements = ##class(%Stream.GlobalCharacter).%New()
	For tRec = 1:1:$Get(tRecords) {
		Set tValues = ""
		For i = 1:1:$ListLength(tColumns) {
			Set tColumn = $List(tColumns, i), tField = $List(tFields, i)
			If '$Data(tRecords(tRec, tField), tValue) {
				Set pResult = ""
				Return $$$ERROR($$$GeneralError, "Build SQL insert: record "_tRec_" has no field "_tField_" (column "_tColumn_")")
			}
			Set tValue = $ZStrip(tValue, "<>W")
			If $ListFind(tNumeric, tColumn) {
				If tValue = "" {
					Set tValue = "NULL"
				}
				ElseIf '$IsValidNum(tValue) {
					Set pResult = ""
					Return $$$ERROR($$$GeneralError, "Build SQL insert: record "_tRec_", column "_tColumn_" is numeric but has '"_tValue_"'")
				}
				Else {
					Set tValue = +tValue
				}
			}
			ElseIf (tValue = "") && ..EmptyAsNull {
				Set tValue = "NULL"
			}
			Else {
				Set tValue = "'"_$Replace(tValue, "'", "''")_"'"
			}
			Set tValues = tValues_$ListBuild(tValue)
		}
		If tRec > 1 Do tStatements.Write($Char(13, 10))
		Do tStatements.Write(tHead_$ListToString(tValues, ", ")_")")
	}
	Do tStatements.Rewind()
	Set pResult.Statements = tStatements
	Set pResult.RecordCount = +$Get(tRecords)
	Set pResult.ResultText = pResult.RecordCount_" insert statement(s) for "_..TableName
	Quit $$$OK
}

/// Splits <var>pColumns</var> ("COL", "COL=FIELD", comma-separated) into lists of
/// column names and field names. A column that is listed twice, or a name with
/// characters an SQL name cannot have, fails, as either is a typing error.
ClassMethod ParseColumns(pColumns As %String, Output pColumnList As %List, Output pFieldList As %List) As %Status
{
	Set pColumnList = "", pFieldList = ""
	For i = 1:1:$Length(pColumns, ",") {
		Set tItem = $ZStrip($Piece(pColumns, ",", i), "<>W")
		If tItem = "" Continue
		Set tColumn = $ZStrip($Piece(tItem, "=", 1), "<>W")
		Set tField = $ZStrip($Piece(tItem, "=", 2, *), "<>W")
		If tField = "" Set tField = tColumn
		If '$Match(tColumn, "[A-Za-z_][A-Za-z0-9_$#@]*") {
			Quit:$Get(tError)'=""
			Set tError = "column name '"_tColumn_"' is not a valid SQL name"
		}
		If $ListFind(pColumnList, tColumn) {
			Quit:$Get(tError)'=""
			Set tError = "column "_tColumn_" is listed twice"
		}
		Set pColumnList = pColumnList_$ListBuild(tColumn), pFieldList = pFieldList_$ListBuild(tField)
	}
	If $Get(tError) '= "" Quit $$$ERROR($$$GeneralError, "Build SQL insert, Columns: "_tError)
	If pColumnList = "" Quit $$$ERROR($$$GeneralError, "Build SQL insert, Columns: no columns given")
	Quit $$$OK
}

/// Reads the records of XML stream <var>pStream</var>: every element named
/// <var>pRecordElement</var> (namespaces ignored) becomes
/// <var>pRecords</var>(n, field) = text, for each of its child elements;
/// <var>pRecords</var> is the number of records.
ClassMethod ReadRecords(pStream As %Stream.Object, pRecordElement As %String, Output pRecords) As %Status
{
	Kill pRecords
	Set pRecords = 0
	If $IsObject(pStream) Do pStream.Rewind()
	Set tSC = ##class(%XML.TextReader).ParseStream(pStream, .tReader)
	If $$$ISERR(tSC) Quit tSC
	// %XML.TextReader gives an element's text the element's own Depth, and its
	// end one less: a field's end is at the record's depth, the record's end
	// one above it.
	Set tRecordDepth = "", tField = ""
	While tReader.Read() {
		Set tType = tReader.NodeType
		Set tName = tReader.LocalName
		If tName = "" Set tName = $Piece(tReader.Name, ":", *)
		If tType = "element" {
			If (tRecordDepth = "") && (tName = pRecordElement) {
				Set tRecordDepth = tReader.Depth
				Set pRecords = pRecords + 1
			}
			ElseIf (tRecordDepth '= "") && (tReader.Depth = (tRecordDepth + 1)) {
				Set tField = tName
				Set pRecords(pRecords, tField) = ""
			}
		}
		ElseIf ((tType = "chars") || (tType = "cdata")) && (tField '= "") {
			Set pRecords(pRecords, tField) = pRecords(pRecords, tField)_tReader.Value
		}
		ElseIf tType = "endelement" {
			If (tRecordDepth '= "") && (tReader.Depth = tRecordDepth) Set tField = ""
			If (tRecordDepth '= "") && (tReader.Depth < tRecordDepth) Set tRecordDepth = "", tField = ""
		}
	}
	Quit $$$OK
}

}
