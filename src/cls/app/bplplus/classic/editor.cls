/// The Business Process Designer, with custom activities.
/// <p>
/// This is the standard designer (EnsPortal.BPLEditor), in which a custom
/// activity is a step of its own:
/// <ul>
/// <li>The <b>Add Activity</b> menu gets a <i>Custom activities</i> group listing
/// every subclass of app.bplplus.activity in the namespace.</li>
/// <li>Its shape shows the activity's caption, colour and a gear icon.</li>
/// <li>The Activity tab shows only the activity: a field per parameter, with the
/// help text, required marks and suggested values the activity class declares,
/// and a field per result naming the context property it is stored in.</li>
/// <li>Results are stored in context properties automatically when the activity
/// is added (unless the activity sets ACTIVITYAUTOMAP = 0), and a context
/// property a result is stored in is created when it does not exist yet.</li>
/// </ul>
/// In the BPL a custom activity is a &lt;code&gt; activity whose ObjectScript
/// this page writes: it creates the activity object, sets the parameters, calls
/// Run(process, .result) and stores the results. The page reads the fields back
/// from that code, which is hidden unless asked for. Everything else, saving and
/// compiling included, is the standard designer, so a process edited here still
/// opens, compiles and runs without this page.
/// <p>
/// Open it as <code>/csp/&lt;namespace&gt;/app.bplplus.classic.editor.zen</code>,
/// optionally with <code>?BP=&lt;process class&gt;.bpl</code>, or make it the
/// default designer with app.bplplus.classic.redirect.
/// <p>
/// It reaches into the designer's own JavaScript (the Add Activity select box, the
/// Activity tab and the diagram's shape drawing), which InterSystems does not
/// document as an API. Every hook fails quietly: if an IRIS upgrade changes those
/// internals, the page falls back to the standard designer and custom activities
/// show as ordinary code activities.
Class app.bplplus.classic.editor Extends EnsPortal.BPLEditor
{

/// Keeps the designer's own links (open, save as, new) on this page instead of
/// switching back to the standard designer.
Parameter DESIGNERURL As STRING = "app.bplplus.classic.editor.zen";

/// The custom activities of this namespace as JSON, from
/// app.bplplus.catalog:Activities(), read once when the page is built.
Property activityCatalogJSON As %ZEN.Datatype.string(MAXLEN = "");

/// The new editor with custom activities (app.bplplus.angular.editor), which the
/// designer's "Open in the new UI" button opens instead of the plain new editor.
Parameter NEWEDITORPATH As STRING = "/ui/interop/bpl-plus/index.html";

/// NEWEDITORPATH, for the client side.
Property newEditorPath As %ZEN.Datatype.string [ InitialExpression = {..#NEWEDITORPATH} ];

/// Adds the script both editors share, app.bplplus.editorCore, which defines
/// bplplusCore: reading and writing the code of a custom activity, and its form.
Method %OnDrawHTMLHead() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Write "<script type=""text/javascript"">",!
	Do ##class(app.bplplus.editorCore).WriteScript()
	Write !,"</script>",!
	Quit $$$OK
}

/// Page name in the portal's breadcrumb, so it is clear this is not the standard
/// designer. Not set through the PAGENAME parameter: that is localized at compile
/// time in the designer's "Ensemble" message domain, which lives in the read-only
/// ENSLIB database, so a subclass cannot compile with a new text there.
Method %OnGetPageName() As %String
{
	Quit "Business Process Designer (custom activities)"
}

/// Reads the activity catalog after the standard page is built. A catalog that
/// fails to load leaves the page as the standard designer rather than breaking it.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Try {
		Set ..activityCatalogJSON = ##class(app.bplplus.catalog).Activities().%ToJSON()
	}
	Catch ex {
		Set ..activityCatalogJSON = "[]"
	}
	Quit $$$OK
}

/// What the magnifier of parameter <var>pProperty</var> of activity
/// <var>pClass</var> lists, as JSON (app.bplplus.catalog:Choices). Read when the
/// magnifier is clicked, so the list follows the classes and the running
/// production.
ClassMethod BplplusChoicesJSON(pClass As %String, pProperty As %String) As %String [ ZenMethod ]
{
	Try {
		Set tJSON = ##class(app.bplplus.catalog).Choices(pClass, pProperty).%ToJSON()
	}
	Catch ex {
		Set tJSON = "{}"
	}
	Quit tJSON
}

