"""Example of a custom BPL activity in a plain Python module."""
import re

from bplplus import Activity, Param, Result


class NormalizePhone(Activity):
    """Turns a phone number as people type it into its international form
    (E.164), such as 06-12345678 into +31612345678, so systems that match on
    phone numbers find the same number however it was written.

    A text that is not a phone number is a negative outcome (success False),
    not an error. Its ObjectScript twin is app.bplplus.examples.normalizePhone.
    """

    caption = "Normalize phone (Python)"
    color = "#FCE4EC"

    Number = Param(str, required=True, doc="The number as typed, for example 06-12345678, (020) 555 1234 or 0031 6 1234 5678.")
    CountryCode = Param(str, default="31", doc="Country calling code for numbers without one, without + or 00; 31 is the Netherlands.")

    E164 = Result(str, doc="The number in international form, such as +31612345678; empty when the text is not a phone number.")

    # Digits after the country code: the Netherlands has 9; other countries are
    # checked against the E.164 limits only.
    NATIONAL_LENGTH = {"31": 9}

    def perform(self, process, result):
        typed = self.Number.strip()
        digits = re.sub(r"[^\d+]", "", typed)
        if digits.startswith("+"):
            number = digits[1:]
        elif digits.startswith("00"):
            number = digits[2:]
        elif digits.startswith("0"):
            number = self.CountryCode + digits[1:]
        else:
            number = self.CountryCode + digits

        country = next((code for code in self.NATIONAL_LENGTH if number.startswith(code)), None)
        valid = number.isdigit() and 8 <= len(number) <= 15
        if valid and country:
            valid = len(number) - len(country) == self.NATIONAL_LENGTH[country]
        if not valid:
            result.success = False
            result.text = f"Not a phone number: {typed}"
            return

        result.E164 = "+" + number
        result.success = True
        result.text = result.E164
