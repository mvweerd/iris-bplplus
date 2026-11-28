// Tests the script both editors share (XData Script of app.bplplus.editorCore):
// the format of the code of a custom activity, checked against the activity
// classes and the demo processes in this repo. Run with: node --test tests/js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const ROOT = path.join(__dirname, '..', '..');
const read = (rel) => fs.readFileSync(path.join(ROOT, rel), 'utf8');

// The script, taken from the class as IRIS serves it, run in a sandbox.
function loadCore() {
	const cls = read('src/cls/app/bplplus/editorCore.cls');
	const start = cls.indexOf('{', cls.search(/^XData Script/m)) + 1;
	const end = cls.lastIndexOf('}', cls.lastIndexOf('}') - 1);
	const sandbox = {};
	sandbox.globalThis = sandbox;
	vm.runInNewContext(cls.substring(start, end), sandbox);
	return sandbox.bplplusCore;
}
const core = loadCore();

// The properties of an activity or result class file, in declaration order.
function properties(rel) {
	return [...read(rel).matchAll(/^Property (\w+) As ([\w%.]+)/gm)].map((m) => ({ name: m[1], type: m[2] }));
}
// The file of an activity: a class, or for "python:module.Class" the module.
function classFile(className) {
	if (className.startsWith('python:')) {
		return 'src/python/' + className.substring(7).split('.').slice(0, -1).join('/') + '.py';
	}
	return 'src/cls/' + className.replace(/\./g, '/') + '.cls';
}
// What the catalog says about an activity class, built from its file the same
// way: inputs in declaration order, results inherited first, then its own. A
// Python activity declares its parameters and results as Param(...) and
// Result(...) attributes, and is created through app.bplplus.python.step.
function describe(className) {
	const file = classFile(className);
	if (className.startsWith('python:')) {
		const source = read(file);
		const declared = (kind) => [...source.matchAll(new RegExp('^\\s+(\\w+) = ' + kind + '\\(', 'gm'))].map((m) => ({ name: m[1], default: '' }));
		const pathName = className.substring(7);
		return {
			className, caption: className,
			create: '##class(app.bplplus.python.step).%New("' + pathName + '")',
			inputs: declared('Param'),
			outputs: [{ name: 'Success' }, { name: 'ResultText' }, ...declared('Result')]
		};
	}
	const resultClass = (/Parameter ACTIVITYRESULT = "([^"]+)"/.exec(read(file)) || [])[1] || 'app.bplplus.activityResult';
	const results = properties(classFile('app.bplplus.activityResult'));
	if (resultClass !== 'app.bplplus.activityResult') results.push(...properties(classFile(resultClass)));
	return { className, caption: className, inputs: properties(file).map((p) => ({ ...p, default: '' })), outputs: results };
}

// Every code block with the marker in the demo processes and the example
// processes.
function demoBlocks() {
	const blocks = [];
	for (const dir of ['tests/app/bplplus', 'src/cls/app/bplplus/examples']) {
		for (const name of fs.readdirSync(path.join(ROOT, dir), { recursive: true })) {
			if (!String(name).endsWith('.cls')) continue;
			const text = read(path.join(dir, String(name)));
			for (const m of text.matchAll(/<!\[CDATA\[\n?([\s\S]*?)\n?\]\]>/g)) {
				if (m[1].includes(core.MARKER)) blocks.push({ file: name, code: m[1] });
			}
		}
	}
	return blocks;
}

test('the demo processes have custom activities to check', () => {
	assert.ok(demoBlocks().length >= 8, 'found ' + demoBlocks().length);
});

test('every demo activity is an existing class with existing parameters and results', () => {
	for (const { file, code } of demoBlocks()) {
		const parsed = core.parse(code);
		assert.ok(parsed, file + ': not recognised');
		assert.ok(fs.existsSync(path.join(ROOT, classFile(parsed.className))), file + ': no class ' + parsed.className);
		const def = describe(parsed.className);
		for (const name of Object.keys(parsed.inputs)) {
			assert.ok(def.inputs.some((p) => p.name === name), `${file}: ${parsed.className} has no parameter ${name}`);
		}
		for (const name of Object.keys(parsed.results)) {
			assert.ok(def.outputs.some((p) => p.name === name), `${file}: ${parsed.className} has no result ${name}`);
		}
	}
});

test('write gives back exactly the code of every demo activity', () => {
	for (const { file, code } of demoBlocks()) {
		const parsed = core.parse(code);
		assert.equal(core.write(describe(parsed.className), parsed), code, file + ': ' + parsed.className);
	}
});

test('ordinary code is not a custom activity', () => {
	assert.equal(core.parse(' Set x = 1'), null);
	assert.equal(core.parse(''), null);
	assert.equal(core.parse(' Set x = 1\n // bplstep app.x.y'), null, 'the marker has to come first');
	assert.equal(core.parse('\n\n // bplstep app.x.y').className, 'app.x.y', 'blank lines before it are fine');
});

