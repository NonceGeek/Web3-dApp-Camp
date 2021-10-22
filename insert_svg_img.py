import sys,re

templet = '''
<a xmlns="http://www.w3.org/2000/svg" href="{}" target="_blank" fill="#9FA0A4">{}</a>
'''

with open("new.svg","r") as r:
    data = r.read()

insert_old = sys.argv[1]
insert_url = sys.argv[2]

try:
    insert_old_se = re.findall('<tspan id=".*?" style=".*?">{}<\/tspan>'.format(insert_old),data)[0]
    insert_old_se = insert_old_se[insert_old_se.rfind("<tspan"):]
except Exception as e:
    print("err:{}".format(e))

insert_data = templet.format(insert_url,insert_old_se)
data = data.replace(insert_old_se,insert_data)

with open("new.svg",'w') as w:
    w.write(data)