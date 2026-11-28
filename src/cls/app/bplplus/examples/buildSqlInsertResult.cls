/// Result of Build SQL insert: the statements and how many there are.
Class app.bplplus.examples.buildSqlInsertResult Extends app.bplplus.activityResult
{

/// The INSERT statements, one per record, separated by line ends (CR LF),
/// rewound and ready to read. A stream, as a large batch of records does not
/// fit in a string (3.6 MB at most).
Property Statements As %Stream.GlobalCharacter;

/// Number of records, and so of statements.
Property RecordCount As %Integer;

}
