#!/usr/bin/env python3
"""Check a Neo4j bulk import before running it: read an import script and its CSVs the way neo4j-admin does, offline.

    python3 scripts/check-import.py [--csv-root DIR] [--neo4j VERSION] [--map PREFIX=DIR] [--verbose] SCRIPT [SCRIPT ...]

SCRIPT is an import script such as scripts/all-import.sh; a bare name is looked up next to this file. The check reads
the script's variables and its neo4j-admin command, finds the files of every --nodes and --relationships group under
--csv-root (the folder the import runs from; default: the current folder), reads every CSV with neo4j-admin's rules,
and links every relationship to its nodes. It prints what the import would load, every problem that would stop it,
and warnings. It prints counts, file names and IDs, never the text of a field.

Exit status: 0 if every import would complete; 1 if one would fail; 2 if a script can't be checked.

The rules follow the Neo4j 5.15 sources (BufferedCharSeeker, CsvInputParser, BadCollector, ImportCommand, Validators):
- a file name in a group is a regular expression over its folder; a missing folder, or a name that matches no file,
  stops the import; the first file of a group holds the header;
- a quote opens a quoted field only as the field's first character, and "" inside quotes is one quote; anything but
  the delimiter or a line end after a closing quote is fatal, and so is a missing end quote; a line break inside
  quotes is fatal unless --multiline-fields allows it for that file;
- a row may have fewer fields than its header; each field beyond it is fatal, or one bad entry with
  --ignore-extra-columns;
- an empty field is no value; a quoted empty string ("") is a property unless --ignore-empty-strings;
- an integer column takes an optional '-' and the digits 0-9, between Java whitespace (Character.isWhitespace);
- node IDs live in ID spaces (the group in ":ID(group)"); a repeated ID is fatal, or one bad entry with
  --skip-duplicate-nodes (that node isn't imported);
- a relationship whose start or end ID isn't a node of its ID space is fatal, or one bad entry with
  --skip-bad-relationships (that relationship isn't imported);
- bad entries count against --bad-tolerance (default 1000; unlimited from Neo4j 2025.12): one more stops the import.

Not simulated: memory, disk and the database itself; --multiline-fields-format=v2's own rules; options that change how
fields are read (--legacy-style-quoting, --trim-strings, --normalize-types), which get a warning. File-name patterns
run as Python regular expressions, which agree with Java's for the usual ones (.*_verses.csv). With --strict=false
(neo4j-admin's default) Neo4j may miss a few bad relationships that this check reports, so it errs on the strict side.
"""
import argparse
import re
import shlex
import sys
import unicodedata
from collections import Counter, defaultdict, namedtuple
from pathlib import Path

HERE = Path(__file__).resolve().parent

# neo4j-admin options that take the next word as their value when written without '='
VALUED = {
    'additional-config', 'array-delimiter', 'bad-tolerance', 'database', 'delimiter', 'format', 'high-parallel-io',
    'id-type', 'input-encoding', 'max-off-heap-memory', 'multiline-fields-format', 'nodes', 'quote',
    'read-buffer-size', 'relationships', 'report-file', 'schema', 'temp-path', 'threads', 'vector-delimiter',
}
# options that are flags: written alone, they mean true
FLAGS = {
    'auto-skip-subsequent-headers', 'cache-on-heap', 'dry-run', 'expand-commands', 'force', 'ignore-empty-strings',
    'ignore-extra-columns', 'legacy-style-quoting', 'multiline-fields', 'normalize-types', 'overwrite-destination',
    'skip-bad-relationships', 'skip-duplicate-nodes', 'strict', 'trim-strings', 'verbose',
}
# options that change how fields are read, which this check doesn't reproduce
NOT_SIMULATED = {'auto-skip-subsequent-headers', 'legacy-style-quoting', 'normalize-types', 'schema', 'trim-strings'}

INTEGER_TYPES = {'byte', 'short', 'int', 'long'}
FLOAT_TYPES = {'float', 'double'}
SPECIAL = {'ID', 'START_ID', 'END_ID', 'LABEL', 'TYPE', 'IGNORE'}

ASSIGN = re.compile(r'([A-Za-z_][A-Za-z0-9_]*)=(.*)', re.S)
VAR = re.compile(r'\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))')
SHELL_FEATURE = re.compile(r'(function\s|for\s|while\s|until\s|case\s|select\s|if\s|declare\s|local\s|source\s|\.\s'
                           r'|[A-Za-z_][A-Za-z0-9_]*\s*\(\)\s*\{)')
