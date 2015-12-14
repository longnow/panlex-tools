
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
    def __init__(self, dual_func, fromField, toField, **kwargs):
        self.func = dual_func
        self.fromProps = fromField.split('.')
        self.toProps = toField.split('.')

    def __call__(self, entry, *args, **kwargs):
        fromField = entry.__getattribute__(self.fromProps[0]).__getattribute__(self.fromProps[1])
        toField = entry.__getattribute__(self.toProps[0]).__getattribute__(self.toProps[1])
        fromResult,toResult = self.func(fromField, toField)
        entry.__getattribute__(self.fromProps[0]).__setattr__(self.fromProps[1], fromResult)
        entry.__getattribute__(self.toProps[0]).__setattr__(self.toProps[1], toResult)


