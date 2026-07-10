import io

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.models.relatorio import RelatorioCatequisandosPorFaseGenero
from app.services.pdf_comum import (
    COR_AZUL_ESCURO,
    COR_LINHA_ALTERNADA,
    bloco_assinatura,
    bloco_cabecalho,
    campo_rotulo_valor,
    estilos_documento,
)


def gerar_pdf_relatorio_fase_genero(relatorio: RelatorioCatequisandosPorFaseGenero) -> bytes:
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer, pagesize=A4, topMargin=1.8 * cm, bottomMargin=1.8 * cm, leftMargin=2 * cm, rightMargin=2 * cm,
    )
    e = estilos_documento()
    elementos: list = []

    elementos += bloco_cabecalho(e, doc.width)
    elementos.append(Paragraph("Relatório Estatístico — Catequisandos por Fase e Género", e["titulo_doc"]))
    elementos.append(campo_rotulo_valor(e, "ANO LETIVO", str(relatorio.ano_letivo)))
    elementos.append(Spacer(1, 12))

    estilo_cabecalho = ParagraphStyle(
        "cab_relgen", fontName="Helvetica-Bold", fontSize=9, textColor=colors.white, alignment=TA_CENTER,
    )
    estilo_cabecalho_esq = ParagraphStyle("cab_relgen_esq", parent=estilo_cabecalho, alignment=TA_LEFT)
    estilo_celula = ParagraphStyle(
        "cel_relgen", fontName="Helvetica", fontSize=9, textColor=colors.black, alignment=TA_CENTER,
    )
    estilo_celula_esq = ParagraphStyle("cel_relgen_esq", parent=estilo_celula, alignment=TA_LEFT)
    estilo_negrito = ParagraphStyle("neg_relgen", parent=estilo_celula, fontName="Helvetica-Bold")
    estilo_negrito_esq = ParagraphStyle("neg_relgen_esq", parent=estilo_celula_esq, fontName="Helvetica-Bold")

    def _c(texto, estilo=estilo_celula) -> Paragraph:
        return Paragraph(str(texto), estilo)

    linhas = [[
        _c("FASE", estilo_cabecalho_esq),
        _c("MASCULINO", estilo_cabecalho),
        _c("FEMININO", estilo_cabecalho),
        _c("NÃO INF.", estilo_cabecalho),
        _c("TOTAL", estilo_cabecalho),
    ]]
    for l in relatorio.linhas:
        linhas.append([
            _c(l.fase_nome, estilo_celula_esq), _c(l.masculino), _c(l.feminino), _c(l.nao_informado), _c(l.total),
        ])
    linhas.append([
        _c("TOTAL GERAL", estilo_negrito_esq),
        _c(relatorio.total_masculino, estilo_negrito),
        _c(relatorio.total_feminino, estilo_negrito),
        _c(relatorio.total_nao_informado, estilo_negrito),
        _c(relatorio.total_geral, estilo_negrito),
    ])

    largura_util = doc.width
    col_fase = largura_util * 0.36
    col_resto = (largura_util - col_fase) / 4

    tabela = Table(linhas, colWidths=[col_fase, col_resto, col_resto, col_resto, col_resto], repeatRows=1)
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

    elementos += bloco_assinatura(e, cargo="Coordenador(a) da Catequese")

    doc.build(elementos)
    return buffer.getvalue()