HEADER_RE = re.compile(r'(?P<name>[^:]*)(?::(?P<type>[A-Za-z_]+(?:\[\])?)(?:\((?P<group>[^)]*)\))?)?')
FLOAT_RE = re.compile(r'[+-]?(?:NaN|Infinity|(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:[eE][+-]?[0-9]+)?[fFdD]?)')
PLAIN_INTEGER = re.compile(r'-?[0-9]+').fullmatch
UP_TO_SPACE = ''.join(map(chr, range(0x21)))

Entry = namedtuple('Entry', 'name kind group ptype raw')


class ScriptError(Exception):
    """The script can't be checked (exit 2)."""


# ---------------------------------------------------------------------------------------------------------- versions

def parse_version(text):
    m = re.fullmatch(r'(\d+)\.(\d+)(?:\.\d+)?', text.strip())
    if not m:
        raise argparse.ArgumentTypeError(f'not a Neo4j version: {text} (for example 5.26 or 2026.10)')
    return int(m.group(1)), int(m.group(2))


def show_version(v):
    return f'{v[0]}.{v[1]}'


# ------------------------------------------------------------------------------------------------- the import script

def logical_lines(text):
    """Yield (first line number, line) with bash's backslash-newline continuations joined.

    A backslash at the end of a comment line doesn't continue it, as in bash.
    """
    buf, start = [], None
    for n, line in enumerate(text.split('\n'), 1):
        if start is None:
            start = n
        if line.endswith('\\') and not line.endswith('\\\\') and not line.lstrip().startswith('#'):
            buf.append(line[:-1])
            continue
        buf.append(line)
        yield start, ''.join(buf)
        buf, start = [], None
    if buf:
        yield start, ''.join(buf)


def expand(text, env):
    """Expand $VAR and ${VAR} outside single quotes, as bash does; return (text, names it can't expand)."""
    out, unknown = [], []
    i, single, double = 0, False, False
    while i < len(text):
        c = text[i]
        if c == '\\' and not single:
            out.append(text[i:i + 2])
            i += 2
            continue
        if c == "'" and not double:
            single = not single
        elif c == '"' and not single:
            double = not double
        elif c == '$' and not single:
            m = VAR.match(text, i)
            if m:
                name = m.group(1) or m.group(2)
                if name in env:
                    out.append(env[name])
                else:
                    unknown.append('$' + name)
                i = m.end()
                continue
            following = text[i + 1:i + 2]
            if following and (following in '({[@*#?!$-' or following.isdigit()):
                unknown.append(text[i:i + 12] + '…')
        out.append(c)
        i += 1
    return ''.join(out), unknown


def parse_script(path):
    """Return (commands, script problems, warnings). Raise ScriptError when the script can't be followed."""
    raw = path.read_bytes()
    text = raw.decode('utf-8', errors='replace')
    problems, warnings = [], []
    if b'\r\n' in raw:
        problems.append('the script has CRLF line ends: bash on Linux would not join its continuation lines')
    env, commands = {}, []
    for n, line in logical_lines(text.replace('\r', '')):
        stripped = line.lstrip()  # trailing spaces stay: "\ " at a line's end is an escaped space, as in bash
        if not stripped.strip() or stripped.startswith('#'):
            continue
        if SHELL_FEATURE.match(stripped):
            raise ScriptError(f'line {n}: "{stripped.split()[0]}": the check follows only variables and the '
                              f'neo4j-admin command, not shell logic')
        expanded, unknown = expand(stripped, env)
        if unknown:
            raise ScriptError(f'line {n}: can\'t expand {", ".join(dict.fromkeys(unknown))}')
        try:
            words = shlex.split(expanded, comments=True)
        except ValueError as e:
            raise ScriptError(f'line {n}: {e}')
        if words and words[0] in ('export', 'readonly'):
            words = words[1:]
            for w in words:
                m = ASSIGN.fullmatch(w)
                if m:
                    env[m.group(1)] = m.group(2)
            continue
        while words and ASSIGN.fullmatch(words[0]):
            m = ASSIGN.fullmatch(words.pop(0))
            env[m.group(1)] = m.group(2)
        if not words:
            continue
        admin = next((k for k, w in enumerate(words) if Path(w).name == 'neo4j-admin'), None)
        if admin is not None:  # also after a prefix such as "sudo -u neo4j" or "docker exec neo"
            command = parse_command(n, words[admin:])
            if command:
                commands.append(command)
        elif words[0].startswith('-'):
            problems.append(f'line {n} starts with an option outside any command ({words[0][:40]}): a space after '
                            f'the "\\" on the line before ends the command there')
        elif words[0] == 'cd':
            warnings.append(f'line {n}: "cd": the check reads relative paths from --csv-root, not from there')
    if not commands:
        raise ScriptError('no "neo4j-admin database import" or "neo4j-admin import" command')
    return commands, problems, warnings


