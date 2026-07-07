import io

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.models.pauta import PautaOut
from app.services.pdf_comum import (
    COR_AZUL_ESCURO,
    COR_LINHA_ALTERNADA,
    bloco_assinatura,
    bloco_cabecalho,
    campo_rotulo_valor,
    estilos_documento,
)

_ROTULO_SITUACAO = {
    "permanece": "Permanece",
    "progride": "Progride",
}


def gerar_pdf_pauta(pauta: PautaOut) -> bytes:
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
    elementos.append(Paragraph(f"Pauta — {pauta.fase_nome}", e["titulo_doc"]))
    elementos.append(campo_rotulo_valor(e, "ANO LETIVO", str(pauta.ano_letivo)))
    elementos.append(Spacer(1, 12))

    estilo_cabecalho = ParagraphStyle(
        "cabecalho_pauta", fontName="Helvetica-Bold", fontSize=9,
        textColor=colors.white, alignment=TA_CENTER,
    )
    estilo_cabecalho_esq = ParagraphStyle("cabecalho_pauta_esq", parent=estilo_cabecalho, alignment=TA_LEFT)
    estilo_celula = ParagraphStyle(
        "celula_pauta", fontName="Helvetica", fontSize=9, textColor=colors.black, alignment=TA_CENTER,
    )
    estilo_celula_esq = ParagraphStyle("celula_pauta_esq", parent=estilo_celula, alignment=TA_LEFT)
    estilo_celula_negrito = ParagraphStyle("celula_pauta_negrito", parent=estilo_celula, fontName="Helvetica-Bold")

    def _c(texto: str, estilo=estilo_celula) -> Paragraph:
        return Paragraph(texto, estilo)

    dados_tabela = [[
        _c("NOME", estilo_cabecalho_esq),
        _c("PRESENÇAS", estilo_cabecalho),
        _c("FALTAS", estilo_cabecalho),
        _c("FALTAS JUST.", estilo_cabecalho),
        _c("SITUAÇÃO", estilo_cabecalho),
    ]]

    for item in pauta.itens:
        situacao_texto = _ROTULO_SITUACAO.get(
            item.situacao.value if item.situacao else None, "Por definir"
        )
        estilo_situacao = estilo_celula_negrito if item.situacao else estilo_celula
        dados_tabela.append([
            _c(item.catequisando_nome, estilo_celula_esq),
            _c(str(item.total_presencas)),
            _c(str(item.total_faltas)),
            _c(str(item.total_faltas_justificadas)),
            _c(situacao_texto, estilo_situacao),
        ])

    if len(dados_tabela) == 1:
        dados_tabela.append([_c("Sem catequisandos nesta fase", estilo_celula_esq), _c("—"), _c("—"), _c("—"), _c("—")])

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
    ]
    for i in range(1, len(dados_tabela)):
        if i % 2 == 0:
            estilo_tabela.append(("BACKGROUND", (0, i), (-1, i), COR_LINHA_ALTERNADA))
    tabela.setStyle(TableStyle(estilo_tabela))
    elementos.append(tabela)

    elementos += bloco_assinatura(e, cargo="Catequista da Fase")

    doc.build(elementos)
    return buffer.getvalue()
