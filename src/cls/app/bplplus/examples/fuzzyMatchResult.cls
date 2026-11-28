/// Result of Fuzzy match: the closest candidate and how alike it is.
Class app.bplplus.examples.fuzzyMatchResult Extends app.bplplus.activityResult
{

/// The candidate most like the value, also when it is below MinimumScore.
Property BestMatch As %String(MAXLEN = 1000);

/// How alike BestMatch and the value are, from 0 (nothing) to 1 (the same).
Property Score As %Numeric(SCALE = 3);

}
