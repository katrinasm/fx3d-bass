escapes = {
    '\\': r'\\',
    '\'': r'\s',
    '\"': r'\d',
    '\n': r'\n',
    ';':  r'\b',
}

unescapes = {
    '\\': '\\',
    's': '\'',
    'd': '\"',
    'n': '\n',
    'b': ';',
}

def bass_str(s):
    es = "\""
    for ch in s:
        es += escapes.get(ch, ch)
    es += "\""
    return es

def intconst(f, name, v):
    f.write(f"\tconstant {name}({v});")
def strconst(f, name, v):
    f.write(f"{name}:\n\t%string_constant({bass_str(v)});")

def basstoks(text):
    text = text.lstrip()
    while text:
        if text.startswith('//'):
            comment, text = text.split('\n', maxsplit = 1)
            yield comment
        elif text[0].isalpha():
            word, text = split_word(text)
            yield word
        elif text[0].isdigit():
            digits, text = split_word(text)
            num = int(digits.replace('\'', ''))
            yield num
        elif text[0] == '$' or text.startswith('0x'):
            i = 1 if text[0] == '$' else 2
            digits, text = split_word(text[i:])
            num = int(digits.replace('\'', ''), 16)
            yield num
        elif text.startswith('0b') or text.startswith('%0') or text.startswith('%1'):
            i = 1 if text[0] == '%' else 2
            digits, text = split_word(text[i:])
            num = int(digits.replace('\'', ''), 2)
            yield num
        elif text.startswith('%'):
            word, text = split_word(text[1:])
            yield '%' + word
        elif text[0] == '\"':
            s, text = bass_str_tok(text)
            yield s
        elif text[0] == '{':
            if text[1].isalpha():
                word, text = split_word(text[1:])
                if text[0] == '}':
                    text = text[1:]
                    yield '{' + word + '}'
                else:
                    yield '{'
                    yield word
            else:
                text = text[1:]
                yield '{'
        elif text[0] in '}()[]+-*/:;':
            tok, text = text[0], text[1:]
            yield tok
        text = text.lstrip()
    return None

def split_word(text):
    i = 0
    while i < len(text) and text[i].isalnum() or text[i] == '_' or text[i] == '\'':
        i += 1
    (text[:i], text[i:])

def bass_str_tok(text):
    if text[0] != "\"":
        return None
    s = "\""
    i = 1
    while i < len(text) and text[i] != "\"":
        if text[i] == '\\':
            s += unescapes[text[i + 1]]
            i += 2
        else:
            s += text[i]
            i += 1
    if text[i] != "\"":
        return None
    return (s + "\"", text[i + 1:])

def buildparse(text):
    d = {}
    if not text:
        return d
    toks = filter(lambda tok: not tok.startswith('//'), basstoks(text))
    expect(toks, 'scope')
    expect(toks, 'automatic')
    expect(toks, '{')

    while True:
        tok = toks(next)
        if tok is None:
            break
        elif tok == 'constant':
            name = toks(next)
            expect(toks, '(')
            value = toks(next)
            expect(toks, ')')
            expect(toks, ';')
        else:
            name = tok
            expect(toks, ':')
            expect(toks, 'string_constant')
            expect(toks, '(')
            qvalue = toks(next)
            if qvalue.startswith("\"") and qvalue.endswith("\""):
                value = qvalue[1:-1]
            else:
                raise f"expected a string for {name}, got {qvalue}"
            expect(toks, ')')
            expect(toks, ';')
        d[name] = value
    return d

def expect(toks, *args):
    tok = next(toks)
    if tok in args:
        return tok
    raise f"expected {args}, got {tok}"

def build_dict(f, name, d, indent = 0):
    tabs = '\t' * indent
    f.write(f"{tabs}scope {name} {{\n")
    for (name, value) in d.items():
        if type(value) == int:
            f.write(f"{tabs}\tconstant {name}({value});\n")
        elif type(value) == str:
            f.write(f"{tabs}{name}:\n")
            f.write(f"{tabs}\tfx.string_constant({bass_str(value)});\n")
        else:
            raise f"can't put {value} in a build dict"
    f.write(f"{tabs}}}\n")

if __name__ == '__main__':
    import time
    from datetime import datetime, timezone
    import subprocess
    date = datetime.now(timezone.utc)
    datestr = date.strftime("%Y-%m-%dT%H:%MZ")
    d = {
        'buildtime': int(time.time()),
        'builddate': datestr,
    }
    with open('automatic.asm', 'w') as auto_text:
        auto_text.write("// automatically generated by build.py\n")
        auto_text.write("arch \"arch/null.arch\";\n")
        build_dict(auto_text, 'automatic', d)
    subprocess.run(['python', 'fxtex.py', 'res/chabank.bin', 'texture/chabank.bin'])
    subprocess.run(['python', 'fxtex.py', 'res/genbank.bin', 'texture/genbank.bin'])
    subprocess.run(['bass', '-o', 'fx3d.sfc', 'build.asm'])
