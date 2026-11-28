/// Finds the candidate that looks most like a value, such as the supplier a
/// typed name means ("Acme Fods BV" is "Acme Foods B.V."), and says how alike
/// they are. Written in Python: difflib from its standard library does the
/// comparing, which ObjectScript has no equivalent for.
/// <p>
/// Below MinimumScore there is no match: Success is 0, a normal outcome the
/// process can branch on, and BestMatch still names the closest candidate.
Class app.bplplus.examples.fuzzyMatch Extends app.bplplus.python.activity
{

Parameter ACTIVITYCAPTION = "Fuzzy match";

Parameter ACTIVITYCOLOR = "#E0F7FA";

Parameter ACTIVITYRESULT = "app.bplplus.examples.fuzzyMatchResult";

/// The value to look up, for example a supplier name as typed in an order.
Property Value As %String(MAXLEN = 1000) [ Required ];

/// The candidates, separated by semicolons or line ends, for example
/// "Acme Foods B.V.;Globex Trading;Initech Supplies".
Property Candidates As %String(MAXLEN = "") [ Required ];

/// The lowest similarity, from 0 to 1, that counts as a match.
Property MinimumScore As %Numeric(MAXVAL = 1, MINVAL = 0) [ InitialExpression = 0.8 ];

/// 1 compares without regard to case, punctuation and extra spaces, so
/// "ACME foods bv" and "Acme Foods B.V." count as the same.
Property IgnoreCase As %Boolean [ InitialExpression = 1 ];

/// Scores every candidate against Value and keeps the best.
Method Perform(process As Ens.BusinessProcess, result As app.bplplus.activityResult) [ Language = python ]
{
    import difflib, re

    candidates = [c.strip() for c in re.split(r"[;\r\n]+", self.Candidates or "") if c.strip()]
    if not candidates:
        raise ValueError("Candidates is empty: give at least one, separated by semicolons")

    def normal(text):
        if not self.IgnoreCase:
            return text.strip()
        return " ".join(re.sub(r"[^\w\s]", " ", text.lower()).split())

    value = normal(self.Value or "")
    best, score = None, 0.0
    for candidate in candidates:
        ratio = difflib.SequenceMatcher(None, value, normal(candidate)).ratio()
        if ratio > score:
            best, score = candidate, ratio

    minimum = float(self.MinimumScore)
    result.BestMatch = best
    result.Score = round(score, 3)
    result.Success = 1 if score >= minimum else 0
    if result.Success:
        result.ResultText = "%s (%d%%)" % (best, round(score * 100))
    else:
        result.ResultText = "No candidate is %d%% alike; the closest is %s (%d%%)" % (round(minimum * 100), best, round(score * 100))
}

}
