#!/usr/bin/env python3
"""Prepare the existing bundle metadata and simple string catalogs without Xcode."""
import json
import pathlib
import plistlib
import sys


def write_catalog(catalog, destination, name):
    languages = {catalog['sourceLanguage']}
    for entry in catalog['strings'].values():
        languages.update(entry.get('localizations', {}))
    for language in languages:
        strings = {}
        for key, entry in catalog['strings'].items():
            localized = entry.get('localizations', {}).get(language)
            # shortcut: current catalogs contain only stringUnit, add plural support when needed.
            if localized is not None and set(localized) != {'stringUnit'}:
                raise ValueError(f'Unsupported localization for {name}/{language}/{key}')
            strings[key] = localized['stringUnit']['value'] if localized else key
        folder = destination / f'{language}.lproj'
        folder.mkdir(parents=True, exist_ok=True)
        with (folder / f'{name}.strings').open('wb') as output:
            plistlib.dump(strings, output)


def main():
    root, contents = map(pathlib.Path, sys.argv[1:])
    with (root / 'resources/Info.plist').open('rb') as source:
        info = plistlib.load(source)
    info.update(CFBundleIdentifier='im.rime.inputmethod.Squirrel',
                CFBundleVersion='1.1.2', CFBundleShortVersionString='1.1.2',
                LSMinimumSystemVersion='13.0', SUEnableAutomaticChecks=False)
    with (contents / 'Info.plist').open('wb') as output:
        plistlib.dump(info, output)
    for source in (root / 'resources').glob('*.xcstrings'):
        write_catalog(json.loads(source.read_text()), contents / 'Resources', source.stem)


if __name__ == '__main__':
    main()
