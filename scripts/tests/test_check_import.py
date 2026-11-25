"""Black-box tests for scripts/check-import.py: tiny made-up imports, each with one thing wrong (or right).

Run from the repository root: python3 -m unittest discover -s scripts/tests
They run the script as a program and read only its exit status and output, so they can check any other version of it.
"""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

CHECK = Path(__file__).resolve().parents[1] / 'check-import.py'

PEOPLE = 'id:ID(P);name;age:long\np1;Ann;30\np2;Ben;41\np3;Cy;\n'
KNOWS = ':START_ID(P);:END_ID(P);since:long\np1;p2;2001\np2;p3;2010\n'
CLEAN = 'would import: 3 nodes, 2 relationships, 10 properties'  # 3 + 3 + 2 node properties, 2 relationship ones


def script(*options, command='neo4j-admin database import full test', folder='./data', people_file='people.csv'):
    lines = ['#!/usr/bin/env bash', f'export D={folder}', f'{command} \\', '    --id-type STRING \\',
             '    --delimiter ";" \\', '    --array-delimiter "|" \\']
    lines += [f'    {option} \\' for option in options]
    lines += [f'    --nodes=Person="$D/{people_file}" \\', '    --relationships=KNOWS="$D/knows.csv"', '']
    return '\n'.join(lines)


