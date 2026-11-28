/// The new BPL editor (/ui/interop/bpl-editor) with custom activities, served at
/// /ui/interop/bpl-plus/.
/// <p>
/// The new editor is a compiled Angular application that cannot be extended. This
/// web application serves its files unchanged, straight from the installation, and
/// adds one script to its index.html (see XData Script). That script makes custom
/// activities building blocks in the editor: a <i>Custom activities</i> button next
/// to Add, shapes drawn with the activity's caption, colour and icon, and in the
/// inspector a field per parameter and per result instead of the code. Under the
/// hood a custom activity is the same &lt;code&gt; activity app.bplplus.classic.editor
/// writes, so both designers work on the same processes.
/// <p>
/// The original editor at /ui/interop/bpl-editor is not touched. Open this one as
/// <code>/ui/interop/bpl-plus/index.html?$NAMESPACE=&lt;ns&gt;&amp;BP=&lt;process class&gt;</code>.
/// <p>
/// The script works with the editor's page as it is drawn (element ids, the Add
/// menu, the code field), which InterSystems does not document as an API. Every
/// hook fails quietly: if an IRIS release changes those, the page is the plain new
/// editor and custom activities show as code activities.
Class app.bplplus.angular.editor Extends %CSP.REST
{

/// Where the new editor's files live, relative to the directory of the /ui/interop
/// web application.
Parameter EDITORDIRECTORY = "bpl-editor";

/// File name the script is served under, next to the editor's own files.
Parameter SCRIPTNAME = "bplplus.js";

Parameter HandleCorsRequest = 0;

/// A CSP session, so the login of the Management Portal (the web application is
/// in its authentication group, %ISCMgtPortal) applies here as well: whoever
/// comes from the portal is logged in for the catalog without logging in again.
Parameter UseSession As Integer = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/catalog" Method="GET" Call="Catalog"/>
<Route Url="/choices" Method="GET" Call="Choices"/>
<Route Url="/bplplus.js" Method="GET" Call="Script"/>
<Route Url="/(.*)" Method="GET" Call="File"/>
</Routes>
}

/// The custom activities of the namespace in the <code>namespace</code> query
/// parameter, as app.bplplus.catalog:Activities() describes them. Only for a
/// logged-in user (through the Management Portal's login) who may read BPL;
/// anyone else gets 403, not 401, so the browser does not pop up a login box over
/// the editor. An empty list when the namespace does not have the activities.
ClassMethod Catalog() As %Status
{
	If ($Username = "UnknownUser") || '$System.Security.Check("%Ens_BPL", "READ") {
		Set %response.Status = "403 Forbidden"
		Quit $$$OK
	}
	Set tNamespace = $Get(%request.Data("namespace", 1))
	If (tNamespace = "") || '##class(%SYS.Namespace).Exists(tNamespace) {
		Set %response.Status = "400 Bad Request"
		Quit $$$OK
	}
	Set %response.ContentType = "application/json"
	Set tList = []
	Try {
		New $Namespace
		Set $Namespace = tNamespace
		If ##class(%Dictionary.CompiledClass).%ExistsId("app.bplplus.catalog") {
			Set tList = ##class(app.bplplus.catalog).Activities()
		}
	}
	Catch ex {
		Set tList = []
	}
	Write tList.%ToJSON()
	Quit $$$OK
}

/// What the magnifier of a parameter lists: the context search of parameter
/// <code>property</code> of activity <code>class</code> in namespace
/// <code>namespace</code> (app.bplplus.catalog:Choices), with the same login
/// check as <method>Catalog</method>. Empty for a parameter without a magnifier.
ClassMethod Choices() As %Status
{
	If ($Username = "UnknownUser") || '$System.Security.Check("%Ens_BPL", "READ") {
		Set %response.Status = "403 Forbidden"
		Quit $$$OK
	}
	Set tNamespace = $Get(%request.Data("namespace", 1))
	If (tNamespace = "") || '##class(%SYS.Namespace).Exists(tNamespace) {
		Set %response.Status = "400 Bad Request"
		Quit $$$OK
	}
	Set %response.ContentType = "application/json"
	Set tChoices = {}
	Try {
		New $Namespace
		Set $Namespace = tNamespace
		If ##class(%Dictionary.CompiledClass).%ExistsId("app.bplplus.catalog") {
			Set tChoices = ##class(app.bplplus.catalog).Choices($Get(%request.Data("class", 1)), $Get(%request.Data("property", 1)))
		}
	}
	Catch ex {
		Set tChoices = {}
	}
	Write tChoices.%ToJSON()
	Quit $$$OK
}

