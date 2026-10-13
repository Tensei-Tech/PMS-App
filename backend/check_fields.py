import urllib.request, json
try:
    data = json.loads(urllib.request.urlopen('http://127.0.0.1:8000/api/categories/Tadipar/form-definition/').read().decode('utf-8'))
    for f in data['fields']:
        print(f"{f['field_key']}: {f['field_type']}")
except Exception as e:
    print(e)
