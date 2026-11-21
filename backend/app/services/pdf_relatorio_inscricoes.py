import io

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.models.relatorio import RelatorioInscricoes
from app.services.pdf_comum import (
    COR_AZUL_ESCURO,
    COR_LINHA_ALTERNADA,
    bloco_assinatura,
    bloco_cabecalho,
    campo_rotulo_valor,
    estilos_documento,
)


def gerar_pdf_relatorio_inscricoes(relatorio: RelatorioInscricoes) -> bytes:
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer, pagesize=A4, topMargin=1.8 * cm, bottomMargin=1.8 * cm, leftMargin=2 * cm, rightMargin=2 * cm,
    )
    e = estilos_documento()
    elementos: list = []

    elementos += bloco_cabecalho(e, doc.width)
    elementos.append(Paragraph("Relatório de Inscrições e Renovações por Fase", e["titulo_doc"]))
    elementos.append(campo_rotulo_valor(e, "ANO LETIVO", str(relatorio.ano_letivo)))
    elementos.append(Spacer(1, 12))

    estilo_cabecalho = ParagraphStyle(
        "cab_relinsc", fontName="Helvetica-Bold", fontSize=9, textColor=colors.white, alignment=TA_CENTER,
    )
    estilo_cabecalho_esq = ParagraphStyle("cab_relinsc_esq", parent=estilo_cabecalho, alignment=TA_LEFT)
    estilo_celula = ParagraphStyle(
        "cel_relinsc", fontName="Helvetica", fontSize=9, textColor=colors.black, alignment=TA_CENTER,
    )
    estilo_celula_esq = ParagraphStyle("cel_relinsc_esq", parent=estilo_celula, alignment=TA_LEFT)
    estilo_negrito = ParagraphStyle("neg_relinsc", parent=estilo_celula, fontName="Helvetica-Bold")
    estilo_negrito_esq = ParagraphStyle("neg_relinsc_esq", parent=estilo_celula_esq, fontName="Helvetica-Bold")

    def _c(texto, estilo=estilo_celula) -> Paragraph:
        return Paragraph(str(texto), estilo)

    linhas = [[
        _c("FASE", estilo_cabecalho_esq),
        _c("CATEQ.", estilo_cabecalho),
        _c("INSCR.", estilo_cabecalho),
        _c("RENOV.", estilo_cabecalho),
        _c("PENDENTES", estilo_cabecalho),
        _c("VALOR (MT)", estilo_cabecalho),
    ]]
    for l in relatorio.linhas:
        linhas.append([
            _c(l.fase_nome, estilo_celula_esq),
            _c(l.total_catequisandos),
            _c(l.inscricoes),
            _c(l.renovacoes),
            _c(l.pendentes),
            _c(f"{l.valor_total:.2f}"),
        ])
    linhas.append([
        _c("TOTAL GERAL", estilo_negrito_esq),
        _c(relatorio.total_catequisandos, estilo_negrito),
        _c(relatorio.total_inscricoes, estilo_negrito),
        _c(relatorio.total_renovacoes, estilo_negrito),
        _c(relatorio.total_pendentes, estilo_negrito),
        _c(f"{relatorio.valor_total:.2f}", estilo_negrito),
    ])

    largura_util = doc.width
    col_fase = largura_util * 0.30
    col_resto = (largura_util - col_fase) / 5

    tabela = Table(
        linhas,
        colWidths=[col_fase, col_resto, col_resto, col_resto, col_resto, col_resto],
        repeatRows=1,
    )
    estilo_tabela = [
        ("BACKGROUND", (0, 0), (-1, 0), COR_AZUL_ESCURO),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#DDDDDD")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("BACKGROUND", (0, -1), (-1, -1), COR_LINHA_ALTERNADA),
        ("LINEABOVE", (0, -1), (-1, -1), 1, COR_AZUL_ESCURO),
    ]
    for i in range(1, len(linhas) - 1):
        if i % 2 == 0:
            estilo_tabela.append(("BACKGROUND", (0, i), (-1, i), COR_LINHA_ALTERNADA))
    tabela.setStyle(TableStyle(estilo_tabela))
    elementos.append(tabela)

    estilo_legenda = ParagraphStyle(
        "legenda_relinsc", fontName="Helvetica", fontSize=8, textColor=colors.HexColor("#555555"),
        alignment=TA_LEFT, spaceBefore=8,
    )
    elementos.append(Paragraph(
        "<b>Nota</b> — \"Pendentes\" é o número de catequisandos ativos da fase "
        "que ainda não têm inscrição ou renovação registada na Caixa para este ano letivo.",
        estilo_legenda,
    ))

    elementos += bloco_assinatura(e, cargo="Coordenador(a) da Catequese")

    doc.build(elementos)
    return buffer.getvalue()
