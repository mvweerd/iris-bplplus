"""Custom BPL activities written as plain Python classes.

A step is a class in a module of the package ``bplplus_steps``, deriving from
``Activity``. Its ``Param`` attributes are the fields the designers show, its
``Result`` attributes the results that can be stored in the process context,
and ``perform`` does the work::

    from bplplus import Activity, Param, Result

    class CountWords(Activity):
        \"\"\"Counts the words in a text.\"\"\"
        caption = "Count words"
        Text = Param(str, required=True, doc="The text to count the words of.")
        Count = Result(int, doc="The number of words.")

        def perform(self, process, result):
            result.Count = len(self.Text.split())
            result.text = f"{result.Count} words"

Both editors list such a class under Custom activities like an ObjectScript
activity; in the BPL it runs through the ObjectScript class
app.bplplus.python.step, which calls ``run`` below. Names are the ones the
designers show, so they follow IRIS's style (Text, Count) rather than
snake_case.

The module is plain Python: everything but ``process`` (the business process)
works, and can be tested, without IRIS.
"""
import importlib
import inspect
import json
import pkgutil
import sys

STEPS_PACKAGE = "bplplus_steps"
RUNNER_CLASS = "app.bplplus.python.step"
RESULT_CLASS = "app.bplplus.python.stepResult"
_IRIS_TYPES = {str: "%Library.String", int: "%Library.Integer", float: "%Library.Numeric", bool: "%Library.Boolean"}


class Param:
    """A parameter of an activity: a field in the designer, and an attribute
    of the activity in ``perform``, converted to ``type``."""

    def __init__(self, type=str, default=None, required=False, doc="", choices=None):
        self.type = type
        self.default = default
        self.required = required
        self.doc = doc
        self.choices = list(choices or [])

    def convert(self, name, value):
        """``value`` as the process passed it (text or a number), as ``type``;
        the default when it is empty."""
        if value is None or value == "":
            return self.default
        if self.type is bool:
            return str(value).strip().lower() in ("1", "true", "yes")
        try:
            converted = self.type(value)
        except (TypeError, ValueError):
            raise ValueError(f"{name} must be a {self.type.__name__}, not {value!r}") from None
        if self.choices and converted not in self.choices:
            raise ValueError(f"{name} must be one of {', '.join(map(str, self.choices))}, not {converted!r}")
        return converted


class Result:
    """A result of an activity: set it on ``result`` in ``perform``."""

    def __init__(self, type=str, doc=""):
        self.type = type
        self.doc = doc


class Outcome:
    """What ``perform`` fills in: ``success`` and ``text``, which every activity
    has, and an attribute per declared ``Result``, None until set."""

    def __init__(self, names):
        self.success = True
        self.text = ""
        for name in names:
            setattr(self, name, None)


class Activity:
    """Base class of a custom BPL activity in Python.

    Class attributes: ``caption`` (menu entry and shape caption; the class name
    when empty), ``color`` (the shape's fill) and ``auto_map`` (store every
    result in a context property of its own when the activity is added). The
    first paragraph of the docstring is the help text in the designer.
    """

    caption = None
    color = "#F3E5F5"
    auto_map = True

    def perform(self, process, result):
        """Does the work. ``process`` is the business process (None outside
        one), ``result`` an ``Outcome`` to fill in. A negative outcome is
        ``result.success = False``; raise an exception when the activity cannot
        do its work, which makes the process raise a fault."""
        raise NotImplementedError(f"{type(self).__name__} does not implement perform")


def _declared(cls, kind):
    """The ``kind`` (Param or Result) attributes of ``cls``, base classes
    first, each in declaration order."""
    found = {}
    for klass in reversed(cls.__mro__):
        for name, value in vars(klass).items():
            if isinstance(value, kind):
                found[name] = value
    return found


def _expression(value):
    """``value`` as an ObjectScript expression, for the designer's fields."""
    if value is None:
        return ""
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, (int, float)):
        return str(value)
    return '"' + str(value).replace('"', '""') + '"'


