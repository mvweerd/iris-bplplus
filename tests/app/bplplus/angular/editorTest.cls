/// Tests the server side of the new editor with custom activities: which files
/// it serves, and how the script gets into index.html.
Class test.app.bplplus.angular.editorTest Extends %UnitTest.TestCase
{

/// The editor's directory is found; skips the file tests on an instance without
/// the new editor.
Method TestEditorDirectory()
{
	Set tDir = ##class(app.bplplus.angular.editor).EditorDirectory()
	If tDir = "" {
		Do $$$LogMessage("This instance has no new BPL editor; nothing to serve")
		Quit
	}
	Do $$$AssertTrue(##class(%File).Exists(tDir_"index.html"), "index.html in "_tDir)
}

/// Files inside the editor's directory are served; anything outside it, or
/// missing, is not.
Method TestResolveFile()
{
	If ##class(app.bplplus.angular.editor).EditorDirectory() = "" Quit
	Do $$$AssertNotEquals(##class(app.bplplus.angular.editor).ResolveFile("index.html"), "")
	Do $$$AssertEquals(##class(app.bplplus.angular.editor).ResolveFile("../../../iris.cpf"), "", "no way up")
	Do $$$AssertEquals(##class(app.bplplus.angular.editor).ResolveFile("..\..\..\iris.cpf"), "", "no way up with backslashes")
	Do $$$AssertEquals(##class(app.bplplus.angular.editor).ResolveFile("/etc/passwd"), "", "no absolute path")
	Do $$$AssertEquals(##class(app.bplplus.angular.editor).ResolveFile("C:/Windows/win.ini"), "", "no drive")
	Do $$$AssertEquals(##class(app.bplplus.angular.editor).ResolveFile("no-such-file.js"), "", "missing file")
	Do $$$AssertEquals(##class(app.bplplus.angular.editor).ResolveFile("assets"), "", "not a directory")
}

/// The script tag goes right after the head tag, with the class's compile time
/// as version, and in front of everything when there is no head tag.
Method TestInjectScript()
{
	Set tHTML = ##class(app.bplplus.angular.editor).InjectScript("<html><HEAD><title>x</title></HEAD></html>")
	Do $$$AssertTrue(tHTML [ "<HEAD><script src=""bplplus.js?v=", "after <head>, any case: "_tHTML)
	Do $$$AssertTrue(tHTML [ "></script><title>", "before the rest of the head")
	Set tHTML = ##class(app.bplplus.angular.editor).InjectScript("<p>no head</p>")
	Do $$$AssertEquals($Extract(tHTML, 1, 8), "<script ", "in front without a head")
}

/// Content types for the kinds of files the editor has.
Method TestContentType()
{
	Do $$$AssertEquals(##class(app.bplplus.angular.editor).ContentType("main.123.js"), "application/javascript")
	Do $$$AssertEquals(##class(app.bplplus.angular.editor).ContentType("x.WOFF2"), "font/woff2")
	Do $$$AssertEquals(##class(app.bplplus.angular.editor).ContentType("styles.css"), "text/css")
	Do $$$AssertEquals(##class(app.bplplus.angular.editor).ContentType("unknown.bin"), "application/octet-stream")
}

}
