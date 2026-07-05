import io

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.models.presenca import LinhaRelatorioPresencas
from app.services.pdf_comum import (
    COR_AZUL_ESCURO,
    COR_LINHA_ALTERNADA,
    bloco_assinatura,
    bloco_cabecalho,
    campo_rotulo_valor,
    estilos_documento,
)


def gerar_pdf_relatorio_presencas(
    fase_nome: str,
    catequistas_nomes: list[str],
    linhas: list[LinhaRelatorioPresencas],
) -> bytes:
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
    elementos.append(Paragraph(f"Relatório de Presenças — {fase_nome}", e["titulo_doc"]))

    catequistas_str = ", ".join(catequistas_nomes) or "—"
    elementos.append(campo_rotulo_valor(e, "CATEQUISTA(S) DA FASE", catequistas_str))
    elementos.append(Spacer(1, 12))

    estilo_cabecalho = ParagraphStyle(
        "cabecalho_relatorio", fontName="Helvetica-Bold", fontSize=9,
        textColor=colors.white, alignment=TA_CENTER,
    )
    estilo_cabecalho_esq = ParagraphStyle("cabecalho_relatorio_esq", parent=estilo_cabecalho, alignment=TA_LEFT)
    estilo_celula = ParagraphStyle(
        "celula_relatorio", fontName="Helvetica", fontSize=9,
        textColor=colors.black, alignment=TA_CENTER,
    )
    estilo_celula_esq = ParagraphStyle("celula_relatorio_esq", parent=estilo_celula, alignment=TA_LEFT)
    estilo_celula_negrito = ParagraphStyle(
        "celula_relatorio_negrito", parent=estilo_celula, fontName="Helvetica-Bold",
    )

    def _c(texto: str, estilo=estilo_celula) -> Paragraph:
        return Paragraph(texto, estilo)

    dados_tabela = [[
        _c("NOME", estilo_cabecalho_esq),
        _c("PRESENÇAS", estilo_cabecalho),
        _c("FALTAS", estilo_cabecalho),
        _c("FALTAS JUST.", estilo_cabecalho),
        _c("ASSIDUIDADE", estilo_cabecalho),
    ]]

    total_presencas = total_faltas = total_faltas_just = total_geral = 0

    for linha in linhas:
        percentagem = f"{(linha.presencas / linha.total * 100):.0f}%" if linha.total else "—"
        dados_tabela.append([
            _c(linha.nome, estilo_celula_esq),
            _c(str(linha.presencas)),
            _c(str(linha.faltas)),
            _c(str(linha.faltas_justificadas)),
            _c(percentagem),
        ])
        total_presencas += linha.presencas
        total_faltas += linha.faltas
        total_faltas_just += linha.faltas_justificadas
        total_geral += linha.total

    if not linhas:
        dados_tabela.append([_c("Sem catequisandos nesta fase", estilo_celula_esq), _c("—"), _c("—"), _c("—"), _c("—")])
    else:
        percentagem_geral = f"{(total_presencas / total_geral * 100):.0f}%" if total_geral else "—"
        dados_tabela.append([
            _c("TOTAL", estilo_celula_negrito),
            _c(str(total_presencas), estilo_celula_negrito),
            _c(str(total_faltas), estilo_celula_negrito),
            _c(str(total_faltas_just), estilo_celula_negrito),
            _c(percentagem_geral, estilo_celula_negrito),
        ])

    largura_util = doc.width
    col_nome = largura_util * 0.36
    col_resto = (largura_util - col_nome) / 4

    tabela = Table(
        dados_tabela,
        colWidths=[col_nome, col_resto, col_resto, col_resto, col_resto],
        repeatRows=1,
    )
    estilo_tabela = [
        ("BACKGROUND", (0, 0), (-1, 0), COR_AZUL_ESCURO),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#DDDDDD")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("LINEABOVE", (0, -1), (-1, -1), 1, COR_AZUL_ESCURO),
    ]
    for i in range(1, len(dados_tabela) - 1):
        if i % 2 == 0:
            estilo_tabela.append(("BACKGROUND", (0, i), (-1, i), COR_LINHA_ALTERNADA))
    tabela.setStyle(TableStyle(estilo_tabela))
    elementos.append(tabela)

    elementos += bloco_assinatura(e, cargo="Coordenador(a) da Catequese")

    doc.build(elementos)
    return buffer.getvalue()
