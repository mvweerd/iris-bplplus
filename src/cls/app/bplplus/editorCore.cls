/// What both editors (app.bplplus.classic.editor and app.bplplus.angular.editor)
/// share: the JavaScript in XData Script that reads and writes the code of a
/// custom activity, names the context properties its results go to, and draws
/// its form. Each editor only adds how it hooks into its own page.
/// <p>
/// The code of a custom activity is a &lt;code&gt; activity whose first line is
/// the marker followed by the activity class, then
/// <code>Set bplstep.Param = expression</code> per parameter, the call of Run, and
/// <code>Set target = bplstepResult.Result</code> per stored result. Both editors
/// recognise a custom activity by that marker, so the format is defined here, in
/// one place, and tests/js checks it against the demo processes.
Class app.bplplus.editorCore [ Abstract ]
{

/// Writes the script to the current device: inside a &lt;script&gt; element of a
/// page, or as the body of a served script.
ClassMethod WriteScript()
{
	Set tXData = ##class(%Dictionary.CompiledXData).%OpenId($ClassName()_"||Script")
	If '$IsObject(tXData) Quit
	Do tXData.Data.Rewind()
	Do tXData.Data.OutputToDevice()
}

/// The shared script. It defines window.bplplusCore and nothing else.
XData Script [ MimeType = application/javascript ]
{
/* Shared by both BPL editors with custom activities (app.bplplus.editorCore). */
(function (global) {
	'use strict';
	if (global.bplplusCore) return;
	var MARKER = '// bplstep ';

	/* Reads the code of a custom activity: the activity class from the marker
	   line, the expression of every parameter and the property every result is
	   stored in. null for code without the marker, any ordinary code activity. */
	function parse(code) {
		var lines = String(code || '').split(/\r?\n/), parsed = null;
		for (var i = 0; i < lines.length; i++) {
			var line = lines[i].replace(/^\s+|\s+$/g, '');
			if (!parsed) {
				if (line === '') continue;
				if (line.indexOf(MARKER) !== 0) return null;
				parsed = { className: line.substring(MARKER.length).split(' ')[0], inputs: {}, results: {} };
				continue;
			}
			var m = /^Set bplstep\.([A-Za-z][A-Za-z0-9]*) = (.*)$/.exec(line);
			if (m) { parsed.inputs[m[1]] = m[2]; continue; }
			m = /^Set (.+) = bplstepResult\.([A-Za-z][A-Za-z0-9]*)$/.exec(line);
			if (m) parsed.results[m[2]] = m[1];
		}
		return parsed;
	}

	/* Writes the code of a custom activity from parsed: parameters and results
	   in the order the activity class declares them, and a Quit on error so a
	   failed activity raises a fault like any other activity. */
	function write(def, parsed) {
		var lines = [' ' + MARKER + def.className + ' - written by the designer: change it there, not here',
			' Set bplstep = ' + (def.create || ('##class(' + def.className + ').%New()'))];
		def.inputs.forEach(function (input) {
			if (parsed.inputs[input.name] !== undefined) lines.push(' Set bplstep.' + input.name + ' = ' + parsed.inputs[input.name]);
		});
		lines.push(' Set status = bplstep.Run(process, .bplstepResult)');
		lines.push(' If $$$ISERR(status) Quit');
		def.outputs.forEach(function (result) {
			if (parsed.results[result.name] !== undefined) lines.push(' Set ' + parsed.results[result.name] + ' = bplstepResult.' + result.name);
		});
		return lines.join('\n');
	}

	/* The context property a result is stored in by default: the activity's
	   name in CamelCase followed by the result's name, such as
	   context.ValidateValueSuccess, so several activities never share one. */
	function autoTarget(activityName, result) {
		var stem = '';
		String(activityName || '').split(/[^A-Za-z0-9]+/).forEach(function (w) {
			if (w) stem += w.charAt(0).toUpperCase() + w.substring(1);
		});
		if (!/^[A-Za-z]/.test(stem)) stem = 'Step' + stem;
		return 'context.' + stem + result.name;
	}

	/* The parsed code of a newly added activity: parameters with a default set
	   to it, and, unless the activity turns that off, every result stored in a
	   context property of its own. */
	function newParsed(def, activityName) {
		var parsed = { className: def.className, inputs: {}, results: {} };
		def.inputs.forEach(function (input) {
			if (input['default'] !== '') parsed.inputs[input.name] = input['default'];
		});
		if (def.autoMap) autoMap(parsed, def, activityName);
		return parsed;
	}

	/* Stores every result that is not stored yet in a context property of its
	   own. */
	function autoMap(parsed, def, activityName) {
		def.outputs.forEach(function (result) {
			if (parsed.results[result.name] === undefined) parsed.results[result.name] = autoTarget(activityName, result);
		});
	}

	/* Sets parameter or result name to value (trimmed); empty removes it, so a
	   parameter keeps the activity's own initial value and a result is not
	   stored. kind is 'inputs' or 'results'. */
	function apply(parsed, kind, name, value) {
		value = String(value == null ? '' : value).replace(/^\s+|\s+$/g, '');
		if (value === '') delete parsed[kind][name]; else parsed[kind][name] = value;
	}

	/* The name of the context property target stores into (X of context.X), or
	   null when target is anything else. */
	function contextProperty(target) {
		var m = /^context\.([A-Za-z][A-Za-z0-9]*)$/.exec(String(target || ''));
		return m ? m[1] : null;
	}

	function esc(text) {
		return String(text == null ? '' : text).replace(/&/g, '&amp;').replace(/</g, '&lt;')
			.replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
	}

	function listValues(valueList) {
		return valueList ? valueList.substring(1).split(valueList.charAt(0)) : [];
	}

	/* The form of a custom activity, as HTML: its description, a field per
	   parameter (with help, required mark and suggested values) and per result,
	   and links. Fields and links carry data- attributes that bindPanel wires up.
	   options: readOnly, showCode, listPrefix (unique per page for the
	   datalists). */
	function panelHTML(def, parsed, options) {
		options = options || {};
		var dis = options.readOnly ? ' disabled' : '', h = [], prefix = options.listPrefix || 'bplplus-list-';
		h.push('<div class="bplplus-title">' + esc(def.caption) + ' <span>custom activity</span></div>');
		if (def.description) h.push('<div class="bplplus-desc">' + esc(def.description) + '</div>');
		h.push('<div class="bplplus-section">Parameters</div>');
		if (!def.inputs.length) h.push('<div class="bplplus-help">This activity has no parameters.</div>');
		def.inputs.forEach(function (input, i) {
			var value = (parsed.inputs[input.name] !== undefined) ? parsed.inputs[input.name] : '';
			var suggestions = listValues(input.valueList).map(function (v) { return '"' + v + '"'; });
			if (!suggestions.length && (input.type == '%Library.Boolean')) suggestions = ['1', '0'];
			h.push('<div class="bplplus-field' + ((input.required && (value === '')) ? ' bplplus-missing' : '') + '">');
			h.push('<label>' + esc(input.name) + (input.required ? ' <b title="Required">*</b>' : '') + '</label>');
			var field = '<input type="text" data-input="' + esc(input.name) + '" value="' + esc(value) + '"' + dis
				+ (suggestions.length ? ' list="' + prefix + i + '"' : '') + ' placeholder="' + (input.required ? 'required' : 'not set') + '">';
			/* A parameter with a context search (app.bplplus.lookup) gets a
			   magnifier, and a list under the field that bindPanel fills when it is
			   clicked. */
			if (input.lookup && !options.readOnly) {
				h.push('<div class="bplplus-row">' + field + '<button type="button" class="bplplus-lookup" data-lookup="' + esc(input.name)
					+ '" title="Choose from a list">&#x1F50D;</button></div>');
				h.push('<div class="bplplus-picker" data-picker="' + esc(input.name) + '" hidden></div>');
			}
			else h.push(field);
			if (suggestions.length) {
				h.push('<datalist id="' + prefix + i + '">');
				suggestions.forEach(function (s) { h.push('<option value="' + esc(s) + '"></option>'); });
				h.push('</datalist>');
			}
			var help = input.description || '';
			if (input.valueList) help += (help ? ' ' : '') + 'One of: ' + listValues(input.valueList).join(', ') + '.';
			else if (input.type == '%Library.Boolean') help += (help ? ' ' : '') + '1 or 0.';
			if (help) h.push('<div class="bplplus-help">' + esc(help) + '</div>');
			h.push('</div>');
		});
		if (def.outputs.length) {
			h.push('<div class="bplplus-section">Results, stored in</div>');
			def.outputs.forEach(function (result) {
				var target = (parsed.results[result.name] !== undefined) ? parsed.results[result.name] : '';
				h.push('<div class="bplplus-field"><label>' + esc(result.name) + '</label>');
				h.push('<input type="text" data-result="' + esc(result.name) + '" value="' + esc(target) + '"' + dis + ' placeholder="not stored">');
				if (result.description) h.push('<div class="bplplus-help">' + esc(result.description) + '</div>');
				h.push('</div>');
			});
			if (!options.readOnly) h.push('<div><a class="bplplus-link" data-automap>Store every result in its own context property</a></div>');
		}
		h.push('<div class="bplplus-hint">Values are ObjectScript expressions: quote literal text ("abc"), or refer to request.Property or context.Property. '
			+ 'A context property named under results is created when it does not exist yet.</div>');
		h.push('<div><a class="bplplus-link" data-togglecode>' + (options.showCode ? 'Hide the generated code' : 'Show the generated code') + '</a></div>');
		return h.join('');
	}

	/* A value as an ObjectScript string literal, as a field holds an expression. */
	function literal(value) {
		return '"' + String(value == null ? '' : value).replace(/"/g, '""') + '"';
	}

	/* The list of a magnifier, as HTML, from the result of a context search
	   (app.bplplus.catalog:Choices): its caption, the top results, then the
	   others below a line. error is shown instead when it could not be read. */
	function pickerHTML(choices, error) {
		if (error) return '<div class="bplplus-help">' + esc(error) + '</div>';
		var top = (choices && choices.top) || [], other = (choices && choices.other) || [];
		if (!top.length && !other.length) return '<div class="bplplus-help">Nothing to choose from.</div>';
		var line = function (value) { return '<div class="bplplus-choice" data-value="' + esc(value) + '">' + esc(value) + '</div>'; };
		return (choices.caption ? '<div class="bplplus-help">' + esc(choices.caption) + '</div>' : '')
			+ top.map(line).join('')
			+ ((top.length && other.length) ? '<div class="bplplus-rule"></div>' : '')
			+ other.map(line).join('');
	}

	/* Wires the fields and links of a form from panelHTML to handlers:
	   input(name, value), result(name, value), autoMap(), toggleCode(), and
	   choices(name, done) for a magnifier: it runs the search of parameter name
	   and calls done(choices) or done(null, error). Picking a choice is an
	   input(name, the choice as a string literal). */
	function bindPanel(panel, handlers) {
		Array.prototype.forEach.call(panel.querySelectorAll('[data-input]'), function (el) {
			el.addEventListener('change', function () { handlers.input(el.getAttribute('data-input'), el.value); });
		});
		Array.prototype.forEach.call(panel.querySelectorAll('[data-lookup]'), function (button) {
			var name = button.getAttribute('data-lookup');
			var picker = null;
			Array.prototype.forEach.call(panel.querySelectorAll('[data-picker]'), function (p) {
				if (p.getAttribute('data-picker') === name) picker = p;
			});
			if (!picker || !handlers.choices) return;
			button.addEventListener('click', function () {
				if (!picker.hidden) { picker.hidden = true; return; }
				picker.innerHTML = '<div class="bplplus-help">Loading&hellip;</div>';
				picker.hidden = false;
				handlers.choices(name, function (choices, error) {
					picker.innerHTML = pickerHTML(choices, error);
				});
			});
			picker.addEventListener('click', function (ev) {
				var choice = ev.target.closest ? ev.target.closest('[data-value]') : null;
				if (!choice) return;
				picker.hidden = true;
				/* Shown at once: an editor may not draw the form again while it
				   has the focus. */
				var value = literal(choice.getAttribute('data-value'));
				Array.prototype.forEach.call(panel.querySelectorAll('[data-input]'), function (el) {
					if (el.getAttribute('data-input') === name) el.value = value;
				});
				handlers.input(name, value);
			});
		});
		Array.prototype.forEach.call(panel.querySelectorAll('[data-result]'), function (el) {
			el.addEventListener('change', function () { handlers.result(el.getAttribute('data-result'), el.value); });
		});
		var auto = panel.querySelector('[data-automap]');
		if (auto) auto.addEventListener('click', function () { handlers.autoMap(); });
		var code = panel.querySelector('[data-togglecode]');
		if (code) code.addEventListener('click', function () { handlers.toggleCode(); });
	}

	/* The form's look, added once to document doc. */
	function addStyle(doc) {
		if (doc.getElementById('bplplus-style')) return;
		var css = doc.createElement('style');
		css.id = 'bplplus-style';
		css.textContent = [
			'.bplplus-panel{box-sizing:border-box;max-width:100%;margin:6px 0 10px 0;padding:8px 10px;border:1px solid #C9B27C;border-radius:4px;background:#FFFBF0;font-size:12px;white-space:normal;overflow-wrap:anywhere;}',
			'.bplplus-panel .bplplus-title{font-weight:bold;font-size:13px;color:#404040;}',
			'.bplplus-panel .bplplus-title span{font-weight:normal;font-size:11px;color:#907030;}',
			'.bplplus-panel .bplplus-desc{color:#606060;margin:2px 0 6px 0;}',
			'.bplplus-panel .bplplus-section{margin-top:10px;font-weight:bold;color:#404080;}',
			'.bplplus-panel .bplplus-field{margin-top:6px;}',
			'.bplplus-panel label{display:block;font-weight:bold;color:#404040;}',
			'.bplplus-panel label b{color:#C00000;}',
			'.bplplus-panel input{box-sizing:border-box;width:100%;font-family:monospace;font-size:12px;padding:2px 4px;border:1px solid #bbb;border-radius:3px;}',
			'.bplplus-panel .bplplus-missing input{border-color:#C00000;background:#FFF0F0;}',
			'.bplplus-panel .bplplus-help{color:#707070;font-size:11px;}',
			'.bplplus-panel .bplplus-hint{margin-top:8px;color:#707070;font-size:11px;font-style:italic;}',
			'.bplplus-panel .bplplus-link{color:#3060A0;cursor:pointer;text-decoration:underline;font-size:11px;}',
			'.bplplus-panel .bplplus-row{display:flex;gap:3px;}',
			'.bplplus-panel .bplplus-row input{flex:1;min-width:0;}',
			'.bplplus-panel .bplplus-lookup{flex:none;padding:0 4px;font-size:12px;line-height:18px;border:1px solid #bbb;border-radius:3px;background:#fff;cursor:pointer;}',
			'.bplplus-panel .bplplus-picker{margin-top:2px;max-height:220px;overflow-y:auto;border:1px solid #C9B27C;border-radius:3px;background:#fff;}',
			'.bplplus-panel .bplplus-picker[hidden]{display:none;}',
			'.bplplus-panel .bplplus-choice{padding:3px 6px;cursor:pointer;border-bottom:1px solid #f0e8d8;}',
			'.bplplus-panel .bplplus-choice:hover{background:#FFF3D6;}',
			'.bplplus-panel .bplplus-choice{font-family:monospace;color:#303030;}',
			'.bplplus-panel .bplplus-picker .bplplus-help{padding:3px 6px;}',
			'.bplplus-panel .bplplus-rule{border-top:2px solid #C9B27C;}'
		].join('\n');
		(doc.head || doc.documentElement).appendChild(css);
	}

	global.bplplusCore = {
		MARKER: MARKER, parse: parse, write: write, autoTarget: autoTarget, newParsed: newParsed,
		autoMap: autoMap, apply: apply, contextProperty: contextProperty, esc: esc,
		literal: literal, panelHTML: panelHTML, pickerHTML: pickerHTML, bindPanel: bindPanel, addStyle: addStyle
	};
})(typeof window !== 'undefined' ? window : globalThis);
}

}
