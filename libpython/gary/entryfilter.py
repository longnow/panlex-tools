
class SimpleFilter(object):
    def __init__(self, func, *languages):
        self.func = func
        self.langs = languages

    def __call__(self, entry, *args, **kwargs):
        for langId in self.langs:
            langObj = entry.__getattribute__(langId)
            result = self.func(langObj.text, **kwargs)
            langObj.text = result


class ExtractorFilter(object):
    def __init__(self, func, fromField, toField, **kwargs):
        self.func = func
        self.fromProperties = fromField.split('.')
        self.toProperties = toField.split('.')

    def __call__(self, entry, *args, **kwargs):
        fromField = entry.__getattribute__(self.fromProperties[0]).__getattribute__(self.fromProperties[1])
        result = self.func()
        toField = entry.__getattribute__(self.toProperties[0]).__getattribute__(self.toProperties[1])
