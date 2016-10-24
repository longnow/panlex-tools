from gary import process_method_synonyms, process_synonyms,process_plx_synonyms,process_plx_dual_synonyms


class EntryFilter(object):
    # def extract_fields(self, *fields)-> list:
    #     pass
    #
    #
    # def setFields(self, entry, fieldId:str):
    #     # PRE: field ID is never null
    #     labels = fieldId.split('.')
    #     entry.setField(labels[0], labels[1])


    def _splitFields(self, label:str) -> str:
        fields = label.split('.')

        if len(fields) == 1:
            column = 'text'
        else:
            column = fields[1]

        return '%s.%s' % (fields[0],column)



class SimpleFilter(EntryFilter):
    def __init__(self, func, *fields):
        self.func = func
        self.name = func.__name__
        self.fields = []
        for field in fields:
            result = self._splitFields(field)
            self.fields.append(result)


    def __call__(self, entry, *args, **kwargs):
        for fieldId in self.fields:
            if type(entry[fieldId]) != str:
                bad_type = str(type(entry[fieldId]))
                msg = 'field %s has type %s, should be string' % (fieldId, bad_type)
                raise TypeError(msg)
            entry[fieldId] = self.func(entry[fieldId])

        return entry


class SynonymFilter(object):
    def __init__(self, func, *filtered_fields):
        self.name = func.__name__
        self.func = process_synonyms(func)
        self.fields = filtered_fields


    def __call__(self, entry, *args, **kwargs):
        for fieldId in self.fields:
            entry[fieldId] = self.func(entry[fieldId])

        return entry



class PanlexSynonymFilter:
    def __init__(self, func, *fields):
        self.name = func.__name__
        self.func = process_plx_synonyms(func)
        self.fields = fields

    def __call__(self, entry):
        for fieldId in self.fields:
            entry[fieldId] = self.func(entry[fieldId])

        return entry



class PredicateFilter(EntryFilter):
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



class ExtractorFilter(EntryFilter):
    def __init__(self, dual_func, fromField, toField, **kwargs):
        print('DEPRECATED: ExtractorFilter')
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



class PanlexExtractorFilter:
    def __init__(self, dual_func, fromField, toField, **kwargs):
        self.func = process_plx_dual_synonyms(dual_func)
        self.name = dual_func.__name__
        self.fromProps = fromField
        self.toProps = toField

    def __call__(self, entry, *args, **kwargs):
        fromField = entry[self.fromProps]
        toField = entry[self.toProps]
        result = self.func(fromField, toField)
        fromResult,toResult = result
        entry[self.fromProps] = fromResult
        entry[self.toProps] = toResult
