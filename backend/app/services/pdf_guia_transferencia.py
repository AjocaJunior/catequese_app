import io
from datetime import date

from reportlab.lib.enums import TA_JUSTIFY, TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer

from app.services.pdf_comum import (
    bloco_assinatura_dupla,
    bloco_cabecalho,
    estilos_documento,
    formatar_data_extenso,
)


def gerar_pdf_guia_transferencia(doc: dict, fase: dict | None, pessoas: dict) -> bytes:
    """doc: o catequisando (já com os campos transferencia_* preenchidos).
    pessoas: {'pai': dict|None, 'mae': dict|None} — pessoas resolvidas."""
    buffer = io.BytesIO()
    documento = SimpleDocTemplate(
        buffer, pagesize=A4, topMargin=1.8 * cm, bottomMargin=1.8 * cm, leftMargin=2.2 * cm, rightMargin=2.2 * cm,
    )
    e = estilos_documento()
    elementos: list = []
    largura = documento.width

    elementos += bloco_cabecalho(e, largura)

    numero = doc.get("transferencia_numero") or "—"
    ano_guia = doc.get("transferencia_ano_guia")
    estilo_titulo = ParagraphStyle("titulo_guia", fontName="Helvetica-Bold", fontSize=14, alignment=TA_CENTER, spaceAfter=18)
    elementos.append(Paragraph(f"Guia de Transferência nº. {numero}/{ano_guia if ano_guia else '—'}", estilo_titulo))

    pai = pessoas.get("pai") or {}
    mae = pessoas.get("mae") or {}
    data_nasc = doc.get("data_nascimento")
    ano_frequentado = doc.get("transferencia_ano_frequentado")
    fase_nome = fase["nome"] if fase else "—"
    nome_catecismo = (fase.get("nome_catecismo") if fase else None) or "—"
    destino_comunidade = doc.get("transferencia_destino_comunidade") or "—"
    destino_arquidiocese = doc.get("transferencia_destino_arquidiocese") or "—"

    estilo_corpo = ParagraphStyle(
        "corpo_guia", fontName="Helvetica", fontSize=11.5, alignment=TA_JUSTIFY, leading=18,
    )

    texto = (
        "Para os efeitos julgados convenientes e a pedido do interessado, a Coordenação da Catequese da "
        "Paróquia de Nossa Senhora da Assunção – Liberdade, atesta que "
        f"<b>o(a) {doc['nome']}</b>, nascido(a) aos <b>{formatar_data_extenso(data_nasc)}</b>, "
        f"filho(a) de <b>{pai.get('nome') or '—'}</b>, e de <b>{mae.get('nome') or '—'}</b>, "
        f"frequentou nesta Paróquia no ano de <b>{ano_frequentado if ano_frequentado else '—'}</b>, "
        f"a catequese no(a) <b>{fase_nome}</b> com o catecismo <b>{nome_catecismo}</b> "
        f"e vai ser transferido para a Paróquia/Comunidade <b>{destino_comunidade}</b>, "
        f"da Arquidiocese de <b>{destino_arquidiocese}</b>, a fim de prosseguir com a sua caminhada de fé."
    )
    elementos.append(Paragraph(texto, estilo_corpo))
    elementos.append(Spacer(1, 16))

    observacao = doc.get("transferencia_observacao")
    if observacao:
        estilo_nb = ParagraphStyle("nb_guia", fontName="Helvetica", fontSize=10.5, alignment=TA_JUSTIFY)
        elementos.append(Paragraph(f"<b>NB:</b> {observacao}", estilo_nb))
        elementos.append(Spacer(1, 14))

    estilo_saudacao = ParagraphStyle("saudacao_guia", fontName="Helvetica", fontSize=11.5)
    elementos.append(Paragraph("Saudações fraternas.", estilo_saudacao))
    elementos.append(Spacer(1, 10))

    data_impressao = doc.get("transferencia_data") or date.today()
    elementos.append(Paragraph(f"Liberdade, aos {formatar_data_extenso(data_impressao)}", estilo_saudacao))

    elementos += bloco_assinatura_dupla(e, largura, "O Coordenador", "O Pároco")

    documento.build(elementos)
    return buffer.getvalue()
