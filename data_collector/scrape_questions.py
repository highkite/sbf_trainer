import sys
import json
import urllib.request
import lxml.etree as ET

url = "https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragenkatalog-Binnen/Basisfragen/Basisfragen-node.html"
xp_question = "//div/ol"

with urllib.request.urlopen(url) as response:
    html = response.read()

    root = ET.HTML(html)

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
            f = open(f"0000000{i}-{j}.jpg", "wb")
            image_names.append(f"0000000{i}-{j}.jpg")
            f.write(urllib.request.urlopen(img_url).read())
            f.close()
            j += 1

        i += 1
        obj = {"answers": answers, "question": question[0]}
        if len(image_names) > 0:
            obj["images"] = image_names
        data.append(obj)
        # print(text.xpath("//li/text()"))
    #    tree = etree.parse(str(html))
    #
    #    r = tree.xpath(xp_question)
    #    for x in r:
    #        print(x.xpath("//li/text()"))

    with open("./data.json", "w") as f:
        f.write(json.dumps(data))
