#!/usr/bin/env python3
"""
Load the custom BPL activities into an IRIS namespace, without IPM.

Loads and compiles the app.bplplus.* classes in one go; with --tests also the
demo process, demo production and unit tests (test.app.bplplus.*).

Usage:
    python scripts/deploy_bplplus.py                    # settings from .env
    python scripts/deploy_bplplus.py --ns BPLDEMO --tests
    python scripts/deploy_bplplus.py --host box --port 1972 --user _SYSTEM --pass SYS

Connection settings default to IRIS_HOST, IRIS_PORT, IRIS_NAMESPACE, IRIS_USER
and IRIS_PASSWORD, from the environment or from the .env file in the repo root
(the environment wins).

Requirements:
    pip install intersystems-irispython

IRIS reads the class files from its own file system, so this must run on the
same machine as the target instance (or the repo must be visible to it).

The same load from an IRIS terminal, in the target namespace:
    do $system.OBJ.ImportDir("<repo>/src/cls","*.cls","ck",.err,1)
    do $system.OBJ.ImportDir("<repo>/tests","*.cls","ck",.err,1)
"""
import argparse
import os
import pathlib
import shutil
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent

# Dependencies first: the base classes before the activities that extend them,
# the activities before the catalog test that reads them.
SRC_FILES = [
    "src/cls/app/bplplus/activityResult.cls",
    "src/cls/app/bplplus/activity.cls",
    "src/cls/app/bplplus/python/activity.cls",
    "src/cls/app/bplplus/python/stepResult.cls",
    "src/cls/app/bplplus/python/step.cls",
    "src/cls/app/bplplus/lookup.cls",
    "src/cls/app/bplplus/catalog.cls",
    "src/cls/app/bplplus/editorCore.cls",
    "src/cls/app/bplplus/call/search.cls",
    "src/cls/app/bplplus/call/callProcess.cls",
    "src/cls/app/bplplus/classic/editor.cls",
    "src/cls/app/bplplus/classic/redirect.cls",
    "src/cls/app/bplplus/angular/editor.cls",
    "src/cls/app/bplplus/examples/buildSqlInsertResult.cls",
    "src/cls/app/bplplus/examples/buildSqlInsert.cls",
    "src/cls/app/bplplus/examples/checkResponseResult.cls",
    "src/cls/app/bplplus/examples/checkResponse.cls",
    "src/cls/app/bplplus/examples/fuzzyMatchResult.cls",
    "src/cls/app/bplplus/examples/fuzzyMatch.cls",
    "src/cls/app/bplplus/examples/handleError.cls",
    "src/cls/app/bplplus/examples/normalizePhoneResult.cls",
    "src/cls/app/bplplus/examples/normalizePhone.cls",
    "src/cls/app/bplplus/examples/sendNotification.cls",
    "src/cls/app/bplplus/examples/validateValue.cls",
    # The example processes of Call process, after the activities they use.
    "src/cls/app/bplplus/examples/contact.cls",
    "src/cls/app/bplplus/examples/cleanContact.cls",
    "src/cls/app/bplplus/examples/registerContact.cls",
    "src/cls/app/bplplus/examples/signLetter.cls",
    "src/cls/app/bplplus/examples/writeLetter.cls",
]

TEST_FILES = [
    "tests/app/bplplus/demo/registrationRequest.cls",
    "tests/app/bplplus/demo/response.cls",
    "tests/app/bplplus/demo/textRequest.cls",
    "tests/app/bplplus/demo/registration.cls",
    "tests/app/bplplus/demo/sendNotification.cls",
    "tests/app/bplplus/demo/validateValue.cls",
    "tests/app/bplplus/demo/handleError.cls",
    "tests/app/bplplus/demo/checkResponse.cls",
    "tests/app/bplplus/demo/buildSqlInsert.cls",
    "tests/app/bplplus/demo/fuzzyMatch.cls",
    "tests/app/bplplus/demo/normalizePhonePython.cls",
    "tests/app/bplplus/demo/normalizePhoneObjectScript.cls",
    "tests/app/bplplus/demo/callee.cls",
    "tests/app/bplplus/demo/callProcess.cls",
    "tests/app/bplplus/demo/production.cls",
    "tests/app/bplplus/catalogTest.cls",
    "tests/app/bplplus/activityTest.cls",
    "tests/app/bplplus/examplesTest.cls",
    "tests/app/bplplus/callTest.cls",
    "tests/app/bplplus/python/stepTest.cls",
    "tests/app/bplplus/classic/redirectTest.cls",
    "tests/app/bplplus/angular/editorTest.cls",
    "tests/app/bplplus/demo/productionTest.cls",
]


def load_dotenv():
    """Put the repo's .env values into os.environ, without overriding real ones."""
    env_file = REPO / ".env"
    if not env_file.exists():
        return
    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


