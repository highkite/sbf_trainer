import sys
import json
import urllib.request
import lxml.etree as ET

url = "https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragenkatalog-Binnen/Basisfragen/Basisfragen-node.html"
# Spez fragen Binnen
url = "https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragenkatalog-Binnen/Spezifische-Fragen-Binnen/Spezifische-Fragen-Binnen-node.html;jsessionid=9C139B4A93F78D24AD0746522F17ED4D.server1t2"
url = "https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragenkatalog-Binnen/Spezifische-Fragen-Segeln/Spezifische-Fragen-Segeln-node.html;jsessionid=9C139B4A93F78D24AD0746522F17ED4D.server1t2"
xp_question = "//div/ol"


def iter_text(element):
    p = ""
    for q in element.itertext():
        p += str(q)

    return p


with urllib.request.urlopen(url) as response:
    html = response.read()

    root = ET.HTML(html)

    i = 1
    data = []

    for x in root.xpath('//div[contains(@class, "line")]'):
        ps = x.xpath("./following-sibling::*")
        q = 0
        question_str = iter_text(ps[q])

        answers = []
        image_names = []
        q = 1

        nextV = ps[q]

        while not nextV.tag == "ol":
            # add image
            images = nextV.xpath("./*/img/@src")

            j = 0
            for img in images:
                img_url = "https://elwis.de" + img
                print(f"Fetch: {img_url}")
                f = open(f"0000003{i}-{j}.gif", "wb")
                image_names.append(f"0000003{i}-{j}.gif")
                f.write(urllib.request.urlopen(img_url).read())
                f.close()
                j += 1

            nextV = ps[q]
            q += 1

        answer_path = nextV.xpath("./li")

        for an in answer_path:
            answers.append(iter_text(an))

        obj = {
            "ide": {"ide": i, "questionType": 3},
            "answers": answers,
            "question": question_str,
        }

        if len(image_names) > 0:
            obj["images"] = image_names

        data.append(obj)
        i += 1

    with open("./segeln_data.json", "w") as f:
        f.write(json.dumps(data))