/// "Open in the new UI": the same as the standard designer's button, but to the
/// new editor with custom activities, so they stay building blocks there.
ClientMethod openNewBPLEditor() [ Language = javascript ]
{
	var prefix = window.location.href.split('/csp/')[0];
	var namespace = zenPage.currentNamespace || '';
	var href = prefix + this.newEditorPath + '?';
	if (namespace) {
		href += ('$NAMESPACE=' + encodeURIComponent(namespace));
	}
	if (zenPage.bpId) {
		href += ('&BP=' + encodeURIComponent(zenPage.bpId));
	}
	window.location.href = href;
}

/// The catalog as a JavaScript array, parsed once.
ClientMethod bplplusCatalog() [ Language = javascript ]
{
	if (!this._bplplusList) {
		try {
			this._bplplusList = JSON.parse(this.activityCatalogJSON || '[]');
		}
		catch (ex) {
			this._bplplusList = [];
		}
	}
	return this._bplplusList;
}

/// The catalog entry for activity class <var>className</var>, or null when that
/// class is not a custom activity.
ClientMethod bplplusFind(className) [ Language = javascript ]
{
	if (!className) return null;
	var list = this.bplplusCatalog();
	for (var i = 0; i < list.length; i++) {
		if (list[i].className == className) return list[i];
	}
	return null;
}

/// Writes the code of the custom activity <var>model</var> from
/// <var>parsed</var> (bplplusCore.write). It also updates the (hidden) code
/// field, so a later change of name or annotation does not put the old code
/// back.
ClientMethod bplplusWrite(model, def, parsed) [ Language = javascript ]
{
	model.Code = bplplusCore.write(def,parsed);
	if (this._currShape && (this._currShape.model === model)) {
		var codeField = zen('codeCode');
		if (codeField) codeField.setValue(model.Code);
	}
}

/// The catalog entry of the custom activity <var>model</var> is, or null when
/// the shape is anything else.
ClientMethod bplplusDefOf(model) [ Language = javascript ]
{
	if (!model || (model.Type != 'code') || !window.bplplusCore) return null;
	var parsed = bplplusCore.parse(model.Code);
	return parsed ? this.bplplusFind(parsed.className) : null;
}

/// Hooks into the diagram before the standard code draws it, so custom
/// activities are drawn as themselves from the first render on, and adds the
/// custom activities to the Add Activity menu.
ClientMethod initializeSVG() [ Language = javascript ]
{
	try {
		this.bplplusPatchCanvas();
		this.bplplusFillMenu();
	}
	catch (ex) {
		// leave the standard designer working
	}
	return this.invokeSuper('initializeSVG',arguments);
}

/// Adds a "Custom activities" group to the Add Activity select box. The option
/// values start with "bplstep:" so addNewShape can tell them from built-in types.
ClientMethod bplplusFillMenu() [ Language = javascript ]
{
	var select = self.document.getElementById('selectNewShape');
	var list = this.bplplusCatalog();
	if (!select || !list.length || self.document.getElementById('bplplusMenuGroup')) return;
	var group = self.document.createElement('optgroup');
	group.id = 'bplplusMenuGroup';
	group.label = 'Custom activities';
	for (var i = 0; i < list.length; i++) {
		var option = self.document.createElement('option');
		option.value = 'bplstep:' + list[i].className;
		option.title = list[i].description || list[i].className;
		option.text = ' ' + list[i].caption + ' ';
		group.appendChild(option);
	}
	select.appendChild(group);
}

/// Wraps the diagram's activity drawing so a custom activity is redrawn as
/// itself after the standard drawing. The diagram lives in its own SVG frame, so
/// the patch goes on that window's BPL.Activity.
ClientMethod bplplusPatchCanvas() [ Language = javascript ]
{
	var svgWin = this.getSVGWindow();
	if (!svgWin || !svgWin.BPL || !svgWin.BPL.Activity) return;
	var proto = svgWin.BPL.Activity.prototype;
	if (proto._bplplusPatched) return;
	var standardRender = proto.render;
	var page = this;
	proto.render = function bplplus_render() {
		var drawn = standardRender.apply(this,arguments);
		try {
			page.bplplusDecorate(this);
		}
		catch (ex) {
			// a failed decoration leaves the standard shape
		}
		return drawn;
	};
	proto._bplplusPatched = true;
}

