const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');

function load(context, file, names) {
  const source = fs.readFileSync(path.resolve(__dirname, '../../..', file), 'utf8');
  for (const name of names) {
    const start = source.indexOf(`function ${name}(`), end = source.indexOf('\nfunction ', start + 1);
    assert.ok(start >= 0, name);
    let code = source.slice(start, end < 0 ? undefined : end).replace(/^#.*$/gm, '');
    code = code.replace(/with \(obj_recurso\) \{([\s\S]*?)\n    \}/,
      'for (const _instance of groups[obj_recurso]) { with (_instance) {$1\n    }}');
    vm.runInContext(code, context);
  }
}

module.exports = load;