def parse_command(n, words):
    args = words[1:]
    if args[:2] == ['database', 'import'] and len(args) > 2 and args[2] in ('full', 'incremental'):
        form, args = 5, args[3:]
    elif args[:1] == ['import']:
        form, args = 4, args[1:]
    else:
        return None
    opts, groups, positionals, unknown, order = {}, [], [], [], []
    pending = None
    for w in args:
        if pending:
            if pending in ('nodes', 'relationships'):
                groups.append((pending, w))
            else:
                opts[pending] = w
            pending = None
            continue
        if w.startswith('--'):
            name, eq, value = w[2:].partition('=')
            order.append('option')
            if name not in VALUED and name not in FLAGS:
                unknown.append(name)
            if name in ('nodes', 'relationships'):
                if eq:
                    groups.append((name, value))
                else:
                    pending = name
            elif eq:
                opts[name] = value
            elif name in VALUED:
                pending = name
            else:
                opts[name] = 'true'
        else:
            positionals.append(w)
            order.append('name')
    if pending:
        raise ScriptError(f'line {n}: --{pending} has no value')
    return {'line': n, 'form': form, 'opts': opts, 'groups': groups, 'positionals': positionals,
            'unknown': unknown, 'name_first': bool(order) and order[0] == 'name'}


# ---------------------------------------------------------------------------------------------------- reading CSVs

def java_whitespace(c):
    """java.lang.Character.isWhitespace, which neo4j-admin uses to trim a number."""
    if c in '\u00a0\u2007\u202f':
        return False
    return c in '\t\n\u000b\f\r\u001c\u001d\u001e\u001f' or unicodedata.category(c) in ('Zs', 'Zl', 'Zp')


def is_integer(v):
    """Extractors.extractLong: Java whitespace around an optional '-' and the digits 0-9."""
    if PLAIN_INTEGER(v):
        return True
    i, j = 0, len(v)
    while i < j and java_whitespace(v[i]):
        i += 1
    while j > i and java_whitespace(v[j - 1]):
        j -= 1
    if i < j and v[i] == '-':
        i += 1
    return i < j and all('0' <= c <= '9' for c in v[i:j])


def is_float(v):
    """Float.parseFloat: characters up to U+0020 trimmed, then a decimal, NaN or Infinity (hex floats aren't read)."""
    return bool(FLOAT_RE.fullmatch(v.strip(UP_TO_SPACE)))


def value_test(ptype, array_delimiter):
    """A function that tells whether a non-empty value fits the column type, or None when any text fits."""
    base, is_array = (ptype[:-2], True) if ptype.endswith('[]') else (ptype, False)
    test = is_integer if base in INTEGER_TYPES else is_float if base in FLOAT_TYPES else None
    if test is None or not is_array:
        return test
    return lambda v: all(test(p) for p in v.split(array_delimiter) if p)


def parse_header(fields):
    entries = []
    for f in fields:
        m = HEADER_RE.fullmatch(f)
        name, typ, group = (m.group('name'), m.group('type'), m.group('group')) if m else (f, None, None)
        if typ and typ.upper() in SPECIAL:
            entries.append(Entry(name, typ.upper(), group or None, None, f))
        else:
            entries.append(Entry(name, 'PROPERTY', None, (typ or 'string').lower(), f))
    return entries