class CheckImportTest(unittest.TestCase):

    def check(self, *args, people=PEOPLE, knows=KNOWS, sh=None, options=(), **script_args):
        """Write the files into a fresh folder, run the check there, return (exit status, output)."""
        files = {'import.sh': sh if sh is not None else script(*options, **script_args),
                 'data/people.csv': people, 'data/knows.csv': knows}
        with tempfile.TemporaryDirectory() as root:
            for name, text in files.items():
                path = Path(root, name)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(text.encode('utf-8'))
            result = subprocess.run([sys.executable, '-B', str(CHECK), '--csv-root', root, *args,
                                     str(Path(root, 'import.sh'))], capture_output=True, encoding='utf-8')
        return result.returncode, result.stdout + result.stderr

    def assertFails(self, expected, *args, **kwargs):
        status, out = self.check(*args, **kwargs)
        self.assertEqual(status, 1, out)
        self.assertIn('WOULD FAIL', out)
        self.assertIn(expected, out)
        return out

    def assertCompletes(self, *args, **kwargs):
        status, out = self.check(*args, **kwargs)
        self.assertEqual(status, 0, out)
        self.assertIn('would complete', out)
        return out

    # --- a clean import
    def test_clean_import_completes_with_its_counts(self):
        out = self.assertCompletes()
        self.assertIn(CLEAN, out)
        self.assertIn('labels: Person 3', out)
        self.assertIn('relationship types: KNOWS 2', out)

    # --- reading rows
    def test_extra_column_is_fatal(self):
        self.assertFails('fields beyond the header', people=PEOPLE + 'p4;Di;5;x\n')

    def test_extra_column_is_a_bad_entry_with_ignore_extra_columns(self):
        out = self.assertCompletes(people=PEOPLE + 'p4;Di;5;x\n', options=['--ignore-extra-columns=true'])
        self.assertIn('bad entries (skipped rows and fields): 1', out)

    def test_data_after_a_closing_quote_is_fatal(self):
        self.assertFails('data after a closing quote', people=PEOPLE + 'p4;"Di"x;5\n')

    def test_missing_end_quote_is_fatal(self):
        self.assertFails('missing end quote', people=PEOPLE + 'p4;"Di;5\n')

    def test_quote_inside_a_field_is_a_plain_character(self):
        self.assertCompletes(people=PEOPLE + 'p4;D"i;5\n')

    def test_line_break_inside_quotes_needs_multiline_fields(self):
        people = PEOPLE + 'p4;"Di\nana";5\n'
        self.assertFails('line break inside a quoted field', people=people)
        out = self.assertCompletes(people=people, options=['--multiline-fields=true'])
        self.assertIn('need --multiline-fields): data/people.csv 1', out)

    def test_cr_inside_quotes_gets_a_warning(self):
        out = self.assertCompletes(people=PEOPLE + 'p4;"Di\r\nana";5\n', options=['--multiline-fields=true'])
        self.assertIn('quoted fields hold a CR', out)

    # --- values
    def test_word_in_a_long_column_is_fatal(self):
        self.assertFails('aren\'t numbers', people=PEOPLE + 'p4;Di;forty\n')

    def test_numbers_are_trimmed_with_java_whitespace(self):
        self.assertCompletes(people=PEOPLE + 'p4;Di; 42 \n')
        self.assertCompletes(people=PEOPLE + 'p4;Di;\u200342\n')   # an em space is Java whitespace
        self.assertFails('aren\'t numbers', people=PEOPLE + 'p4;Di;42\u00a0\n')  # a no-break space isn't

    def test_quoted_empty_string_is_a_property(self):
        out = self.assertCompletes(people=PEOPLE + 'p4;"";5\n')
        self.assertIn('would import: 4 nodes, 2 relationships, 13 properties', out)
        out = self.assertCompletes(people=PEOPLE + 'p4;"";5\n', options=['--ignore-empty-strings=true'])
        self.assertIn('would import: 4 nodes, 2 relationships, 12 properties', out)

    # --- IDs and links
    def test_repeated_id_is_fatal(self):
        self.assertFails('repeated IDs', people=PEOPLE + 'p1;Again;9\n')

    def test_repeated_id_is_skipped_with_skip_duplicate_nodes(self):
        out = self.assertCompletes(people=PEOPLE + 'p1;Again;9\n', options=['--skip-duplicate-nodes=true'])
        self.assertIn(CLEAN, out)

    def test_unresolved_link_is_fatal(self):
        self.assertFails('point at missing nodes', knows=KNOWS + 'p1;p9;2020\n')

    def test_unresolved_link_is_skipped_with_skip_bad_relationships(self):
        out = self.assertCompletes(knows=KNOWS + 'p1;p9;2020\n', options=['--skip-bad-relationships=true'])
        self.assertIn(CLEAN, out)
        self.assertIn('data/knows.csv: end ID not found', out)

    def test_bad_entries_above_the_tolerance_are_fatal(self):
        self.assertFails('more than --bad-tolerance', knows=KNOWS + 'p1;p9;2020\n',
                         options=['--skip-bad-relationships=true', '--bad-tolerance=0'])

    # --- files
    def test_missing_folder_is_fatal(self):
        self.assertFails('doesn\'t exist', folder='./nothing')

    def test_pattern_that_matches_nothing_is_fatal(self):
        self.assertFails('no file matches', people_file='.*_people.csv')

    def test_pattern_is_a_regular_expression(self):
        self.assertCompletes(people_file='peo.*[.]csv')

    # --- the script
    def test_unknown_variable_cant_be_checked(self):
        status, out = self.check(sh=script().replace('$D/knows', '$NOPE/knows'))
        self.assertEqual(status, 2, out)
        self.assertIn('$NOPE', out)

    def test_space_after_the_backslash_splits_the_command(self):
        self.assertFails('starts with an option outside any command',
                         sh=script().replace('--delimiter ";" \\', '--delimiter ";" \\ '))

    def test_crlf_script_is_fatal(self):
        self.assertFails('CRLF', sh=script().replace('\n', '\r\n'))

    def test_comment_ending_in_a_backslash_continues_nothing(self):
        self.assertCompletes(sh=script().replace('export D=./data', '# a note \\\nexport D=./data'))

    # --- Neo4j versions
    def test_neo4j_2026_needs_a_vector_delimiter(self):
        self.assertFails('--vector-delimiter', '--neo4j', '2026.10')
        self.assertCompletes('--neo4j', '2026.10', options=['--vector-delimiter "|"'])

    def test_bad_tolerance_defaults_to_1000_then_unlimited(self):
        knows = KNOWS + 'p1;p9;2020\n' * 1001
        self.assertFails('more than --bad-tolerance', knows=knows, options=['--skip-bad-relationships=true'])
        self.assertCompletes('--neo4j', '2026.10', knows=knows,
                             options=['--skip-bad-relationships=true', '--vector-delimiter "|"'])

    def test_neo4j_4_command_needs_neo4j_4(self):
        command = 'neo4j-admin import --database=test'
        self.assertFails('Neo4j 4.x command', command=command)
        self.assertCompletes('--neo4j', '4.4', command=command)


if __name__ == '__main__':
    unittest.main()
