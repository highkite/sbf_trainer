import sys
import json
import urllib.request
import lxml.etree as ET

url = "https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragenkatalog-Binnen/Basisfragen/Basisfragen-node.html"
# Spez fragen Binnen
url = "https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragenkatalog-Binnen/Spezifische-Fragen-Binnen/Spezifische-Fragen-Binnen-node.html;jsessionid=9C139B4A93F78D24AD0746522F17ED4D.server1t2"
xp_question = "//div/ol"

with urllib.request.urlopen(url) as response:
    html = response.read()

    root = ET.HTML(html)

    for x in root.xpath('//div[@id="content"]/ol/li'):
        p = ""
        for q in x.itertext():
            p += str(q)

        print(p)

    exit(0)

    data = []

    i = 1
    for text in root.xpath(xp_question):
        question = text.xpath("./li/text()")
        if len(question) <= 0:
            continue
        print(f"==========================")
        print(f"Question: {i}")
        print(question[0])
        answers = [x for x in text.xpath("./li/ol/li/text()") if len(x) > 2]
        for answer in answers:
            print(f"\t{answer}")

        images = text.xpath("./li/p/span/img/@src")

        image_names = []

        j = 0
        for img in images:
            img_url = "https://elwis.de" + img
            print(f"Fetch: {img_url}")
            f = open(f"0000002{i}-{j}.jpg", "wb")
            image_names.append(f"0000002{i}-{j}.jpg")
            f.write(urllib.request.urlopen(img_url).read())
            f.close()
            j += 1

        obj = {
            "ide": {"ide": i, "questionType": 2},
            "answers": answers,
            "question": question[0],
        }
        i += 1
        if len(image_names) > 0:
            obj["images"] = image_names
        data.append(obj)
        # print(text.xpath("//li/text()"))
    #    tree = etree.parse(str(html))
    #
    #    r = tree.xpath(xp_question)
    #    for x in r:
    #        print(x.xpath("//li/text()"))

    with open("./binnen_data.json", "w") as f:
        f.write(json.dumps(data))