def read_rows(text, delimiter, quote, multiline):
    """Yield (line, fields, quoted, problems, line_break_fields, cr_fields) per row, as neo4j-admin splits rows.

    quoted is None when no field of the row is quoted. A CR or an LF ends a row, and empty lines are skipped.
    """
    n = len(text)
    i, line = 0, 1
    starts_quoted = delimiter + quote
    stop = re.compile('[' + re.escape(delimiter) + '\r\n]')
    while i < n:
        c = text[i]
        if c == '\n':
            line += 1
            i += 1
            continue
        if c == '\r':
            i += 1
            continue
        j = text.find('\n', i)
        if j == -1:
            j = n
        body = text[i:j]
        if body.endswith('\r'):
            body = body[:-1]
        if '\r' not in body and not body.startswith(quote) and starts_quoted not in body:
            yield line, body.split(delimiter), None, (), 0, 0
            i += len(body)
            continue
        start_line = line
        fields, quoted, problems = [], [], []
        breaks = crs = 0
        while True:
            if i < n and text[i] == quote:
                i += 1
                parts, closed = [], False
                while True:
                    k = text.find(quote, i)
                    if k == -1:
                        parts.append(text[i:])
                        i = n
                        break
                    parts.append(text[i:k])
                    if k + 1 < n and text[k + 1] == quote:
                        parts.append(quote)
                        i = k + 2
                        continue
                    i = k + 1
                    closed = True
                    break
                value = ''.join(parts)
                line += value.count('\n')
                if '\n' in value or '\r' in value:
                    breaks += 1
                    if not multiline:
                        problems.append('line break inside a quoted field')
                if '\r' in value:
                    crs += 1
                if not closed:
                    problems.append('missing end quote')
                    fields.append(value)
                    quoted.append(True)
                    break
                if i < n and text[i] not in (delimiter, '\r', '\n'):
                    problems.append('data after a closing quote')
                    m = stop.search(text, i)
                    k = m.start() if m else n
                    value += text[i:k]
                    i = k
                fields.append(value)
                quoted.append(True)
            else:
                m = stop.search(text, i)
                k = m.start() if m else n
                fields.append(text[i:k])
                quoted.append(False)
                i = k
            if i < n and text[i] == delimiter:
                i += 1
                continue
            break
        yield start_line, fields, quoted, problems, breaks, crs


# ------------------------------------------------------------------------------------------------------- simulation

