"""Inspect APK native ABI coverage and ELF load alignment using Python stdlib."""
import argparse
import hashlib
import json
import struct
import zipfile
from pathlib import Path


def inspect(path):
    libraries = []
    with zipfile.ZipFile(path) as apk:
        names = apk.namelist()
        for name in names:
            if not name.startswith('lib/') or not name.endswith('.so'):
                continue
            data = apk.read(name)
            if data[:4] != b'\x7fELF' or data[4] != 2:
                raise ValueError(f'Expected a 64-bit ELF library: {name}')
            offset = struct.unpack_from('<Q', data, 32)[0]
            size, count = struct.unpack_from('<HH', data, 54)
            segments = []
            for i in range(count):
                header = struct.unpack_from('<IIQQQQQQ', data, offset + i * size)
                if header[0] == 1:
                    segments.append(header)
            aligned = bool(segments) and all(h[7] >= 16384 and (h[2] - h[3]) % 16384 == 0 for h in segments)
            libraries.append({'path': name, 'elf16kb': aligned,
                              'loadAlignment': [hex(h[7]) for h in segments]})
        required = ['lib/arm64-v8a/' + name for name in ['libunity.so', 'libil2cpp.so', 'libflutter.so', 'libisar.so']]
        missing = [name for name in required if name not in names]
        with path.open('rb') as source:
            digest = hashlib.file_digest(source, 'sha256').hexdigest()
        result = {'apk': str(path.resolve()), 'bytes': path.stat().st_size,
                  'sha256': digest,
                  'missingLibraries': missing, 'nativeLibraries': libraries,
                  'allElf16kb': all(lib['elf16kb'] for lib in libraries)}
        if missing:
            raise ValueError('APK lacks required native libraries: ' + ', '.join(missing))
        if any(not lib['path'].startswith('lib/arm64-v8a/') for lib in libraries):
            raise ValueError('Unexpected ABI in ARM64-only build')
        if not result['allElf16kb']:
            raise ValueError('Native libraries lack 16 KB alignment: ' + ', '.join(
                lib['path'] for lib in libraries if not lib['elf16kb']))
        return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('apk', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = inspect(args.apk)
    text = json.dumps(result, indent=2)
    if args.output:
        args.output.write_text(text, encoding='utf-8')
    print(text)
