/// A text parameter with a magnifier in the designer, like a setting in the
/// production configuration: the button next to the field lists what the
/// search in CONTEXT finds, and picking one fills in the field (quoted, as the
/// field holds an expression).
/// <p>
/// CONTEXT has the form the Management Portal uses for settings, a class and
/// method of a context search (see Ens.ContextSearch) with optional parameters,
/// for example
/// <code>Property Target As app.bplplus.lookup(CONTEXT = "Ens.ContextSearch/ProductionItems?targets=1&amp;productionName=@productionId")</code>.
/// @productionId stands for the running production.
Class app.bplplus.lookup Extends %String
{

Parameter MAXLEN = 250;

/// The context search the magnifier runs, such as
/// "Ens.ContextSearch/BusinessOperations".
Parameter CONTEXT As STRING;

}
