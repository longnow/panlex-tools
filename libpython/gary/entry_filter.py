from gary import process_method_synonyms, process_synonyms, process_plx_synonyms, process_plx_dual_synonyms
from gary import source


class SimpleFilter(object):
    def __init__(self, func, *fields):
        self.func = func
        self.name = func.__name__
        self.fields = []
        for field in fields:
            if len(field.split('.')) == 1:
                self.fields.append('%s.text' % field)
            else:
                self.fields.append(field)


    def __call__(self, entry, *args, **kwargs):
        for fieldId in self.fields:
            parts = fieldId.split('.')
            langObj = entry.__getattribute__(parts[0])
            langValue = langObj.__getattribute__(parts[1])
            result = self.func(langValue, **kwargs)
            langObj.__setattr__(parts[1], result)



class SynonymFilter(object):
    def __init__(self, func, *languages):
        self.name = func.__name__
        self.func = process_synonyms(func)
        self.langs = languages


    def __call__(self, entry, *args, **kwargs):
        for langId in self.langs:
            langObj = entry.__getattribute__(langId)
            result = self.func(langObj.text, **kwargs)
            langObj.text = result


class PanlexSynonymFilter:
    def __init__(self, func, *languages):
        self.name = func.__name__
        self.func = process_plx_synonyms(func)
        self.langs = languages

    def __call__(self, entry, *args, **kwargs):
        for langId in self.langs:
            langObj = entry.__getattribute__(langId)
            result = self.func(langObj.text, **kwargs)
            langObj.text = result


class PanlexExtractorFilter:
    def __init__(self, dual_func, fromField, toField, **kwargs):
        self.func = process_plx_dual_synonyms(dual_func)
        self.name = dual_func.__name__
        self.fromProps = fromField.split('.')
        self.toProps = toField.split('.')

    def __call__(self, entry, *args, **kwargs):
        fromField = entry.__getattribute__(self.fromProps[0]).__getattribute__(self.fromProps[1])
        toField = entry.__getattribute__(self.toProps[0]).__getattribute__(self.toProps[1])
        result = self.func(fromField, toField)
        fromResult,toResult = result
        entry.__getattribute__(self.fromProps[0]).__setattr__(self.fromProps[1], fromResult)
        entry.__getattribute__(self.toProps[0]).__setattr__(self.toProps[1], toResult)



class PredicateFilter(object):
    def __init__(self, func, *field_list):
        self.func = func
        self.name = func.__name__
        self.fields = []

        for field in field_list:
            items = field.split('.')

            if len(items) == 1:
                # if no attribute is given, assume text field attribute
                self.fields.append((field,'text'))
            elif len(items) == 2:
                self.fields.append(tuple(items))
            else:
                print('WARNING: FAILED MATCH FOR FIELD: %s' % field)

    def __call__(self, entry, *args, **kwargs):
        for lang,field in self.fields:
            langObj = entry.__getattribute__(lang)
            langValue = langObj.__getattribute__(field)
            return self.func(langValue, **kwargs)



class ExtractorFilter(object):
    def __init__(self, dual_func, fromField, toField, **kwargs):
        self.func = dual_func
        self.name = dual_func.__name__
        self.fromProps = fromField.split('.')
        self.toProps = toField.split('.')

    def __call__(self, entry, *args, **kwargs):
        fromField = entry.__getattribute__(self.fromProps[0]).__getattribute__(self.fromProps[1])
        toField = entry.__getattribute__(self.toProps[0]).__getattribute__(self.toProps[1])
        fromResult,toResult = self.func(fromField, toField)
        entry.__getattribute__(self.fromProps[0]).__setattr__(self.fromProps[1], fromResult)
        entry.__getattribute__(self.toProps[0]).__setattr__(self.toProps[1], toResult)




class TextExtractorFilter(object):
    def __init__(self, dual_func, fromField, toField, **kwargs):
        self.name = dual_func.__name__
        self.func = source.process_text_synonym_extract(dual_func)
        self.fromProps = fromField.split('.')
        self.toProps = toField.split('.')

    def __call__(self, entry, *args, **kwargs):
        fromField = entry.__getattribute__(self.fromProps[0]).__getattribute__(self.fromProps[1])
        toField = entry.__getattribute__(self.toProps[0]).__getattribute__(self.toProps[1])
        fromResult,toResult = self.func(fromField, toField)
        entry.__getattribute__(self.fromProps[0]).__setattr__(self.fromProps[1], fromResult)
        entry.__getattribute__(self.toProps[0]).__setattr__(self.toProps[1], toResult)