/// Draws a custom activity as itself: its caption in place of &lt;code&gt;, its
/// colour, and a gear instead of the code icon.
ClientMethod bplplusDecorate(shape) [ Language = javascript ]
{
	var model = shape ? shape.model : null;
	var def = this.bplplusDefOf(model);
	if (!def || !shape.svgGroup) return;
	var svgDoc = shape.svgGroup.ownerDocument;
	var texts = shape.svgGroup.getElementsByTagName('text');
	for (var i = 0; i < texts.length; i++) {
		if (texts[i].getAttribute('class') == 'ActivityType') {
			texts[i].textContent = def.caption;
		}
	}
	var main = svgDoc.getElementById('shape_main_' + model.Index);
	if (main && def.color) main.style.fill = def.color;
	var icon = svgDoc.getElementById('icon_' + model.Index);
	if (icon) {
		icon.style.display = 'none';
		var gear = svgDoc.createElementNS('http://www.w3.org/2000/svg','text');
		gear.setAttribute('x','100');
		gear.setAttribute('y','14');
		gear.setAttribute('text-anchor','middle');
		gear.setAttribute('style','font-size: 16px; fill: #806030;');
		gear.textContent = '⚙';
		shape.svgGroup.appendChild(gear);
	}
}

/// Handles the Add Activity menu: options of the custom group add a custom
/// activity, everything else goes to the standard code.
ClientMethod addNewShape(shapeType) [ Language = javascript ]
{
	var select = self.document.getElementById('selectNewShape');
	var type = shapeType ? shapeType : (select ? select.value : '');
	if (type && (type.indexOf('bplstep:') == 0)) {
		if (select) select.value = '';
		if (!this.checkEdit()) return false;
		this.bplplusAdd(type.substring(8));
		return true;
	}
	return this.invokeSuper('addNewShape',arguments);
}

/// Adds activity <var>className</var> to the diagram: a code activity, in
/// ObjectScript whatever the process language, with every parameter that has a
/// default set to it and, unless the activity turns that off, every result stored
/// in a context property of its own (created if needed). It is connected and
/// selected like any new shape.
ClientMethod bplplusAdd(className) [ Language = javascript ]
{
	var def = this.bplplusFind(className);
	if (!def) return;
	this.startUndoAction();
	this.setOption('autoArrange',false);
	var parent = this._BPLDiagram ? this._BPLDiagram.currentParent : null;
	var model = this.createShapeModel('code',this.bplplusUniqueName(def.caption),parent,null,null,'',true);
	if (model) {
		model.PropertyBag.LanguageOverride = 'objectscript';
		var parsed = bplplusCore.newParsed(def,model.Name);
		this.bplplusEnsureContext(parsed,def);
		this.bplplusWrite(model,def,parsed);
		var shape = this._BPLDiagram ? this._BPLDiagram.shapeList[model.Index] : null;
		if (shape) {
			shape.render();
			this._BPLDiagram.selectItem(shape);
		}
	}
	this.setOption('autoArrange',this.prefAutoArrange);
	this.endUndoAction();
}

/// <var>caption</var>, or caption 2, 3 ... when an activity of that name is
/// already in the diagram, so the generated context properties stay apart.
ClientMethod bplplusUniqueName(caption) [ Language = javascript ]
{
	var names = {};
	var shapes = this._BPLDiagram ? this._BPLDiagram.shapeList : [];
	for (var i = 0; i < shapes.length; i++) {
		if (shapes[i] && shapes[i].model) names[shapes[i].model.Name] = true;
	}
	if (!names[caption]) return caption;
	var n = 2;
	while (names[caption + ' ' + n]) n++;
	return caption + ' ' + n;
}

/// Creates the context properties the results in <var>parsed</var> are stored in
/// (context.X), with the result's type, when the process does not have them yet.
/// Text results keep their MAXLEN, so a long result is not cut off at the
/// %String default of 50.
ClientMethod bplplusEnsureContext(parsed, def) [ Language = javascript ]
{
	var bpl = this.getBPLObject();
	if (!bpl || !bpl.Context) return;
	if (!bpl.Context.Properties) bpl.Context.Properties = [];
	var list = bpl.Context.Properties;
	var added = false;
	for (var r = 0; r < def.outputs.length; r++) {
		var result = def.outputs[r];
		var name = bplplusCore.contextProperty(parsed.results[result.name]);
		if (!name) continue;
		var exists = false;
		for (var i = 0; i < list.length; i++) {
			if (list[i].Name == name) exists = true;
		}
		if (exists) continue;
		var parms = [];
		if ((typeof result.maxLen != 'undefined') && (result.maxLen !== null)) {
			parms.push({ "Name": "MAXLEN", "Value": String(result.maxLen) });
		}
		list.push({ "_type": null, "Name": name, "Type": result.type, "InitialExpression": "", "Collection": "",
			"Annotation": result.name + ' of ' + def.caption, "Parameters": parms,
			"Instantiate": false, "DeleteWithContext": false });
		added = true;
	}
	if (added) this.renderContextTable();
}

