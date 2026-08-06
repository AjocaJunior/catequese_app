import io

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.models.relatorio import RelatorioObservacoes
from app.services.pdf_comum import (
    COR_AZUL_ESCURO,
    COR_LINHA_ALTERNADA,
    bloco_assinatura,
    bloco_cabecalho,
    campo_rotulo_valor,
    estilos_documento,
)


def gerar_pdf_relatorio_observacoes(relatorio: RelatorioObservacoes) -> bytes:
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer, pagesize=A4, topMargin=1.8 * cm, bottomMargin=1.8 * cm, leftMargin=2 * cm, rightMargin=2 * cm,
    )
    e = estilos_documento()
    elementos: list = []

    elementos += bloco_cabecalho(e, doc.width)
    elementos.append(Paragraph("Relatório de Observações Pendentes", e["titulo_doc"]))
    elementos.append(campo_rotulo_valor(e, "TOTAL DE CATEQUISANDOS COM OBSERVAÇÃO", str(relatorio.total)))
    elementos.append(Spacer(1, 12))

    if not relatorio.grupos:
        elementos.append(Paragraph("Nenhum catequisando tem observações preenchidas de momento.", e["corpo"]))
        elementos += bloco_assinatura(e, cargo="Coordenador(a) da Catequese")
        doc.build(elementos)
        return buffer.getvalue()

    estilo_fase = ParagraphStyle(
        "fase_obs", fontName="Helvetica-Bold", fontSize=11, textColor=colors.white,
        alignment=TA_LEFT, backColor=COR_AZUL_ESCURO,
    )
    estilo_cabecalho = ParagraphStyle(
        "cab_obs", fontName="Helvetica-Bold", fontSize=9, textColor=colors.white, alignment=TA_CENTER,
    )
    estilo_cabecalho_esq = ParagraphStyle("cab_obs_esq", parent=estilo_cabecalho, alignment=TA_LEFT)
    estilo_celula = ParagraphStyle(
        "cel_obs", fontName="Helvetica", fontSize=9.5, textColor=colors.black, alignment=TA_CENTER,
    )
    estilo_celula_esq = ParagraphStyle("cel_obs_esq", parent=estilo_celula, alignment=TA_LEFT, leading=13)

    def _c(texto, estilo=estilo_celula) -> Paragraph:
        return Paragraph(str(texto), estilo)

    largura_util = doc.width
    col_num = 1.0 * cm
    col_nome = largura_util * 0.28
    col_obs = largura_util - col_num - col_nome

    for grupo in relatorio.grupos:
        tabela_titulo = Table([[Paragraph(grupo.fase_nome, estilo_fase)]], colWidths=[largura_util])
        tabela_titulo.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), COR_AZUL_ESCURO),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ]))
        elementos.append(tabela_titulo)

        linhas = [[_c("Nº", estilo_cabecalho), _c("NOME", estilo_cabecalho_esq), _c("OBSERVAÇÃO", estilo_cabecalho_esq)]]
        for item in grupo.linhas:
            linhas.append([_c(item.numero), _c(item.nome, estilo_celula_esq), _c(item.observacoes, estilo_celula_esq)])

        tabela = Table(linhas, colWidths=[col_num, col_nome, col_obs], repeatRows=1)
        estilo_tabela = [
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#3A4A6B")),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#DDDDDD")),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("TOPPADDING", (0, 0), (-1, -1), 6),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ]
        for i in range(1, len(linhas)):
            if i % 2 == 0:
                estilo_tabela.append(("BACKGROUND", (0, i), (-1, i), COR_LINHA_ALTERNADA))
        tabela.setStyle(TableStyle(estilo_tabela))
        elementos.append(tabela)
        elementos.append(Spacer(1, 16))

    elementos += bloco_assinatura(e, cargo="Coordenador(a) da Catequese")

    doc.build(elementos)
    return buffer.getvalue()
