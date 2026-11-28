/// Tests that the event class sends the standard designer, and only that page,
/// to the designer with custom activities.
Class test.app.bplplus.classic.redirectTest Extends %UnitTest.TestCase
{

/// The standard designer goes to the replacement page next to it, with its
/// query string, in any letter case; other pages do not.
Method TestRedirectTarget()
{
	Set tClass = "app.bplplus.classic.redirect"
	Do $$$AssertEquals($ClassMethod(tClass, "RedirectTarget", "/csp/bpldemo/EnsPortal.BPLEditor.zen", "BP=x.bpl&STUDIO=1"), "/csp/bpldemo/app.bplplus.classic.editor.zen?BP=x.bpl&STUDIO=1")
	Do $$$AssertEquals($ClassMethod(tClass, "RedirectTarget", "/csp/bpldemo/ensportal.bpleditor.zen", ""), "/csp/bpldemo/app.bplplus.classic.editor.zen", "case, no query")
	Do $$$AssertEquals($ClassMethod(tClass, "RedirectTarget", "/csp/bpldemo/EnsPortal.ProductionConfig.zen", "x=1"), "", "other portal page")
	Do $$$AssertEquals($ClassMethod(tClass, "RedirectTarget", "/csp/bpldemo/app.bplplus.classic.editor.zen", ""), "", "the replacement itself")
}

/// OnStartRequest sets the redirect for the standard designer only.
Method TestOnStartRequest()
{
	New %request, %response
	Set %request = ##class(%CSP.Request).%New()
	Set %request.URL = "/csp/bpldemo/EnsPortal.BPLEditor.zen"
	Set %request.CgiEnvs("QUERY_STRING") = "BP=x.bpl"
	Set %response = ##class(%CSP.Response).%New()
	Do $$$AssertStatusOK(##class(app.bplplus.classic.redirect).OnStartRequest())
	Do $$$AssertEquals(%response.Redirect, "/csp/bpldemo/app.bplplus.classic.editor.zen?BP=x.bpl")
	Set %request.URL = "/csp/bpldemo/EnsPortal.ProductionConfig.zen"
	Set %response = ##class(%CSP.Response).%New()
	Do $$$AssertStatusOK(##class(app.bplplus.classic.redirect).OnStartRequest())
	Do $$$AssertEquals(%response.Redirect, "")
}

}