/// Shows the standard Activity tab, then turns it into the activity's own form
/// when the selected shape is a custom activity.
ClientMethod updateActivitySettings(shape, isUpdate, noTabSelect) [ Language = javascript ]
{
	var shown = this.invokeSuper('updateActivitySettings',arguments);
	try {
		this.bplplusRenderPanel(shape);
	}
	catch (ex) {
		// the standard Activity tab is still complete
	}
	return shown;
}

/// Shows or hides the generated code of custom activities.
ClientMethod bplplusToggleCode() [ Language = javascript ]
{
	this._bplplusShowCode = !this._bplplusShowCode;
	this.bplplusRenderPanel(this._currShape);
}

/// Draws the activity's own form under its name, position and annotation, and
/// hides the code unless asked for: one field per parameter, holding its
/// expression, and one per result, holding the property it is stored in.
ClientMethod bplplusRenderPanel(shape) [ Language = javascript ]
{
	var old = self.document.getElementById('bplplusPanel');
	if (old) old.parentNode.removeChild(old);
	var model = shape ? shape.model : null;
	var def = this.bplplusDefOf(model);
	var desc = zen('aDesc');
	var descDiv = desc ? desc.getEnclosingDiv() : null;
	// The form goes under the activity's name, position and annotation, in the
	// annotation's cell; without one, in the description at the top.
	var annotation = zen('aAnnotation');
	var annotationDiv = annotation ? annotation.getEnclosingDiv() : null;
	var host = (annotationDiv && annotationDiv.parentNode) ? annotationDiv.parentNode : descDiv;
	if (!def || !host) return;
	var parsed = bplplusCore.parse(model.Code);

	var codeGroup = zen('vgCode');
	if (codeGroup) codeGroup.setProperty('hidden',!this._bplplusShowCode);

	// The standard description ("<code> Executes ...") says nothing about the
	// activity; the form has its own title.
	if (descDiv) descDiv.innerHTML = '';
	bplplusCore.addStyle(self.document);
	var panel = self.document.createElement('div');
	panel.id = 'bplplusPanel';
	panel.className = 'bplplus-panel';
	panel.innerHTML = bplplusCore.panelHTML(def,parsed,{ readOnly: (this.readOnly || !this.canEdit), showCode: this._bplplusShowCode });
	host.appendChild(panel);
	var page = this;
	bplplusCore.bindPanel(panel,{
		input: function(name,value) { page.bplplusChange(function(p) { bplplusCore.apply(p,'inputs',name,value); }); },
		result: function(name,value) { page.bplplusChange(function(p,d) { bplplusCore.apply(p,'results',name,value); page.bplplusEnsureContext(p,d); }); },
		autoMap: function() { page.bplplusChange(function(p,d,m) { bplplusCore.autoMap(p,d,m.Name); page.bplplusEnsureContext(p,d); }); },
		toggleCode: function() { page.bplplusToggleCode(); },
		choices: function(name,done) {
			var choices = null;
			try {
				choices = JSON.parse(page.BplplusChoicesJSON(def.className,name) || '{}');
			}
			catch (ex) {
				done(null,'The list could not be read.');
				return;
			}
			done(choices);
		}
	});
}

/// Applies <var>change</var> to the parsed code of the selected custom activity
/// and writes the code again, as one undo step, then redraws the form.
ClientMethod bplplusChange(change) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) return;
	var shape = this._currShape;
	var model = shape ? shape.model : null;
	var def = this.bplplusDefOf(model);
	if (!def) return;
	var parsed = bplplusCore.parse(model.Code);
	this.startUndoAction();
	change.call(this,parsed,def,model);
	this.bplplusWrite(model,def,parsed);
	this.endUndoAction();
	this.bplplusRenderPanel(shape);
}

}
