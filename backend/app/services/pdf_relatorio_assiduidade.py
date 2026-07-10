import io

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.models.relatorio import RelatorioAssiduidade
from app.services.pdf_comum import (
    COR_AZUL_ESCURO,
    COR_LINHA_ALTERNADA,
    bloco_assinatura,
    bloco_cabecalho,
    campo_rotulo_valor,
    estilos_documento,
)


def gerar_pdf_relatorio_assiduidade(relatorio: RelatorioAssiduidade) -> bytes:
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer, pagesize=A4, topMargin=1.8 * cm, bottomMargin=1.8 * cm, leftMargin=2 * cm, rightMargin=2 * cm,
    )
    e = estilos_documento()
    elementos: list = []

    elementos += bloco_cabecalho(e, doc.width)
    elementos.append(Paragraph("Relatório de Assiduidade Geral", e["titulo_doc"]))
    elementos.append(campo_rotulo_valor(e, "ANO LETIVO", str(relatorio.ano_letivo)))
    elementos.append(campo_rotulo_valor(e, "TAXA DE ASSIDUIDADE GERAL", f"{relatorio.taxa_geral:.1f}%"))
    elementos.append(Spacer(1, 12))

    estilo_cabecalho = ParagraphStyle(
        "cab_assid", fontName="Helvetica-Bold", fontSize=9, textColor=colors.white, alignment=TA_CENTER,
    )
    estilo_cabecalho_esq = ParagraphStyle("cab_assid_esq", parent=estilo_cabecalho, alignment=TA_LEFT)
    estilo_celula = ParagraphStyle(
        "cel_assid", fontName="Helvetica", fontSize=9, textColor=colors.black, alignment=TA_CENTER,
    )
    estilo_celula_esq = ParagraphStyle("cel_assid_esq", parent=estilo_celula, alignment=TA_LEFT)
    estilo_negrito = ParagraphStyle("neg_assid", parent=estilo_celula, fontName="Helvetica-Bold")

    def _c(texto, estilo=estilo_celula) -> Paragraph:
        return Paragraph(str(texto), estilo)

    def _cor_taxa(taxa: float):
        if taxa >= 80:
            return colors.HexColor("#1B7A3D")
        if taxa >= 60:
            return colors.HexColor("#B8860B")
        return colors.HexColor("#B22222")

    linhas = [[
        _c("FASE", estilo_cabecalho_esq),
        _c("CATEQUISANDOS", estilo_cabecalho),
        _c("PRESENÇAS", estilo_cabecalho),
        _c("FALTAS", estilo_cabecalho),
        _c("FALTAS JUST.", estilo_cabecalho),
        _c("ASSIDUIDADE", estilo_cabecalho),
    ]]
    for l in relatorio.linhas:
        estilo_taxa = ParagraphStyle(
            f"taxa_{l.fase_id}", parent=estilo_negrito, textColor=_cor_taxa(l.taxa_assiduidade),
        )
        linhas.append([
            _c(l.fase_nome, estilo_celula_esq),
            _c(l.total_catequisandos),
            _c(l.total_presencas),
            _c(l.total_faltas),
            _c(l.total_faltas_justificadas),
            _c(f"{l.taxa_assiduidade:.1f}%", estilo_taxa),
        ])

    largura_util = doc.width
    col_fase = largura_util * 0.28
    col_resto = (largura_util - col_fase) / 5

    tabela = Table(
        linhas, colWidths=[col_fase, col_resto, col_resto, col_resto, col_resto, col_resto], repeatRows=1,
    )
    estilo_tabela = [
        ("BACKGROUND", (0, 0), (-1, 0), COR_AZUL_ESCURO),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#DDDDDD")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
    ]
    for i in range(1, len(linhas)):
        if i % 2 == 0:
            estilo_tabela.append(("BACKGROUND", (0, i), (-1, i), COR_LINHA_ALTERNADA))
    tabela.setStyle(TableStyle(estilo_tabela))
    elementos.append(tabela)

    elementos.append(Spacer(1, 10))
    elementos.append(Paragraph(
        "Assiduidade = presenças ÷ (presenças + faltas + faltas justificadas). "
        "Catequisandos já Crismados não entram nesta contagem.",
        e["corpo"],
    ))

    elementos += bloco_assinatura(e, cargo="Coordenador(a) da Catequese")

    doc.build(elementos)
    return buffer.getvalue()
