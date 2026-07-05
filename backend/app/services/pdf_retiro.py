import io

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.services.pdf_comum import (
    COR_AZUL_ESCURO,
    COR_FUNDO_CLARO,
    COR_LINHA_ALTERNADA,
    bloco_assinatura,
    bloco_cabecalho,
    campo_rotulo_valor,
    estilos_documento,
)


def gerar_pdf_retiro(retiro: dict, fases_nomes: list[str], sectores_nomes: list[str] | None = None) -> bytes:
    """Recebe o documento do retiro (tal como guardado no Mongo) e os nomes
    das fases/sectores já resolvidos, devolve os bytes do PDF."""
    sectores_nomes = sectores_nomes or []

    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        topMargin=1.8 * cm,
        bottomMargin=1.8 * cm,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
    )
    e = estilos_documento()
    elementos: list = []

    elementos += bloco_cabecalho(e, doc.width)
    elementos.append(Paragraph(retiro["titulo"], e["titulo_doc"]))

    data_str = retiro["data"].strftime("%Y-%m-%d")
    oradores_str = ", ".join(retiro.get("oradores", [])) or "—"
    fases_str = ", ".join(fases_nomes) or "—"
    sectores_str = ", ".join(sectores_nomes) or "—"

    linha1 = Table(
        [[
            campo_rotulo_valor(e, "DATA", data_str),
            campo_rotulo_valor(e, "ORADOR(A)", oradores_str),
        ]],
        colWidths=[doc.width / 2, doc.width / 2],
    )
    linha1.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    elementos.append(linha1)
    elementos.append(Spacer(1, 6))

    linha2 = Table(
        [[
            campo_rotulo_valor(e, "LOCAL", retiro.get("local", "")),
            campo_rotulo_valor(e, "FASES CONTEMPLADAS", fases_str),
        ]],
        colWidths=[doc.width / 2, doc.width / 2],
    )
    linha2.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    elementos.append(linha2)
    elementos.append(Spacer(1, 6))

    linha3 = Table(
        [[
            campo_rotulo_valor(e, "SECTORES PARTICIPANTES", sectores_str),
            campo_rotulo_valor(e, "", ""),
        ]],
        colWidths=[doc.width / 2, doc.width / 2],
    )
    linha3.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    elementos.append(linha3)
    elementos.append(Spacer(1, 10))

    # --- Tema ---
    elementos.append(Paragraph("TEMA", e["secao"]))
    tema_tabela = Table(
        [[Paragraph(retiro.get("tema", "") or "—", e["corpo"])]],
        colWidths=[doc.width],
    )
    tema_tabela.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), COR_FUNDO_CLARO),
        ("LINEBEFORE", (0, 0), (0, 0), 3, colors.HexColor("#B8964F")),
        ("LEFTPADDING", (0, 0), (-1, -1), 14),
        ("TOPPADDING", (0, 0), (-1, -1), 10),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 14),
    ]))
    elementos.append(tema_tabela)
    elementos.append(Spacer(1, 10))

    # --- Programa do dia ---
    elementos.append(Paragraph("PROGRAMA DO DIA", e["secao"]))

    estilo_cabecalho = ParagraphStyle(
        "cabecalho_programa", fontName="Helvetica-Bold", fontSize=10,
        textColor=colors.white, alignment=TA_CENTER,
    )
    estilo_celula = ParagraphStyle(
        "celula_programa", fontName="Helvetica", fontSize=10, textColor=colors.black,
    )

    programa = retiro.get("programa", [])
    linhas = [[
        Paragraph("HORA", estilo_cabecalho),
        Paragraph("ACTIVIDADE", estilo_cabecalho),
        Paragraph("RESPONSÁVEL", estilo_cabecalho),
    ]]
    for item in programa:
        linhas.append([
            Paragraph(item["hora"], estilo_celula),
            Paragraph(item["atividade"], estilo_celula),
            Paragraph(item["responsavel"], estilo_celula),
        ])

    if len(linhas) == 1:
        linhas.append([
            Paragraph("—", estilo_celula),
            Paragraph("Programa ainda por definir", estilo_celula),
            Paragraph("—", estilo_celula),
        ])

    tabela_programa = Table(linhas, colWidths=[3 * cm, doc.width - 3 * cm - 4.5 * cm, 4.5 * cm], repeatRows=1)
    estilo_tabela = [
        ("BACKGROUND", (0, 0), (-1, 0), COR_AZUL_ESCURO),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#DDDDDD")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
    ]
    for i in range(1, len(linhas)):
        if i % 2 == 0:
            estilo_tabela.append(("BACKGROUND", (0, i), (-1, i), COR_LINHA_ALTERNADA))
    tabela_programa.setStyle(TableStyle(estilo_tabela))
    elementos.append(tabela_programa)

    # --- Assinatura do coordenador ---
    elementos += bloco_assinatura(e, cargo="Coordenador(a) da Catequese")

    doc.build(elementos)
    return buffer.getvalue()
