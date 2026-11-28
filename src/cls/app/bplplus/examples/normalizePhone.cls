/// Turns a phone number as people type it into its international form
/// (E.164), such as 06-12345678 into +31612345678, so systems that match on
/// phone numbers find the same number however it was written.
/// <p>
/// The ObjectScript twin of the activity in the plain Python module
/// src/python/bplplus_steps/phone.py: the same parameters, results and answers,
/// to compare the two ways of writing an activity. A text that is not a phone
/// number is a negative outcome (Success 0), not an error.
Class app.bplplus.examples.normalizePhone Extends app.bplplus.activity
{

Parameter ACTIVITYCAPTION = "Normalize phone (ObjectScript)";

Parameter ACTIVITYCOLOR = "#FCE4EC";

Parameter ACTIVITYRESULT = "app.bplplus.examples.normalizePhoneResult";

/// Digits after the country code, per country code, as a list of code:length:
/// the Netherlands has 9. Other countries are checked against the E.164 limits
/// only.
Parameter NATIONALLENGTHS = "31:9";

/// The number as typed, for example 06-12345678, (020) 555 1234 or 0031 6 1234 5678.
Property Number As %String(MAXLEN = 100) [ Required ];

/// Country calling code for numbers without one, without + or 00; 31 is the Netherlands.
Property CountryCode As %String(MAXLEN = 4) [ InitialExpression = "31" ];

/// Keeps the digits (and a leading +), adds the country code where the number
/// has none, and checks the length.
Method Execute(pProcess As Ens.BusinessProcess, Output pResult As app.bplplus.examples.normalizePhoneResult) As %Status
{
	Set pResult = ##class(app.bplplus.examples.normalizePhoneResult).%New()
	Set tTyped = $ZStrip(..Number, "<>W")
	// Digits and +, nothing else: "(020) 555-1234" -> "0205551234".
	Set tDigits = $ZStrip(tTyped, "*E'N", "", "+")
	If $Extract(tDigits) = "+" {
		Set tNumber = $Extract(tDigits, 2, *)
	}
	ElseIf $Extract(tDigits, 1, 2) = "00" {
		Set tNumber = $Extract(tDigits, 3, *)
	}
	ElseIf $Extract(tDigits) = "0" {
		Set tNumber = ..CountryCode_$Extract(tDigits, 2, *)
	}
	Else {
		Set tNumber = ..CountryCode_tDigits
	}

	Set tValid = (tNumber ? 1.N) && ($Length(tNumber) >= 8) && ($Length(tNumber) <= 15)
	For i = 1:1:$Length(..#NATIONALLENGTHS, ",") {
		Set tCode = $Piece($Piece(..#NATIONALLENGTHS, ",", i), ":", 1)
		Set tLength = $Piece($Piece(..#NATIONALLENGTHS, ",", i), ":", 2)
		If tValid && ($Extract(tNumber, 1, $Length(tCode)) = tCode) {
			Set tValid = ($Length(tNumber) - $Length(tCode) = tLength)
		}
	}
	If 'tValid {
		Set pResult.Success = 0
		Set pResult.ResultText = "Not a phone number: "_tTyped
		Quit $$$OK
	}
	Set pResult.E164 = "+"_tNumber
	Set pResult.Success = 1
	Set pResult.ResultText = pResult.E164
	Quit $$$OK
}

}
