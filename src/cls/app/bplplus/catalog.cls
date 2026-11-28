/// Lists the custom BPL activities of the current namespace, for the designer
/// page app.bplplus.classic.editor. An activity is any compiled, non-abstract subclass of
/// app.bplplus.activity; this class reads what the designer needs to show
/// it from the class definition, so there is no list to keep up to date.
Class app.bplplus.catalog [ Abstract ]
{

/// Class every custom activity extends.
Parameter BASECLASS = "app.bplplus.activity";

/// Class every activity result has to extend.
Parameter RESULTBASECLASS = "app.bplplus.activityResult";

/// Every activity in this namespace, sorted by caption, as an array of the
/// objects <method>Describe</method> returns, and the activities written as
/// plain Python classes, as bplplus.describe describes them (with a className
/// "python:module.Class" and a create expression). Activities that cannot be described
/// (not compiled, abstract) are left out rather than breaking the designer.
ClassMethod Activities() As %DynamicArray
{
	Set tList = []
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinitionQuery:SubclassOf")
	If $$$ISERR(tRS.Execute(..#BASECLASS)) Quit tList
	While tRS.Next() {
		Set tClass = tRS.GetData(1)
		Set tEntry = ..Describe(tClass)
		If $IsObject(tEntry) Set tSorted($ZConvert(tEntry.caption, "L"), tClass) = tEntry
	}
	// Activities written as plain Python classes (the package bplplus_steps),
	// described by Python itself. Without Embedded Python there are none.
	Try {
		If ##class(%Dictionary.CompiledClass).%ExistsId("app.bplplus.python.step") {
			Set tPython = ##class(%DynamicAbstractObject).%FromJSON(##class(app.bplplus.python.step).Catalog())
			Set tIter = tPython.%GetIterator()
			While tIter.%GetNext(.tKey, .tEntry) {
				Set tSorted($ZConvert(tEntry.caption, "L"), tEntry.className) = tEntry
			}
		}
	}
	Catch ex {
	}
	Set tCaption = ""
	For {
		Set tCaption = $Order(tSorted(tCaption))
		Quit:tCaption=""
		Set tClass = ""
		For {
			Set tClass = $Order(tSorted(tCaption, tClass), 1, tEntry)
			Quit:tClass=""
			Do tList.%Push(tEntry)
		}
	}
	Quit tList
}

/// Describes one activity class for the designer, or returns "" when
/// <var>pClass</var> is not a usable activity. The object has
/// <ul>
/// <li><b>className</b>, <b>caption</b>, <b>description</b> (first paragraph of
/// the class comment), <b>color</b>, <b>autoMap</b></li>
/// <li><b>resultClass</b>: ACTIVITYRESULT, or app.bplplus.activityResult when
/// that does not name a compiled result class</li>
/// <li><b>inputs</b> and <b>outputs</b>: the parameters and results, as
/// <method>Properties</method> returns them</li>
/// </ul>
ClassMethod Describe(pClass As %String) As %DynamicObject
{
	Set tDef = ##class(%Dictionary.CompiledClass).%OpenId(pClass)
	If '$IsObject(tDef) || tDef.Abstract Quit ""
	If '$ClassMethod(pClass, "%Extends", ..#BASECLASS) Quit ""
	If '$Parameter(pClass, "ACTIVITYLISTED") Quit ""

	Set tResult = $Parameter(pClass, "ACTIVITYRESULT")
	If (tResult = "") || '##class(%Dictionary.CompiledClass).%ExistsId(tResult) || '$ClassMethod(tResult, "%Extends", ..#RESULTBASECLASS) {
		Set tResult = ..#RESULTBASECLASS
	}
	Set tCaption = $Parameter(pClass, "ACTIVITYCAPTION")
	If tCaption = "" Set tCaption = $Piece(pClass, ".", *)

	Set tEntry = {}
	Set tEntry.className = pClass
	Set tEntry.caption = tCaption
	Set tEntry.description = ..FirstParagraph(tDef.Description)
	Set tEntry.color = $Parameter(pClass, "ACTIVITYCOLOR")
	Do tEntry.%Set("autoMap", +$Parameter(pClass, "ACTIVITYAUTOMAP"), "boolean")
	Set tEntry.resultClass = tResult
	Set tEntry.inputs = ..Properties(pClass, ..DesignerDefaults(pClass))
	Set tEntry.outputs = ..Properties(tResult)
	Quit tEntry
}

/// The properties of <var>pClass</var> that a process designer can fill in or
/// read: the inherited ones first, then the class's own, each in the order they
/// are declared. Left out are properties inherited from
/// % system classes, and private, internal, calculated and
/// multidimensional ones: the generated code cannot set them. Each entry has
/// <b>name</b>, <b>type</b>, <b>description</b>, <b>required</b>,
/// <b>default</b>, <b>valueList</b>, <b>displayList</b> and, when the property
/// sets one, <b>maxLen</b> (used for the context property a result is stored in).
/// <p>
/// <b>default</b> is the value the designer fills in: the entry for the property
/// in <var>pDefaults</var> when there is one, otherwise its InitialExpression
/// (which is already a valid BPL expression).
ClassMethod Properties(pClass As %String, pDefaults As %DynamicObject = "") As %DynamicArray
{
	Set tList = []
	Set tDef = ##class(%Dictionary.CompiledClass).%OpenId(pClass)
	If '$IsObject(tDef) Quit tList
	For i = 1:1:tDef.Properties.Count() {
		Set tProp = tDef.Properties.GetAt(i)
		If $Extract(tProp.Name) = "%" Continue
		If tProp.Private || tProp.Internal || tProp.Calculated || tProp.MultiDimensional Continue
		Set tOrigin = tProp.Origin
		If $Extract(tOrigin) = "%" Continue
		// Inherited properties first, then the class's own: sequence numbers
		// count per class, so they alone would mix the two.
		Set tOwn = (tOrigin = pClass)
		Set tOrdered(tOwn, +tProp.SequenceNumber, tProp.Name) = tProp
	}
	For tOwn = 0, 1 {
	Set tSeq = ""
	For {
		Set tSeq = $Order(tOrdered(tOwn, tSeq))
		Quit:tSeq=""
		Set tName = ""
		For {
			Set tName = $Order(tOrdered(tOwn, tSeq, tName), 1, tProp)
			Quit:tName=""
			Set tEntry = {}
			Set tEntry.name = tProp.Name
			Set tEntry.type = tProp.Type
			Set tEntry.description = ..FirstParagraph(tProp.Description)
			Do tEntry.%Set("required", +tProp.Required, "boolean")
			// The dictionary stores "no initial value" as the expression "".
			Set tDefault = tProp.InitialExpression
			Set tDefault = $Select(tDefault = """""": "", 1: tDefault)
			If $IsObject(pDefaults) && (pDefaults.%GetTypeOf(tProp.Name) = "string") {
				Set tDefault = pDefaults.%Get(tProp.Name)
			}
			Set tEntry.default = tDefault
			Set tEntry.valueList = tProp.Parameters.GetAt("VALUELIST")
			Set tEntry.displayList = tProp.Parameters.GetAt("DISPLAYLIST")
			// Defined, possibly empty (unlimited), only when the property sets it.
			If tProp.Parameters.IsDefined("MAXLEN") Set tEntry.maxLen = tProp.Parameters.GetAt("MAXLEN")
			// A parameter with a magnifier (see app.bplplus.lookup).
			If ..ContextOf(tProp) '= "" Do tEntry.%Set("lookup", 1, "boolean")
			Do tList.%Push(tEntry)
		}
	}
	}
	Quit tList
}

/// Base class of the parameter types that have a magnifier.
Parameter LOOKUPBASECLASS = "app.bplplus.lookup";

/// The context search of compiled property <var>pProp</var> (a
/// %Dictionary.CompiledProperty) when its type is app.bplplus.lookup or a
/// subclass: its CONTEXT parameter, or the type's. "" for any other property.
ClassMethod ContextOf(pProp As %Dictionary.CompiledProperty) As %String
{
	Set tDef = ##class(%Dictionary.CompiledClass).%OpenId(pProp.Type)
	If '$IsObject(tDef) || '(("~"_tDef.PrimarySuper_"~") [ ("~"_..#LOOKUPBASECLASS_"~")) Quit ""
	Set tContext = pProp.Parameters.GetAt("CONTEXT")
	If tContext = "" Set tContext = $Parameter(pProp.Type, "CONTEXT")
	Quit tContext
}

/// What the magnifier of parameter <var>pProperty</var> of activity
/// <var>pClass</var> lists: the Management Portal's context search
/// (%ZEN.Portal.ContextSearch) of its CONTEXT, with @productionId standing for
/// the running production. An object with <b>caption</b>, <b>top</b> (the top
/// results) and <b>other</b> (the remaining results), each an array of values;
/// empty when the parameter has no magnifier or the search fails. The search is
/// looked up from the activity, never taken from the caller, so a page can only
/// run the searches activities declare.
ClassMethod Choices(pClass As %String, pProperty As %String) As %DynamicObject
{
	Set tChoices = { "caption": "", "top": [], "other": [] }
	If ..Describe(pClass) = "" Quit tChoices
	Set tProp = ##class(%Dictionary.CompiledProperty).%OpenId(pClass_"||"_pProperty)
	If '$IsObject(tProp) Quit tChoices
	Set tContext = ..ContextOf(tProp)
	If tContext = "" Quit tChoices
	If tContext [ "@productionId" {
		Do ##class(Ens.Director).GetProductionStatus(.tProduction)
		Set tContext = $Replace(tContext, "@productionId", $Get(tProduction))
	}
	Try {
		Set tSC = ##class(%ZEN.Portal.ContextSearch).%Search(.tCaption, .tTop, .tResults, tContext, "")
		If $$$ISERR(tSC) Quit
		Set tChoices.caption = $Get(tCaption)
		Set tKey = ""
		For {
			Set tKey = $Order(tTop(tKey), 1, tValue)
			Quit:tKey=""
			Do tChoices.top.%Push(tValue)
			Set tIsTop(tValue) = ""
		}
		Set tKey = ""
		For {
			Set tKey = $Order(tResults(tKey), 1, tValue)
			Quit:tKey=""
			If '$Data(tIsTop(tValue)) Do tChoices.other.%Push(tValue)
		}
	}
	Catch ex {
	}
	Quit tChoices
}

/// The designer-only defaults of activity <var>pClass</var>: the JSON object in
/// its XData block ActivityDefaults, mapping property names to the BPL expression
/// to fill in, for example <code>{ "ErrorStatus": "context.%LastError" }</code>.
/// Use it for a default that refers to the process (request, context), which
/// InitialExpression cannot: that is evaluated when the activity object is created.
/// Returns an empty object when there is no such block or it is not valid JSON.
ClassMethod DesignerDefaults(pClass As %String) As %DynamicObject
{
	Set tDefaults = {}
	Set tXData = ##class(%Dictionary.CompiledXData).%OpenId(pClass_"||ActivityDefaults")
	If '$IsObject(tXData) Quit tDefaults
	Try {
		Set tParsed = ##class(%DynamicAbstractObject).%FromJSON(tXData.Data)
		If tParsed.%IsA("%DynamicObject") Set tDefaults = tParsed
	}
	Catch ex {
	}
	Quit tDefaults
}

/// First paragraph of a class or property comment as plain text: up to the first
/// blank line or &lt;p&gt;, with the remaining HTML tags removed, so it fits as a
/// tooltip or a line of help in the designer.
ClassMethod FirstParagraph(pText As %String) As %String
{
	Set tText = $Replace($Replace(pText, $Char(13), ""), "<p>", $Char(10, 10))
	Set tText = $Piece(tText, $Char(10, 10), 1)
	Set tOut = ""
	Set tInTag = 0
	For i = 1:1:$Length(tText) {
		Set c = $Extract(tText, i)
		If c = "<" { Set tInTag = 1 Continue }
		If c = ">" { Set tInTag = 0 Continue }
		If 'tInTag Set tOut = tOut_$Select(c = $Char(10): " ", 1: c)
	}
	Quit $ZStrip(tOut, "<>=W")
}

}
