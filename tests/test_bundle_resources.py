import importlib.util
import pathlib
import tempfile
import unittest
import plistlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('bundle_resources', ROOT / 'scripts/bundle-resources.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ResourcesTests(unittest.TestCase):
    def test_catalog_preserves_translation_and_source_fallback(self):
        catalog = {'sourceLanguage': 'en', 'strings': {
            'Deploy': {'localizations': {'zh-Hans': {'stringUnit': {'value': '重新部署'}}}},
            'Quoted "key"': {}}}
        with tempfile.TemporaryDirectory() as directory:
            module.write_catalog(catalog, pathlib.Path(directory), 'Localizable')
            with open(pathlib.Path(directory) / 'en.lproj/Localizable.strings', 'rb') as f:
                self.assertEqual(plistlib.load(f)['Quoted "key"'], 'Quoted "key"')
            with open(pathlib.Path(directory) / 'zh-Hans.lproj/Localizable.strings', 'rb') as f:
                self.assertEqual(plistlib.load(f)['Deploy'], '重新部署')

    def test_unsupported_variation_is_not_silently_dropped(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                module.write_catalog({'sourceLanguage': 'en', 'strings': {
                    'Count': {'localizations': {'en': {'variations': {}}}}}},
                    pathlib.Path(directory), 'Localizable')


if __name__ == '__main__':
    unittest.main()
