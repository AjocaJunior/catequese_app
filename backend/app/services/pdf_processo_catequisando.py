import io

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.services.pdf_comum import (
    COR_AZUL_ESCURO,
    COR_LINHA_ALTERNADA,
    bloco_assinatura,
    bloco_cabecalho,
    campo_rotulo_valor,
    estilos_documento,
)


def gerar_pdf_processo_catequisando(
    catequisando: dict,
    fase_nome: str,
    registos_presenca: list[dict],
    sector_nome: str | None = None,
) -> bytes:
    """catequisando: documento do Mongo do catequisando.
    registos_presenca: lista de {"data": date, "presente": bool}, já ordenada por data."""
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
    elementos.append(Paragraph("Processo do Catequisando", e["titulo_doc"]))
    elementos.append(Paragraph(catequisando["nome"], ParagraphStyle(
        "nome_catequisando", fontName="Helvetica-Bold", fontSize=13,
        alignment=TA_CENTER, spaceAfter=14,
    )))

    data_nasc = catequisando.get("data_nascimento")
    data_nasc_str = data_nasc.strftime("%d/%m/%Y") if data_nasc else "—"

    linha1 = Table(
        [[
            campo_rotulo_valor(e, "FASE", fase_nome),
            campo_rotulo_valor(e, "DATA DE NASCIMENTO", data_nasc_str),
        ]],
        colWidths=[doc.width / 2, doc.width / 2],
    )
    linha1.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    elementos.append(linha1)

    linha1b = Table(
        [[
            campo_rotulo_valor(e, "SECTOR PASTORAL", sector_nome or "—"),
            campo_rotulo_valor(e, "", ""),
        ]],
        colWidths=[doc.width / 2, doc.width / 2],
    )
    linha1b.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    elementos.append(linha1b)

    linha2 = Table(
        [[
            campo_rotulo_valor(e, "ENCARREGADO DE EDUCAÇÃO", catequisando.get("encarregado_nome") or "—"),
            campo_rotulo_valor(e, "PARENTESCO", catequisando.get("encarregado_parentesco") or "—"),
        ]],
        colWidths=[doc.width / 2, doc.width / 2],
    )
    linha2.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    elementos.append(linha2)

    linha3 = Table(
        [[
            campo_rotulo_valor(e, "CONTACTO DO ENCARREGADO", catequisando.get("encarregado_contacto") or "—"),
            campo_rotulo_valor(e, "OBSERVAÇÕES", catequisando.get("observacoes") or "—"),
        ]],
        colWidths=[doc.width / 2, doc.width / 2],
    )
    linha3.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    elementos.append(linha3)
    elementos.append(Spacer(1, 6))

    # --- Resumo de presenças ---
    total = len(registos_presenca)
    presentes = sum(1 for r in registos_presenca if r["status"] == "presente")
    faltas = sum(1 for r in registos_presenca if r["status"] == "falta")
    faltas_justificadas = sum(1 for r in registos_presenca if r["status"] == "falta_justificada")
    percentagem = f"{(presentes / total * 100):.0f}%" if total else "—"

    elementos.append(Paragraph("PRESENÇAS", e["secao"]))
    resumo = Table(
        [[
            campo_rotulo_valor(e, "REGISTOS", str(total)),
            campo_rotulo_valor(e, "PRESENÇAS", str(presentes)),
            campo_rotulo_valor(e, "FALTAS", str(faltas)),
            campo_rotulo_valor(e, "FALTAS JUST.", str(faltas_justificadas)),
            campo_rotulo_valor(e, "ASSIDUIDADE", percentagem),
        ]],
        colWidths=[doc.width / 5] * 5,
    )
    resumo.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    elementos.append(resumo)
    elementos.append(Spacer(1, 10))

    if registos_presenca:
        estilo_cabecalho = ParagraphStyle(
            "cabecalho_presencas", fontName="Helvetica-Bold", fontSize=9,
            textColor=colors.white, alignment=TA_CENTER,
        )
        estilo_celula = ParagraphStyle(
            "celula_presencas", fontName="Helvetica", fontSize=9,
            textColor=colors.black, alignment=TA_CENTER,
        )

        rotulo_status = {
            "presente": "Presente",
            "falta": "Falta",
            "falta_justificada": "Falta Justificada",
        }

        linhas = [[Paragraph("DATA", estilo_cabecalho), Paragraph("PRESENÇA", estilo_cabecalho)]]
        for r in registos_presenca:
            texto = rotulo_status.get(r["status"], r["status"])
            linhas.append([
                Paragraph(r["data"].strftime("%d/%m/%Y"), estilo_celula),
                Paragraph(texto, estilo_celula),
            ])

        tabela = Table(linhas, colWidths=[doc.width / 2, doc.width / 2], repeatRows=1)
        estilo_tabela = [
            ("BACKGROUND", (0, 0), (-1, 0), COR_AZUL_ESCURO),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#DDDDDD")),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ]
        for i in range(1, len(linhas)):
            if i % 2 == 0:
                estilo_tabela.append(("BACKGROUND", (0, i), (-1, i), COR_LINHA_ALTERNADA))
        tabela.setStyle(TableStyle(estilo_tabela))
        elementos.append(tabela)
    else:
        elementos.append(Paragraph("Ainda não há registos de presença.", e["corpo"]))

    elementos += bloco_assinatura(e, cargo="Coordenador(a) da Catequese")

    doc.build(elementos)
    return buffer.getvalue()