def path_of(cls):
    """Where ``run`` finds ``cls``: module and class name."""
    return f"{cls.__module__}.{cls.__qualname__}"


def describe(cls):
    """``cls`` as app.bplplus.catalog describes an activity, for the editors."""
    params = _declared(cls, Param)
    results = _declared(cls, Result)
    doc = inspect.getdoc(cls) or ""
    path = path_of(cls)

    def field(name, type_, description, extra=None):
        entry = {"name": name, "type": _IRIS_TYPES.get(type_, "%Library.String"), "description": description,
                 "required": False, "default": "", "valueList": "", "displayList": ""}
        if type_ is str:
            entry["maxLen"] = ""
        entry.update(extra or {})
        return entry

    return {
        "className": "python:" + path,
        "create": f'##class({RUNNER_CLASS}).%New("{path}")',
        "caption": cls.caption or cls.__name__,
        "description": " ".join(doc.split("\n\n")[0].split()),
        "color": cls.color,
        "autoMap": bool(cls.auto_map),
        "resultClass": RESULT_CLASS,
        "inputs": [field(name, p.type, p.doc, {
            "required": bool(p.required),
            "default": _expression(p.default),
            "valueList": ("," + ",".join(map(str, p.choices))) if p.choices else ""}) for name, p in params.items()],
        "outputs": [field("Success", bool, "1 when the activity did what it was asked, 0 when the outcome was negative."),
                    field("ResultText", str, "What happened, in words.")]
                   + [field(name, r.type, r.doc) for name, r in results.items()],
    }


def _step_classes(package):
    """Every Activity class defined in the modules of ``package``, reloaded so
    a changed module shows in the designer without restarting anything."""
    importlib.invalidate_caches()
    root = importlib.import_module(package)
    classes = []
    for info in pkgutil.iter_modules(root.__path__, package + "."):
        module = importlib.import_module(info.name)
        module = importlib.reload(module)
        for _, cls in inspect.getmembers(module, inspect.isclass):
            if issubclass(cls, Activity) and cls is not Activity and cls.__module__ == module.__name__ \
                    and cls.perform is not Activity.perform:
                classes.append(cls)
    return classes


def catalog(package=STEPS_PACKAGE):
    """The activities in ``package``, as a JSON array for app.bplplus.catalog."""
    return json.dumps([describe(cls) for cls in _step_classes(package)])


def _load(path):
    module_name, _, class_name = path.rpartition(".")
    module = sys.modules.get(module_name) or importlib.import_module(module_name)
    cls = getattr(module, class_name, None)
    if not (inspect.isclass(cls) and issubclass(cls, Activity)):
        raise TypeError(f"{path} is not an Activity class")
    return cls


def run(path, params_json, process=None):
    """Runs the activity at ``path`` with the parameters in ``params_json`` (a
    JSON object of name to value, as the process set them), and returns its
    results as a JSON object. Checks first that every required parameter has a
    value and that there are no parameters the activity does not have (a typing
    error in the process)."""
    cls = _load(path)
    params = _declared(cls, Param)
    results = _declared(cls, Result)
    values = json.loads(params_json or "{}")
    unknown = sorted(set(values) - set(params))
    if unknown:
        raise ValueError(f"{cls.caption or cls.__name__} has no parameter {', '.join(unknown)}")
    activity = cls()
    for name, param in params.items():
        value = values.get(name)
        if param.required and (value is None or value == ""):
            raise ValueError(f"{cls.caption or cls.__name__}: {name} is required")
        setattr(activity, name, param.convert(name, value))
    outcome = Outcome(results)
    # Not "process or None": an IRIS object (the business process) has no truth
    # value.
    activity.perform(None if process is None or isinstance(process, str) else process, outcome)
    out = {"Success": 1 if outcome.success else 0, "ResultText": "" if outcome.text is None else str(outcome.text)}
    for name in results:
        value = getattr(outcome, name, None)
        if isinstance(value, bool):
            value = 1 if value else 0
        elif value is not None and not isinstance(value, (int, float, str)):
            value = str(value)
        out[name] = value
    return json.dumps(out)