/// The script: app.bplplus.editorCore's shared part, then XData Script.
ClassMethod Script() As %Status
{
	Set %response.ContentType = "application/javascript"
	Set %response.CharSet = "utf-8"
	Do %response.SetHeader("Cache-Control", "no-cache")
	Set tXData = ##class(%Dictionary.CompiledXData).%OpenId($ClassName()_"||Script")
	If '$IsObject(tXData) {
		Set %response.Status = "404 Not Found"
		Quit $$$OK
	}
	// The part both editors share first; it defines bplplusCore.
	Do ##class(app.bplplus.editorCore).WriteScript()
	Write !
	Do tXData.Data.Rewind()
	Do tXData.Data.OutputToDevice()
	Quit $$$OK
}

/// A file of the new editor, unchanged, except index.html (or no file at all),
/// which gets the script added. Paths outside the editor's directory are refused.
ClassMethod File(pPath As %String = "") As %Status
{
	Set tPath = $Piece(pPath, "?", 1)
	If (tPath = "") || (tPath = "index.html") {
		Quit ..Index()
	}
	Set tFile = ..ResolveFile(tPath)
	If tFile = "" {
		Set %response.Status = "404 Not Found"
		Quit $$$OK
	}
	Set %response.ContentType = ..ContentType(tFile)
	// The editor's file names carry a content hash, so they can be cached.
	Do %response.SetHeader("Cache-Control", "max-age=86400")
	Set tStream = ##class(%Stream.FileBinary).%New()
	Set tSC = tStream.LinkToFile(tFile)
	If $$$ISERR(tSC) Quit tSC
	Quit tStream.OutputToDevice()
}

/// The editor's index.html with the script added.
ClassMethod Index() As %Status
{
	Set tFile = ..ResolveFile("index.html")
	If tFile = "" {
		Set %response.Status = "404 Not Found"
		Quit $$$OK
	}
	Set tStream = ##class(%Stream.FileCharacter).%New()
	Set tStream.TranslateTable = "UTF8"
	Set tSC = tStream.LinkToFile(tFile)
	If $$$ISERR(tSC) Quit tSC
	Set tHTML = tStream.Read($$$MaxStringLength)
	Set %response.ContentType = "text/html"
	Set %response.CharSet = "utf-8"
	Do %response.SetHeader("Cache-Control", "no-cache")
	Write ..InjectScript(tHTML)
	Quit $$$OK
}