class Check:
    """One neo4j-admin import command, simulated over the CSVs under the CSV root."""

    def __init__(self, command, root, maps, version):
        self.command, self.root, self.maps, self.version = command, root, maps, version
        self.fatal, self.warnings, self.notes = [], [], []
        self.nodes = self.relationships = self.properties = 0
        self.labels, self.types = Counter(), Counter()
        self.files_read, self.rows = set(), 0
        self.empty_files = []
        self.line_breaks, self.cr_fields = Counter(), Counter()
        self.data_problems = defaultdict(lambda: [0, None])     # (problem, group) -> [count, first file:line]
        self.bad_values = defaultdict(lambda: [0, None])        # (column, group) -> [count, first file:line]
        self.extra = [0, None]                                  # fields, first file:line
        self.extra_files = set()
        self.duplicates = defaultdict(lambda: [0, None])        # ID space -> [count, first ID]
        self.bad_relationships = defaultdict(lambda: [0, None])  # (file, reason) -> [count, first (start, end)]
        self.no_type = 0
        self.ids = defaultdict(set)                             # ID space -> node IDs
        self.spaces = set()                                     # ID spaces that node groups define
        self.group_lines = []
        self.bad_entries = 0
        self.start_errors = defaultdict(list)                   # problem -> the patterns it stops

    # -- helpers
    def show(self, path):
        try:
            return path.relative_to(self.root).as_posix()
        except ValueError:
            return path.as_posix()

    def char_option(self, name, default):
        value = self.command['opts'].get(name, default)
        if value.upper() in ('TAB', '\\T'):
            return '\t'
        if len(value) != 1:
            self.fatal.append(('options', f'--{name} "{value}" isn\'t one character'))
            return default
        return value

    def flag(self, name):
        return self.command['opts'].get(name, 'false').lower() == 'true'

    def resolve(self, pattern):
        """The files a pattern names (Validators.matchingFiles), or an error."""
        p = pattern
        for prefix, target in self.maps:
            prefix = prefix.rstrip('/')
            if p == prefix or p.startswith(prefix + '/'):
                p = target + p[len(prefix):]
                break
        path = self.root / p
        parent, name = path.parent, path.name
        if not parent.is_dir():
            return [], (f'folder {self.show(parent)} doesn\'t exist', pattern)
        try:
            rx = re.compile(name)
        except re.error as e:
            return [], (f'not a valid pattern ({e})', pattern)
        files = sorted(c for c in parent.iterdir() if rx.fullmatch(c.name) and c.is_file())
        if not files:
            return [], ('no file matches', pattern)
        return files, None

    def read(self, path, multiline_files):
        """Yield the file's rows. A header file shared by several groups is read once per group, counted once."""
        data = path.read_bytes()
        first_time = path not in self.files_read
        self.files_read.add(path)
        if first_time and not data:
            self.empty_files.append(path)
        try:
            text = data.decode('utf-8')
        except UnicodeDecodeError:
            text = data.decode('utf-8', errors='replace')
            self.warnings.append(f'{self.show(path)} isn\'t valid UTF-8 (neo4j-admin reads UTF-8)')
        if text.startswith('\ufeff'):
            text = text[1:]
        multiline = self.multiline_all or path in multiline_files
        for row in read_rows(text, self.delimiter, self.quote, multiline):
            self.rows += 1
            if first_time and row[4]:
                self.line_breaks[path] += row[4]
            if first_time and row[5]:
                self.cr_fields[path] += row[5]
            yield row

    # -- the run
    def run(self):
        c, o, v = self.command, self.command['opts'], self.version
        self.delimiter = self.char_option('delimiter', ',')
        self.array_delimiter = self.char_option('array-delimiter', ';')
        self.quote = self.char_option('quote', '"')
        self.ignore_empty = self.flag('ignore-empty-strings')
        self.check_version_rules()
        for name in c['unknown']:
            self.warnings.append(f'unknown option --{name}: not simulated')
        for name in sorted(NOT_SIMULATED & o.keys()):
            if o[name].lower() != 'false':
                self.warnings.append(f'--{name} changes how fields are read; the check doesn\'t reproduce it')
        if o.get('id-type', 'STRING').upper() != 'STRING':
            self.warnings.append(f'--id-type {o["id-type"]}: IDs are compared as text, as with STRING')
        if o.get('input-encoding', 'UTF-8').upper().replace('_', '-') not in ('UTF-8', 'UTF8'):
            self.warnings.append(f'--input-encoding {o["input-encoding"]}: the check reads UTF-8')
        multiline_files = self.multiline_option()
        node_groups, rel_groups = [], []
        for kind, spec in c['groups']:
            key, sep, files = spec.partition('=')
            if not sep:
                key, files = '', spec
            patterns = [f for f in files.split(',') if f]
            resolved = []
            for pattern in patterns:
                found, error = self.resolve(pattern)
                if error:
                    self.start_errors[error[0]].append(error[1])
                resolved.extend(found)
            (node_groups if kind == 'nodes' else rel_groups).append((key, patterns, resolved))
        for problem, patterns in self.start_errors.items():
            listed = patterns[0] if len(patterns) == 1 else f'{len(patterns)} patterns, the first {patterns[0]}'
            self.fatal.append(('start', f'{problem} ({listed})'))
        for key, patterns, files in node_groups:
            self.node_group(key, patterns, files, multiline_files)
        for key, patterns, files in rel_groups:
            self.relationship_group(key, patterns, files, multiline_files)
        self.verdict()
        return self

    def check_version_rules(self):
        c, o, v = self.command, self.command['opts'], self.version
        if c['form'] == 4 and v >= (5, 0):
            self.fatal.append(('version', f'"neo4j-admin import" is the Neo4j 4.x command; Neo4j {show_version(v)} '
                                          f'needs "neo4j-admin database import full"'))
        if c['form'] == 5 and v < (5, 0):
            self.fatal.append(('version', f'"neo4j-admin database import" needs Neo4j 5 or later'))
        if c['form'] == 5 and v >= (5, 26) and c['positionals'] and not c['name_first']:
            self.warnings.append('the database name comes after the options; the notes in docs/neo4j-import.md say '
                                 'that 5.26 wants it first')
        if 'vector-delimiter' in o and v < (2025, 10):
            self.fatal.append(('version', f'--vector-delimiter doesn\'t exist before Neo4j 2025.10'))
        if v >= (2026, 6):
            vector = o.get('vector-delimiter', ';')
            if vector == o.get('delimiter', ','):
                self.fatal.append(('version', f'--vector-delimiter is "{vector}", the same as --delimiter: Neo4j '
                                              f'{show_version(v)} refuses to start (add --vector-delimiter "|")'))
        if 'bad-tolerance' in o:
            try:
                self.tolerance = int(o['bad-tolerance'])
            except ValueError:
                self.fatal.append(('options', f'--bad-tolerance "{o["bad-tolerance"]}" isn\'t a number'))
                self.tolerance = 1000
        else:
            self.tolerance = -1 if v >= (2025, 12) else 1000

    def multiline_option(self):
        o = self.command['opts']
        value = o.get('multiline-fields', 'false')
        self.multiline_all = value.lower() == 'true'
        if value.lower() in ('true', 'false'):
            return set()
        if self.version < (5, 26):
            self.fatal.append(('version', f'--multiline-fields takes a list of files only from Neo4j 5.26 on'))
        if o.get('multiline-fields-format', '').lower() == 'v2':
            self.warnings.append('--multiline-fields-format=v2 has rules of its own (quoted text fields) that the '
                                 'check doesn\'t reproduce')
        files = set()
        for pattern in value.split(','):
            found, error = self.resolve(pattern)
            if error:
                self.fatal.append(('start', f'--multiline-fields: {error[0]} ({error[1]})'))
            files.update(found)
        return files

    def header_of(self, key, patterns, files, multiline_files, kind):
        rows = self.read(files[0], multiline_files)
        first = next(rows, None)
        if first is None:
            self.fatal.append(('data', f'{self.show(files[0])} has no header ({kind} group {key or patterns[0]})'))
            return None, []
        if len(files) > 1 and re.search(r'[*+?\[\]()|^$\\]', patterns[0]):
            self.warnings.append(f'the header of {patterns[0]} comes from whichever matching file Neo4j lists first')
        return parse_header(first[1]), [(files[0], r) for r in rows]

    def rows_of(self, files, first_rows, multiline_files):
        for path, row in first_rows:
            yield path, row
        for path in files[1:]:
            for row in self.read(path, multiline_files):
                yield path, row

    def property_columns(self, entries):
        """(index, entry, value test, whether a quoted "" counts) for each property column of a header."""
        return [(k, e, value_test(e.ptype, self.array_delimiter), e.ptype == 'string' and not self.ignore_empty)
                for k, e in enumerate(entries) if e.kind == 'PROPERTY']

    def note_row(self, path, row, width, columns, group):
        """Record the row's problems; return how many properties it holds."""
        line, fields, quoted, problems = row[0], row[1], row[2], row[3]
        for p in problems:
            slot = self.data_problems[(p, group)]
            slot[0] += 1
            slot[1] = slot[1] or f'{self.show(path)} line {line}'
        if len(fields) > width:
            self.extra[0] += len(fields) - width
            self.extra[1] = self.extra[1] or f'{self.show(path)} line {line}'
            self.extra_files.add(path)
        properties = 0
        count = len(fields)
        for k, e, test, quoted_empty_counts in columns:
            if k >= count:
                break
            value = fields[k]
            if value == '':
                if quoted_empty_counts and quoted and quoted[k]:
                    properties += 1
                continue
            if test and not test(value):
                slot = self.bad_values[(e.raw, group)]
                slot[0] += 1
                slot[1] = slot[1] or f'{self.show(path)} line {line}'
                continue
            properties += 1
        return properties

    def node_group(self, key, patterns, files, multiline_files):
        if not files:
            return
        entries, first_rows = self.header_of(key, patterns, files, multiline_files, 'nodes')
        if entries is None:
            return
        group = self.show(files[0]) + (f' (+{len(files) - 1} files)' if len(files) > 1 else '')
        id_columns = [k for k, e in enumerate(entries) if e.kind == 'ID']
        space = entries[id_columns[0]].group if id_columns else None
        if id_columns:
            self.spaces.add(space)
        label_columns = [k for k, e in enumerate(entries) if e.kind == 'LABEL']
        group_labels = [x for x in key.split(':') if x]
        width, columns = len(entries), self.property_columns(entries)
        ids, skip_duplicates = self.ids[space], self.flag('skip-duplicate-nodes')
        imported = 0
        for path, row in self.rows_of(files, first_rows, multiline_files):
            fields = row[1]
            properties = self.note_row(path, row, width, columns, group)
            parts = [fields[k] for k in id_columns if k < len(fields) and fields[k] != '']
            properties += sum(1 for k in id_columns if k < len(fields) and fields[k] != '' and entries[k].name)
            if parts:
                node_id = '\x1f'.join(parts)
                if node_id in ids:
                    slot = self.duplicates[space]
                    slot[0] += 1
                    slot[1] = slot[1] or node_id
                    if skip_duplicates:
                        continue
                else:
                    ids.add(node_id)
            imported += 1
            self.properties += properties
            for k in label_columns:
                if k < len(fields):
                    self.labels.update(x for x in fields[k].split(self.array_delimiter) if x)
        self.nodes += imported
        for label in group_labels if imported else ():
            self.labels[label] += imported
        self.group_lines.append(f'nodes {key or "-"}: {group}: {imported:,} nodes')

    def relationship_group(self, key, patterns, files, multiline_files):
        if not files:
            return
        entries, first_rows = self.header_of(key, patterns, files, multiline_files, 'relationships')
        if entries is None:
            return
        group = self.show(files[0]) + (f' (+{len(files) - 1} files)' if len(files) > 1 else '')
        find = {kind: next((k for k, e in enumerate(entries) if e.kind == kind), None)
                for kind in ('START_ID', 'END_ID', 'TYPE')}
        start_space = entries[find['START_ID']].group if find['START_ID'] is not None else None
        end_space = entries[find['END_ID']].group if find['END_ID'] is not None else None
        for space in (start_space, end_space):
            if space not in self.spaces:
                self.warnings.append(f'{group}: no node group defines the ID space {space or "(global)"}')
        start_ids, end_ids = self.ids[start_space], self.ids[end_space]
        s, e, t = find['START_ID'], find['END_ID'], find['TYPE']
        width, columns = len(entries), self.property_columns(entries)
        before = self.relationships
        for path, row in self.rows_of(files, first_rows, multiline_files):
            fields = row[1]
            properties = self.note_row(path, row, width, columns, group)
            start = fields[s] if s is not None and s < len(fields) else ''
            end = fields[e] if e is not None and e < len(fields) else ''
            found_start, found_end = start != '' and start in start_ids, end != '' and end in end_ids
            if found_start and found_end:
                rel_type = (fields[t] if t is not None and t < len(fields) else '') or key
                if not rel_type:
                    self.no_type += 1
                self.relationships += 1
                self.properties += properties
                self.types[rel_type or '(no type)'] += 1
            else:
                reason = ('start and end IDs not found' if not found_start and not found_end else
                          'start ID not found' if not found_start else 'end ID not found')
                slot = self.bad_relationships[(self.show(path), reason)]
                slot[0] += 1
                slot[1] = slot[1] or (start, end)
        self.group_lines.append(f'relationships {key or "-"}: {group}: {self.relationships - before:,} relationships')

    def verdict(self):
        bad_entries = 0
        for (problem, group), (count, where) in self.data_problems.items():
            self.fatal.append(('data', f'{problem}: {count:,} in {group} (first at {where})'))
        for (column, group), (count, where) in self.bad_values.items():
            self.fatal.append(('data', f'{count:,} values in column "{column}" aren\'t numbers, in {group} '
                                       f'(first at {where})'))
        fields, files, where = self.extra[0], len(self.extra_files), self.extra[1]
        if fields:
            if self.flag('ignore-extra-columns'):
                bad_entries += fields
            else:
                self.fatal.append(('data', f'{fields:,} fields beyond the header, in {files:,} files (first at '
                                           f'{where}), and no --ignore-extra-columns'))
        duplicates = sum(c for c, _ in self.duplicates.values())
        if duplicates:
            if self.flag('skip-duplicate-nodes'):
                bad_entries += duplicates
            else:
                for space, (count, first) in self.duplicates.items():
                    self.fatal.append(('nodes', f'{count:,} repeated IDs in the ID space {space or "(global)"} '
                                                f'(first: {short(first)}), and no --skip-duplicate-nodes'))
        bad = sum(c for c, _ in self.bad_relationships.values())
        if bad:
            if self.flag('skip-bad-relationships'):
                bad_entries += bad
            else:
                self.fatal.append(('relationships', f'{bad:,} relationships point at missing nodes, and no '
                                                    f'--skip-bad-relationships'))
        if self.tolerance != -1 and bad_entries > self.tolerance:
            self.fatal.append(('relationships', f'{bad_entries:,} bad entries, more than --bad-tolerance '
                                                f'{self.tolerance:,}'))
        self.bad_entries = bad_entries
        if self.no_type:
            self.warnings.append(f'{self.no_type:,} relationships have no type')
        for path, count in sorted(self.cr_fields.items()):
            self.warnings.append(f'{self.show(path)}: {count:,} quoted fields hold a CR (a copy from a Windows '
                                 f'checkout?); the graph would keep those CRs')



