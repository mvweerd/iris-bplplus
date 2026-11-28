/// Makes app.bplplus.classic.editor the default Business Process Designer of a
/// namespace: set this class as the <b>Event Class</b> of the namespace's web
/// application (/csp/&lt;namespace&gt;), and every request for the standard
/// designer, EnsPortal.BPLEditor.zen, is served by app.bplplus.classic.editor.zen
/// instead, with the same query string. The portal's own links (the
/// Interoperability menu, Open from the production, the process list) then open
/// the designer with custom activities.
/// <p>
/// Only that one page is redirected, and only in web applications that use this
/// event class; clear the Event Class to go back to the standard designer. A web
/// application that already has an event class can get the redirect by making
/// that class extend this one and call ##super() in OnStartRequest.
/// <p>
/// Installed with IPM, the module sets this class as Event Class of the
/// namespace's default web application itself (<method>EnableForNamespace</method>),
/// but only when that application has no Event Class yet, and clears it again on
/// uninstall (<method>DisableForNamespace</method>), but only when it is still
/// this class.
Class app.bplplus.classic.redirect Extends %CSP.SessionEvents
{

/// The page that is replaced, in lower case.
Parameter STANDARDPAGE = "ensportal.bpleditor.zen";

/// The page served instead.
Parameter REPLACEMENTPAGE = "app.bplplus.classic.editor.zen";

/// Sends the browser to the replacement page when the standard designer is
/// requested, with the same query string (BP, STUDIO and so on). An HTTP redirect
/// and not a server-side one: the browser then asks for the replacement page
/// itself, so IRIS's login applies to it as to any page. A server-side redirect
/// would skip the login and load the designer for UnknownUser, which reloads
/// itself without end. ($Username cannot tell the two apart here: at the start of
/// a request it is UnknownUser even in a logged-in session.)
ClassMethod OnStartRequest() As %Status
{
	Try {
		Set tTarget = ..RedirectTarget(%request.URL, $Get(%request.CgiEnvs("QUERY_STRING")))
		If tTarget '= "" Set %response.Redirect = tTarget
	}
	Catch ex {
		// never stop a request because of the redirect
	}
	Quit $$$OK
}

/// Where a request for <var>pURL</var> with query string <var>pQuery</var> is
/// sent: the replacement page next to it, with the same query string, for the
/// standard designer; "" for any other page.
ClassMethod RedirectTarget(pURL As %String, pQuery As %String = "") As %String
{
	Set tPath = $Piece(pURL, "?", 1)
	If $ZConvert($Piece(tPath, "/", *), "L") '= ..#STANDARDPAGE Quit ""
	Quit $Piece(tPath, "/", 1, * - 1)_"/"_..#REPLACEMENTPAGE_$Select(pQuery = "": "", 1: "?"_pQuery)
}

/// Called by IPM on install (Configure phase): makes this class the Event Class
/// of the default web application of <var>pNamespace</var>, such as
/// /csp/bpldemo, when that application has none. An Event Class that is already
/// set is left alone, with a message saying how to add the redirect to it. Never
/// fails the install: a namespace without a default web application, or an
/// installing user who may not change it, only gets a message.
ClassMethod EnableForNamespace(pNamespace As %String = {$Namespace}) As %Status
{
	Set tApp = ..DefaultApplication(pNamespace)
	If tApp = "" {
		Write !,"Namespace "_pNamespace_" has no default web application; set "_$ClassName()_" as Event Class by hand to make the designer with custom activities the default.",!
		Quit $$$OK
	}
	Quit ..Enable(tApp)
}

/// Called by IPM on uninstall (Unconfigure phase): clears the Event Class of the
/// default web application of <var>pNamespace</var> when it is this class, which
/// is about to be deleted. Any other Event Class is left alone.
ClassMethod DisableForNamespace(pNamespace As %String = {$Namespace}) As %Status
{
	Set tApp = ..DefaultApplication(pNamespace)
	If tApp = "" Quit $$$OK
	Quit ..Disable(tApp)
}

/// Makes this class the Event Class of web application <var>pApp</var>, only
/// when it has none.
ClassMethod Enable(pApp As %String) As %Status
{
	Set tClass = $ClassName()
	Try {
		New $Namespace
		Set $Namespace = "%SYS"
		Set tSC = ##class(Security.Applications).Get(pApp, .tProps)
		If $$$ISERR(tSC) {
			Write !,"Web application "_pApp_" could not be read ("_$System.Status.GetErrorText(tSC)_"); set "_tClass_" as its Event Class by hand.",!
			Quit
		}
		Set tCurrent = $Get(tProps("EventClass"))
		If tCurrent = tClass Quit
		If tCurrent '= "" {
			Write !,"Web application "_pApp_" already has Event Class "_tCurrent_", which is left as it is. To make the designer with custom activities the default there, let "_tCurrent_" extend "_tClass_" and call ##super() in its OnStartRequest.",!
			Quit
		}
		Kill tNew
		Set tNew("EventClass") = tClass
		Set tSC = ##class(Security.Applications).Modify(pApp, .tNew)
		If $$$ISERR(tSC) {
			Write !,"Event Class of "_pApp_" could not be set ("_$System.Status.GetErrorText(tSC)_"); set "_tClass_" by hand.",!
			Quit
		}
		Write !,"Event Class of "_pApp_" set to "_tClass_": the portal opens the designer with custom activities there.",!
	}
	Catch ex {
		Write !,"Event Class of "_pApp_" not set ("_ex.DisplayString()_"); set "_tClass_" by hand.",!
	}
	Quit $$$OK
}

/// Clears the Event Class of web application <var>pApp</var>, only when it is
/// this class.
ClassMethod Disable(pApp As %String) As %Status
{
	Set tClass = $ClassName()
	Try {
		New $Namespace
		Set $Namespace = "%SYS"
		If $$$ISERR(##class(Security.Applications).Get(pApp, .tProps)) Quit
		If $Get(tProps("EventClass")) '= tClass Quit
		Set tNew("EventClass") = ""
		Set tSC = ##class(Security.Applications).Modify(pApp, .tNew)
		If $$$ISERR(tSC) {
			Write !,"Event Class "_tClass_" of "_pApp_" could not be cleared ("_$System.Status.GetErrorText(tSC)_"); clear it by hand, as the class is being removed.",!
			Quit
		}
		Write !,"Event Class "_tClass_" removed from "_pApp_".",!
	}
	Catch ex {
		Write !,"Event Class of "_pApp_" not cleared ("_ex.DisplayString()_"); clear it by hand.",!
	}
	Quit $$$OK
}

/// The default web application of <var>pNamespace</var>, such as /csp/bpldemo,
/// without trailing slash; "" when it has none.
ClassMethod DefaultApplication(pNamespace As %String) As %String
{
	Set tApp = ""
	Try {
		Set tApp = $System.CSP.GetDefaultApp(pNamespace)
	}
	Catch ex {
		Set tApp = ""
	}
	If $Extract(tApp, *) = "/" Set tApp = $Extract(tApp, 1, * - 1)
	Quit tApp
}

}
