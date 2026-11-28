"""Tests of the Python side of custom activities, without IRIS:
python -m unittest discover -s tests/python"""
import json
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "src", "python"))

import bplplus  # noqa: E402
from bplplus import Activity, Param, Result  # noqa: E402
from bplplus_steps.phone import NormalizePhone  # noqa: E402


class Echo(Activity):
    """Repeats a text.

    Only used by these tests."""
    caption = "Echo"
    Text = Param(str, required=True, doc="What to repeat.")
    Times = Param(int, default=2)
    Loud = Param(bool, default=False)
    Mode = Param(str, default="plain", choices=["plain", "fancy"])
    Repeated = Result(str, doc="The repeated text.")

    def perform(self, process, result):
        text = self.Text.upper() if self.Loud else self.Text
        result.Repeated = " ".join([text] * self.Times)
        result.text = f"{self.Times} times"


def run(cls, **params):
    return json.loads(bplplus.run(bplplus.path_of(cls), json.dumps(params)))


class TestDescribe(unittest.TestCase):
    def test_fields_for_the_designer(self):
        d = bplplus.describe(Echo)
        self.assertEqual(d["className"], "python:" + __name__ + ".Echo")
        self.assertEqual(d["create"], '##class(app.bplplus.python.step).%New("' + __name__ + '.Echo")')
        self.assertEqual(d["description"], "Repeats a text.", "first paragraph only")
        self.assertEqual([i["name"] for i in d["inputs"]], ["Text", "Times", "Loud", "Mode"], "declaration order")
        text, times, loud, mode = d["inputs"]
        self.assertTrue(text["required"])
        self.assertEqual(times["type"], "%Library.Integer")
        self.assertEqual(times["default"], "2")
        self.assertEqual(loud["default"], "0")
        self.assertEqual(mode["default"], '"plain"', "text defaults are ObjectScript literals")
        self.assertEqual(mode["valueList"], ",plain,fancy")
        self.assertEqual([o["name"] for o in d["outputs"]], ["Success", "ResultText", "Repeated"])

    def test_catalog_lists_the_steps_package(self):
        captions = [d["caption"] for d in json.loads(bplplus.catalog())]
        self.assertIn("Normalize phone (Python)", captions)


class TestRun(unittest.TestCase):
    def test_converts_parameters_and_returns_results(self):
        out = run(Echo, Text="hi", Times="3", Loud="1")
        self.assertEqual(out["Repeated"], "HI HI HI")
        self.assertEqual(out["Success"], 1)
        self.assertEqual(out["ResultText"], "3 times")

    def test_defaults_for_empty_parameters(self):
        self.assertEqual(run(Echo, Text="hi", Times="")["Repeated"], "hi hi")

    def test_refuses_what_the_process_got_wrong(self):
        with self.assertRaisesRegex(ValueError, "Text is required"):
            run(Echo)
        with self.assertRaisesRegex(ValueError, "Times must be a int"):
            run(Echo, Text="hi", Times="many")
        with self.assertRaisesRegex(ValueError, "Mode must be one of plain, fancy"):
            run(Echo, Text="hi", Mode="loud")
        with self.assertRaisesRegex(ValueError, "has no parameter Txet"):
            run(Echo, Txet="hi")

    def test_refuses_what_is_not_an_activity(self):
        with self.assertRaises(TypeError):
            bplplus.run("json.JSONDecoder", "{}")


class TestNormalizePhone(unittest.TestCase):
    def check(self, typed, expected):
        out = run(NormalizePhone, Number=typed)
        self.assertEqual(out["E164"], expected, typed)
        self.assertEqual(out["Success"], 1 if expected else 0, typed)

    def test_dutch_numbers(self):
        self.check("06-12345678", "+31612345678")
        self.check("(020) 555 1234", "+31205551234")
        self.check("0031 6 1234 5678", "+31612345678")
        self.check("+31 6 12345678", "+31612345678")

    def test_other_countries(self):
        self.check("+49 30 123456", "+4930123456")
        out = run(NormalizePhone, Number="030 123456", CountryCode="49")
        self.assertEqual(out["E164"], "+4930123456")

    def test_not_a_phone_number(self):
        self.check("06-1234", None)
        self.check("call me", None)
        self.assertIn("Not a phone number", run(NormalizePhone, Number="06-1234")["ResultText"])


if __name__ == "__main__":
    unittest.main()