// Objects made in the sandbox have the sandbox's prototypes, so compare them as
// JSON.
const same = (actual, expected, message) => assert.equal(JSON.stringify(actual), JSON.stringify(expected), message);

test('parse and write round-trip, in declaration order whatever the order of setting', () => {
	const def = describe('app.bplplus.examples.validateValue');
	const parsed = { className: def.className, inputs: { Pattern: '"[0-9]+"', Value: 'request.Text' }, results: { Success: 'context.Ok' } };
	const code = core.write(def, parsed);
	assert.ok(code.indexOf('bplstep.Value') < code.indexOf('bplstep.Pattern'), 'Value before Pattern, as declared');
	const back = core.parse(code);
	same(back.inputs, { Value: 'request.Text', Pattern: '"[0-9]+"' }, 'read back in declaration order');
	same(back.results, parsed.results);
});

test('a new activity gets its defaults and, by default, a context property per result', () => {
	const def = describe('app.bplplus.examples.validateValue');
	def.inputs.find((i) => i.name === 'FailureText').default = '"Value is not valid"';
	def.autoMap = true;
	const parsed = core.newParsed(def, 'Validate value 2');
	assert.equal(parsed.inputs.FailureText, '"Value is not valid"');
	assert.equal(parsed.inputs.Value, undefined, 'no default, not set');
	assert.equal(parsed.results.Success, 'context.ValidateValue2Success');
	assert.equal(parsed.results.ResultText, 'context.ValidateValue2ResultText');
	def.autoMap = false;
	same(core.newParsed(def, 'x').results, {});
});

test('names, context properties and escaping', () => {
	assert.equal(core.autoTarget('2nd check', { name: 'Success' }), 'context.Step2ndCheckSuccess');
	assert.equal(core.contextProperty('context.Valid'), 'Valid');
	assert.equal(core.contextProperty('response.Valid'), null);
	assert.equal(core.esc('<a href="x">\'&'), '&lt;a href=&quot;x&quot;&gt;&#39;&amp;');
	const parsed = { inputs: { A: '1' }, results: {} };
	core.apply(parsed, 'inputs', 'A', '  ');
	same(parsed.inputs, {}, 'empty removes');
	core.apply(parsed, 'results', 'Success', ' context.X ');
	assert.equal(parsed.results.Success, 'context.X', 'trimmed');
});

test('a parameter with a context search gets a magnifier, and its list shows the results', () => {
	const def = describe('app.bplplus.call.callProcess');
	def.inputs.find((i) => i.name === 'Target').lookup = true;
	const html = core.panelHTML(def, { inputs: {}, results: {} }, {});
	assert.ok(html.includes('data-lookup="Target"'), 'a magnifier on Target');
	assert.ok(html.includes('data-picker="Target"'), 'with a list under it');
	assert.equal((html.match(/data-lookup=/g) || []).length, 1, 'only on Target');
	assert.ok(!core.panelHTML(def, { inputs: {}, results: {} }, { readOnly: true }).includes('data-lookup'), 'none when read-only');

	const list = core.pickerHTML({ caption: 'BPL <processes>', top: ['a.Fits'], other: ['b.Other'] });
	assert.ok(list.includes('BPL &lt;processes&gt;'), 'the caption, escaped');
	assert.ok(list.indexOf('data-value="a.Fits"') < list.indexOf('bplplus-rule'), 'top results first');
	assert.ok(list.indexOf('bplplus-rule') < list.indexOf('data-value="b.Other"'), 'then the others, below a line');
	assert.ok(!core.pickerHTML({ top: ['a'], other: [] }).includes('bplplus-rule'), 'no line without others');
	assert.ok(core.pickerHTML(null, 'Failed <here>').includes('Failed &lt;here&gt;'));
	assert.ok(core.pickerHTML({ top: [], other: [] }).includes('Nothing to choose from'));
	assert.equal(core.literal('my.bp'), '"my.bp"', 'a choice is filled in as a string literal');
	assert.equal(core.literal('say "hi"'), '"say ""hi"""', 'with quotes doubled');
});

test('the form has a field per parameter and result, escaped', () => {
	const def = describe('app.bplplus.examples.sendNotification');
	def.caption = 'Send <notification>';
	const html = core.panelHTML(def, { inputs: { Subject: '"a "quoted" text"' }, results: {} }, {});
	for (const p of def.inputs) assert.ok(html.includes(`data-input="${p.name}"`), p.name);
	for (const r of def.outputs) assert.ok(html.includes(`data-result="${r.name}"`), r.name);
	assert.ok(html.includes('Send &lt;notification&gt;'));
	assert.ok(html.includes('value="&quot;a &quot;quoted&quot; text&quot;"'));
	assert.ok(!core.panelHTML(def, { inputs: {}, results: {} }, { readOnly: true }).includes('data-automap'), 'no auto-map when read-only');
});
