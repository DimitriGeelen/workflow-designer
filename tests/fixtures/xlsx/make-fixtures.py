#!/usr/bin/env python3
"""T-1442: how the two Excel fixtures were made (workbooks NOT written by the designer).

  python3 tests/fixtures/xlsx/make-fixtures.py <arc-lifecycle.csv exported by the designer> <scratch dir>

arc-lifecycle-libreoffice.xlsx: openpyxl writes a first sheet "Notes" (no "id" column) and the step table on sheet 2
"Process", columns in another order plus a numeric column "order"; LibreOffice then re-saves it (shared strings,
numbers as <v>, its own package layout). no-id-column.xlsx: one sheet whose header has no "id", re-saved the same way.
Needs openpyxl and soffice; the designer's tests only read the results, so the pool needs neither.
"""
import csv, os, shutil, subprocess, sys
import openpyxl

src, scratch = sys.argv[1], sys.argv[2]
here = os.path.dirname(os.path.abspath(__file__))
os.makedirs(scratch, exist_ok=True)
rows = list(csv.reader(open(src, newline='', encoding='utf-8')))
head, body = rows[0], rows[1:]
order = ['name', 'id', 'lane', 'type', 'next', 'next_labels', 'uid', 'lane_code', 'lane_authority']

wb = openpyxl.Workbook()
notes = wb.active
notes.title = 'Notes'
notes.append(['About'])
notes.append(['The step list is on the next sheet.'])
ws = wb.create_sheet('Process')
ws.append(order + ['order'])
for i, r in enumerate(body, 1):
    ws.append([r[head.index(k)] for k in order] + [i])
wb.save(os.path.join(scratch, 'arc-lifecycle-libreoffice.xlsx'))

wb2 = openpyxl.Workbook()
wb2.active.append(['Step', 'Lane'])
wb2.active.append(['Create', 'Agent'])
wb2.save(os.path.join(scratch, 'no-id-column.xlsx'))

out = os.path.join(scratch, 'resaved')
os.makedirs(out, exist_ok=True)
for name in ('arc-lifecycle-libreoffice.xlsx', 'no-id-column.xlsx'):
    subprocess.run(['soffice', f'-env:UserInstallation=file://{scratch}/lo-profile', '--headless', '--convert-to',
                    'xlsx:Calc MS Excel 2007 XML', '--outdir', out, os.path.join(scratch, name)], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    shutil.copyfile(os.path.join(out, name), os.path.join(here, name))
    print('wrote', os.path.join(here, name))