def short(text, width=60):
    return text if len(text) <= width else text[:width - 1] + '…'


# ---------------------------------------------------------------------------------------------------------- output

def report(name, check, verbose):
    c, o = check.command, check.command['opts']
    subcommand = 'database import full' if c['form'] == 5 else 'import'
    target = ' '.join(c['positionals']) or o.get('database', '')
    print(f'== {name}: neo4j-admin {subcommand} {target} (line {c["line"]}; Neo4j {show_version(check.version)} '
          f'rules)')
    shown = {k: o[k] for k in ('id-type', 'delimiter', 'array-delimiter', 'vector-delimiter', 'multiline-fields',
                               'skip-bad-relationships', 'skip-duplicate-nodes', 'ignore-extra-columns',
                               'bad-tolerance') if k in o}
    print(f'   options: {" ".join(f"--{k}={v}" for k, v in shown.items()) or "(defaults)"}')
    print(f'   read: {len(check.files_read):,} files, {check.rows:,} rows, from {check.root}')
    print(f'   would import: {check.nodes} nodes, {check.relationships} relationships, {check.properties} properties')
    labels = check.labels.most_common()
    print(f'   labels: {", ".join(f"{k} {v:,}" for k, v in labels[:20]) or "(none)"}'
          + (f', … {len(labels) - 20} more' if len(labels) > 20 else ''))
    print(f'   relationship types: {", ".join(f"{k} {v:,}" for k, v in check.types.most_common()) or "(none)"}')
    bad = sum(count for count, _ in check.bad_relationships.values())
    if bad:
        skipped = 'skipped' if check.flag('skip-bad-relationships') else 'fatal without --skip-bad-relationships'
        print(f'   relationships that point at missing nodes: {bad:,} ({skipped})')
    for (path, reason), (count, (start, end)) in sorted(check.bad_relationships.items(), key=lambda kv: -kv[1][0])[:12]:
        print(f'     {count:>9,}  {path}: {reason} (first: {short(start)} -> {short(end)})')
    if len(check.bad_relationships) > 12:
        print(f'     … {len(check.bad_relationships) - 12} more files')
    if check.bad_entries or any(check.flag(f) for f in ('skip-bad-relationships', 'skip-duplicate-nodes',
                                                          'ignore-extra-columns')):
        tolerance = 'unlimited' if check.tolerance == -1 else f'{check.tolerance:,}'
        print(f'   bad entries (skipped rows and fields): {check.bad_entries:,}, --bad-tolerance {tolerance}')
    if check.line_breaks:
        listed = ', '.join(f'{check.show(p)} {n:,}' for p, n in sorted(check.line_breaks.items()))
        print(f'   line breaks inside quoted fields (files that need --multiline-fields): {listed}')
    if check.empty_files:
        print(f'   empty files: {len(check.empty_files):,} (first: {check.show(check.empty_files[0])})')
    if verbose:
        for line in check.group_lines:
            print(f'   {line}')
    for w in dict.fromkeys(check.warnings):
        print(f'   warning: {w}')
    if check.fatal:
        print('   WOULD FAIL:')
        for stage, message in dict.fromkeys(check.fatal):
            print(f'     {stage}: {message}')
    else:
        print('   would complete')
    print()


