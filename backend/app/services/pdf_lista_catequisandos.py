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


def gerar_pdf_lista_catequisandos(
    fase_nome: str,
    catequistas_nomes: list[str],
    catequisandos: list[dict],
) -> bytes:
    """catequisandos: lista de documentos do Mongo (já ordenados alfabeticamente
    pelo chamador), cada um com pelo menos 'nome', e opcionalmente
    'data_nascimento' (datetime) e 'encarregado_contacto'."""
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
    elementos.append(Paragraph(f"Lista de Catequisandos — {fase_nome}", e["titulo_doc"]))

    catequistas_str = ", ".join(catequistas_nomes) or "—"
    elementos.append(campo_rotulo_valor(e, "CATEQUISTA(S) DA FASE", catequistas_str))
    elementos.append(Spacer(1, 12))

    # Estilos próprios da tabela: células como Paragraph, para quebrar texto
    # em vez de sobrepor a coluna seguinte (era o bug do cabeçalho anterior).
    estilo_cabecalho = ParagraphStyle(
        "cabecalho_lista", fontName="Helvetica-Bold", fontSize=8.5,
        textColor=colors.white, alignment=TA_LEFT, leading=10,
    )
    estilo_cabecalho_centro = ParagraphStyle(
        "cabecalho_lista_centro", parent=estilo_cabecalho, alignment=TA_CENTER,
    )
    estilo_celula = ParagraphStyle(
        "celula_lista", fontName="Helvetica", fontSize=9,
        textColor=colors.black, alignment=TA_LEFT, leading=11,
    )
    estilo_celula_centro = ParagraphStyle(
        "celula_lista_centro", parent=estilo_celula, alignment=TA_CENTER,
    )

    def _c(texto: str, estilo=estilo_celula) -> Paragraph:
        return Paragraph(texto, estilo)

    linhas = [[
        _c("Nº", estilo_cabecalho_centro),
        _c("NOME", estilo_cabecalho),
        _c("DATA NASC.", estilo_cabecalho),
        _c("CONT. ENC.", estilo_cabecalho),
        _c("PARENTESCO", estilo_cabecalho),
    ]]
    for i, c in enumerate(catequisandos, start=1):
        data_nasc = c.get("data_nascimento")
        data_str = data_nasc.strftime("%d/%m/%Y") if data_nasc else "—"
        contacto = c.get("encarregado_contacto") or "—"
        parentesco = c.get("encarregado_parentesco") or "—"
        linhas.append([
            _c(str(i), estilo_celula_centro),
            _c(c["nome"]),
            _c(data_str),
            _c(contacto),
            _c(parentesco),
        ])

    if len(linhas) == 1:
        linhas.append([_c("—", estilo_celula_centro), _c("Sem catequisandos nesta fase"), _c("—"), _c("—"), _c("—")])

    largura_util = doc.width
    col_num = 0.9 * cm
    col_data = 2.3 * cm
    col_contacto = 2.6 * cm
    col_parentesco = 2.3 * cm
    col_nome = largura_util - col_num - col_data - col_parentesco - col_contacto

    tabela = Table(
        linhas,
        colWidths=[col_num, col_nome, col_data, col_contacto, col_parentesco],
        repeatRows=1,
    )
    estilo_tabela = [
        ("BACKGROUND", (0, 0), (-1, 0), COR_AZUL_ESCURO),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#DDDDDD")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
    ]
    for i in range(1, len(linhas)):
        if i % 2 == 0:
            estilo_tabela.append(("BACKGROUND", (0, i), (-1, i), COR_LINHA_ALTERNADA))
    tabela.setStyle(TableStyle(estilo_tabela))
    elementos.append(tabela)

    elementos += bloco_assinatura(e, cargo="Coordenador(a) da Catequese")

    doc.build(elementos)
    return buffer.getvalue()
