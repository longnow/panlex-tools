def get_translations(expn, startLang, endLang, distance=1):
    """Get all translations of expn, an expression in startLang, into endLang.
    Languages are specified as PanLex UID codes (e.g. eng-000 for English.)"""
    params1 = {"uid":startLang,
               "tt":expn,
               "indent":True}
    r1 = query("/ex",params1)
    exid = r1["result"][0]["ex"]
    params2 = {"trex":exid,
               "uid":endLang,
               "indent":True,
               "include":"trq",
               "trdistance":distance,
               "sort":"trq desc",
    r2 = query("/ex",params2)
    
    return r2["result"]