def main(argv=None):
    parser = argparse.ArgumentParser(
        description='Check a neo4j-admin bulk import offline: read the import script and its CSVs as neo4j-admin '
                    'does, and say whether the import would complete, and with what.',
        epilog='Exit status: 0 if every import would complete, 1 if one would fail, 2 if a script can\'t be checked.')
    parser.add_argument('scripts', nargs='+', metavar='SCRIPT', help='an import script, e.g. scripts/all-import.sh')
    parser.add_argument('--csv-root', default='.', type=Path,
                        help='the folder the import runs from (its relative paths start there); default: here')
    parser.add_argument('--neo4j', default='5.26', type=parse_version, metavar='VERSION',
                        help='the Neo4j version whose rules apply: default --bad-tolerance, --vector-delimiter, the '
                             'command form (default: 5.26, docker/docker-compose.yaml today)')
    parser.add_argument('--map', action='append', default=[], metavar='PREFIX=DIR',
                        help='read absolute paths starting with PREFIX (as in the container) from DIR')
    parser.add_argument('--verbose', action='store_true', help='also print one line per --nodes and '
                                                                '--relationships group')
    args = parser.parse_args(argv)
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    maps = []
    for m in args.map:
        prefix, sep, target = m.partition('=')
        if not sep or not prefix:
            parser.error(f'--map wants PREFIX=DIR, not {m}')
        maps.append((prefix, target))
    root = args.csv_root.resolve()
    if not root.is_dir():
        parser.error(f'--csv-root {args.csv_root} isn\'t a folder')
    status = 0
    for name in args.scripts:
        path = Path(name)
        if not path.is_file() and (HERE / name).is_file():
            path = HERE / name
        if not path.is_file():
            print(f'== {name}: no such script\n')
            status = 2
            continue
        try:
            commands, problems, warnings = parse_script(path)
        except ScriptError as e:
            print(f'== {name}: can\'t check it: {e}\n')
            status = 2
            continue
        for command in commands:
            check = Check(command, root, maps, args.neo4j).run()
            check.fatal[:0] = [('script', p) for p in problems]
            check.warnings[:0] = warnings
            report(name, check, args.verbose)
            if check.fatal and status == 0:
                status = 1
    return status


if __name__ == '__main__':
    sys.exit(main())
