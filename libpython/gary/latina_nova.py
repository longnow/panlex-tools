
import requests
from urllib.parse import urlencode

def find_latin(text):
    result = {'name':text}
    payload = {'text':text}
    response = requests.get('http://localhost:3000', params=payload)

    if response.status_code == 200:
        data = response.json()

        if len(data) > 0:
            result = data[0]
    else:
        print('Error reading URL: %s' %  response.status_code)

    return result


if __name__ == '__main__':
    with open('latin_words.txt') as fin:
        for example in fin:
            result = find_latin(example)
            if 'offsets' in result:
                start,end = result['offsets']
                name = result['name']
                print('LATIN: %s[%s]%s' % (name[:start],name[start:end],name[end:]))
            else:
                print('NOT LATIN: %s' % example.strip())