/// <var>pHTML</var> with a script tag for the script right after &lt;head&gt;, so it
/// runs before the editor starts and sees the editor's first requests. The tag
/// carries the time this class was compiled, so a browser never keeps running an
/// older script after an update.
ClassMethod InjectScript(pHTML As %String) As %String
{
	Set tVersion = $Translate($ZStrip(##class(%Dictionary.CompiledClass).%OpenId($ClassName()).TimeChanged, "*W"), ".,:-")
	Set tTag = "<script src="""_..#SCRIPTNAME_"?v="_tVersion_"""></script>"
	Set tPos = $Find($ZConvert(pHTML, "L"), "<head>")
	If tPos = 0 Quit tTag_pHTML
	Quit $Extract(pHTML, 1, tPos - 1)_tTag_$Extract(pHTML, tPos, *)
}

/// Full path of file <var>pPath</var> in the new editor's directory, or "" when it
/// does not exist or is not inside that directory.
ClassMethod ResolveFile(pPath As %String) As %String
{
	Set tDir = ..EditorDirectory()
	If (tDir = "") || (pPath = "") Quit ""
	Set tPath = $Translate(pPath, "\", "/")
	If (tPath [ "..") || ($Extract(tPath) = "/") || (tPath [ ":") Quit ""
	Set tFile = ##class(%File).NormalizeFilename(tPath, tDir)
	If $Extract(tFile, 1, $Length(tDir)) '= tDir Quit ""
	If '##class(%File).Exists(tFile) || ##class(%File).DirectoryExists(tFile) Quit ""
	Quit tFile
}

/// Directory of the new editor's files: EDITORDIRECTORY inside the directory of
/// the /ui/interop web application, or else in ui/interop of the installation
/// directory. "" when the instance has no new editor.
ClassMethod EditorDirectory() As %String
{
	Set tDir = ""
	Try {
		New $Namespace
		Set $Namespace = "%SYS"
		Set tApp = ##class(Security.Applications).%OpenId("/ui/interop")
		If $IsObject(tApp) && (tApp.Path '= "") {
			Set tDir = ##class(%File).NormalizeDirectory(..#EDITORDIRECTORY, tApp.Path)
		}
	}
	Catch ex {
		Set tDir = ""
	}
	// A user without access to the security settings still gets the standard
	// location in the installation directory.
	If (tDir = "") || '##class(%File).DirectoryExists(tDir) {
		Set tDir = ##class(%File).NormalizeDirectory("ui/interop/"_..#EDITORDIRECTORY, $System.Util.InstallDirectory())
	}
	If '##class(%File).DirectoryExists(tDir) Set tDir = ""
	Quit tDir
}

/// Content type for <var>pFile</var>, by extension.
ClassMethod ContentType(pFile As %String) As %String
{
	Set tExt = $ZConvert($Piece(pFile, ".", *), "L")
	Quit $Case(tExt,
		"js": "application/javascript",
		"css": "text/css",
		"html": "text/html",
		"json": "application/json",
		"svg": "image/svg+xml",
		"png": "image/png",
		"ico": "image/x-icon",
		"woff": "font/woff",
		"woff2": "font/woff2",
		"ttf": "font/ttf",
		"eot": "application/vnd.ms-fontobject",
		"txt": "text/plain",
		: "application/octet-stream")
}

/// The script added to the new editor. Kept in one place with the class that
/// serves it; see the class description for what it does.
XData Script [ MimeType = application/javascript ]
{
/* Custom activities for the new BPL editor. Served by app.bplplus.angular.editor. */
(function () {
	'use strict';
	if (window.bplplus || !window.bplplusCore) return;
	var core = window.bplplusCore, parse = core.parse, write = core.write, esc = core.esc;
	var S = window.bplplus = { catalog: null, ns: null, codes: {}, showCode: false, panelKey: null, busy: false };
	var nativeParse = JSON.parse;
	var base = location.pathname.replace(/[^\/]*$/, '');

	/* ---------- the model, from the editor's own API responses ---------- */
	JSON.parse = function () {
		var parsed = nativeParse.apply(this, arguments);
		try {
			// A process without context properties has no Context field at all.
			if (parsed && Array.isArray(parsed.ShapeList) && ('Name' in parsed)) takeModel(parsed);
		} catch (ex) { /* never break the editor */ }
		return parsed;
	};
	function takeModel(model) {
		S.codes = {};
		model.ShapeList.forEach(function (shape) {
			if (shape && shape.Type == 'code') S.codes[shape.Index] = shape.Code || '';
		});
		schedule();
	}

	/* ---------- requests: namespace, and context properties on save ---------- */
	var nativeOpen = XMLHttpRequest.prototype.open;
	var nativeSend = XMLHttpRequest.prototype.send;
	XMLHttpRequest.prototype.open = function (method, url) {
		this._bplplus = { method: String(method).toUpperCase(), url: String(url) };
		try {
			var m = /\/interop-editors\/v\d+\/([^\/?]+)\/bpl/.exec(String(url));
			if (m) setNamespace(decodeURIComponent(m[1]));
		} catch (ex) { }
		return nativeOpen.apply(this, arguments);
	};
	XMLHttpRequest.prototype.send = function (body) {
		try {
			var info = this._bplplus;
			if (info && ((info.method == 'PUT') || (info.method == 'POST')) && (typeof body == 'string')
					&& /\/bpl\/[^\/?]+(\?|$)/.test(info.url) && !/\/bpl\/(compile|validate|preferences)/.test(info.url)) {
				var model = nativeParse(body);
				if (model && Array.isArray(model.ShapeList) && addContextProperties(model)) body = JSON.stringify(model);
			}
		} catch (ex) { }
		return nativeSend.call(this, body);
	};

	/* Every result stored in context.X needs context property X: added to the
	   process being saved, with the result's type and MAXLEN, when missing. */
	function addContextProperties(model) {
		if (!S.catalog) return false;
		var changed = false;
		if (!model.Context) model.Context = { ClassName: 'Ens.BPL.Context', Properties: [] };
		if (!model.Context.Properties) model.Context.Properties = [];
		var props = model.Context.Properties;
		model.ShapeList.forEach(function (shape) {
			if (!shape || (shape.Type != 'code')) return;
			var parsed = parse(shape.Code);
			var def = parsed ? find(parsed.className) : null;
			if (!def) return;
			def.outputs.forEach(function (result) {
				var name = core.contextProperty(parsed.results[result.name]);
				if (!name) return;
				for (var i = 0; i < props.length; i++) if (props[i].Name == name) return;
				var prop = { ClassName: 'Ens.BPL.Property', Name: name, Type: result.type, Instantiate: false, DeleteWithContext: false };
				/* MAXLEN "" (unlimited) makes the editor's API fail on save with a
				   SAX error, so unlimited is written as the longest string. */
				if ((result.maxLen !== undefined) && (result.maxLen !== null)) prop.Parameters = { MAXLEN: (String(result.maxLen) === '') ? '3641144' : String(result.maxLen) };
				props.push(prop);
				changed = true;
			});
		});
		return changed;
	}

	/* ---------- the catalog, with the Management Portal's login ---------- */
	function setNamespace(ns) {
		if (!ns || (ns == S.ns)) return;
		S.ns = ns;
		S.catalog = null;
		loadCatalog(0);
	}
	/* Retried while it is refused, so logging in to the portal in another tab is
	   enough: the activities appear without reloading the editor. */
	function loadCatalog(attempt) {
		var ns = S.ns;
		if (!ns) return;
		var xhr = new XMLHttpRequest();
		nativeOpen.call(xhr, 'GET', base + 'catalog?namespace=' + encodeURIComponent(ns));
		xhr.withCredentials = true;
		xhr.onload = function () {
			if (ns != S.ns) return;
			if (xhr.status == 200) {
				try { S.catalog = nativeParse(xhr.responseText); } catch (ex) { S.catalog = []; }
				schedule();
			}
			else {
				if ((xhr.status == 403) && window.console) console.info('bplplus: log in to the Management Portal to use custom activities here');
				if (attempt < 300) setTimeout(function () { loadCatalog(attempt + 1); }, 3000);
			}
		};
		nativeSend.call(xhr);
	}
	/* The choices of the magnifier of parameter property of activity className,
	   read when it is clicked. */
	function loadChoices(className, property, done) {
		var xhr = new XMLHttpRequest();
		nativeOpen.call(xhr, 'GET', base + 'choices?namespace=' + encodeURIComponent(S.ns || '')
			+ '&class=' + encodeURIComponent(className) + '&property=' + encodeURIComponent(property));
		xhr.withCredentials = true;
		xhr.onload = function () {
			if (xhr.status != 200) { done(null, 'The list could not be read (' + xhr.status + ').'); return; }
			try { done(nativeParse(xhr.responseText)); } catch (ex) { done(null, 'The list could not be read.'); }
		};
		xhr.onerror = function () { done(null, 'The list could not be read.'); };
		nativeSend.call(xhr);
	}
	function find(className) {
		var list = S.catalog || [];
		for (var i = 0; i < list.length; i++) if (list[i].className == className) return list[i];
		return null;
	}

	/* ---------- the page ---------- */
	var scheduled = false;
	function schedule() {
		if (scheduled) return;
		scheduled = true;
		requestAnimationFrame(function () {
			scheduled = false;
			try { refresh(); } catch (ex) { if (window.console) console.warn('bplplus', ex); }
		});
	}
	function start() {
		addStyle();
		new MutationObserver(schedule).observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ['class'] });
		schedule();
	}
	if (document.readyState == 'loading') document.addEventListener('DOMContentLoaded', start); else start();

	function shapeGroups() {
		return Array.prototype.filter.call(document.querySelectorAll('g[id^="shapeGroup_"]'), function (g) { return /^shapeGroup_\d+\s*$/.test(g.id); });
	}
	function indexOf(g) { return parseInt(g.id.replace(/\D+/g, ''), 10); }
	function selectedGroup() {
		var groups = shapeGroups().filter(function (g) {
			var main = g.querySelector('[id^="shape_main_"]');
			return main && /\bselected\b/.test(main.getAttribute('class') || '');
		});
		return groups.length == 1 ? groups[0] : null;
	}
	function shapeName(g) {
		var t = g.querySelector('text.activity-name title') || g.querySelector('text.activity-name');
		return t ? t.textContent.replace(/^\s+|\s+$/g, '') : '';
	}
	function setNativeValue(el, value) {
		var proto = (el.tagName == 'TEXTAREA') ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
		Object.getOwnPropertyDescriptor(proto, 'value').set.call(el, value);
		['input', 'change', 'blur'].forEach(function (t) { el.dispatchEvent(new Event(t, { bubbles: true })); });
	}

	function refresh() {
		if (!S.catalog) return;
		addMenuButton();
		var selected = selectedGroup();
		var codeField = document.getElementById('activity-settings-code-textarea');
		var nameField = document.getElementById('activity-settings-name-input');
		// The code field belongs to the selected shape once its name is shown.
		if (selected && codeField && nameField && (nameField.value == shapeName(selected))) {
			S.codes[indexOf(selected)] = codeField.value;
		}
		shapeGroups().forEach(decorate);
		renderPanel(selected, codeField, nameField);
	}

	function decorate(g) {
		var parsed = parse(S.codes[indexOf(g)]);
		var def = parsed ? find(parsed.className) : null;
		var type = g.querySelector('text.activity-type');
		var main = g.querySelector('[id^="shape_main_"]');
		var badge = g.querySelector('g.bplplus-badge');
		if (!def) {
			if (g.getAttribute('data-bplplus')) {
				g.removeAttribute('data-bplplus');
				if (type && (type.textContent != 'code')) type.textContent = 'code';
				if (main) main.style.fill = '';
				if (badge) badge.parentNode.removeChild(badge);
			}
			return;
		}
		if (g.getAttribute('data-bplplus') != def.className) g.setAttribute('data-bplplus', def.className);
		if (type && (type.textContent != def.caption)) type.textContent = def.caption;
		if (main) {
			var fill = /\bselected\b/.test(main.getAttribute('class') || '') ? '' : (def.color || '');
			if (main.style.fill != fill) main.style.fill = fill;
		}
		/* A round badge with the caption's first letter: the editor's font has no
		   icon characters, and a badge reads as "not a built-in activity". */
		if (!badge) {
			var svgNS = 'http://www.w3.org/2000/svg';
			badge = document.createElementNS(svgNS, 'g');
			badge.setAttribute('class', 'bplplus-badge');
			var circle = document.createElementNS(svgNS, 'circle');
			circle.setAttribute('cx', '104');
			circle.setAttribute('cy', '0');
			circle.setAttribute('r', '8');
			circle.setAttribute('style', 'fill:#806030;stroke:none;');
			var letter = document.createElementNS(svgNS, 'text');
			letter.setAttribute('x', '104');
			letter.setAttribute('y', '4');
			letter.setAttribute('text-anchor', 'middle');
			letter.setAttribute('style', 'font-size:11px;font-weight:bold;fill:#fff;stroke:none;');
			badge.appendChild(circle);
			badge.appendChild(letter);
			g.appendChild(badge);
		}
		var badgeText = badge.querySelector('text');
		var initial = def.caption.charAt(0).toUpperCase();
		if (badgeText.textContent != initial) badgeText.textContent = initial;
	}

	/* The inspector: the activity's fields instead of the code field. */
	function renderPanel(selected, codeField, nameField) {
		var panel = document.getElementById('bplplus-panel');
		var holder = codeField ? (codeField.closest('formly-field') || codeField.parentNode) : null;
		var ok = selected && codeField && nameField && (nameField.value == shapeName(selected));
		var parsed = ok ? parse(codeField.value) : null;
		var def = parsed ? find(parsed.className) : null;
		if (!def) {
			if (panel) panel.parentNode.removeChild(panel);
			if (holder && holder.getAttribute('data-bplplus-hidden')) {
				holder.style.display = '';
				holder.removeAttribute('data-bplplus-hidden');
			}
			S.panelKey = null;
			return;
		}
		var wantDisplay = S.showCode ? '' : 'none';
		if (holder.style.display != wantDisplay) holder.style.display = wantDisplay;
		holder.setAttribute('data-bplplus-hidden', '1');
		var key = indexOf(selected) + '|' + S.showCode + '|' + codeField.value;
		if (panel && (S.panelKey == key) && panel.parentNode) return;
		if (panel && panel.contains(document.activeElement)) return;
		S.panelKey = key;
		if (!panel) {
			panel = document.createElement('div');
			panel.id = 'bplplus-panel';
			panel.className = 'bplplus-panel';
		}
		if (panel.parentNode != holder.parentNode) holder.parentNode.insertBefore(panel, holder);
		panel.innerHTML = core.panelHTML(def, parsed, { readOnly: codeField.disabled || codeField.readOnly, showCode: S.showCode });
		core.bindPanel(panel, {
			input: function (name, value) { change(function (p) { core.apply(p, 'inputs', name, value); }); },
			result: function (name, value) { change(function (p) { core.apply(p, 'results', name, value); }); },
			autoMap: function () { change(function (p, d) { core.autoMap(p, d, nameField.value); }); },
			toggleCode: function () { S.showCode = !S.showCode; S.panelKey = null; schedule(); },
			choices: function (name, done) { loadChoices(def.className, name, done); }
		});
	}
	function change(fn) {
		var codeField = document.getElementById('activity-settings-code-textarea');
		var selected = selectedGroup();
		var parsed = codeField ? parse(codeField.value) : null;
		var def = parsed ? find(parsed.className) : null;
		if (!def) return;
		fn(parsed, def);
		var code = write(def, parsed);
		setNativeValue(codeField, code);
		if (selected) S.codes[indexOf(selected)] = code;
		S.panelKey = null;
		schedule();
	}
	/* The "Custom activities" button next to Add. */
	function addMenuButton() {
		if (document.getElementById('bplplus-add')) return;
		var add = document.getElementById('new-shape-iconbutton');
		if (!add || !S.catalog.length) return;
		var anchor = add.closest('fr-button') || add;
		var wrap = document.createElement('span');
		wrap.id = 'bplplus-add';
		wrap.innerHTML = '<button type="button" class="bplplus-addbtn" title="Add a custom activity">⚙ Custom activities ▾</button><div class="bplplus-menu" hidden></div>';
		anchor.parentNode.insertBefore(wrap, anchor.nextSibling);
		var menu = wrap.querySelector('.bplplus-menu');
		wrap.querySelector('button').addEventListener('click', function (ev) {
			ev.stopPropagation();
			menu.innerHTML = S.catalog.map(function (d) {
				return '<div class="bplplus-item" data-class="' + esc(d.className) + '" title="' + esc(d.description) + '">'
					+ '<i style="background:' + esc(d.color || '#ddd') + '"></i>' + esc(d.caption) + '</div>';
			}).join('');
			menu.hidden = !menu.hidden;
		});
		menu.addEventListener('click', function (ev) {
			var item = ev.target.closest('.bplplus-item');
			menu.hidden = true;
			if (item) addActivity(find(item.getAttribute('data-class')));
		});
		document.addEventListener('click', function () { menu.hidden = true; });
	}

	/* Adds a custom activity: the editor's own Add > Activity > Code, then its
	   name and code. Results are stored in context properties of their own
	   unless the activity turns that off. */
	function addActivity(def) {
		if (!def || S.busy) return;
		var before = shapeGroups().map(function (g) { return g.id; });
		var names = shapeGroups().map(shapeName);
		var name = def.caption, n = 2;
		while (names.indexOf(name) >= 0) name = def.caption + ' ' + (n++);
		S.busy = true;
		var done = function () { S.busy = false; };
		document.getElementById('new-shape-iconbutton').click();
		waitFor(function () { return document.querySelector('.cdk-overlay-container button.mat-mdc-menu-item'); }, function (category) {
			category.click();
			waitFor(function () {
				return Array.prototype.filter.call(document.querySelectorAll('.cdk-overlay-container button.mat-mdc-menu-item'),
					function (b) { return b.textContent.replace(/^\s+|\s+$/g, '') == 'Code'; })[0];
			}, function (codeItem) {
				codeItem.click();
				waitFor(function () {
					return shapeGroups().filter(function (g) { return before.indexOf(g.id) < 0; })[0];
				}, function (g) {
					var main = g.querySelector('[id^="shape_main_"]');
					['mousedown', 'mouseup', 'click'].forEach(function (t) { main.dispatchEvent(new MouseEvent(t, { bubbles: true })); });
					waitFor(function () {
						var c = document.getElementById('activity-settings-code-textarea');
						var nm = document.getElementById('activity-settings-name-input');
						return (c && nm) ? [c, nm] : null;
					}, function (fields) {
						var parsed = core.newParsed(def, name);
						setNativeValue(fields[1], name);
						var code = write(def, parsed);
						setNativeValue(fields[0], code);
						S.codes[indexOf(g)] = code;
						fixPosition(g);
						/* The form does not show what was just written until the
						   shape is selected again: select another one, then this. */
						var other = shapeGroups().filter(function (o) { return o !== g; })[0];
						setTimeout(function () {
							if (other) select(other.querySelector('[id^="shape_main_"]'));
							setTimeout(function () {
								var again = shapeGroups().filter(function (o) { return o.id == g.id; })[0] || g;
								select(again.querySelector('[id^="shape_main_"]'));
								S.panelKey = null;
								done();
								schedule();
							}, 200);
						}, 200);
					}, done);
				}, done);
			}, done);
		}, done);
	}
	function select(el) {
		if (!el) return;
		['mousedown', 'mouseup', 'click'].forEach(function (t) { el.dispatchEvent(new MouseEvent(t, { bubbles: true })); });
	}

	/* When a shape is added on a connection, the editor can give it a negative
	   position, which the server refuses on save (ERROR #9406 on xPos); its own
	   Add > Code does the same. Then the diagram is arranged with the editor's
	   own Arrange button, or, without one, the step goes in the column of the
	   other steps, below the lowest one. */
	function fixPosition(g) {
		var x = document.getElementById('activity-settings-xPos-number');
		var y = document.getElementById('activity-settings-yPos-number');
		if (!x || !y || ((parseInt(x.value, 10) >= 0) && (parseInt(y.value, 10) >= 0))) return;
		var arrange = document.getElementById('arrange-iconbutton');
		if (arrange && !arrange.disabled) {
			arrange.click();
			return;
		}
		var maxY = 0, column = 200;
		shapeGroups().forEach(function (other) {
			if (other === g) return;
			var m = /translate\((-?[\d.]+)[ ,]+(-?[\d.]+)\)/.exec(other.getAttribute('transform') || '');
			if (m && (parseFloat(m[2]) >= maxY)) { maxY = parseFloat(m[2]); column = parseFloat(m[1]); }
		});
		setNativeValue(x, String(Math.max(0, Math.round(column))));
		setNativeValue(y, String(Math.round(maxY) + 100));
	}

	function waitFor(test, then, fail) {
		var tries = 0;
		(function poll() {
			var found = null;
			try { found = test(); } catch (ex) { }
			if (found) return then(found);
			if (++tries > 40) { if (fail) fail(); return; }
			setTimeout(poll, 100);
		})();
	}

	/* The form's look comes from the core; the button and its menu are this
	   editor's own. */
	function addStyle() {
		core.addStyle(document);
		var css = document.createElement('style');
		css.textContent = [
			'#bplplus-add{position:relative;display:inline-block;margin-left:6px;}',
			'#bplplus-add .bplplus-addbtn{border:1px solid #C9B27C;background:#FFFBF0;border-radius:4px;padding:3px 8px;cursor:pointer;font-size:12px;color:#404040;}',
			'#bplplus-add .bplplus-menu{position:absolute;z-index:2000;top:100%;left:0;min-width:200px;background:#fff;border:1px solid #ccc;border-radius:4px;box-shadow:0 2px 8px rgba(0,0,0,.2);}',
			'#bplplus-add .bplplus-item{padding:6px 10px;cursor:pointer;white-space:nowrap;font-size:13px;}',
			'#bplplus-add .bplplus-item:hover{background:#F3F0E6;}',
			'#bplplus-add .bplplus-item i{display:inline-block;width:10px;height:10px;border:1px solid #999;border-radius:2px;margin-right:8px;}'
		].join('\n');
		document.head.appendChild(css);
	}
})();
}

}
