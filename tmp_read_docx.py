import zipfile
import xml.etree.ElementTree as ET
import sys

def read_docx(file_path):
    try:
        with zipfile.ZipFile(file_path, 'r') as z:
            doc_xml = z.read('word/document.xml')
            root = ET.fromstring(doc_xml)
            namespace = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
            text = []
            for para in root.findall('.//w:p', namespace):
                para_text = "".join([t.text for t in para.findall('.//w:t', namespace) if t.text])
                if para_text:
                    text.append(para_text)
            return "\n".join(text)
    except Exception as e:
        return f"Error: {str(e)}"

if __name__ == "__main__":
    file_path = "D:\\Tavo\\2025\\UX\\00. Recetas\\ESPECIFICACIÓN DE REQUERIMIENTOS (SRS) - DETALLE TOTAL.docx"
    with open("tmp_srs_content.md", "w", encoding="utf-8") as f:
        f.write(read_docx(file_path))
