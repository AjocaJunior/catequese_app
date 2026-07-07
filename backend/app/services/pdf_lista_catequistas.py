import io

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Table, TableStyle

from app.services.pdf_comum import (
    COR_AZUL_ESCURO,
    COR_LINHA_ALTERNADA,
    bloco_assinatura,
    bloco_cabecalho,
    estilos_documento,
)

_ROTULO_DIA = {
    "segunda": "Segunda-feira",
    "terca": "Terça-feira",
    "quarta": "Quarta-feira",
    "quinta": "Quinta-feira",
    "sexta": "Sexta-feira",
    "sabado": "Sábado",
    "domingo": "Domingo",
}


def gerar_pdf_lista_catequistas(fases_com_catequistas: list[dict]) -> bytes:
    """fases_com_catequistas: lista de dicts, cada um com
    'ordem', 'nome', 'dia_semana' (opcional), 'hora' (opcional), 'local' (opcional),
    e 'catequistas': lista de {'nome', 'contacto'}.

    Gera uma única tabela — uma linha por catequista, repetindo os dados da
    fase em cada linha (mesmo formato da planilha original da comunidade).
    Fases sem catequistas atribuídos aparecem com uma linha própria."""
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        topMargin=1.8 * cm,
        bottomMargin=1.8 * cm,
        leftMargin=1.5 * cm,
        rightMargin=1.5 * cm,
    )
    e = estilos_documento()
    elementos: list = []

    elementos += bloco_cabecalho(e, doc.width)
    elementos.append(Paragraph("Lista de Catequistas", e["titulo_doc"]))

    estilo_cabecalho = ParagraphStyle(
        "cabecalho_lista", fontName="Helvetica-Bold", fontSize=8.5,
        textColor=colors.white, alignment=TA_CENTER,
    )
    estilo_cabecalho_esq = ParagraphStyle("cabecalho_lista_esq", parent=estilo_cabecalho, alignment=TA_LEFT)
    estilo_celula = ParagraphStyle(
        "celula_lista", fontName="Helvetica", fontSize=8.5, textColor=colors.black, alignment=TA_CENTER,
    )
    estilo_celula_esq = ParagraphStyle("celula_lista_esq", parent=estilo_celula, alignment=TA_LEFT)

    def _c(texto, estilo=estilo_celula) -> Paragraph:
        return Paragraph(str(texto), estilo)

    linhas = [[
        _c("ORDEM", estilo_cabecalho),
        _c("FASE", estilo_cabecalho_esq),
        _c("DIA DA SEMANA", estilo_cabecalho),
        _c("HORA", estilo_cabecalho),
        _c("LOCAL", estilo_cabecalho),
        _c("NOME", estilo_cabecalho_esq),
        _c("CONTACTO", estilo_cabecalho),
    ]]

    for fase in fases_com_catequistas:
        rotulo_dia = _ROTULO_DIA.get(fase.get("dia_semana"), fase.get("dia_semana") or "—")
        hora = fase.get("hora") or "—"
        local = fase.get("local") or "—"
        catequistas = fase["catequistas"]

        if not catequistas:
            linhas.append([
                _c(fase["ordem"]),
                _c(fase["nome"], estilo_celula_esq),
                _c(rotulo_dia),
                _c(hora),
                _c(local),
                _c("Sem catequistas atribuídos", estilo_celula_esq),
                _c("—"),
            ])
            continue

        for cat in catequistas:
            linhas.append([
                _c(fase["ordem"]),
                _c(fase["nome"], estilo_celula_esq),
                _c(rotulo_dia),
                _c(hora),
                _c(local),
                _c(cat["nome"], estilo_celula_esq),
                _c(cat.get("contacto") or "—"),
            ])

    largura = doc.width
    col_ordem = largura * 0.06
    col_fase = largura * 0.18
    col_dia = largura * 0.14
    col_hora = largura * 0.09
    col_local = largura * 0.13
    col_contacto = largura * 0.14
    col_nome = largura - (col_ordem + col_fase + col_dia + col_hora + col_local + col_contacto)

    tabela = Table(
        linhas,
        colWidths=[col_ordem, col_fase, col_dia, col_hora, col_local, col_nome, col_contacto],
        repeatRows=1,
    )
    estilo_tabela = [
        ("BACKGROUND", (0, 0), (-1, 0), COR_AZUL_ESCURO),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#DDDDDD")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
    ]
    for i in range(1, len(linhas)):
        if i % 2 == 0:
            estilo_tabela.append(("BACKGROUND", (0, i), (-1, i), COR_LINHA_ALTERNADA))
    tabela.setStyle(TableStyle(estilo_tabela))
    elementos.append(tabela)

    elementos += bloco_assinatura(e, cargo="Coordenador(a) da Catequese")

    doc.build(elementos)
    return buffer.getvalue()