def main():
    load_dotenv()
    ap = argparse.ArgumentParser(
        description="Load the app.bplplus.* custom BPL activities into an IRIS namespace",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    ap.add_argument("--host", default=os.environ.get("IRIS_HOST", "localhost"))
    ap.add_argument("--port", default=int(os.environ.get("IRIS_PORT", "1972")), type=int)
    ap.add_argument("--ns", default=os.environ.get("IRIS_NAMESPACE", "USER"), metavar="NAMESPACE")
    ap.add_argument("--user", default=os.environ.get("IRIS_USER", "_SYSTEM"))
    ap.add_argument("--pass", default=os.environ.get("IRIS_PASSWORD", "SYS"), dest="password")
    ap.add_argument("--tests", action="store_true",
                    help="also load the demo process, demo production and unit tests")
    ap.add_argument("--web-port", default=int(os.environ.get("IRIS_WEB_PORT", "52773")), type=int,
                    metavar="PORT", help="IRIS web port, for the URL printed at the end")
    args = ap.parse_args()

    try:
        import iris
    except ImportError:
        sys.exit("iris driver not found -- run: pip install intersystems-irispython")

    print(f"Connecting to {args.host}:{args.port}/{args.ns} as {args.user} ...")
    try:
        conn = iris.connect(args.host, args.port, args.ns, args.user, args.password)
    except Exception as exc:
        sys.exit(f"Connection failed: {exc}")
    irispy = iris.createIRIS(conn)

    # Every class here builds on Ens.*, which IRIS only maps into namespaces
    # enabled for interoperability. Checked up front, because otherwise the first
    # sign is a compile error that says nothing about why.
    if not irispy.classMethodValue("%Library.EnsembleMgr", "IsEnsembleNamespace", args.ns):
        conn.close()
        sys.exit(
            f"Namespace {args.ns} is not enabled for interoperability, and the activities need it.\n"
            "Enable it (see the README, Setup), then deploy again."
        )

    # The Python side of activities written as plain Python classes goes into
    # the python directory of the installation, which Embedded Python searches.
    python_dir = os.path.join(irispy.classMethodString("%SYSTEM.Util", "ManagerDirectory"), "python")
    for package in ("bplplus", "bplplus_steps"):
        target = os.path.join(python_dir, package)
        shutil.copytree(REPO / "src" / "python" / package, target, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns("__pycache__"))
        print(f"  OK    python/{package} -> {target}")

    files = SRC_FILES + (TEST_FILES if args.tests else [])
    print("Loading classes:")
    ok = True
    with tempfile.TemporaryDirectory() as tmpdir:
        copies = []
        for i, rel in enumerate(files):
            src = REPO / rel
            if not src.exists():
                print(f"  MISS  {rel}")
                ok = False
                continue
            # A plain temp name: IRIS reads the file itself, and a repo path with
            # spaces or a UNC prefix trips some installations up. Numbered, as
            # classic/editor.cls and angular/editor.cls share a file name.
            tmp = os.path.join(tmpdir, f"{i:02d}_{src.name}")
            shutil.copy2(src, tmp)
            copies.append(tmp)
        # Load everything first and compile it as one set, so classes that refer
        # to each other compile in the right order.
        for tmp in copies:
            sc = irispy.classMethodValue("%SYSTEM.OBJ", "Load", tmp, "-d")
            err = irispy.classMethodString("%SYSTEM.Status", "GetErrorText", sc)
            print(f"  FAIL  {os.path.basename(tmp)}: {err}" if err else f"  OK    {os.path.basename(tmp)}")
            ok = ok and not err
        if ok:
            names = []
            for rel in files:
                parts = pathlib.Path(rel).with_suffix("").parts
                pkg = parts[2:] if parts[0] == "src" else ("test",) + parts[1:]
                names.append(".".join(pkg) + ".cls")
            sc = irispy.classMethodValue("%SYSTEM.OBJ", "CompileList", ",".join(names), "ck-d")
            err = irispy.classMethodString("%SYSTEM.Status", "GetErrorText", sc)
            print(f"  FAIL  compile: {err}" if err else "  OK    compiled")
            ok = not err

    conn.close()
    if not ok:
        sys.exit("\nAborting: fix the errors above and retry.")
    print("\nDone.")
    print(f"  Designer:   http://{args.host}:{args.web_port}/csp/{args.ns.lower()}/app.bplplus.classic.editor.zen")
    print(f"  New editor: http://{args.host}:{args.web_port}/ui/interop/bpl-plus/index.html?$NAMESPACE={args.ns}"
          "  (needs the /ui/interop/bpl-plus web application, see the README)")
    if args.tests:
        print(f"  Demo:     ...app.bplplus.classic.editor.zen?BP=test.app.bplplus.demo.registration.bpl")


if __name__ == "__main__":
    main()
