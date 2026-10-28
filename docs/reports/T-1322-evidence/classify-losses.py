"""T-1322: what one open-and-save loses, per class, outside DI. Usage: classify1322.py <src_dir> <exp_dir>."""
import collections, glob, os, sys
import xml.etree.ElementTree as E

BPMN = 'http://www.omg.org/spec/BPMN/20100524/MODEL'
AEF = 'http://anchorpoint.framework/aef/extensions'
XSI = 'http://www.w3.org/2001/XMLSchema-instance'
DI_NS = {'http://www.omg.org/spec/BPMN/20100524/DI', 'http://www.omg.org/spec/DD/20100524/DC',
         'http://www.omg.org/spec/DD/20100524/DI'}
REF_TAGS = {'incoming', 'outgoing', 'flowNodeRef'}   # rewritten from ids, not content


def ns(tag):
    return tag[1:].split('}')[0] if tag.startswith('{') else ''


def local(tag):
    return tag.split('}')[-1]


def census(path):
    c = collections.Counter()
    comments = 0
    parser = E.XMLParser(target=E.TreeBuilder(insert_comments=True))
    root = E.parse(path, parser).getroot()
    for el in root.iter():
        if el.tag is E.Comment:
            comments += 1
            continue
        n = ns(el.tag)
        if n in DI_NS or n == AEF:
            continue
        if n == BPMN:
            t = local(el.tag)
            if t in REF_TAGS:
                continue
            c[('F2/F5 bpmn element', t)] += 1
            for a in el.attrib:
                an = ns(a)
                if an == '' and a not in ('id', 'name'):
                    c[('F2 bpmn attribute', t + '@' + a)] += 1
                elif an not in ('', XSI, BPMN):
                    c[('F1 foreign attribute', t + '@' + local(a))] += 1
            if t == 'script' or t == 'text':
                c[('F2/F5 text', t)] += 1 if (el.text or '').strip() else 0
        else:
            c[('F1 foreign element', local(el.tag))] += 1
    c[('F11 comment', 'comment')] = comments
    return c


src, exp = sys.argv[1], sys.argv[2]
total = collections.Counter()
files_hit = collections.Counter()
for f in sorted(glob.glob(os.path.join(src, '*.bpmn'))):
    e = os.path.join(exp, os.path.basename(f))
    a, b = census(f), census(e)
    lost = {k: a[k] - b[k] for k in a if a[k] > b[k]}
    print('== %s: %d lost item(s)' % (os.path.basename(f), sum(lost.values())))
    for k in sorted(lost):
        print('   %-22s %-40s %d' % (k[0], k[1], lost[k]))
        total[k] += lost[k]
        files_hit[k] += 1
print('\n== TOTAL over %d files (item, count, files)' % len(glob.glob(os.path.join(src, '*.bpmn'))))
by_class = collections.Counter()
for k in sorted(total):
    print('   %-22s %-40s %4d  %d' % (k[0], k[1], total[k], files_hit[k]))
    by_class[k[0]] += total[k]
print('\n== BY CLASS')
for k, v in by_class.most_common():
    print('   %-22s %d' % (k, v))
