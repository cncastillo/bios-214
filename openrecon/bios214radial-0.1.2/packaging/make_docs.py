"""Render the scanner README into the PDF required by the OpenRecon archive."""
import re
import sys
from pathlib import Path
from xml.sax.saxutils import escape

from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer

source, target = map(Path, sys.argv[1:])
styles = getSampleStyleSheet()
styles["Title"].fontSize = 18
styles["Title"].leading = 22
styles["Heading2"].fontSize = 11
styles["Heading2"].leading = 14
styles["Heading2"].spaceBefore = 9
body = ParagraphStyle("ScannerBody", fontName="Helvetica", fontSize=9, leading=12, spaceAfter=5)
bullet = ParagraphStyle("ScannerBullet", parent=body, leftIndent=10, firstLineIndent=-7, spaceAfter=3)
story = []
for paragraph in re.split(r"\n\s*\n", source.read_text().strip()):
    if paragraph.startswith("# "):
        story.append(Paragraph(escape(paragraph[2:]), styles["Title"]))
    elif paragraph.startswith("## "):
        story.append(Paragraph(escape(paragraph[3:]), styles["Heading2"]))
    elif paragraph.startswith("- "):
        story.extend(Paragraph("- " + escape(line[2:]), bullet) for line in paragraph.splitlines())
    else:
        story.append(Paragraph(escape(paragraph), body))
story.append(Spacer(1, 3 * mm))
SimpleDocTemplate(str(target), pagesize=(210 * mm, 297 * mm),
                  leftMargin=17 * mm, rightMargin=17 * mm, topMargin=13 * mm,
                  bottomMargin=13 * mm, title="bios214radial 0.1.2 - scanner instructions").build(story)
